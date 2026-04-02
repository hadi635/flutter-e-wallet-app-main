import admin from 'firebase-admin';
import { createUsdcMonitor, USDC_MINT_ADDRESS } from '../solana_usdc_monitor.js';

function calculateCryptoTopupAmounts(grossAmount, feePercentage) {
  const toMoney = (value) => Math.round(Number(value) * 1000000) / 1000000;
  const normalizedGross = toMoney(grossAmount);
  const feeAmount = toMoney(
    normalizedGross * (Number(feePercentage) / 100),
  );
  const netAmount = toMoney(Math.max(0, normalizedGross - feeAmount));
  return {
    grossAmount: normalizedGross,
    feeAmount,
    netAmount,
  };
}

function generateCryptoExactAmount(amount) {
  const toMicros = (value) => Math.round(Number(value) * 1000000);
  const baseMicros = toMicros(amount);
  const randomMarker = Math.floor(Math.random() * 900) + 100;
  const exactMicros = baseMicros + randomMarker;
  return {
    exactAmount: exactMicros / 1000000,
    exactAmountMicros: exactMicros,
    markerMicros: randomMarker,
  };
}

function resolveCryptoUsdRate({ tokenSymbol, tokenMint }) {
  const normalizedSymbol = (tokenSymbol || '').toString().trim().toUpperCase();
  const normalizedMint = (tokenMint || '').toString().trim();

  if (normalizedSymbol === 'USDC' || normalizedMint === USDC_MINT_ADDRESS) {
    return 1;
  }

  return 1;
}

