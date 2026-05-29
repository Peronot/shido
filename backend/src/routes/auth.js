import crypto from 'crypto';
import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { promisify } from 'util';

import { JWT_SECRET } from '../config/auth.js';
import { authenticate } from '../middleware/authenticate.js';
import {
  assignDefaultUserRole,
  createUser,
  findUserByEmail,
  findUserPasswordById,
  findUserByPhone,
  updateUserPasswordHash,
} from '../db/authRepository.js';

const router = Router();
const scryptAsync = promisify(crypto.scrypt);
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const loginAttempts = new Map();
const MAX_ATTEMPTS = 5;
const WINDOW_MS = 15 * 60 * 1000;

function getClientKey(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip ?? 'unknown';
}

function isRateLimited(key) {
  const now = Date.now();
  const current = loginAttempts.get(key);
  if (!current || current.resetAt <= now) {
    loginAttempts.set(key, { count: 0, resetAt: now + WINDOW_MS });
    return false;
  }
  return current.count >= MAX_ATTEMPTS;
}

function trackFailedAttempt(key) {
  const now = Date.now();
  const current = loginAttempts.get(key);
  if (!current || current.resetAt <= now) {
    loginAttempts.set(key, { count: 1, resetAt: now + WINDOW_MS });
    return;
  }
  current.count += 1;
}

function clearAttempts(key) {
  loginAttempts.delete(key);
}

async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const derivedKey = await scryptAsync(password, salt, 64);
  return `scrypt:${salt}:${Buffer.from(derivedKey).toString('hex')}`;
}

async function verifyPassword(inputPassword, storedHash) {
  if (storedHash.startsWith('scrypt:')) {
    const parts = storedHash.split(':');
    if (parts.length !== 3) return false;
    const [, salt, expected] = parts;
    const derivedKey = await scryptAsync(inputPassword, salt, 64);
    const actual = Buffer.from(derivedKey).toString('hex');
    return crypto.timingSafeEqual(Buffer.from(actual), Buffer.from(expected));
  }

  const sha256 = crypto
    .createHash('sha256')
    .update(inputPassword)
    .digest('hex');
  return sha256 === storedHash || inputPassword === storedHash;
}

function toPublicUser(user) {
  const role = (user.role_name ?? 'user').toString().toLowerCase();
  return {
    id: user.id,
    full_name: user.full_name,
    email: user.email,
    phone: user.phone,
    role,
    is_admin: role === 'admin',
    is_active: user.is_active,
    created_at: user.created_at,
  };
}

function signAuthToken(user) {
  const role = (user.role_name ?? 'user').toString().toLowerCase();
  return jwt.sign({ email: user.email, role }, JWT_SECRET, {
    subject: String(user.id),
    expiresIn: '12h',
  });
}

router.post('/register', async (req, res) => {
  try {
    const { full_name: fullName, email, phone, password } = req.body ?? {};

    if (!fullName || !email || !password) {
      return res.status(400).json({
        error: 'full_name, email and password are required',
      });
    }

    if (!emailRegex.test(email.trim())) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ error: 'Password must be at least 6 characters' });
    }

    const existingUser = await findUserByEmail(email.trim());
    if (existingUser) {
      return res.status(409).json({ error: 'Email already exists' });
    }

    const created = await createUser({
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone?.trim(),
      passwordHash: await hashPassword(password),
    });
    await assignDefaultUserRole(created.id);

    const createdWithRole = await findUserByEmail(created.email);
    if (!createdWithRole) {
      return res.status(500).json({ error: 'Failed to finalize user role' });
    }

    return res.status(201).json({ data: toPublicUser(createdWithRole) });
  } catch (error) {
    if (error?.code === '23505') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    return res.status(500).json({ error: 'Failed to register user' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const clientKey = getClientKey(req);
    if (isRateLimited(clientKey)) {
      return res.status(429).json({
        error: 'Too many login attempts. Try again in 15 minutes.',
      });
    }

    const { email, phone, password } = req.body ?? {};
    const loginValue = (email ?? phone ?? '').toString().trim();
    const isEmail = loginValue.includes('@');

    if (!loginValue || !password) {
      return res
        .status(400)
        .json({ error: 'email/phone and password are required' });
    }

    const user = isEmail
      ? await findUserByEmail(loginValue)
      : await findUserByPhone(loginValue);
    if (!user) {
      trackFailedAttempt(clientKey);
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const validPassword = await verifyPassword(password, user.password_hash);
    if (!validPassword) {
      trackFailedAttempt(clientKey);
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (!user.is_active) {
      return res.status(403).json({ error: 'Account is inactive' });
    }

    if (!user.password_hash.startsWith('scrypt:')) {
      const upgradedHash = await hashPassword(password);
      await updateUserPasswordHash(user.id, upgradedHash);
    }

    clearAttempts(clientKey);

    const tokenPayload = signAuthToken(user);

    return res.json({
      data: {
        token: tokenPayload,
        user: toPublicUser(user),
      },
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to login' });
  }
});

router.post('/social-login', async (req, res) => {
  try {
    const { email, full_name: fullName, provider } = req.body ?? {};
    const normalizedEmail = (email ?? '').toString().trim().toLowerCase();
    const normalizedName = (fullName ?? '').toString().trim();
    const normalizedProvider = (provider ?? 'social').toString().trim();

    if (!normalizedEmail || !emailRegex.test(normalizedEmail)) {
      return res.status(400).json({ error: 'Valid email is required' });
    }

    if (!normalizedName) {
      return res.status(400).json({ error: 'full_name is required' });
    }

    let user = await findUserByEmail(normalizedEmail);
    if (!user) {
      const created = await createUser({
        fullName: normalizedName,
        email: normalizedEmail,
        phone: null,
        passwordHash: await hashPassword(`social:${normalizedProvider}:${normalizedEmail}`),
      });
      await assignDefaultUserRole(created.id);
      user = await findUserByEmail(normalizedEmail);
    }

    if (!user) {
      return res.status(500).json({ error: 'Failed to finalize social login' });
    }

    if (!user.is_active) {
      return res.status(403).json({ error: 'Account is inactive' });
    }

    return res.json({
      data: {
        token: signAuthToken(user),
        user: toPublicUser(user),
      },
    });
  } catch (_error) {
    return res.status(500).json({ error: 'Failed social login' });
  }
});

router.post('/change-password', authenticate, async (req, res) => {
  try {
    const { current_password: currentPassword, new_password: newPassword } =
      req.body ?? {};

    if (!currentPassword || !newPassword) {
      return res
        .status(400)
        .json({ error: 'current_password and new_password are required' });
    }

    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ error: 'New password must be at least 6 characters' });
    }

    const user = await findUserPasswordById(req.auth.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const valid = await verifyPassword(currentPassword, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const nextHash = await hashPassword(newPassword);
    await updateUserPasswordHash(user.id, nextHash);
    return res.json({ data: { changed: true } });
  } catch (_error) {
    return res.status(500).json({ error: 'Failed to change password' });
  }
});

export default router;
