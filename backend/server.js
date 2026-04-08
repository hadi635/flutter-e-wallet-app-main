import 'dotenv/config';
import axios from 'axios';
import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import Joi from 'joi';
import admin from 'firebase-admin';
import Stripe from 'stripe';
import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { createCryptoTopupService } from './services/crypto_topup_service.js';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadDir = path.join(__dirname, 'uploads', 'profiles');
const isProduction = process.env.NODE_ENV === 'production';

app.disable('x-powered-by');
app.set('trust proxy', 1);

// === SECURITY ADDITIONS (minimal) ===
// Helmet for security headers
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        baseUri: ["'self'"],
        frameAncestors: ["'none'"],
        formAction: ["'self'"],
        objectSrc: ["'none'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
      },
    },
    crossOriginEmbedderPolicy: false,
    hsts: isProduction
      ? {
          maxAge: 31536000,
          includeSubDomains: true,
          preload: true,
        }
      : false,
    referrerPolicy: { policy: 'no-referrer' },
  }),
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100, // 100 req/user
  standardHeaders: true,
  legacyHeaders: false,
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
});
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/create-checkout-session', limiter);
app.use('/confirm-topup', limiter);
app.use('/moonpay/sign-url', authLimiter);
app.use('/api/moonpay/sign-url', authLimiter);
app.use('/moonpay/verify', authLimiter);
app.use('/api/moonpay/verify', authLimiter);
app.use('/moonpay/webhook', limiter);
app.use('/api/moonpay/webhook', limiter);
app.use('/upload-profile-image', limiter);
app.use('/create-crypto-topup', authLimiter);
app.use('/confirm-crypto-topup', authLimiter);
app.use('/upload-profile-image', uploadLimiter);

