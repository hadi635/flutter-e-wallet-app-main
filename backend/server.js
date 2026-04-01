import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import Joi from 'joi';
import admin from 'firebase-admin';
import Stripe from 'stripe';
import { createUsdcMonitor, USDC_MINT_ADDRESS } from './solana_usdc_monitor.js';

const app = express();

// === SECURITY ADDITIONS (minimal) ===
// Helmet for security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
    },
  },
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100, // 100 req/user
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/create-checkout-session', limiter);
app.use('/confirm-topup', limiter);

// Strict CORS
app.use(cors({
  origin: process.env.CLIENT_ORIGINS ? process.env.CLIENT_ORIGINS.split(',') : 'http://localhost:3000',
  credentials: true,
}));

// Auth middleware (verify Firebase ID token)
async function authMiddleware(req, res, next) {
  try {
    const idToken = req.headers.authorization?.replace('Bearer ', '') || req.headers['x-access-token'];
    if (!idToken) return res.status(401).json({ error: 'No token' });
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Own wallet check middleware
async function ownWalletCheck(req, res, next) {
  try {
    const { email, walletId } = req.body;
    const userDoc = await db.collection('user').doc(req.user.email).get();
    if (!userDoc.exists) return res.status(404).json({ error: 'User not found' });
    const userData = userDoc.data();
    if ((email && email.toLowerCase() !== req.user.email.toLowerCase()) ||
        (walletId && walletId !== userData.WalletId)) {
      return res.status(403).json({ error: 'Not your wallet' });
    }
    next();
  } catch (err) {
    res.status(500).json({ error: 'Check failed' });
  }
}

// Joi schemas
const createSessionSchema = Joi.object({
  amount: Joi.number().positive().required(),
  currency: Joi.string().valid('usd').default('usd'),
  email: Joi.string().email().required(),
  walletId: Joi.string().optional(),
});

const confirmSchema = Joi.object({
  sessionId: Joi.string().required(),
});

const createCryptoTopupSchema = Joi.object({
  amount: Joi.number().positive().required(),
  email: Joi.string().email().required(),
  walletId: Joi.string().optional(),
});

const confirmCryptoTopupSchema = Joi.object({
  depositId: Joi.string().required(),
});

// Original code (unchanged structure)
app.use(express.json());
app.use(express.raw({ type: 'application/json' })); // for webhook before json

const port = Number(process.env.PORT || 4242);
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || '';
const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const successUrl =
  process.env.STRIPE_SUCCESS_URL || 'http://localhost:3000/success';
const cancelUrl = process.env.STRIPE_CANCEL_URL || 'http://localhost:3000/cancel';
const configuredTopupFeePercentage = Number(process.env.TOPUP_FEE_PERCENT || 5.5);
const topupFeePercentage = Number.isFinite(configuredTopupFeePercentage)
  ? configuredTopupFeePercentage
  : 5.5;
const configuredTopupFixedFee = Number(process.env.TOPUP_FEE_FIXED || 0.3);
const topupFixedFee = Number.isFinite(configuredTopupFixedFee)
  ? configuredTopupFixedFee
  : 0.3;
const configuredCryptoTopupFeePercentage = Number(
  process.env.CRYPTO_TOPUP_FEE_PERCENT || 3,
);
const cryptoTopupFeePercentage = Number.isFinite(configuredCryptoTopupFeePercentage)
  ? configuredCryptoTopupFeePercentage
  : 3;
const firebaseProjectId = process.env.FIREBASE_PROJECT_ID || 'ewallet-12201';
const firebaseStorageBucket =
  process.env.FIREBASE_STORAGE_BUCKET || 'ewallet-12201.firebasestorage.app';
const firebaseClientEmail = process.env.FIREBASE_CLIENT_EMAIL || '';
const firebasePrivateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(
  /\\n/g,
  '\n',
);

if (!stripeSecretKey) {
  console.error('Missing STRIPE_SECRET_KEY in backend/.env');
  process.exit(1);
}

if (!admin.apps.length) {
  const appOptions = {
    projectId: firebaseProjectId,
    storageBucket: firebaseStorageBucket,
  };

  if (firebaseClientEmail && firebasePrivateKey) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: firebaseProjectId,
        clientEmail: firebaseClientEmail,
        privateKey: firebasePrivateKey,
      }),
      ...appOptions,
    });
  } else {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      ...appOptions,
    });
  }
}

const db = admin.firestore();
const stripe = new Stripe(stripeSecretKey);
const firestoreProjectId = firebaseProjectId;
const solanaWalletAddress = (process.env.SOLANA_WALLET_ADDRESS || '').trim();
const solanaRpcUrl = (process.env.SOLANA_RPC_URL || '').trim();
let usdcMonitor = null;

