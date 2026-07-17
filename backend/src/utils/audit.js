const db = require('../config/database');

function roleOf(user) {
  if (user.is_admin) return 'admin';
  if (user.is_supervisor) return 'supervisor';
  if (user.is_security) return 'security';
  return 'employee';
}

function ipOf(req) {
  if (!req) return null;
  return (req.headers && (req.headers['x-forwarded-for'] || '').split(',')[0].trim()) ||
    (req.socket && req.socket.remoteAddress) ||
    (req.connection && req.connection.remoteAddress) ||
    null;
}

async function logAudit(req, { action, entity, entity_id = null, description = null } = {}) {
  try {
    const user = req && req.user;
    if (!user) return;
    await db('audit_logs').insert({
      actor_id: user.employee_id,
      actor_name: user.full_name,
      actor_role: roleOf(user),
      action,
      entity,
      entity_id: entity_id ? String(entity_id) : null,
      description: description ? String(description) : null,
      ip_address: ipOf(req),
    });
  } catch (err) {
    console.error('Audit log failed:', err.message);
  }
}

module.exports = { logAudit };
