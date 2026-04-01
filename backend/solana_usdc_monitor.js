import { Connection, PublicKey, clusterApiUrl } from '@solana/web3.js';

const TOKEN_PROGRAM_ID = new PublicKey(
  'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
);
const ASSOCIATED_TOKEN_PROGRAM_ID = new PublicKey(
  'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL',
);
export const USDC_MINT_ADDRESS =
  'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

function resolveRpcHttpUrl(rpcUrl) {
  const trimmed = (rpcUrl || '').trim();
  if (trimmed) {
    return trimmed;
  }
  return clusterApiUrl('mainnet-beta');
}

function resolveRpcWsUrl(rpcUrl) {
  const parsed = new URL(resolveRpcHttpUrl(rpcUrl));
  if (parsed.protocol === 'https:') {
    parsed.protocol = 'wss:';
  } else if (parsed.protocol === 'http:') {
    parsed.protocol = 'ws:';
  }
  return parsed.toString();
}

function normalizeBalance(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return 0;
  return amount;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function deriveAssociatedTokenAccount(walletAddress, mintAddress) {
  const wallet = new PublicKey(walletAddress);
  const mint = new PublicKey(mintAddress);
  const [ata] = PublicKey.findProgramAddressSync(
    [wallet.toBuffer(), TOKEN_PROGRAM_ID.toBuffer(), mint.toBuffer()],
    ASSOCIATED_TOKEN_PROGRAM_ID,
  );
  return ata;
}

async function getTokenUiAmount(connection, ataAddress) {
  try {
    const result = await connection.getTokenAccountBalance(ataAddress, 'confirmed');
    return normalizeBalance(result?.value?.uiAmount ?? 0);
  } catch (error) {
    // Fresh wallets may not have an ATA yet. Treat that as zero until created.
    if (
      error?.message?.includes('could not find account') ||
      error?.message?.includes('Invalid param')
    ) {
      return 0;
    }
    throw error;
  }
}

async function findMatchingIncomingSignature({
  connection,
  ataAddress,
  previousBalance,
  nextBalance,
  mintAddress,
}) {
  const signatures = await connection.getSignaturesForAddress(ataAddress, {
    limit: 10,
  });

  for (const item of signatures) {
    if (!item.signature || item.err) continue;

    const tx = await connection.getParsedTransaction(item.signature, {
      commitment: 'confirmed',
      maxSupportedTransactionVersion: 0,
    });
    if (!tx?.meta) continue;

    const preTokenBalance = tx.meta.preTokenBalances?.find(
      (entry) =>
        entry.accountIndex !== undefined &&
        entry.mint === mintAddress &&
        entry.owner &&
        entry.uiTokenAmount,
    );
    const postTokenBalance = tx.meta.postTokenBalances?.find(
      (entry) =>
        entry.accountIndex !== undefined &&
        entry.mint === mintAddress &&
        entry.owner &&
        entry.uiTokenAmount,
    );

    const preAmount = normalizeBalance(preTokenBalance?.uiTokenAmount?.uiAmount);
    const postAmount = normalizeBalance(postTokenBalance?.uiTokenAmount?.uiAmount);

    const matchesCurrentWindow =
        Math.abs(preAmount - previousBalance) < 0.000001 &&
        Math.abs(postAmount - nextBalance) < 0.000001;
    const isIncoming = postAmount > preAmount;

    if (matchesCurrentWindow && isIncoming) {
      return item.signature;
    }
  }

  const fallback = signatures.find((item) => item.signature && !item.err);
  return fallback?.signature ?? 'unknown';
}

export class SolanaUsdcMonitor {
  constructor({
    walletAddress,
    rpcUrl,
    mintAddress = USDC_MINT_ADDRESS,
    commitment = 'confirmed',
    reconnectDelayMs = 5000,
    heartbeatIntervalMs = 30000,
    onIncomingPayment,
  }) {
    if (!walletAddress) {
      throw new Error('walletAddress is required');
    }
    if (typeof onIncomingPayment !== 'function') {
      throw new Error('onIncomingPayment callback is required');
    }

    this.walletAddress = walletAddress;
    this.rpcUrl = resolveRpcHttpUrl(rpcUrl);
    this.wsUrl = resolveRpcWsUrl(this.rpcUrl);
    this.mintAddress = mintAddress;
    this.commitment = commitment;
    this.reconnectDelayMs = reconnectDelayMs;
    this.heartbeatIntervalMs = heartbeatIntervalMs;
    this.onIncomingPayment = onIncomingPayment;

    this.connection = null;
    this.ataAddress = deriveAssociatedTokenAccount(walletAddress, mintAddress);
    this.subscriptionId = null;
    this.heartbeatTimer = null;
    this.reconnectTimer = null;
    this.lastKnownBalance = 0;
    this.lastSeenSignature = null;
    this.isStopping = false;
    this.isReconnecting = false;
  }

  async start() {
    this.isStopping = false;
    await this.#connectAndSubscribe();
  }

  async stop() {
    this.isStopping = true;

    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.connection && this.subscriptionId !== null) {
      try {
        await this.connection.removeAccountChangeListener(this.subscriptionId);
      } catch (error) {
        console.error('Failed to remove Solana account listener:', error);
      }
    }

    this.subscriptionId = null;
    this.connection = null;
  }

  async #connectAndSubscribe() {
    this.connection = new Connection(this.rpcUrl, {
      commitment: this.commitment,
      wsEndpoint: this.wsUrl,
    });

    this.lastKnownBalance = await getTokenUiAmount(this.connection, this.ataAddress);
    console.log(
      `[USDC Monitor] Watching wallet ${this.walletAddress} on ATA ${this.ataAddress.toBase58()}. Current USDC balance: ${this.lastKnownBalance}`,
    );

    this.subscriptionId = this.connection.onAccountChange(
      this.ataAddress,
      async () => {
        await this.#handleAccountChange();
      },
      this.commitment,
    );

    this.#attachWebSocketLifecycleHandlers();
    this.#startHeartbeat();
  }

  #attachWebSocketLifecycleHandlers() {
    const ws = this.connection?._rpcWebSocket;
    if (!ws || typeof ws.on !== 'function') {
      return;
    }

    ws.on('error', (error) => {
      console.error('[USDC Monitor] WebSocket error:', error);
      this.#scheduleReconnect();
    });

    ws.on('close', () => {
      console.warn('[USDC Monitor] WebSocket closed. Reconnecting...');
      this.#scheduleReconnect();
    });
  }

  #startHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
    }

    this.heartbeatTimer = setInterval(async () => {
      try {
        await this.connection.getSlot(this.commitment);
      } catch (error) {
        console.error('[USDC Monitor] Heartbeat failed:', error);
        this.#scheduleReconnect();
      }
    }, this.heartbeatIntervalMs);
  }

  async #handleAccountChange() {
    try {
      const nextBalance = await getTokenUiAmount(this.connection, this.ataAddress);
      if (nextBalance <= this.lastKnownBalance) {
        this.lastKnownBalance = nextBalance;
        return;
      }

      const receivedAmount = Number(
        (nextBalance - this.lastKnownBalance).toFixed(6),
      );
      const signature = await findMatchingIncomingSignature({
        connection: this.connection,
        ataAddress: this.ataAddress,
        previousBalance: this.lastKnownBalance,
        nextBalance,
        mintAddress: this.mintAddress,
      });

      if (signature === this.lastSeenSignature) {
        this.lastKnownBalance = nextBalance;
        return;
      }

      this.lastSeenSignature = signature;
      this.lastKnownBalance = nextBalance;

      console.log(`[USDC Monitor] Incoming payment detected: ${receivedAmount} USDC`);
      console.log(`[USDC Monitor] Transaction signature: ${signature}`);

      await this.onIncomingPayment(receivedAmount, signature);
    } catch (error) {
      console.error('[USDC Monitor] Failed to process account change:', error);
    }
  }

  #scheduleReconnect() {
    if (this.isStopping || this.isReconnecting) {
      return;
    }

    this.isReconnecting = true;

    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }

    this.reconnectTimer = setTimeout(async () => {
      try {
        if (this.connection && this.subscriptionId !== null) {
          await this.connection.removeAccountChangeListener(this.subscriptionId);
        }
      } catch (error) {
        console.error('[USDC Monitor] Failed to clean old subscription:', error);
      } finally {
        this.connection = null;
        this.subscriptionId = null;
      }

      while (!this.isStopping) {
        try {
          console.log('[USDC Monitor] Attempting to reconnect...');
          await this.#connectAndSubscribe();
          this.isReconnecting = false;
          console.log('[USDC Monitor] Reconnected successfully.');
          return;
        } catch (error) {
          console.error('[USDC Monitor] Reconnect failed:', error);
          await delay(this.reconnectDelayMs);
        }
      }
    }, this.reconnectDelayMs);
  }
}

