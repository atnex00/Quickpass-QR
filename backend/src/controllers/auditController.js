const auditService = require('../services/auditService');

async function getAuditLogs(req, res, next) {
  try {
    const { page = 1, limit = 25, actor_id } = req.query;

    const result = await auditService.query({
      page: Number(page),
      limit: Number(limit),
      actorId: actor_id,
    });

    res.json({
      success: true,
      data: result.data,
      pagination: {
        total: result.total,
        page: Number(page),
        limit: Number(limit),
        pages: Math.ceil(result.total / Number(limit)),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function exportAuditLogs(req, res, next) {
  try {
    const { actor_id } = req.query;
    const rows = await auditService.exportQuery({ actorId: actor_id });

    const csvHeader = 'audit_log_id,actor_id,actor_name,actor_role,action,entity,entity_id,description,ip_address,created_at';
    const csvRows = rows.map((r) =>
      [
        r.audit_log_id,
        r.actor_id,
        `"${(r.actor_name || '').replace(/"/g, '""')}"`,
        r.actor_role,
        r.action,
        r.entity,
        r.entity_id || '',
        `"${(r.description || '').replace(/"/g, '""')}"`,
        r.ip_address || '',
        r.created_at,
      ].join(',')
    );

    const csv = [csvHeader, ...csvRows].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="audit_log.csv"');
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

module.exports = { getAuditLogs, exportAuditLogs };