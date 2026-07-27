const db = require('../config/database');

async function log({ action, actor, entity, entityId, description, ip }) {
  await db('audit_logs').insert({
    actor_id: actor.id,
    actor_name: actor.name,
    actor_role: actor.role,
    action,
    entity,
    entity_id: entityId || null,
    description: description || null,
    ip_address: ip || null,
  });
}

async function query({ page = 1, limit = 25, actorId } = {}) {
  let query = db('audit_logs').orderBy('created_at', 'desc');

  if (actorId) {
    query = query.where('actor_id', actorId);
  }

  const total = await query.clone().clearOrder().count('* as count').first();
  const data = await query.clone().limit(limit).offset((page - 1) * limit);

  return { data, total: Number(total?.count || 0) };
}

async function exportQuery({ actorId } = {}) {
  let query = db('audit_logs').orderBy('created_at', 'desc');

  if (actorId) {
    query = query.where('actor_id', actorId);
  }

  return query;
}

module.exports = { log, query, exportQuery };