async function findUserWalletTarget({ email, walletId }) {
  const normalizedWalletId = (walletId || '').toString().trim();
  if (normalizedWalletId) {
    const walletQuery = await db
      .collection('user')
      .where('WalletId', '==', normalizedWalletId)
      .limit(1)
      .get();

    if (!walletQuery.empty) {
      const userRef = walletQuery.docs[0].ref;
      return {
        userRef,
        userDocId: userRef.id,
        matchedBy: `field:WalletId:${normalizedWalletId}`,
      };
    }
  }

  const rawEmail = (email || '').toString().trim();
  if (!rawEmail) {
    throw new Error('Missing email and walletId');
  }

  const normalizedEmail = rawEmail.toLowerCase();
  const candidateDocIds = [...new Set([rawEmail, normalizedEmail])];

  for (const docId of candidateDocIds) {
    const userRef = db.collection('user').doc(docId);
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      return {
        userRef,
        userDocId: userRef.id,
        matchedBy: `doc_id:${docId}`,
      };
    }
  }

  for (const candidateEmail of candidateDocIds) {
    const querySnap = await db
      .collection('user')
      .where('Email', '==', candidateEmail)
      .limit(1)
      .get();
    if (!querySnap.empty) {
      const userRef = querySnap.docs[0].ref;
      return {
        userRef,
        userDocId: userRef.id,
        matchedBy: `field:Email:${candidateEmail}`,
      };
    }
  }

  throw new Error(
    `User wallet document not found for walletId/email: ${normalizedWalletId || '-'} / ${rawEmail}`,
  );
}

function calculateTopupAmounts(grossAmount) {
  const toMoney = (value) => Math.round(Number(value) * 100) / 100;
  const normalizedGross = toMoney(grossAmount);
  const feeAmount = toMoney(
    normalizedGross * (topupFeePercentage / 100) + topupFixedFee,
  );
  const netAmount = toMoney(Math.max(0, normalizedGross - feeAmount));
  return {
    grossAmount: normalizedGross,
    feeAmount,
    netAmount,
  };
}