// Strict CORS
const allowedOrigins = new Set(
  (process.env.CLIENT_ORIGINS ||
          [
            'http://localhost:3000',
            'https://infinity-sharing.money',
            'https://www.infinity-sharing.money',
          ].join(','))
      .split(',')
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0),
);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.has(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error(`CORS blocked for origin: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type', 'Stripe-Signature'],
    optionsSuccessStatus: 204,
  }),
);

function requireAllowedOrigin(req, res, next) {
  const origin = req.headers.origin;
  if (!origin || allowedOrigins.has(origin)) {
    next();
    return;
  }
  res.status(403).json({ error: 'Origin not allowed' });
}

function requireJsonBody(req, res, next) {
  if (req.method === 'GET' || req.method === 'HEAD') {
    next();
    return;
  }
  if (!req.is('application/json')) {
    res.status(415).json({ error: 'Content-Type must be application/json' });
    return;
  }
  next();
}

function validateConfiguredUrl(value, { allowHttpLocalhost = false } = {}) {
  let parsed;
  try {
    parsed = new URL(value);
  } catch (_error) {
    throw new Error(`Invalid URL: ${value}`);
  }

  if (allowHttpLocalhost && parsed.protocol === 'http:' && parsed.hostname === 'localhost') {
    return parsed.toString().replace(/\/+$/, '');
  }

  if (parsed.protocol !== 'https:') {
    throw new Error(`URL must use https: ${value}`);
  }

  return parsed.toString().replace(/\/+$/, '');
}

function detectImageType(buffer) {
  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return 'image/png';
  }

  if (
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
    return 'image/jpeg';
  }

  if (
    buffer.length >= 12 &&
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP'
  ) {
    return 'image/webp';
  }

  return null;
}

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
  amount: Joi.number().positive().max(10000).required(),
  currency: Joi.string().valid('usd').default('usd'),
  email: Joi.string().email().required(),
  walletId: Joi.string().optional(),
});

const confirmSchema = Joi.object({
  sessionId: Joi.string().required(),
});

const createCryptoTopupSchema = Joi.object({
  amount: Joi.number().positive().max(10000).required(),
  email: Joi.string().email().required(),
  walletId: Joi.string().optional(),
  senderWalletAddress: Joi.string().required(),
});

const confirmCryptoTopupSchema = Joi.object({
  depositId: Joi.string().required(),
});

const signMoonPayUrlSchema = Joi.object({
  url: Joi.string().uri({ scheme: ['https'] }).required(),
});

const verifyMoonPaySchema = Joi.object({
  transactionId: Joi.string().required(),
});

const initializeUserProfileSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(120).required(),
  dateOfBirth: Joi.string().trim().max(40).required(),
  country: Joi.string().trim().min(2).max(80).required(),
  averageMonthlyTransactions: Joi.string().trim().max(80).required(),
  profileImage: Joi.string().allow('').max(4096).default(''),
});

const walletTransferSchema = Joi.object({
  receiverWalletId: Joi.string().trim().min(4).max(40).required(),
  amount: Joi.number().positive().max(10000).required(),
});

const addMoneyRequestSchema = Joi.object({
  method: Joi.string().valid('wish', 'card').required(),
  amount: Joi.number().positive().max(10000).required(),
  note: Joi.string().allow('').max(500).default(''),
  paymentReference: Joi.string().allow('').max(120).default(''),
  senderName: Joi.string().allow('').max(120).default(''),
  senderPhone: Joi.string().allow('').max(80).default(''),
  senderWallet: Joi.string().allow('').max(160).default(''),
});

const cashOutRequestSchema = Joi.object({
  method: Joi.string().valid('card', 'agent', 'crypto', 'wish').required(),
  amount: Joi.number().positive().max(10000).required(),
  note: Joi.string().allow('').max(500).default(''),
  contactPhone: Joi.string().allow('').max(80).default(''),
  preferredLocation: Joi.string().allow('').max(160).default(''),
  walletAddress: Joi.string().allow('').max(180).default(''),
});

const adminLoginSchema = Joi.object({
  username: Joi.string().trim().required(),
  password: Joi.string().required(),
});

const adminBlockSchema = Joi.object({
  email: Joi.string().email().required(),
  blocked: Joi.boolean().required(),
});

const adminRejectSchema = Joi.object({
  reason: Joi.string().allow('').max(500).default(''),
});

const uploadProfileImageSchema = Joi.object({
  fileName: Joi.string().max(255).required(),
  contentType: Joi.string()
    .valid('image/jpeg', 'image/png', 'image/webp')
    .required(),
  imageData: Joi.string().base64().required(),
});
const jsonParser = express.json({ limit: '8mb' });

// Original code (unchanged structure)
app.use((req, res, next) => {
  if (
    req.path === '/stripe-webhook' ||
    req.path === '/moonpay/webhook' ||
    req.path === '/api/moonpay/webhook'
  ) {
    next();
    return;
  }
  jsonParser(req, res, next);
});
app.use(requireAllowedOrigin);
app.use(requireJsonBody);
app.use(
  '/uploads',
  express.static(path.join(__dirname, 'uploads'), {
    fallthrough: false,
    maxAge: '1d',
    setHeaders(res) {
      res.setHeader('Cache-Control', 'public, max-age=86400, immutable');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader(
        'Content-Security-Policy',
        "default-src 'none'; img-src 'self' data: https:;",
      );
    },
  }),
);

const port = Number(process.env.PORT || 4242);
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || '';
const stripeWebhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const successUrl = validateConfiguredUrl(
  process.env.STRIPE_SUCCESS_URL || 'http://localhost:3000/success',
  { allowHttpLocalhost: true },
);
const cancelUrl = validateConfiguredUrl(
  process.env.STRIPE_CANCEL_URL || 'http://localhost:3000/cancel',
  { allowHttpLocalhost: true },
);
const publicBaseUrl = validateConfiguredUrl(
  process.env.PUBLIC_BASE_URL || 'https://www.infinity-sharing.money/api',
  { allowHttpLocalhost: true },
);
const configuredTopupFeePercentage = Number(process.env.TOPUP_FEE_PERCENT || 5.5);
const topupFeePercentage = Number.isFinite(configuredTopupFeePercentage)
  ? configuredTopupFeePercentage
  : 5.5;
const configuredTopupFixedFee = Number(process.env.TOPUP_FEE_FIXED || 0.3);
const topupFixedFee = Number.isFinite(configuredTopupFixedFee)
  ? configuredTopupFixedFee
  : 0.3;
const configuredCryptoTopupFeePercentage = Number(
  process.env.CRYPTO_TOPUP_FEE_PERCENT || 2.5,
);
const cryptoTopupFeePercentage = Number.isFinite(configuredCryptoTopupFeePercentage)
  ? configuredCryptoTopupFeePercentage
  : 2.5;
const firebaseProjectId = process.env.FIREBASE_PROJECT_ID || 'ewallet-12201';
const firebaseStorageBucket =
  process.env.FIREBASE_STORAGE_BUCKET || 'ewallet-12201.firebasestorage.app';
const firebaseClientEmail = process.env.FIREBASE_CLIENT_EMAIL || '';
const firebasePrivateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(
  /\\n/g,
  '\n',
);
const adminUsername = process.env.ADMIN_USERNAME || 'hado@infinity.solution';
const adminPassword = process.env.ADMIN_PASSWORD || '@Infinitylabs.25..';
const adminSessionSecret =
  process.env.ADMIN_SESSION_SECRET || `${stripeSecretKey}:${firebaseProjectId}`;

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
const moonPayApiKey = (process.env.MOONPAY_API_KEY || '').trim();
const moonPaySecretKey = (process.env.MOONPAY_SECRET_KEY || '').trim();
const moonPayWebhookApiKey = (process.env.MOONPAY_WEBHOOK_API_KEY || '').trim();
const moonPayApiBaseUrl = (
  process.env.MOONPAY_API_BASE_URL || 'https://api.moonpay.com'
).trim();
const moonPayPlatformWalletAddress = (
  process.env.MOONPAY_PLATFORM_WALLET_ADDRESS ||
  '0x7c01Fc5c0B9655492d8D75F36BDFb036a73dc20D'
).trim();
const moonPayRedirectUrl = (
  process.env.MOONPAY_REDIRECT_URL ||
  'https://www.infinity-sharing.money/success?provider=moonpay'
).trim();
const moonPayClient = axios.create({
  baseURL: moonPayApiBaseUrl,
  timeout: 15000,
});

function toMoney(value) {
  return Math.round(Number(value) * 100) / 100;
}

function toBase64Url(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function fromBase64Url(input) {
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
  return Buffer.from(padded, 'base64').toString('utf8');
}

function signAdminToken(payload) {
  const encodedPayload = toBase64Url(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', adminSessionSecret)
    .update(encodedPayload)
    .digest('hex');
  return `${encodedPayload}.${signature}`;
}

function verifyAdminToken(token) {
  if (!token || !token.includes('.')) return null;
  const [encodedPayload, signature] = token.split('.', 2);
  const expected = crypto
    .createHmac('sha256', adminSessionSecret)
    .update(encodedPayload)
    .digest('hex');
  if (
    signature.length !== expected.length ||
    !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))
  ) {
    return null;
  }
  try {
    const payload = JSON.parse(fromBase64Url(encodedPayload));
    if (!payload?.exp || Number(payload.exp) <= Date.now()) {
      return null;
    }
    return payload;
  } catch (_error) {
    return null;
  }
}

function serializeForResponse(value) {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }
  if (Array.isArray(value)) {
    return value.map((item) => serializeForResponse(item));
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [
        key,
        serializeForResponse(item),
      ]),
    );
  }
  return value;
}

async function adminMiddleware(req, res, next) {
  try {
    const rawHeader =
      req.headers.authorization?.replace('Bearer ', '').trim() ||
      req.headers['x-admin-token']?.toString().trim() ||
      '';
    const payload = verifyAdminToken(rawHeader);
    if (!payload) {
      return res.status(401).json({ error: 'Invalid admin session' });
    }
    req.admin = payload;
    next();
  } catch (_error) {
    return res.status(401).json({ error: 'Invalid admin session' });
  }
}

async function generateUniqueWalletId() {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const candidate = `W${Array.from({ length: 10 }, () =>
      crypto.randomInt(0, 10),
    ).join('')}`;
    const query = await db
      .collection('user')
      .where('WalletId', '==', candidate)
      .limit(1)
      .get();
    if (query.empty) {
      return candidate;
    }
  }
  throw new Error('Unable to allocate unique wallet ID');
}

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

function normalizeMoonPayStatus(status) {
  const normalized = (status || '').toString().trim();
  if (!normalized) return 'pending';
  return normalized;
}

function isMoonPayCompletedStatus(status) {
  return normalizeMoonPayStatus(status).toLowerCase() === 'completed';
}

function isMoonPayFailedStatus(status) {
  return normalizeMoonPayStatus(status).toLowerCase() === 'failed';
}

function isMoonPayPendingStatus(status) {
  return !isMoonPayCompletedStatus(status) && !isMoonPayFailedStatus(status);
}

function decodeMoonPayExternalTransactionId(externalTransactionId) {
  const raw = (externalTransactionId || '').toString().trim();
  if (!raw.startsWith('ctx_')) {
    return {};
  }

  try {
    const decoded = JSON.parse(fromBase64Url(raw.slice(4)));
    if (!decoded || typeof decoded !== 'object') {
      return {};
    }
    return decoded;
  } catch (_error) {
    return {};
  }
}

function parseMoonPaySignatureHeader(signatureHeader) {
  const header = (signatureHeader || '').toString().trim();
  const values = Object.fromEntries(
    header
      .split(',')
      .map((part) => part.trim())
      .filter(Boolean)
      .map((part) => {
        const [prefix, ...rest] = part.split('=');
        return [prefix, rest.join('=')];
      }),
  );

  return {
    timestamp: (values.t || '').toString(),
    signature: (values.s || '').toString(),
  };
}

function verifyMoonPayWebhookSignature({ rawBody, signatureHeader }) {
  if (!moonPayWebhookApiKey) {
    throw new Error('Missing MOONPAY_WEBHOOK_API_KEY');
  }

  const { timestamp, signature } = parseMoonPaySignatureHeader(signatureHeader);
  if (!timestamp || !signature) {
    throw new Error('Missing MoonPay signature parts');
  }

  const payload = `${timestamp}.${rawBody.toString('utf8')}`;
  const expectedSignature = crypto
    .createHmac('sha256', moonPayWebhookApiKey)
    .update(payload)
    .digest('hex');

  if (
    signature.length !== expectedSignature.length ||
    !crypto.timingSafeEqual(
      Buffer.from(signature, 'utf8'),
      Buffer.from(expectedSignature, 'utf8'),
    )
  ) {
    throw new Error('Invalid MoonPay webhook signature');
  }
}

function buildSignedMoonPayUrl(originalUrl) {
  if (!moonPaySecretKey) {
    throw new Error('Missing MOONPAY_SECRET_KEY');
  }

  const parsed = new URL(originalUrl);
  const signature = crypto
    .createHmac('sha256', moonPaySecretKey)
    .update(parsed.search)
    .digest('base64');

  const separator = originalUrl.includes('?') ? '&' : '?';
  return `${originalUrl}${separator}signature=${encodeURIComponent(signature)}`;
}

function extractMoonPayTransactionPayload(payload) {
  const data = payload?.data && payload.data.id ? payload.data : payload || {};
  const context = decodeMoonPayExternalTransactionId(
    data.externalTransactionId || '',
  );
  const email =
    (context.email || data.email || payload?.email || '').toString().trim();
  const walletId =
    (context.walletId || data.walletId || payload?.walletId || '')
      .toString()
      .trim();
  const userId =
    (context.userId || data.externalCustomerId || payload?.externalCustomerId || '')
      .toString()
      .trim();

  return {
    transactionId: (data.id || '').toString().trim(),
    externalTransactionId: (data.externalTransactionId || '')
      .toString()
      .trim(),
    userId,
    email,
    walletId,
    amountFiat: Number(data.baseCurrencyAmount || 0),
    amountCrypto: Number(
      data.quoteCurrencyAmount ?? data.cryptoAmount ?? data.currencyAmount ?? 0,
    ),
    status: normalizeMoonPayStatus(data.status),
    walletAddress: (data.walletAddress || '').toString().trim(),
    cryptoTransactionId: (data.cryptoTransactionId || '').toString().trim(),
    failureReason: (data.failureReason || '').toString().trim(),
    paymentMethod: (data.paymentMethod || '').toString().trim(),
    baseCurrencyCode: (data.baseCurrency?.code || data.baseCurrencyCode || '')
      .toString()
      .trim(),
    currencyCode: (data.currency?.code || data.currencyCode || '')
      .toString()
      .trim(),
    createdAt: data.createdAt || null,
    updatedAt: data.updatedAt || null,
    rawData: data,
  };
}

async function fetchMoonPayTransactionById(transactionId) {
  if (!moonPayApiKey) {
    throw new Error('Missing MOONPAY_API_KEY');
  }

  const response = await moonPayClient.get(
    `/v1/transactions/${encodeURIComponent(transactionId)}`,
    {
      params: {
        apiKey: moonPayApiKey,
      },
    },
  );

  return response.data;
}

async function upsertMoonPayTransaction({
  payload,
  source = 'api',
  eventType = '',
}) {
  const transaction = extractMoonPayTransactionPayload(payload);
  if (!transaction.transactionId) {
    throw new Error('MoonPay transactionId is missing');
  }

  const transactionRef = db
    .collection('moonpay_transactions')
    .doc(transaction.transactionId);

  const amounts = calculateTopupAmounts(transaction.amountFiat);
  let existingData = null;
  const existingSnap = await transactionRef.get();
  if (existingSnap.exists) {
    existingData = existingSnap.data() || {};
  }

  await transactionRef.set(
    {
      transactionId: transaction.transactionId,
      userId: transaction.userId,
      email: transaction.email,
      walletId: transaction.walletId,
      amount_fiat: amounts.grossAmount,
      amount_crypto: transaction.amountCrypto,
      status: transaction.status,
      walletAddress: transaction.walletAddress,
      feeAmount: amounts.feeAmount,
      feePercent: topupFeePercentage,
      feeFixed: topupFixedFee,
      netAmount: amounts.netAmount,
      externalTransactionId: transaction.externalTransactionId,
      cryptoTransactionId: transaction.cryptoTransactionId,
      baseCurrencyCode: transaction.baseCurrencyCode,
      currencyCode: transaction.currencyCode,
      paymentMethod: transaction.paymentMethod,
      source,
      eventType,
      failureReason: transaction.failureReason,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      moonpayCreatedAt: transaction.createdAt,
      moonpayUpdatedAt: transaction.updatedAt,
      rawData: transaction.rawData,
      createdAt:
        existingData?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      credited: existingData?.credited === true,
      creditedAmount: Number(existingData?.creditedAmount || 0),
    },
    { merge: true },
  );

  let credited = existingData?.credited === true;
  if (
    isMoonPayCompletedStatus(transaction.status) &&
    !credited &&
    (transaction.email || transaction.walletId)
  ) {
    const creditResult = await creditWalletOnce({
      sessionId: `moonpay_${transaction.transactionId}`,
      email: transaction.email,
      walletId: transaction.walletId,
      grossAmount: amounts.grossAmount,
      feeAmount: amounts.feeAmount,
      netAmount: amounts.netAmount,
      feePercentage: topupFeePercentage,
      feeFixed: topupFixedFee,
      source: 'moonpay_buy',
      senderLabel: 'MoonPay',
      senderEmail: 'moonpay@system',
      senderWalletId: 'MOONPAY',
      meta: {
        moonpayTransactionId: transaction.transactionId,
        moonpayStatus: transaction.status,
        moonpayWalletAddress: transaction.walletAddress,
        moonpayCryptoAmount: transaction.amountCrypto,
        moonpayCryptoTransactionId: transaction.cryptoTransactionId,
      },
    });

    credited = creditResult.credited;
    await transactionRef.set(
      {
        credited,
        creditedAmount: creditResult.netAmount,
        creditedAt: admin.firestore.FieldValue.serverTimestamp(),
        userLookup: creditResult.userLookup,
        userDocId: creditResult.userDocId,
      },
      { merge: true },
    );
  }

  if (isMoonPayFailedStatus(transaction.status)) {
    await transactionRef.set(
      {
        credited: false,
        failureReason: transaction.failureReason,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  const latestSnap = await transactionRef.get();
  const latest = latestSnap.data() || {};
  return {
    transactionId: transaction.transactionId,
    status: transaction.status,
    credited: latest.credited === true,
    amountFiat: amounts.grossAmount,
    feeAmount: amounts.feeAmount,
    netAmount: amounts.netAmount,
    email: transaction.email,
    walletId: transaction.walletId,
    failureReason: transaction.failureReason,
  };
}

async function verifyMoonPayTransactionAccess({ transactionData, requesterEmail }) {
  const requestEmail = (requesterEmail || '').toString().trim().toLowerCase();
  const transactionEmail = (transactionData.email || '')
    .toString()
    .trim()
    .toLowerCase();

  if (transactionEmail && transactionEmail === requestEmail) {
    return;
  }

  const walletId = (transactionData.walletId || '').toString().trim();
  if (!walletId) {
    throw new Error('Not your MoonPay transaction');
  }

  const requesterSnap = await db.collection('user').doc(requesterEmail).get();
  const requesterWalletId =
    (requesterSnap.data()?.WalletId || '').toString().trim();
  if (!requesterWalletId || requesterWalletId !== walletId) {
    throw new Error('Not your MoonPay transaction');
  }
}

function calculateManualAddMoneyAmounts({
  method,
  amount,
  completedWishCount = 0,
}) {
  let feePercent = 0;
  let feeFixed = 0;
  let firstWishFree = false;

  switch (method) {
    case 'wish':
      firstWishFree = completedWishCount === 0;
      feePercent = firstWishFree ? 0 : 1;
      break;
    case 'card':
      feePercent = topupFeePercentage;
      feeFixed = topupFixedFee;
      break;
    default:
      throw new Error('Unsupported add money method');
  }

  const requestedAmount = toMoney(amount);
  const feeAmount = toMoney(requestedAmount * (feePercent / 100) + feeFixed);
  const netAmount = toMoney(Math.max(0, requestedAmount - feeAmount));
  if (netAmount <= 0) {
    throw new Error('Amount is too low after fees.');
  }

  return {
    requestedAmount,
    feePercent,
    feeFixed,
    feeAmount,
    netAmount,
    firstWishFree,
  };
}

async function createAddMoneyRequest({
  email,
  method,
  amount,
  note = '',
  paymentReference = '',
  senderName = '',
  senderPhone = '',
  senderWallet = '',
  requestId,
  forceHistoryId,
  source = 'manual',
}) {
  const userSnap = await db.collection('user').doc(email).get();
  if (!userSnap.exists) {
    throw new Error('User profile not found.');
  }

  const userData = userSnap.data() || {};
  if (userData.IsBlocked === true) {
    throw new Error('Your account is blocked.');
  }

  const walletId = (userData.WalletId || '').toString();
  const fullName = (userData['Full Name'] || email).toString();
  const country = (userData.Country || '').toString();
  const completedWishCount = Number(userData.WishAddMoneyCompletedCount || 0);
  const amounts = calculateManualAddMoneyAmounts({
    method,
    amount,
    completedWishCount,
  });

  const requestRef = requestId
    ? db.collection('wallet_requests').doc(requestId)
    : db.collection('wallet_requests').doc();
  const historyRef = forceHistoryId
    ? db.collection('history').doc(forceHistoryId)
    : db.collection('history').doc();

  await requestRef.set({
    requestId: requestRef.id,
    kind: 'add_money',
    method,
    status: 'pending',
    email,
    walletId,
    fullName,
    country,
    requestedAmount: amounts.requestedAmount,
    feePercent: amounts.feePercent,
    feeFixed: amounts.feeFixed,
    feeAmount: amounts.feeAmount,
    netAmount: amounts.netAmount,
    promotionApplied: amounts.firstWishFree ? 'wish_first_payment_free' : '',
    paymentReference: paymentReference.trim(),
    senderName: senderName.trim(),
    senderPhone: senderPhone.trim(),
    senderWallet: senderWallet.trim(),
    note: note.trim(),
    historyId: historyRef.id,
    source,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await historyRef.set({
    Sender:
      method === 'wish'
        ? 'Wish Money'
        : method === 'card'
            ? 'Visa / Mastercard'
            : method,
    Receiver: fullName,
    'Receiver Email': email,
    'Sender Email': `${method}_pending@system`,
    'Sender Wallet ID': method.toUpperCase(),
    'Receiver Wallet ID': walletId,
    type: 'pending',
    method,
    status: 'pending',
    Time: admin.firestore.FieldValue.serverTimestamp(),
    amount: 0,
    requestedAmount: amounts.requestedAmount,
    feeAmount: amounts.feeAmount,
    netAmount: amounts.netAmount,
    reference: requestRef.id,
    source,
  });

  return {
    requestId: requestRef.id,
    historyId: historyRef.id,
    feeAmount: amounts.feeAmount,
    netAmount: amounts.netAmount,
    firstWishFree: amounts.firstWishFree,
  };
}

async function createCashOutRequest({
  email,
  method,
  amount,
  note = '',
  contactPhone = '',
  preferredLocation = '',
  walletAddress = '',
}) {
  const userRef = db.collection('user').doc(email);
  const requestRef = db.collection('wallet_requests').doc();
  const historyRef = db.collection('history').doc();
  let result = null;

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new Error('User profile not found.');
    }
    const userData = userSnap.data() || {};
    if (userData.IsBlocked === true) {
      throw new Error('Your account is blocked.');
    }

    const balance = Number(userData.Balance || 0);
    const heldBalance = Number(userData.HeldBalance || 0);
    const requestedAmount = toMoney(amount);
    if (balance < requestedAmount) {
      throw new Error('Insufficient balance');
    }

    const walletId = (userData.WalletId || '').toString();
    const fullName = (userData['Full Name'] || email).toString();
    const country = (userData.Country || '').toString();

    tx.update(userRef, {
      Balance: toMoney(balance - requestedAmount),
      HeldBalance: toMoney(heldBalance + requestedAmount),
    });

    tx.set(requestRef, {
      requestId: requestRef.id,
      kind: 'cash_out',
      method,
      status: 'pending',
      email,
      walletId,
      fullName,
      country,
      requestedAmount,
      feePercent: 0,
      feeFixed: 0,
      feeAmount: 0,
      netAmount: requestedAmount,
      contactPhone: contactPhone.trim(),
      preferredLocation: preferredLocation.trim(),
      walletAddress: walletAddress.trim(),
      note: note.trim(),
      historyId: historyRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(historyRef, {
      Sender: fullName,
      Receiver: `${method} Cash Out`,
      'Receiver Email': `${method}_cashout@system`,
      'Sender Email': email,
      'Sender Wallet ID': walletId,
      'Receiver Wallet ID': method.toUpperCase(),
      type: 'pending',
      method,
      status: 'pending',
      Time: admin.firestore.FieldValue.serverTimestamp(),
      amount: 0,
      requestedAmount,
      feeAmount: 0,
      netAmount: requestedAmount,
      reference: requestRef.id,
    });

    result = {
      requestId: requestRef.id,
      netAmount: requestedAmount,
    };
  });

  return result;
}

async function fetchUserHistory(email, limit = 120) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 120, 300));
  const [sentSnap, receivedSnap] = await Promise.all([
    db
      .collection('history')
      .where('Sender Email', '==', email)
      .orderBy('Time', 'desc')
      .limit(safeLimit)
      .get(),
    db
      .collection('history')
      .where('Receiver Email', '==', email)
      .orderBy('Time', 'desc')
      .limit(safeLimit)
      .get(),
  ]);

  const merged = new Map();
  for (const doc of [...sentSnap.docs, ...receivedSnap.docs]) {
    merged.set(doc.id, {
      id: doc.id,
      ...serializeForResponse(doc.data()),
    });
  }

  return Array.from(merged.values())
    .sort((a, b) => Number(b.Time || 0) - Number(a.Time || 0))
    .slice(0, safeLimit);
}

async function buildAdminDashboardData() {
  const [usersSnap, requestsSnap, historySnap] = await Promise.all([
    db.collection('user').get(),
    db.collection('wallet_requests').orderBy('createdAt', 'desc').limit(300).get(),
    db.collection('history').orderBy('Time', 'desc').limit(150).get(),
  ]);

  const users = usersSnap.docs.map((doc) => ({
    id: doc.id,
    ...serializeForResponse(doc.data()),
  }));
  const requests = requestsSnap.docs.map((doc) => ({
    id: doc.id,
    ...serializeForResponse(doc.data()),
  }));
  const history = historySnap.docs.map((doc) => ({
    id: doc.id,
    ...serializeForResponse(doc.data()),
  }));

  const walletLiability = users.reduce(
    (sum, user) => sum + Number(user.Balance || 0) + Number(user.HeldBalance || 0),
    0,
  );
  const availableWalletBalance = users.reduce(
    (sum, user) => sum + Number(user.Balance || 0),
    0,
  );
  const heldWalletBalance = users.reduce(
    (sum, user) => sum + Number(user.HeldBalance || 0),
    0,
  );
  const pendingAddMoney = requests
    .filter((item) => item.status === 'pending' && item.kind === 'add_money')
    .reduce((sum, item) => sum + Number(item.netAmount || 0), 0);
  const pendingCashOut = requests
    .filter((item) => item.status === 'pending' && item.kind === 'cash_out')
    .reduce((sum, item) => sum + Number(item.requestedAmount || 0), 0);
  const confirmedFees = requests
    .filter((item) => item.status === 'confirmed')
    .reduce((sum, item) => sum + Number(item.feeAmount || 0), 0);
  const activeUsers = users.filter((user) => user.IsBlocked !== true).length;
  const blockedUsers = users.length - activeUsers;
  const countries = {};
  for (const user of users) {
    const country = (user.Country || 'Unknown').toString().trim();
    countries[country] = (countries[country] || 0) + 1;
  }
  const countryAnalytics = Object.entries(countries)
    .map(([country, count]) => ({ country, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  return {
    overview: {
      walletLiability: toMoney(walletLiability),
      availableWalletBalance: toMoney(availableWalletBalance),
      heldWalletBalance: toMoney(heldWalletBalance),
      pendingAddMoney: toMoney(pendingAddMoney),
      pendingCashOut: toMoney(pendingCashOut),
      confirmedFees: toMoney(confirmedFees),
      activeUsers,
      blockedUsers,
      countryAnalytics,
    },
    requests,
    users,
    history,
  };
}

async function confirmWalletRequest(requestId, adminActor = 'admin') {
  const requestRef = db.collection('wallet_requests').doc(requestId);

  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) {
      throw new Error('Request not found.');
    }

    const request = requestSnap.data() || {};
    const status = (request.status || '').toString();
    if (status === 'confirmed') {
      return;
    }
    if (status === 'rejected') {
      throw new Error('Request is already rejected.');
    }

    const email = (request.email || '').toString();
    if (!email) {
      throw new Error('Request email is missing.');
    }

    const userRef = db.collection('user').doc(email);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new Error('User not found.');
    }

    const userData = userSnap.data() || {};
    if (userData.IsBlocked === true) {
      throw new Error('Blocked users cannot be settled.');
    }

    const historyId = (request.historyId || '').toString();
    const historyRef = historyId
      ? db.collection('history').doc(historyId)
      : db.collection('history').doc();
    const method = (request.method || '').toString();
    const kind = (request.kind || '').toString();
    const requestedAmount = Number(request.requestedAmount || 0);
    const feeAmount = Number(request.feeAmount || 0);
    const netAmount = Number(request.netAmount || 0);
    const balance = Number(userData.Balance || 0);
    const heldBalance = Number(userData.HeldBalance || 0);

    if (kind === 'add_money') {
      tx.update(userRef, {
        Balance: toMoney(balance + netAmount),
        ...(method === 'wish'
          ? {
              WishAddMoneyCompletedCount:
                Number(userData.WishAddMoneyCompletedCount || 0) + 1,
            }
          : {}),
      });

      tx.set(
        historyRef,
        {
          type: 'topup',
          status: 'confirmed',
          amount: netAmount,
          requestedAmount,
          feeAmount,
          netAmount,
          approvedBy: adminActor,
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          Time: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else if (kind === 'cash_out') {
      if (heldBalance < requestedAmount) {
        throw new Error('Held balance is no longer sufficient.');
      }

      tx.update(userRef, {
        HeldBalance: toMoney(heldBalance - requestedAmount),
      });

      tx.set(
        historyRef,
        {
          type: 'cash_out',
          status: 'confirmed',
          amount: requestedAmount,
          requestedAmount,
          feeAmount: 0,
          netAmount: requestedAmount,
          approvedBy: adminActor,
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          Time: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      throw new Error('Unsupported request type.');
    }

    tx.update(requestRef, {
      status: 'confirmed',
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: adminActor,
    });
  });
}

async function rejectWalletRequest(requestId, reason = '', adminActor = 'admin') {
  const requestRef = db.collection('wallet_requests').doc(requestId);

  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) {
      throw new Error('Request not found.');
    }

    const request = requestSnap.data() || {};
    if ((request.status || '').toString() === 'rejected') {
      return;
    }
    if ((request.status || '').toString() === 'confirmed') {
      throw new Error('Confirmed requests cannot be rejected.');
    }

    const email = (request.email || '').toString();
    const kind = (request.kind || '').toString();
    const requestedAmount = Number(request.requestedAmount || 0);
    const historyId = (request.historyId || '').toString();

    if (kind === 'cash_out' && email) {
      const userRef = db.collection('user').doc(email);
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new Error('User not found.');
      }
      const userData = userSnap.data() || {};
      const balance = Number(userData.Balance || 0);
      const heldBalance = Number(userData.HeldBalance || 0);
      tx.update(userRef, {
        Balance: toMoney(balance + requestedAmount),
        HeldBalance: toMoney(Math.max(0, heldBalance - requestedAmount)),
      });
    }

    tx.set(
      requestRef,
      {
        status: 'rejected',
        rejectionReason: reason.trim(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
        rejectedBy: adminActor,
      },
      { merge: true },
    );

    if (historyId) {
      tx.set(
        db.collection('history').doc(historyId),
        {
          status: 'rejected',
          rejectionReason: reason.trim(),
          rejectedBy: adminActor,
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          Time: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

async function createPendingStripeTopupOnce({
  sessionId,
  email,
  walletId,
  grossAmount,
  feeAmount,
  netAmount,
  feePercentage = topupFeePercentage,
  feeFixed = topupFixedFee,
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
  const requestRef = db.collection('wallet_requests').doc(sessionId);
  const historyRef = db.collection('history').doc(`stripe_${sessionId}`);
  const topupRef = db.collection('topups').doc(sessionId);

  let created = false;
  let status = 'pending';
  let requestData = null;

  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (requestSnap.exists) {
      requestData = requestSnap.data() || {};
      status = (requestData?.status || 'pending').toString();
      return;
    }

    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new Error(`User document not found for email: ${email}`);
    }

    const userData = userSnap.data() || {};
    const receiverEmail = (
      userData.Email ||
      userDocId ||
      email ||
      ''
    ).toString();
    const receiverName = (userData['Full Name'] || email).toString();
    const receiverWalletId = (userData.WalletId || '').toString();
    const country = (userData.Country || '').toString();

    tx.set(requestRef, {
      requestId: sessionId,
      kind: 'add_money',
      method: 'card',
      status: 'pending',
      email: receiverEmail,
      walletId: receiverWalletId,
      fullName: receiverName,
      country,
      requestedAmount: grossAmount,
      feePercent: feePercentage,
      feeFixed,
      feeAmount,
      netAmount,
      promotionApplied: '',
      paymentReference: sessionId,
      senderName: receiverName,
      senderPhone: '',
      senderWallet: '',
      note: 'Stripe payment paid. Awaiting admin confirmation.',
      historyId: historyRef.id,
      stripeSessionId: sessionId,
      source: 'stripe_checkout',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(historyRef, {
      Sender: 'Stripe',
      Receiver: receiverName,
      'Receiver Email': receiverEmail,
      'Sender Email': 'stripe@system',
      'Sender Wallet ID': 'STRIPE',
      'Receiver Wallet ID': receiverWalletId,
      receiverWalletId,
      userDocId,
      type: 'pending',
      method: 'card',
      status: 'pending',
      Time: admin.firestore.FieldValue.serverTimestamp(),
      amount: 0,
      requestedAmount: grossAmount,
      feeAmount,
      netAmount,
      source: 'stripe_checkout',
      reference: sessionId,
      stripeSessionId: sessionId,
      userLookup: matchedBy,
    });

    tx.set(topupRef, {
      email: receiverEmail,
      walletId: receiverWalletId,
      userDocId,
      userLookup: matchedBy,
      amount: 0,
      grossAmount,
      feeAmount,
      feePercentage,
      feeFixed,
      source: 'stripe_checkout',
      reference: sessionId,
      stripeSessionId: sessionId,
      status: 'pending_admin_confirmation',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    created = true;
    status = 'pending';
    requestData = {
      requestId: sessionId,
      email: receiverEmail,
      walletId: receiverWalletId,
      fullName: receiverName,
      country,
    };
  });

  return {
    success: true,
    credited: status === 'confirmed',
    pending: status === 'pending',
    rejected: status === 'rejected',
    created,
    requestId: sessionId,
    grossAmount,
    feeAmount,
    netAmount,
    userDocId,
    userLookup: matchedBy,
    requestData,
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

const cryptoTopupService = createCryptoTopupService({
  db,
  solanaWalletAddress,
  solanaRpcUrl,
  cryptoTopupFeePercentage,
  creditWalletOnce,
  findUserWalletTarget,
});

await fs.mkdir(uploadDir, { recursive: true });

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
        await createPendingStripeTopupOnce({
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

async function handleMoonPayWebhook(req, res) {
  try {
    const signatureHeader =
      req.headers['moonpay-signature-v2'] || req.headers['moonpay-signature'];
    verifyMoonPayWebhookSignature({
      rawBody: req.body,
      signatureHeader,
    });

    const payload = JSON.parse(req.body.toString('utf8'));
    console.log('[MoonPay webhook] received', {
      type: payload?.type || '',
      transactionId: payload?.data?.id || '',
      status: payload?.data?.status || '',
    });

    const result = await upsertMoonPayTransaction({
      payload,
      source: 'webhook',
      eventType: (payload?.type || '').toString(),
    });

    return res.json({
      received: true,
      transactionId: result.transactionId,
      status: result.status,
      credited: result.credited,
    });
  } catch (err) {
    console.error('moonpay-webhook processing error:', err);
    return res.status(400).json({ error: err.message || 'Invalid MoonPay webhook' });
  }
}

app.post(
  '/moonpay/webhook',
  express.raw({ type: 'application/json' }),
  handleMoonPayWebhook,
);
app.post(
  '/api/moonpay/webhook',
  express.raw({ type: 'application/json' }),
  handleMoonPayWebhook,
);

// Protected endpoints
async function handleMoonPaySignUrl(req, res) {
  try {
    const { error } = signMoonPayUrlSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    if (!moonPayApiKey || !moonPaySecretKey) {
      return res.status(500).json({ error: 'MoonPay signing is not configured' });
    }

    const url = req.body.url.toString().trim();
    const parsed = new URL(url);
    if (
      parsed.hostname !== 'buy.moonpay.com' &&
      parsed.hostname !== 'buy-sandbox.moonpay.com'
    ) {
      return res.status(400).json({ error: 'Invalid MoonPay host' });
    }

    if (parsed.searchParams.get('apiKey') !== moonPayApiKey) {
      return res.status(400).json({ error: 'Invalid MoonPay apiKey' });
    }

    if (parsed.searchParams.get('walletAddress') !== moonPayPlatformWalletAddress) {
      return res.status(400).json({ error: 'Invalid MoonPay walletAddress' });
    }

    const email = (parsed.searchParams.get('email') || '').trim().toLowerCase();
    if (!email || email !== req.user.email.toLowerCase()) {
      return res.status(403).json({ error: 'Not your MoonPay email' });
    }

    const requesterSnap = await db.collection('user').doc(req.user.email).get();
    const requesterWalletId =
      (requesterSnap.data()?.WalletId || '').toString().trim();
    const requestedWalletId =
      (parsed.searchParams.get('metadata[walletId]') || '').trim();

    if (
      requesterWalletId &&
      requestedWalletId &&
      requesterWalletId !== requestedWalletId
    ) {
      return res.status(403).json({ error: 'Not your MoonPay wallet' });
    }

    const signedUrl = buildSignedMoonPayUrl(url);
    return res.json({ signedUrl });
  } catch (err) {
    console.error('moonpay-sign-url error:', err);
    return res.status(500).json({ error: err.message || 'Unable to sign MoonPay URL' });
  }
}

app.post('/moonpay/sign-url', authMiddleware, handleMoonPaySignUrl);
app.post('/api/moonpay/sign-url', authMiddleware, handleMoonPaySignUrl);

async function handleMoonPayVerify(req, res) {
  try {
    const { error } = verifyMoonPaySchema.validate(req.query);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const transactionId = (req.query.transactionId || '').toString().trim();
    let storedSnap = await db
      .collection('moonpay_transactions')
      .doc(transactionId)
      .get();

    let transactionData = storedSnap.data() || null;
    try {
      const remoteTransaction = await fetchMoonPayTransactionById(transactionId);
      await upsertMoonPayTransaction({
        payload: remoteTransaction,
        source: 'verify_api',
        eventType: 'verify',
      });
      storedSnap = await db.collection('moonpay_transactions').doc(transactionId).get();
      transactionData = storedSnap.data() || null;
    } catch (apiError) {
      console.error('moonpay-verify remote sync error:', apiError?.response?.data || apiError);
    }

    if (!transactionData) {
      return res.status(404).json({ error: 'MoonPay transaction not found' });
    }

    await verifyMoonPayTransactionAccess({
      transactionData,
      requesterEmail: req.user.email,
    });

    return res.json({
      success: true,
      transactionId,
      status: normalizeMoonPayStatus(transactionData.status),
      credited: transactionData.credited === true,
      pending: isMoonPayPendingStatus(transactionData.status),
      failed: isMoonPayFailedStatus(transactionData.status),
      amountFiat: Number(transactionData.amount_fiat || 0),
      amountCrypto: Number(transactionData.amount_crypto || 0),
      feeAmount: Number(transactionData.feeAmount || 0),
      netAmount: Number(transactionData.netAmount || 0),
      walletAddress: (transactionData.walletAddress || '').toString(),
      email: (transactionData.email || '').toString(),
      walletId: (transactionData.walletId || '').toString(),
      message: transactionData.credited === true
          ? 'Wallet credited successfully'
          : isMoonPayFailedStatus(transactionData.status)
              ? ((transactionData.failureReason || '').toString().trim().isNotEmpty
                  ? transactionData.failureReason
                  : 'MoonPay transaction failed')
              : 'Waiting for MoonPay transaction completion',
    });
  } catch (err) {
    console.error('moonpay-verify error:', err);
    if (err.message === 'Not your MoonPay transaction') {
      return res.status(403).json({ error: err.message });
    }
    return res.status(500).json({ error: err.message || 'Unable to verify MoonPay transaction' });
  }
}

app.get('/moonpay/verify', authMiddleware, handleMoonPayVerify);
app.get('/api/moonpay/verify', authMiddleware, handleMoonPayVerify);

app.post('/create-checkout-session', authMiddleware, ownWalletCheck, async (req, res) => {
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

app.post('/confirm-topup', authMiddleware, ownWalletCheck, async (req, res) => {
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
    const result = await createPendingStripeTopupOnce({
      sessionId: session.id,
      email,
      walletId,
      ...topup,
    });

    return res.json({
      success: true,
      credited: result.credited,
      pending: result.pending,
      rejected: result.rejected,
      requestId: result.requestId,
      grossAmount: result.grossAmount,
      feeAmount: result.feeAmount,
      netAmount: result.netAmount,
      userDocId: result.userDocId,
      userLookup: result.userLookup,
      firebaseProjectId: firestoreProjectId,
      message: result.credited
        ? 'Wallet credited successfully'
        : result.pending
            ? 'Card payment received and top-up is pending admin confirmation.'
            : result.rejected
                ? 'Top-up request was rejected.'
                : 'Top-up request already exists.',
    });
  } catch (err) {
    console.error('confirm-topup error:', err);
    return res.status(500).json({ error: 'Unable to confirm top-up' });
  }
});

app.post(
  '/upload-profile-image',
  authMiddleware,
  async (req, res) => {
    try {
      const { error } = uploadProfileImageSchema.validate(req.body);
      if (error) {
        return res.status(400).json({ error: error.details[0].message });
      }

      const fileName = req.body.fileName.toString().trim();
      const contentType = req.body.contentType.toString().trim();
      const imageBuffer = Buffer.from(req.body.imageData, 'base64');

      if (!imageBuffer.length || imageBuffer.length > 2 * 1024 * 1024) {
        return res.status(400).json({ error: 'Invalid image size' });
      }

      const detectedContentType = detectImageType(imageBuffer);
      if (!detectedContentType || detectedContentType !== contentType) {
        return res.status(400).json({ error: 'Invalid image content' });
      }

      const extension =
        contentType === 'image/png'
          ? 'png'
          : contentType === 'image/webp'
              ? 'webp'
              : 'jpg';
      const safeOwner = (req.user?.email || 'anonymous').replace(
        /[^a-zA-Z0-9._-]/g,
        '_',
      );
      const originalBaseName = path.basename(
        fileName,
        path.extname(fileName),
      );
      const safeName = originalBaseName.replace(/[^a-zA-Z0-9._-]/g, '_');
      const finalName =
        `${safeOwner}_${Date.now()}_${crypto.randomUUID()}_${safeName}.${extension}`;
      const finalPath = path.join(uploadDir, finalName);

      await fs.writeFile(finalPath, imageBuffer, { mode: 0o600 });

      const imageUrl = `${publicBaseUrl}/uploads/profiles/${finalName}`;
      return res.json({
        success: true,
        imageUrl,
      });
    } catch (err) {
      console.error('upload-profile-image error:', err);
      return res.status(500).json({ error: 'Unable to upload image' });
    }
  },
);

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

      const amount = Number(req.body?.amount || 0);
      const email = (req.body?.email || '').toString().trim();
      const walletId = (req.body?.walletId || '').toString().trim();
      const senderWalletAddress =
        (req.body?.senderWalletAddress || '').toString().trim();

      if (!Number.isFinite(amount) || amount <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const result = await cryptoTopupService.createTopup({
        amount,
        email,
        walletId,
        senderWalletAddress,
      });

      return res.json(result);
    } catch (err) {
      console.error('create-crypto-topup error:', err);
      return res.status(500).json({ error: err.message || 'Unable to create crypto top-up' });
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
      const result = await cryptoTopupService.confirmTopup({
        depositId,
        requesterEmail: req.user.email,
      });

      return res.json(result);
    } catch (err) {
      console.error('confirm-crypto-topup error:', err);
      if (err.message === 'Crypto top-up not found') {
        return res.status(404).json({ error: err.message });
      }
      if (err.message === 'Not your crypto top-up') {
        return res.status(403).json({ error: err.message });
      }
      return res.status(500).json({ error: err.message || 'Unable to confirm crypto top-up' });
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
  cryptoTopupService.startWatcher().catch((error) => {
    console.error('[Crypto Top-up] Failed to start Solana watcher:', error);
  });
});