export function createCryptoTopupService({
  db,
  solanaWalletAddress,
  solanaRpcUrl,
  cryptoTopupFeePercentage,
  creditWalletOnce,
  findUserWalletTarget,
}) {
  async function findPendingCryptoDepositByMicros(amountMicros) {
    const querySnap = await db
      .collection('crypto_pending_topups')
      .where('status', '==', 'pending')
      .where('expectedAmountMicros', '==', amountMicros)
      .limit(1)
      .get();

    if (querySnap.empty) return null;
    return querySnap.docs[0];
  }

  async function processIncomingCryptoPayment(amount, signature) {
    const amountMicros = Math.round(Number(amount) * 1000000);
    if (!Number.isFinite(amountMicros) || amountMicros <= 0) {
      return;
    }

    const pendingDoc = await findPendingCryptoDepositByMicros(amountMicros);
    if (!pendingDoc) {
      console.log(
        `[Crypto Top-up] No pending deposit matched ${amount} USDC for signature ${signature}`,
      );
      return;
    }

    const pending = pendingDoc.data();
    if (!pending?.email && !pending?.walletId) {
      console.error(
        `[Crypto Top-up] Pending deposit ${pendingDoc.id} is missing email/walletId`,
      );
      return;
    }

    const usdRate = resolveCryptoUsdRate({
      tokenSymbol: pending.tokenSymbol,
      tokenMint: pending.tokenMint,
    });
    const usdGrossAmount = Number((Number(amount) * usdRate).toFixed(6));
    const usdTotals = calculateCryptoTopupAmounts(
      usdGrossAmount,
      cryptoTopupFeePercentage,
    );

    const reference = `solana_${signature}`;
    const result = await creditWalletOnce({
      sessionId: reference,
      email: pending.email || '',
      walletId: pending.walletId || '',
      grossAmount: usdTotals.grossAmount,
      feeAmount: usdTotals.feeAmount,
      netAmount: usdTotals.netAmount,
      feePercentage: cryptoTopupFeePercentage,
      feeFixed: 0,
      source: 'solana_usdc',
      senderLabel: 'Solana USDC',
      senderEmail: 'crypto@system',
      senderWalletId: 'SOLANA-USDC',
      meta: {
        tokenMint: USDC_MINT_ADDRESS,
        tokenSymbol: pending.tokenSymbol || 'USDC',
        blockchain: 'solana',
        signature,
        cryptoAmountReceived: Number(amount),
        usdRateAtCredit: usdRate,
        usdGrossAmount,
      },
    });

    await pendingDoc.ref.set(
      {
        status: result.credited ? 'completed' : 'credited',
        credited: true,
        creditedAt: admin.firestore.FieldValue.serverTimestamp(),
        signature,
        processedReference: reference,
        actualCryptoAmountReceived: Number(amount),
        usdRateAtCredit: usdRate,
        creditedGrossUsdAmount: usdTotals.grossAmount,
        creditedFeeUsdAmount: usdTotals.feeAmount,
        creditedNetUsdAmount: usdTotals.netAmount,
      },
      { merge: true },
    );
  }

  async function createTopup({ amount, email, walletId }) {
    if (!solanaWalletAddress) {
      throw new Error('Crypto wallet is not configured');
    }

    const exact = generateCryptoExactAmount(amount);
    const totals = calculateCryptoTopupAmounts(
      exact.exactAmount,
      cryptoTopupFeePercentage,
    );
    const target = await findUserWalletTarget({ email, walletId });
    const depositRef = db.collection('crypto_pending_topups').doc();

    await depositRef.set({
      depositId: depositRef.id,
      email,
      walletId,
      userDocId: target.userDocId,
      userLookup: target.matchedBy,
      requestedAmount: amount,
      requestedAmountMicros: Math.round(amount * 1000000),
      expectedAmount: totals.grossAmount,
      expectedAmountMicros: exact.exactAmountMicros,
      markerMicros: exact.markerMicros,
      feeAmount: totals.feeAmount,
      netAmount: totals.netAmount,
      estimatedUsdRate: 1,
      feePercentage: cryptoTopupFeePercentage,
      status: 'pending',
      blockchain: 'solana',
      tokenSymbol: 'USDC',
      tokenMint: USDC_MINT_ADDRESS,
      depositWalletAddress: solanaWalletAddress,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      depositId: depositRef.id,
      depositWalletAddress: solanaWalletAddress,
      tokenMint: USDC_MINT_ADDRESS,
      tokenSymbol: 'USDC',
      blockchain: 'Solana',
      amountToSend: totals.grossAmount,
      requestedAmount: amount,
      feeAmount: totals.feeAmount,
      netAmount: totals.netAmount,
      estimatedUsdRate: 1,
      status: 'pending',
    };
  }

  async function confirmTopup({ depositId, requesterEmail }) {
    const depositSnap = await db
      .collection('crypto_pending_topups')
      .doc(depositId)
      .get();

    if (!depositSnap.exists) {
      throw new Error('Crypto top-up not found');
    }

    const data = depositSnap.data() || {};
    if ((data.email || '').toString().toLowerCase() !== requesterEmail.toLowerCase()) {
      throw new Error('Not your crypto top-up');
    }

    return {
      success: true,
      credited: data.status === 'completed' || data.credited === true,
      status: data.status || 'pending',
      amountToSend: data.expectedAmount || 0,
      netAmount: data.netAmount || 0,
      feeAmount: data.feeAmount || 0,
      depositWalletAddress: data.depositWalletAddress || '',
      tokenMint: data.tokenMint || USDC_MINT_ADDRESS,
      tokenSymbol: data.tokenSymbol || 'USDC',
      blockchain: data.blockchain || 'Solana',
      signature: data.signature || '',
      message:
        data.status === 'completed' || data.credited === true
          ? 'Wallet credited successfully'
          : 'Waiting for the Solana USDC payment to arrive',
    };
  }

  async function startWatcher() {
    if (!solanaWalletAddress || !solanaRpcUrl) {
      console.log(
        '[Crypto Top-up] SOLANA_WALLET_ADDRESS or SOLANA_RPC_URL is missing. Crypto watcher not started.',
      );
      return null;
    }

    return createUsdcMonitor({
      walletAddress: solanaWalletAddress,
      rpcUrl: solanaRpcUrl,
      onIncomingPayment: async (amount, signature) => {
        try {
          await processIncomingCryptoPayment(amount, signature);
        } catch (error) {
          console.error('[Crypto Top-up] Failed to process incoming payment:', error);
        }
      },
    });
  }

  return {
    createTopup,
    confirmTopup,
    startWatcher,
  };
}
