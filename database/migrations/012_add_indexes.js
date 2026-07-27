exports.up = function (knex) {
  return knex.schema
    .raw('CREATE INDEX IF NOT EXISTS idx_employees_is_admin ON employees (is_admin)')
    .raw('CREATE INDEX IF NOT EXISTS idx_employees_is_active ON employees (is_active)')
    .raw('CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions (expires_at)');
};

exports.down = function (knex) {
  return knex.schema
    .raw('DROP INDEX IF EXISTS idx_employees_is_admin')
    .raw('DROP INDEX IF EXISTS idx_employees_is_active')
    .raw('DROP INDEX IF EXISTS idx_sessions_expires_at');
};
