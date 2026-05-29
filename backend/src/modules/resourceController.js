import {
  createRow,
  deleteRow,
  getById,
  listRows,
  updateRow,
} from '../db/crudRepository.js';

function getOwnershipScope(req) {
  const role = (req.auth?.role ?? 'user').toString().toLowerCase();
  if (role === 'admin') {
    return {};
  }

  const ownership = req.resourceConfig?.ownership;
  if (!ownership?.column) {
    return {};
  }

  return { [ownership.column]: req.auth.userId };
}

function applyCreateOwnership(payload, req) {
  const role = (req.auth?.role ?? 'user').toString().toLowerCase();
  const ownership = req.resourceConfig?.ownership;
  if (role === 'admin' || !ownership?.column) {
    return payload;
  }

  return {
    ...payload,
    [ownership.column]: req.auth.userId,
  };
}

function sanitizeUpdatePayload(payload, req) {
  const role = (req.auth?.role ?? 'user').toString().toLowerCase();
  const ownership = req.resourceConfig?.ownership;
  if (role === 'admin' || !ownership?.column) {
    return payload;
  }

  const clean = { ...payload };
  delete clean[ownership.column];
  return clean;
}

export async function listResource(req, res) {
  try {
    const { resource } = req.params;
    const limit = Number(req.query.limit ?? 50);
    const offset = Number(req.query.offset ?? 0);
    const scope = getOwnershipScope(req);
    const rows = await listRows(resource, limit, offset, scope);
    res.json({ data: rows, meta: { limit, offset, count: rows.length } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}

export async function getResourceById(req, res) {
  try {
    const { resource, id } = req.params;
    const primaryKey = req.resourceConfig.primaryKey;
    const scope = getOwnershipScope(req);
    const row = await getById(resource, primaryKey, id, scope);

    if (!row) {
      return res.status(404).json({ error: 'Record not found' });
    }

    return res.json({ data: row });
  } catch (error) {
    return res.status(400).json({ error: error.message });
  }
}

export async function createResource(req, res) {
  try {
    const { resource } = req.params;
    const payload = applyCreateOwnership(req.body ?? {}, req);
    const created = await createRow(resource, payload);
    res.status(201).json({ data: created });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}

export async function updateResource(req, res) {
  try {
    const { resource, id } = req.params;
    const primaryKey = req.resourceConfig.primaryKey;
    const scope = getOwnershipScope(req);
    const payload = sanitizeUpdatePayload(req.body ?? {}, req);
    const updated = await updateRow(resource, primaryKey, id, payload, scope);

    if (!updated) {
      return res.status(404).json({ error: 'Record not found' });
    }

    return res.json({ data: updated });
  } catch (error) {
    return res.status(400).json({ error: error.message });
  }
}

export async function removeResource(req, res) {
  try {
    const { resource, id } = req.params;
    const primaryKey = req.resourceConfig.primaryKey;
    const scope = getOwnershipScope(req);
    const deleted = await deleteRow(resource, primaryKey, id, scope);

    if (!deleted) {
      return res.status(404).json({ error: 'Record not found' });
    }

    return res.json({ data: deleted });
  } catch (error) {
    return res.status(400).json({ error: error.message });
  }
}
