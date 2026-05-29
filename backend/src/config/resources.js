export const resources = {
  users: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'update'] },
    ownership: { column: 'id' },
  },
  roles: { primaryKey: 'id', permissions: { admin: ['*'] } },
  permissions: { primaryKey: 'id', permissions: { admin: ['*'] } },
  user_roles: { primaryKey: 'id', permissions: { admin: ['*'] } },
  clubs: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
    ownership: { column: 'owner_user_id' },
  },
  club_members: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  players: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update', 'delete'] },
    ownership: { column: 'user_id' },
  },
  player_statistics: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  games: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update', 'delete'] },
    ownership: { column: 'created_by_user_id' },
  },
  game_teams: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  team_players: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  rounds: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  round_scores: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  game_results: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  notifications: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create'] },
    ownership: { column: 'user_id' },
  },
  reports: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create'] },
    ownership: { column: 'generated_by_user_id' },
  },
  subscriptions: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
  payments: { primaryKey: 'id', permissions: { admin: ['*'] } },
  audit_logs: { primaryKey: 'id', permissions: { admin: ['read'] } },
  app_settings: { primaryKey: 'id', permissions: { admin: ['*'] } },
  tournaments: {
    primaryKey: 'id',
    permissions: { admin: ['*'], user: ['read', 'create', 'update'] },
  },
};
