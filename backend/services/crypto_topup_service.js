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

  async function findPendingCryptoDeposit({
    amountMicros,
    senderWalletAddress,
  }) {
    const normalizedSenderWalletAddress = (senderWalletAddress || '').toString().trim();

    if (normalizedSenderWalletAddress) {
      const senderQuery = await db
        .collection('crypto_pending_topups')
        .where('status', '==', 'pending')
        .where('expectedAmountMicros', '==', amountMicros)
        .where('senderWalletAddress', '==', normalizedSenderWalletAddress)
        .limit(1)
        .get();

      if (!senderQuery.empty) {
        return senderQuery.docs[0];
      }
    }

    return findPendingCryptoDepositByMicros(amountMicros);
  }

  async function processIncomingCryptoPayment(amount, signature, details = {}) {
    const amountMicros = Math.round(Number(amount) * 1000000);
    if (!Number.isFinite(amountMicros) || amountMicros <= 0) {
      return;
    }

    const senderWalletAddress = (details.senderWalletAddress || '').toString().trim();
    const pendingDoc = await findPendingCryptoDeposit({
      amountMicros,
      senderWalletAddress,
    });
    if (!pendingDoc) {
      console.log(
        `[Crypto Top-up] No pending deposit matched ${amount} USDC for signature ${signature} from ${senderWalletAddress || 'unknown sender'}`,
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
        senderWalletAddress: senderWalletAddress || pending.senderWalletAddress || '',
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
        matchedSenderWalletAddress:
          senderWalletAddress || pending.senderWalletAddress || '',
        actualCryptoAmountReceived: Number(amount),
        usdRateAtCredit: usdRate,
        creditedGrossUsdAmount: usdTotals.grossAmount,
        creditedFeeUsdAmount: usdTotals.feeAmount,
        creditedNetUsdAmount: usdTotals.netAmount,
      },
      { merge: true },
    );

    if (pending.pendingHistoryId) {
      await db.collection('history').doc(pending.pendingHistoryId).set({
        status: result.credited ? 'completed' : 'credited',
        amount: usdTotals.netAmount,
        grossAmount: usdTotals.grossAmount,
        feeAmount: usdTotals.feeAmount,
        signature,
        senderWalletAddress:
          senderWalletAddress || pending.senderWalletAddress || '',
        Time: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }

  async function createTopup({ amount, email, walletId, senderWalletAddress }) {
    if (!solanaWalletAddress) {
      throw new Error('Crypto wallet is not configured');
    }

    const normalizedSenderWalletAddress = (senderWalletAddress || '').toString().trim();
    if (!normalizedSenderWalletAddress) {
      throw new Error('Sender wallet address is required');
    }

    const exact = generateCryptoExactAmount(amount);
    const totals = calculateCryptoTopupAmounts(
      exact.exactAmount,
      cryptoTopupFeePercentage,
    );
    const target = await findUserWalletTarget({ email, walletId });
    const depositRef = db.collection('crypto_pending_topups').doc();
    const historyRef = db.collection('history').doc();
    const targetSnap = await target.userRef.get();
    const targetData = targetSnap.data() || {};

    await depositRef.set({
      depositId: depositRef.id,
      email,
      walletId,
      senderWalletAddress: normalizedSenderWalletAddress,
      userDocId: target.userDocId,
      userLookup: target.matchedBy,
      pendingHistoryId: historyRef.id,
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

    await historyRef.set({
      Sender: 'Pending Crypto Deposit',
      Receiver: (targetData['Full Name'] || email).toString(),
      'Receiver Email': (targetData['Email'] || email).toString(),
      'Sender Email': 'crypto@pending',
      'Sender Wallet ID': normalizedSenderWalletAddress,
      senderWalletAddress: normalizedSenderWalletAddress,
      'Receiver Wallet ID': (targetData['WalletId'] || walletId || '').toString(),
      receiverWalletId: (targetData['WalletId'] || walletId || '').toString(),
      type: 'topup',
      status: 'pending',
      Time: admin.firestore.FieldValue.serverTimestamp(),
      amount: 0,
      requestedAmount: amount,
      expectedAmount: totals.grossAmount,
      feeAmount: totals.feeAmount,
      reference: depositRef.id,
      source: 'solana_usdc_pending',
    });

    return {
      depositId: depositRef.id,
      senderWalletAddress: normalizedSenderWalletAddress,
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
      senderWalletAddress: data.senderWalletAddress || '',
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
      onIncomingPayment: async (amount, signature, details) => {
        try {
          await processIncomingCryptoPayment(amount, signature, details);
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
