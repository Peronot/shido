import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.warn('DATABASE_URL is missing. Set it in backend/.env');
}

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
