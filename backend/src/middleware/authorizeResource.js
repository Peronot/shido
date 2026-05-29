const methodActionMap = {
  GET: 'read',
  POST: 'create',
  PUT: 'update',
  PATCH: 'update',
  DELETE: 'delete',
};

function isAllowed(resourceConfig, role, action) {
  const permissions = resourceConfig.permissions ?? {};
  const roleRules = permissions[role] ?? permissions.user ?? [];
  return roleRules.includes(action) || roleRules.includes('*');
}

export function authorizeResource(req, res, next) {
  const action = methodActionMap[req.method];
  if (!action) {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const role = (req.auth?.role ?? 'user').toString().toLowerCase();
  const resourceConfig = req.resourceConfig ?? {};

  if (!isAllowed(resourceConfig, role, action)) {
    return res.status(403).json({ error: 'Forbidden: insufficient permissions' });
  }

  return next();
}
