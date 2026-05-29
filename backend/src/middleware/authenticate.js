import jwt from 'jsonwebtoken';
import { JWT_SECRET } from '../config/auth.js';
import { findUserAuthById } from '../db/authRepository.js';

export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization ?? '';
  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const userId = decoded.sub;
    const currentUser = await findUserAuthById(userId);
    if (!currentUser || !currentUser.is_active) {
      return res.status(401).json({ error: 'Account is inactive or missing' });
    }

    req.auth = {
      userId: currentUser.id,
      email: currentUser.email,
      role: (currentUser.role_name ?? 'user').toString().toLowerCase(),
    };
    return next();
  } catch (_error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
