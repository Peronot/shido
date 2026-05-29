const isProduction = process.env.NODE_ENV === 'production';
const fallbackDevSecret = 'dev-only-secret-change-me';

export const JWT_SECRET = process.env.JWT_SECRET || fallbackDevSecret;

if (!process.env.JWT_SECRET && isProduction) {
  throw new Error('JWT_SECRET is required in production');
}

if (!process.env.JWT_SECRET && !isProduction) {
  console.warn('JWT_SECRET is not set. Using a development fallback secret.');
}
