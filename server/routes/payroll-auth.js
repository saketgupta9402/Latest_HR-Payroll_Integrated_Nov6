import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../db/pool.js';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret';
const TOKEN_COOKIE = 'session';

function createToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
}

router.post('/login-pin', async (req, res) => {
  const { email, pin } = req.body || {};
  if (!email || !pin) {
    return res.status(400).json({ error: 'email and pin required' });
  }

  if (!/^\d{6}$/.test(pin)) {
    return res.status(400).json({ error: 'PIN must be exactly 6 digits' });
  }

  const loweredEmail = email.toLowerCase().trim();

  const result = await query(
    'SELECT id, pin_hash, pin_set_at FROM users WHERE email = $1',
    [loweredEmail]
  );

  if (result.rows.length === 0) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const user = result.rows[0];

  if (!user.pin_hash) {
    return res.status(403).json({
      error: 'PIN not set',
      message: 'Please set up your PIN first. You can do this through SSO from the HR Portal.',
    });
  }

  const ok = await bcrypt.compare(pin, user.pin_hash);
  if (!ok) {
    return res.status(401).json({ error: 'Invalid PIN' });
  }

  const token = createToken({ id: user.id, email: loweredEmail });
  res.cookie(TOKEN_COOKIE, token, { httpOnly: true, sameSite: 'lax' });

  return res.json({ token, user: { id: user.id, email: loweredEmail } });
});

router.post('/setup-pin', async (req, res) => {
  const { email, pin } = req.body || {};
  if (!email || !pin) {
    return res.status(400).json({ error: 'email and pin required' });
  }

  if (!/^\d{6}$/.test(pin)) {
    return res.status(400).json({ error: 'PIN must be exactly 6 digits' });
  }

  const loweredEmail = email.toLowerCase().trim();

  const userResult = await query(
    'SELECT id, pin_hash FROM users WHERE email = $1',
    [loweredEmail]
  );

  if (userResult.rows.length === 0) {
    return res.status(404).json({
      error: 'User not found',
      message: 'Please sign up in the HR Portal first. Users are created automatically when added by HR.',
    });
  }

  const user = userResult.rows[0];

  if (user.pin_hash) {
    return res.status(409).json({ error: 'PIN already set. Use login to sign in.' });
  }

  const pinHash = await bcrypt.hash(pin, 10);
  await query(
    'UPDATE users SET pin_hash = $1, pin_set_at = now() WHERE id = $2',
    [pinHash, user.id]
  );

  const token = createToken({ id: user.id, email: loweredEmail });
  res.cookie(TOKEN_COOKIE, token, { httpOnly: true, sameSite: 'lax' });

  return res.json({
    success: true,
    message: 'PIN set successfully',
    token,
    user: { id: user.id, email: loweredEmail },
  });
});

router.get('/pin-status', async (req, res) => {
  const email = (req.query.email || '').toString().trim();
  if (!email) {
    return res.status(400).json({ error: 'email required' });
  }

  const result = await query(
    'SELECT id, pin_hash FROM users WHERE email = $1',
    [email.toLowerCase()]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  const user = result.rows[0];
  return res.json({
    hasPin: !!user.pin_hash,
    userId: user.id,
  });
});

router.post('/logout', async (_req, res) => {
  res.clearCookie(TOKEN_COOKIE);
  res.json({ ok: true });
});

router.get('/session', async (req, res) => {
  let token;

  const authHeader = req.headers['authorization'];
  if (authHeader) {
    token = authHeader.split(' ')[1];
  }

  if (!token && req.cookies) {
    token = req.cookies[TOKEN_COOKIE];
  }

  if (!token) {
    return res.json({ session: null });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const userId = payload.id || payload.userId;
    if (!userId) {
      return res.json({ session: null });
    }
    return res.json({ session: { userId } });
  } catch (err) {
    return res.json({ session: null });
  }
});

export default router;

