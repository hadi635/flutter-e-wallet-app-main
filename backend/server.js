import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import admin from 'firebase-admin';
import Stripe from 'stripe';

const app = express();
app.use(cors());

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
  const feeAmount = Math.round(
    grossAmount * (topupFeePercentage / 100) + topupFixedFee,
  );
  const netAmount = Math.max(0, grossAmount - feeAmount);
  return {
    grossAmount,
    feeAmount,
    netAmount,
  };
}

async function creditWalletOnce({
  sessionId,
  email,
  walletId,
  grossAmount,
  feeAmount,
  netAmount,
}) {
  if (
    !sessionId ||
    !email ||
    !Number.isFinite(grossAmount) ||
    !Number.isFinite(feeAmount) ||
    !Number.isFinite(netAmount) ||
    grossAmount <= 0 ||
    netAmount <= 0
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
      feePercentage: topupFeePercentage,
      feeFixed: topupFixedFee,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(topupRef, {
      email,
      walletId: walletId || '',
      userDocId,
      userLookup: matchedBy,
      amount: netAmount,
      grossAmount,
      feeAmount,
      feePercentage: topupFeePercentage,
      feeFixed: topupFixedFee,
      source: 'stripe_checkout',
      reference: sessionId,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(historyRef, {
      Sender: 'Stripe',
      Receiver: receiverName,
      'Receiver Email': email,
      'Sender Email': 'stripe@system',
      'Sender Wallet ID': 'STRIPE',
      'Receiver Wallet ID': receiverWalletId,
      receiverWalletId: receiverWalletId,
      userDocId,
      type: 'topup',
      Time: admin.firestore.FieldValue.serverTimestamp(),
      amount: netAmount,
      grossAmount,
      feeAmount,
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

app.post(
  '/stripe-webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    if (!stripeWebhookSecret) {
      return res.status(500).send('Missing STRIPE_WEBHOOK_SECRET');
    }

    const signature = req.headers['stripe-signature'];
    if (!signature) {
      return res.status(400).send('Missing stripe-signature header');
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        signature,
        stripeWebhookSecret,
      );
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      if (
        event.type === 'checkout.session.completed' ||
        event.type === 'checkout.session.async_payment_succeeded'
      ) {
        const session = event.data.object;
        const amount = Math.round(Number(session.amount_total || 0) / 100);
        const email =
          session.metadata?.email || session.customer_details?.email || '';
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
  },
);

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'stripe-backend',
    firebaseProjectId: firestoreProjectId,
    feePercent: topupFeePercentage,
    feeFixed: topupFixedFee,
  });
});

app.post('/create-checkout-session', async (req, res) => {
  try {
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

app.post('/confirm-topup', async (req, res) => {
  try {
    const sessionId = (req.body?.sessionId || '').toString();
    if (!sessionId) {
      return res.status(400).json({ error: 'Missing sessionId' });
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);
    const amount = Math.round(Number(session.amount_total || 0) / 100);
    const email =
      session.metadata?.email || session.customer_details?.email || '';
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

app.listen(port, () => {
  console.log(`Stripe backend running on http://localhost:${port}`);
});
