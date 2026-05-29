import { pool } from './pool.js';

const safeName = /^[a-z_]+$/;

function assertSafeName(value, kind) {
  if (!safeName.test(value)) {
    throw new Error(`Invalid ${kind}: ${value}`);
  }
}

function buildWhereClause(startIndex, filters = {}) {
  const entries = Object.entries(filters);
  if (entries.length === 0) {
    return { sql: '', values: [] };
  }

  const clauses = [];
  const values = [];

  entries.forEach(([column, value], i) => {
    assertSafeName(column, 'column name');
    clauses.push(`${column} = $${startIndex + i}`);
    values.push(value);
  });

  return { sql: ` AND ${clauses.join(' AND ')}`, values };
}

export async function getColumns(tableName) {
  assertSafeName(tableName, 'table name');

  const query = `
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = $1
    ORDER BY ordinal_position
  `;

  const result = await pool.query(query, [tableName]);
  return result.rows.map((row) => row.column_name);
}

export async function listRows(tableName, limit = 50, offset = 0, filters = {}) {
  assertSafeName(tableName, 'table name');
  const where = buildWhereClause(3, filters);
  const result = await pool.query(
    `SELECT * FROM ${tableName} WHERE 1=1${where.sql} ORDER BY created_at DESC NULLS LAST LIMIT $1 OFFSET $2`,
    [limit, offset, ...where.values],
  );
  return result.rows;
}

export async function getById(tableName, primaryKey, id, filters = {}) {
  assertSafeName(tableName, 'table name');
  assertSafeName(primaryKey, 'primary key');
  const where = buildWhereClause(2, filters);
  const result = await pool.query(
    `SELECT * FROM ${tableName} WHERE ${primaryKey} = $1${where.sql} LIMIT 1`,
    [id, ...where.values],
  );
  return result.rows[0] ?? null;
}

export async function createRow(tableName, payload) {
  assertSafeName(tableName, 'table name');
  const keys = Object.keys(payload);

  if (keys.length === 0) {
    throw new Error('Payload cannot be empty');
  }

  const columns = await getColumns(tableName);
  const allowedKeys = keys.filter((key) => columns.includes(key));

  if (allowedKeys.length === 0) {
    throw new Error('No valid columns provided');
  }

  const placeholders = allowedKeys.map((_, i) => `$${i + 1}`).join(', ');
  const values = allowedKeys.map((key) => payload[key]);

  const query = `
    INSERT INTO ${tableName} (${allowedKeys.join(', ')})
    VALUES (${placeholders})
    RETURNING *
  `;

  const result = await pool.query(query, values);
  return result.rows[0];
}

export async function updateRow(tableName, primaryKey, id, payload, filters = {}) {
  assertSafeName(tableName, 'table name');
  assertSafeName(primaryKey, 'primary key');

  const keys = Object.keys(payload);
  if (keys.length === 0) {
    throw new Error('Payload cannot be empty');
  }

  const columns = await getColumns(tableName);
  const allowedKeys = keys.filter(
    (key) => columns.includes(key) && key !== primaryKey,
  );

  if (allowedKeys.length === 0) {
    throw new Error('No valid columns provided');
  }

  const setClause = allowedKeys
    .map((key, i) => `${key} = $${i + 1}`)
    .join(', ');

  const values = allowedKeys.map((key) => payload[key]);
  values.push(id);
  const where = buildWhereClause(values.length + 1, filters);

  const query = `
    UPDATE ${tableName}
    SET ${setClause}
    WHERE ${primaryKey} = $${values.length}${where.sql}
    RETURNING *
  `;

  const result = await pool.query(query, [...values, ...where.values]);
  return result.rows[0] ?? null;
}

export async function deleteRow(tableName, primaryKey, id, filters = {}) {
  assertSafeName(tableName, 'table name');
  assertSafeName(primaryKey, 'primary key');
  const where = buildWhereClause(2, filters);
  const result = await pool.query(
    `DELETE FROM ${tableName} WHERE ${primaryKey} = $1${where.sql} RETURNING *`,
    [id, ...where.values],
  );
  return result.rows[0] ?? null;
}