export async function createUsdcMonitor({
  walletAddress,
  rpcUrl,
  onIncomingPayment,
}) {
  const monitor = new SolanaUsdcMonitor({
    walletAddress,
    rpcUrl,
    onIncomingPayment,
  });
  await monitor.start();
  return monitor;
}

/**
 * Installation:
 *   npm install @solana/web3.js
 *
 * Sample usage:
 *   node solana_usdc_monitor.js <PHANTOM_WALLET_ADDRESS> <RPC_HTTP_URL>
 *
 * Example:
 *   node solana_usdc_monitor.js 8abc...xyz https://your-quicknode-endpoint
 */
async function runExample() {
  const walletAddress = process.argv[2] || process.env.SOLANA_WALLET_ADDRESS;
  const rpcUrl = process.argv[3] || process.env.SOLANA_RPC_URL;

  if (!walletAddress) {
    console.error(
      'Missing wallet address. Pass it as the first argument or set SOLANA_WALLET_ADDRESS.',
    );
    process.exit(1);
  }

  if (!rpcUrl) {
    console.error(
      'Missing Solana RPC URL. Pass it as the second argument or set SOLANA_RPC_URL.',
    );
    process.exit(1);
  }

  const monitor = await createUsdcMonitor({
    walletAddress,
    rpcUrl,
    onIncomingPayment: async (amount, signature) => {
      console.log(
        `[Callback] onIncomingPayment(amount=${amount}, signature=${signature})`,
      );

      // Replace this block with production logic, for example:
      // - credit a user wallet in Firestore
      // - mark a pending crypto deposit as completed
      // - notify your backend or app
    },
  });

  const shutdown = async () => {
    console.log('\n[USDC Monitor] Shutting down...');
    await monitor.stop();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  runExample().catch((error) => {
    console.error('[USDC Monitor] Fatal error:', error);
    process.exit(1);
  });
}
