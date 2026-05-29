import { pool } from './pool.js';

export async function findUserByEmail(email) {
  const query = `
    SELECT
      u.id,
      u.full_name,
      u.email,
      u.phone,
      u.password_hash,
      u.is_active,
      u.created_at,
      COALESCE(
        (
          SELECT r.name
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = u.id
          ORDER BY CASE WHEN LOWER(r.name) = 'admin' THEN 0 ELSE 1 END, ur.created_at ASC
          LIMIT 1
        ),
        'user'
      ) AS role_name
    FROM users u
    WHERE LOWER(u.email) = LOWER($1)
    LIMIT 1
  `;
  const result = await pool.query(query, [email]);
  return result.rows[0] ?? null;
}

export async function findUserByPhone(phone) {
  const query = `
    SELECT
      u.id,
      u.full_name,
      u.email,
      u.phone,
      u.password_hash,
      u.is_active,
      u.created_at,
      COALESCE(
        (
          SELECT r.name
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = u.id
          ORDER BY CASE WHEN LOWER(r.name) = 'admin' THEN 0 ELSE 1 END, ur.created_at ASC
          LIMIT 1
        ),
        'user'
      ) AS role_name
    FROM users u
    WHERE regexp_replace(COALESCE(u.phone, ''), '[^0-9]', '', 'g') = regexp_replace($1, '[^0-9]', '', 'g')
    LIMIT 1
  `;
  const result = await pool.query(query, [phone]);
  return result.rows[0] ?? null;
}

export async function findUserAuthById(userId) {
  const query = `
    SELECT
      u.id,
      u.email,
      u.is_active,
      COALESCE(
        (
          SELECT r.name
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          WHERE ur.user_id = u.id
          ORDER BY CASE WHEN LOWER(r.name) = 'admin' THEN 0 ELSE 1 END, ur.created_at ASC
          LIMIT 1
        ),
        'user'
      ) AS role_name
    FROM users u
    WHERE u.id = $1
    LIMIT 1
  `;
  const result = await pool.query(query, [userId]);
  return result.rows[0] ?? null;
}

export async function findUserPasswordById(userId) {
  const query = `
    SELECT id, password_hash
    FROM users
    WHERE id = $1
    LIMIT 1
  `;
  const result = await pool.query(query, [userId]);
  return result.rows[0] ?? null;
}

export async function createUser({ fullName, email, phone, passwordHash }) {
  const query = `
    INSERT INTO users (full_name, email, phone, password_hash)
    VALUES ($1, $2, $3, $4)
    RETURNING id, full_name, email, phone, is_active, created_at
  `;
  const values = [fullName, email, phone ?? null, passwordHash];
  const result = await pool.query(query, values);
  return result.rows[0];
}

export async function assignDefaultUserRole(userId) {
  const createRoleQuery = `
    INSERT INTO roles (name, description)
    VALUES ('user', 'Default app user')
    ON CONFLICT (name) DO NOTHING
  `;
  await pool.query(createRoleQuery);

  const assignRoleQuery = `
    INSERT INTO user_roles (user_id, role_id)
    SELECT $1, id
    FROM roles
    WHERE name = 'user'
    ON CONFLICT (user_id, role_id) DO NOTHING
  `;
  await pool.query(assignRoleQuery, [userId]);
}

export async function updateUserPasswordHash(userId, passwordHash) {
  const query = `
    UPDATE users
    SET password_hash = $1, updated_at = NOW()
    WHERE id = $2
  `;
  await pool.query(query, [passwordHash, userId]);
}