function calculateCryptoTopupAmounts(grossAmount) {
  const toMoney = (value) => Math.round(Number(value) * 1000000) / 1000000;
  const normalizedGross = toMoney(grossAmount);
  const feeAmount = toMoney(
    normalizedGross * (cryptoTopupFeePercentage / 100),
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

async function creditWalletOnce({
  sessionId,
  email,
  walletId,
  grossAmount,
  feeAmount,
  netAmount,
  feePercentage = topupFeePercentage,
  feeFixed = topupFixedFee,
  source = 'stripe_checkout',
  senderLabel = 'Stripe',
  senderEmail = 'stripe@system',
  senderWalletId = 'STRIPE',
  meta = {},
}) {
  if (
    !sessionId ||
    !Number.isFinite(grossAmount) ||
    !Number.isFinite(feeAmount) ||
    !Number.isFinite(netAmount) ||
    grossAmount <= 0 ||
    netAmount <= 0 ||
    (!email && !walletId)
  ) {
    throw new Error('Invalid top-up payload');
  }

  const { userRef, userDocId, matchedBy } = await findUserWalletTarget({
    email,
    walletId,
  });
  const processedRef = db.collection('processed_topups').doc(sessionId);
  const historyRef = db.collection('history').doc();
  const topupRef = db.collection('topups').doc(sessionId);

  let credited = false;
  await db.runTransaction(async (tx) => {
    const processedSnap = await tx.get(processedRef);
    if (processedSnap.exists) {
      return;
    }

    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new Error(`User document not found for email: ${email}`);
    }

    const currentBalance = Number(userSnap.data()?.Balance || 0);
    const receiverEmail = (
      userSnap.data()?.Email ||
      userDocId ||
      email ||
      ''
    ).toString();
    const receiverName = (userSnap.data()?.['Full Name'] || email).toString();
    const receiverWalletId = (userSnap.data()?.WalletId || '').toString();

    tx.update(userRef, {
      Balance: currentBalance + netAmount,
    });

    tx.set(processedRef, {
      sessionId,
      email,
      walletId: walletId || '',
      userDocId,
      userLookup: matchedBy,
      grossAmount,
      feeAmount,
      netAmount,
      feePercentage,
      feeFixed,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(topupRef, {
      email: receiverEmail,
      walletId: walletId || '',
      userDocId,
      userLookup: matchedBy,
      amount: netAmount,
      grossAmount,
      feeAmount,
      feePercentage,
      feeFixed,
      source,
      reference: sessionId,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...meta,
    });

    tx.set(historyRef, {
      Sender: senderLabel,
      Receiver: receiverName,
      'Receiver Email': receiverEmail,
      'Sender Email': senderEmail,
      'Sender Wallet ID': senderWalletId,
      'Receiver Wallet ID': receiverWalletId,
      receiverWalletId: receiverWalletId,
      userDocId,
      type: 'topup',
      Time: admin.firestore.FieldValue.serverTimestamp(),
      amount: netAmount,
      grossAmount,
      feeAmount,
      source,
      reference: sessionId,
      ...meta,
    });

    credited = true;
  });

  return {
    credited,
    grossAmount,
    feeAmount,
    netAmount,
    userDocId,
    userLookup: matchedBy,
  };
}

async function findPendingCryptoDepositByMicros(amountMicros) {
  const querySnap = await db
    .collection('crypto_pending_topups')
    .where('status', '==', 'pending')
    .where('expectedAmountMicros', '==', amountMicros)
    .limit(1)
    .get();

  if (querySnap.empty) {
    return null;
  }

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

  const reference = `solana_${signature}`;
  const result = await creditWalletOnce({
    sessionId: reference,
    email: pending.email || '',
    walletId: pending.walletId || '',
    grossAmount: Number(pending.expectedAmount || amount),
    feeAmount: Number(pending.feeAmount || 0),
    netAmount: Number(pending.netAmount || amount),
    feePercentage: Number(pending.feePercentage || cryptoTopupFeePercentage),
    feeFixed: 0,
    source: 'solana_usdc',
    senderLabel: 'Solana USDC',
    senderEmail: 'crypto@system',
    senderWalletId: 'SOLANA-USDC',
    meta: {
      tokenMint: USDC_MINT_ADDRESS,
      blockchain: 'solana',
      signature,
    },
  });

  await pendingDoc.ref.set(
    {
      status: result.credited ? 'completed' : 'credited',
      credited: true,
      creditedAt: admin.firestore.FieldValue.serverTimestamp(),
      signature,
      processedReference: reference,
    },
    { merge: true },
  );

  console.log(
    `[Crypto Top-up] Deposit ${pendingDoc.id} credited for ${pending.email || pending.walletId} with signature ${signature}`,
  );
}

async function startSolanaUsdcWatcher() {
  if (!solanaWalletAddress || !solanaRpcUrl) {
    console.log(
      '[Crypto Top-up] SOLANA_WALLET_ADDRESS or SOLANA_RPC_URL is missing. Crypto watcher not started.',
    );
    return;
  }

  usdcMonitor = await createUsdcMonitor({
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

// Webhook (no auth, raw body first)
app.post('/stripe-webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  if (!stripeWebhookSecret) {
    return res.status(500).send('Missing STRIPE_WEBHOOK_SECRET');
  }

  const signature = req.headers['stripe-signature'];
  if (!signature) {
    return res.status(400).send('Missing stripe-signature header');
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, signature, stripeWebhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    if (event.type === 'checkout.session.completed' || event.type === 'checkout.session.async_payment_succeeded') {
      const session = event.data.object;
      const amount = Number(session.amount_total || 0) / 100;
      const email = session.metadata?.email || session.customer_details?.email || '';
      const walletId = (session.metadata?.walletId || '').toString();

      if (session.payment_status === 'paid' && (email || walletId)) {
        const topup = calculateTopupAmounts(amount);
        await creditWalletOnce({
          sessionId: session.id,
          email,
          walletId,
          ...topup,
        });
      }
    }
    return res.json({ received: true });
  } catch (err) {
    console.error('stripe-webhook processing error:', err);
    return res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// Protected endpoints
app.post('/create-checkout-session', authMiddleware, ownWalletCheck, createSessionSchema, async (req, res) => {
  try {
    const { error } = createSessionSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const amount = Number(req.body?.amount || 0);
    const currency = (req.body?.currency || 'usd').toString().toLowerCase();
    const email = (req.body?.email || '').toString();
    const walletId = (req.body?.walletId || '').toString();

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const unitAmount = Math.round(amount * 100);

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      success_url: `${successUrl}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl,
      customer_email: email || undefined,
      payment_method_types: ['card'],
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: unitAmount,
            product_data: {
              name: 'Upay Wallet Top-up',
              description: walletId ? `Wallet: ${walletId}` : 'Wallet top-up',
            },
          },
        },
      ],
      metadata: {
        email,
        walletId,
        amount: String(amount),
      },
    });

    return res.json({
      checkoutUrl: session.url,
      sessionId: session.id,
    });
  } catch (err) {
    console.error('create-checkout-session error:', err);
    return res.status(500).json({ error: 'Unable to create checkout session' });
  }
});

app.post('/confirm-topup', authMiddleware, ownWalletCheck, confirmSchema, async (req, res) => {
  try {
    const { error } = confirmSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const sessionId = (req.body?.sessionId || '').toString();
    if (!sessionId) {
      return res.status(400).json({ error: 'Missing sessionId' });
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);
    const amount = Number(session.amount_total || 0) / 100;
    const email = session.metadata?.email || session.customer_details?.email || '';
    const walletId = (session.metadata?.walletId || '').toString();

    if (session.payment_status !== 'paid') {
      return res.json({
        success: true,
        credited: false,
        message: 'Payment is not completed yet',
      });
    }

    if (!email && !walletId) {
      return res.status(400).json({
        error: 'Missing email/walletId on checkout session',
      });
    }

    const topup = calculateTopupAmounts(amount);
    const result = await creditWalletOnce({
      sessionId: session.id,
      email,
      walletId,
      ...topup,
    });

    return res.json({
      success: true,
      credited: result.credited,
      grossAmount: result.grossAmount,
      feeAmount: result.feeAmount,
      netAmount: result.netAmount,
      userDocId: result.userDocId,
      userLookup: result.userLookup,
      firebaseProjectId: firestoreProjectId,
      message: result.credited
        ? 'Wallet credited successfully'
        : 'Top-up already credited',
    });
  } catch (err) {
    console.error('confirm-topup error:', err);
    return res.status(500).json({ error: 'Unable to confirm top-up' });
  }
});

app.post(
  '/create-crypto-topup',
  authMiddleware,
  ownWalletCheck,
  async (req, res) => {
    try {
      const { error } = createCryptoTopupSchema.validate(req.body);
      if (error) {
        return res.status(400).json({ error: error.details[0].message });
      }

      if (!solanaWalletAddress) {
        return res.status(500).json({ error: 'Crypto wallet is not configured' });
      }

      const amount = Number(req.body?.amount || 0);
      const email = (req.body?.email || '').toString().trim();
      const walletId = (req.body?.walletId || '').toString().trim();

      if (!Number.isFinite(amount) || amount <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const exact = generateCryptoExactAmount(amount);
      const totals = calculateCryptoTopupAmounts(exact.exactAmount);
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
        feePercentage: cryptoTopupFeePercentage,
        status: 'pending',
        blockchain: 'solana',
        tokenSymbol: 'USDC',
        tokenMint: USDC_MINT_ADDRESS,
        depositWalletAddress: solanaWalletAddress,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({
        depositId: depositRef.id,
        depositWalletAddress: solanaWalletAddress,
        tokenMint: USDC_MINT_ADDRESS,
        tokenSymbol: 'USDC',
        blockchain: 'Solana',
        amountToSend: totals.grossAmount,
        requestedAmount: amount,
        feeAmount: totals.feeAmount,
        netAmount: totals.netAmount,
        status: 'pending',
      });
    } catch (err) {
      console.error('create-crypto-topup error:', err);
      return res.status(500).json({ error: 'Unable to create crypto top-up' });
    }
  },
);

app.post(
  '/confirm-crypto-topup',
  authMiddleware,
  async (req, res) => {
    try {
      const { error } = confirmCryptoTopupSchema.validate(req.body);
      if (error) {
        return res.status(400).json({ error: error.details[0].message });
      }

      const depositId = (req.body?.depositId || '').toString().trim();
      const depositSnap = await db
        .collection('crypto_pending_topups')
        .doc(depositId)
        .get();

      if (!depositSnap.exists) {
        return res.status(404).json({ error: 'Crypto top-up not found' });
      }

      const data = depositSnap.data() || {};
      if (
        (data.email || '').toString().toLowerCase() !== req.user.email.toLowerCase()
      ) {
        return res.status(403).json({ error: 'Not your crypto top-up' });
      }

      return res.json({
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
      });
    } catch (err) {
      console.error('confirm-crypto-topup error:', err);
      return res.status(500).json({ error: 'Unable to confirm crypto top-up' });
    }
  },
);

// Health (no auth)
app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'stripe-backend',
  });
});

app.listen(port, () => {
  console.log(`Stripe backend running on http://localhost:${port}`);
  startSolanaUsdcWatcher().catch((error) => {
    console.error('[Crypto Top-up] Failed to start Solana watcher:', error);
  });
});
