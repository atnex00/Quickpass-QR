const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { createError } = require('../middleware/errorHandler');
const { logAudit } = require('../utils/audit');

function csvEscape(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (/[",\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function toCsv(rows, columns) {
  const header = columns.map((c) => csvEscape(c.header)).join(',');
  const body = rows.map((row) => columns.map((c) => csvEscape(c.value(row))).join(',')).join('\n');
  return `${header}\n${body}`;
}

async function createEmployee(req, res, next) {
  try {
    const { employee_id, full_name, position, department_id, email, password, is_supervisor, is_admin, is_security } = req.body;

    if (!employee_id || !full_name || !position || !email || !password) {
      throw createError(400, 'All required fields must be provided');
    }

    if (!/^\d{6}$/.test(employee_id)) {
      throw createError(400, 'Employee ID must be exactly 6 digits');
    }

    const existing = await db('employees').where({ employee_id }).orWhere({ email }).first();
    if (existing) {
      throw createError(409, 'Employee ID or email already exists');
    }

    const password_hash = await bcrypt.hash(password, 10);

    await db('employees').insert({
      employee_id,
      full_name,
      position,
      department_id: department_id || null,
      email,
      password_hash,
      is_supervisor: is_supervisor || false,
      is_admin: is_admin || false,
      is_security: is_security || false,
      is_active: true,
      created_at: db.fn.now(),
      updated_at: db.fn.now(),
    });

    const employee = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', employee_id)
      .select('employees.*', 'departments.department_name')
      .first();

    res.status(201).json({ success: true, data: employee });

    logAudit(req, {
      action: 'create',
      entity: 'employee',
      entity_id: employee_id,
      description: `Created employee ${full_name} (${employee_id})`,
    });
  } catch (err) {
    next(err);
  }
}

async function listEmployees(req, res, next) {
  try {
    const { page = 1, limit = 50, department_id, is_active, search, role } = req.query;
    const offset = (page - 1) * limit;

    let query = db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .select('employees.*', 'departments.department_name', 'departments.department_code');

    if (department_id) {
      query = query.andWhere('employees.department_id', department_id);
    }
    if (is_active !== undefined) {
      query = query.andWhere('employees.is_active', is_active === 'true');
    }
    if (role === 'admin') {
      query = query.andWhere('employees.is_admin', true);
    } else if (role === 'supervisor') {
      query = query.andWhere('employees.is_supervisor', true);
    } else if (role === 'security') {
      query = query.andWhere('employees.is_security', true);
    }

    if (search) {
      query = query.andWhere(function () {
        this.where('employees.full_name', 'ilike', `%${search}%`)
          .orWhere('employees.employee_id', 'ilike', `%${search}%`)
          .orWhere('employees.email', 'ilike', `%${search}%`);
      });
    }

    const { count } = await query.clone().clearSelect().count('* as count').first();
    const employees = await query.orderBy('employees.created_at', 'desc').limit(limit).offset(offset);

    res.json({
      success: true,
      data: employees,
      pagination: {
        total: parseInt(count),
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateEmployee(req, res, next) {
  try {
    const { id } = req.params;
    const updates = req.body;

    const employee = await db('employees').where({ employee_id: id }).first();
    if (!employee) {
      throw createError(404, 'Employee not found');
    }

    const allowed = ['full_name', 'position', 'department_id', 'email', 'is_supervisor', 'is_admin', 'is_security', 'is_active'];
    const toUpdate = {};

    for (const field of allowed) {
      if (updates[field] !== undefined) {
        toUpdate[field] = updates[field] === '' ? null : updates[field];
      }
    }

    if (updates.password) {
      toUpdate.password_hash = await bcrypt.hash(updates.password, 10);
    }

    if (Object.keys(toUpdate).length === 0) {
      throw createError(400, 'No valid fields to update');
    }

    toUpdate.updated_at = db.fn.now();

    await db('employees').where({ employee_id: id }).update(toUpdate);

    const updated = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', id)
      .select('employees.*', 'departments.department_name')
      .first();

    res.json({ success: true, data: updated });

    logAudit(req, {
      action: 'update',
      entity: 'employee',
      entity_id: id,
      description: `Updated employee ${id}`,
    });
  } catch (err) {
    next(err);
  }
}

async function toggleSupervisor(req, res, next) {
  try {
    const { id } = req.params;

    const employee = await db('employees').where({ employee_id: id }).first();
    if (!employee) {
      throw createError(404, 'Employee not found');
    }

    await db('employees').where({ employee_id: id }).update({
      is_supervisor: !employee.is_supervisor,
      updated_at: db.fn.now(),
    });

    res.json({
      success: true,
      message: `Supervisor status toggled to ${!employee.is_supervisor}`,
    });

    logAudit(req, {
      action: 'update',
      entity: 'employee',
      entity_id: id,
      description: `Toggled supervisor status to ${!employee.is_supervisor} for ${id}`,
    });
  } catch (err) {
    next(err);
  }
}

async function toggleAdmin(req, res, next) {
  try {
    const { id } = req.params;

    const employee = await db('employees').where({ employee_id: id }).first();
    if (!employee) {
      throw createError(404, 'Employee not found');
    }

    await db('employees').where({ employee_id: id }).update({
      is_admin: !employee.is_admin,
      updated_at: db.fn.now(),
    });

    res.json({
      success: true,
      message: `Admin status toggled to ${!employee.is_admin}`,
    });

    logAudit(req, {
      action: 'update',
      entity: 'employee',
      entity_id: id,
      description: `Toggled admin status to ${!employee.is_admin} for ${id}`,
    });
  } catch (err) {
    next(err);
  }
}

async function toggleActive(req, res, next) {
  try {
    const { id } = req.params;

    const employee = await db('employees').where({ employee_id: id }).first();
    if (!employee) {
      throw createError(404, 'Employee not found');
    }

    await db('employees').where({ employee_id: id }).update({
      is_active: !employee.is_active,
      updated_at: db.fn.now(),
    });

    res.json({
      success: true,
      message: `Employee ${employee.is_active ? 'deactivated' : 'activated'}`,
      data: { is_active: !employee.is_active },
    });

    logAudit(req, {
      action: 'update',
      entity: 'employee',
      entity_id: id,
      description: `Set active=${!employee.is_active} for ${id}`,
    });
  } catch (err) {
    next(err);
  }
}

async function getDepartments(req, res, next) {
  try {
    const departments = await db('departments').where({ is_active: true }).orderBy('department_name');
    res.json({ success: true, data: departments });
  } catch (err) {
    next(err);
  }
}

async function createDepartment(req, res, next) {
  try {
    const { department_id, department_name, department_code, head_of_department } = req.body;

    if (!department_id || !department_name) {
      throw createError(400, 'Department ID and name are required');
    }

    const existing = await db('departments').where({ department_id }).first();
    if (existing) {
      throw createError(409, 'Department ID already exists');
    }

    const nameConflict = await db('departments').where({ department_name }).first();
    if (nameConflict) {
      throw createError(409, 'Department name already exists');
    }

    if (department_code) {
      const codeConflict = await db('departments').where({ department_code }).first();
      if (codeConflict) {
        throw createError(409, 'Department code already exists');
      }
    }

    await db('departments').insert({
      department_id,
      department_name,
      department_code: department_code || null,
      head_of_department: head_of_department || null,
      is_active: true,
    });

    const dept = await db('departments').where({ department_id }).first();
    res.status(201).json({ success: true, data: dept });

    logAudit(req, {
      action: 'create',
      entity: 'department',
      entity_id: department_id,
      description: `Created department ${department_name} (${department_id})`,
    });
  } catch (err) {
    next(err);
  }
}

async function updateDepartment(req, res, next) {
  try {
    const { id } = req.params;
    const { department_name, department_code, head_of_department, is_active } = req.body;

    const dept = await db('departments').where({ department_id: id }).first();
    if (!dept) {
      throw createError(404, 'Department not found');
    }

    const updateData = {};
    if (department_name !== undefined) updateData.department_name = department_name;
    if (department_code !== undefined) updateData.department_code = department_code || null;
    if (head_of_department !== undefined) updateData.head_of_department = head_of_department || null;
    if (is_active !== undefined) updateData.is_active = is_active;

    await db('departments').where({ department_id: id }).update(updateData);
    const updated = await db('departments').where({ department_id: id }).first();
    res.json({ success: true, data: updated });

    logAudit(req, {
      action: 'update',
      entity: 'department',
      entity_id: id,
      description: `Updated department ${id}`,
    });
  } catch (err) {
    next(err);
  }
}

async function deleteDepartment(req, res, next) {
  try {
    const { id } = req.params;

    const dept = await db('departments').where({ department_id: id }).first();
    if (!dept) {
      throw createError(404, 'Department not found');
    }

    const empCount = await db('employees').where({ department_id: id }).count('* as count').first();
    if (parseInt(empCount?.count || 0) > 0) {
      throw createError(400, `Cannot delete: ${empCount.count} employee(s) still belong to this department`);
    }

    await db('departments').where({ department_id: id }).del();
    res.json({ success: true, message: 'Department deleted' });

    logAudit(req, {
      action: 'delete',
      entity: 'department',
      entity_id: id,
      description: `Deleted department ${dept.department_name} (${id})`,
    });
  } catch (err) {
    next(err);
  }
}

async function deleteEmployee(req, res, next) {
  try {
    const { id } = req.params;

    await db.transaction(async (trx) => {
      const employee = await trx('employees').where({ employee_id: id }).first();
      if (!employee) {
        throw createError(404, 'Employee not found');
      }

      await trx('qr_scan_logs').where({ scanned_by: id }).del();
      await trx('sessions').where({ employee_id: id }).del();
      await trx('leave_requests').where({ employee_id: id }).del();
      await trx('employees').where({ employee_id: id }).del();
    });

    res.json({ success: true, message: 'Employee deleted' });

    logAudit(req, {
      action: 'delete',
      entity: 'employee',
      entity_id: id,
      description: `Deleted employee ${id} and all related records`,
    });
  } catch (err) {
    next(err);
  }
}

async function importEmployees(req, res, next) {
  try {
    const { employees } = req.body;

    if (!Array.isArray(employees) || employees.length === 0) {
      throw createError(400, 'Employees array is required');
    }

    const results = { created: 0, skipped: 0, errors: [] };

    for (const emp of employees) {
      try {
        if (!emp.employee_id || !emp.full_name || !emp.position || !emp.department_id || !emp.email) {
          results.errors.push({ employee_id: emp.employee_id, reason: 'Missing required fields' });
          continue;
        }

        const existing = await db('employees')
          .where({ employee_id: emp.employee_id })
          .orWhere({ email: emp.email })
          .first();

        if (existing) {
          results.skipped++;
          continue;
        }

        const password_hash = await bcrypt.hash(emp.password || uuidv4().split('-')[0], 10);

        await db('employees').insert({
          employee_id: emp.employee_id,
          full_name: emp.full_name,
          position: emp.position,
          department_id: emp.department_id,
          email: emp.email,
          password_hash,
          is_supervisor: emp.is_supervisor || false,
          is_active: true,
          created_at: db.fn.now(),
          updated_at: db.fn.now(),
        });

        results.created++;
      } catch (err) {
        results.errors.push({ employee_id: emp.employee_id, reason: err.message });
      }
    }

    res.json({ success: true, data: results });
  } catch (err) {
    next(err);
  }
}

async function getReports(req, res, next) {
  try {
    const { type, start_date, end_date } = req.query;

    let reportData;

    if (type === 'daily') {
      const date = start_date || new Date().toISOString().split('T')[0];
      reportData = await db('leave_requests')
        .where({ leave_date: date })
        .join('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .join('departments', 'leave_requests.department_id', 'departments.department_id')
        .select(
          'leave_requests.*',
          'employees.full_name as employee_name',
          'departments.department_name'
        )
        .orderBy('leave_requests.start_time');
    } else if (type === 'department') {
      reportData = await db('leave_requests')
        .join('departments', 'leave_requests.department_id', 'departments.department_id')
        .select(
          'departments.department_name',
          'departments.department_id',
          db.raw('COUNT(*) as total_requests'),
          db.raw("COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved"),
          db.raw("COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected"),
          db.raw("COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending"),
          db.raw("COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed")
        )
        .groupBy('departments.department_id', 'departments.department_name');
    } else {
      let query = db('leave_requests')
        .join('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .join('departments', 'leave_requests.department_id', 'departments.department_id')
        .select(
          'leave_requests.*',
          'employees.full_name as employee_name',
          'employees.position',
          'departments.department_name'
        );

      if (start_date) {
        query = query.andWhere('leave_requests.leave_date', '>=', start_date);
      }
      if (end_date) {
        query = query.andWhere('leave_requests.leave_date', '<=', end_date);
      }

      reportData = await query.orderBy('leave_requests.created_at', 'desc');
    }

    res.json({ success: true, data: reportData });
  } catch (err) {
    next(err);
  }
}

async function getAuditLog(req, res, next) {
  try {
    const { page = 1, limit = 25, action, actor_id, entity, start_date, end_date } = req.query;
    const offset = (page - 1) * limit;

    let query = db('audit_logs').orderBy('created_at', 'desc');

    if (action) query = query.andWhere('action', action);
    if (actor_id) query = query.andWhere('actor_id', actor_id);
    if (entity) query = query.andWhere('entity', entity);
    if (start_date) query = query.andWhere('created_at', '>=', `${start_date} 00:00:00`);
    if (end_date) query = query.andWhere('created_at', '<=', `${end_date} 23:59:59`);

    const { count } = await query.clone().clearSelect().count('* as count').first();
    const logs = await query.limit(limit).offset(offset);

    res.json({
      success: true,
      data: logs,
      pagination: {
        total: parseInt(count),
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function exportData(req, res, next) {
  try {
    const { resource, type, start_date, end_date, status } = req.query;

    if (resource === 'reports') {
      let reportData;
      if (type === 'department') {
        reportData = await db('leave_requests')
          .join('departments', 'leave_requests.department_id', 'departments.department_id')
          .select(
            'departments.department_name',
            db.raw('COUNT(*) as total_requests'),
            db.raw("COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved"),
            db.raw("COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected"),
            db.raw("COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending"),
            db.raw("COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed")
          )
          .groupBy('departments.department_id', 'departments.department_name');
      } else {
        let q = db('leave_requests')
          .join('employees', 'leave_requests.employee_id', 'employees.employee_id')
          .join('departments', 'leave_requests.department_id', 'departments.department_id')
          .select(
            'leave_requests.leave_id',
            'leave_requests.leave_date',
            'employees.employee_id',
            'employees.full_name as employee_name',
            'departments.department_name',
            'leave_requests.start_time',
            'leave_requests.end_time',
            'leave_requests.status',
            'leave_requests.rejection_reason'
          );
        if (start_date) q = q.andWhere('leave_requests.leave_date', '>=', start_date);
        if (end_date) q = q.andWhere('leave_requests.leave_date', '<=', end_date);
        if (status) q = q.andWhere('leave_requests.status', status);
        reportData = await q.orderBy('leave_requests.leave_date', 'desc');
      }
      const columns = type === 'department'
        ? [
            { header: 'Department', value: (r) => r.department_name },
            { header: 'Total', value: (r) => r.total_requests },
            { header: 'Approved', value: (r) => r.approved },
            { header: 'Rejected', value: (r) => r.rejected },
            { header: 'Pending', value: (r) => r.pending },
            { header: 'Completed', value: (r) => r.completed },
          ]
        : [
            { header: 'Leave ID', value: (r) => r.leave_id },
            { header: 'Date', value: (r) => r.leave_date },
            { header: 'Employee ID', value: (r) => r.employee_id },
            { header: 'Employee', value: (r) => r.employee_name },
            { header: 'Department', value: (r) => r.department_name },
            { header: 'Start', value: (r) => r.start_time },
            { header: 'End', value: (r) => r.end_time },
            { header: 'Status', value: (r) => r.status },
            { header: 'Rejection Reason', value: (r) => r.rejection_reason },
          ];
      const csv = toCsv(reportData, columns);
      res.attachment('leave_report.csv');
      return res.status(200).send(`\uFEFF${csv}`);
    }

    if (resource === 'leaves') {
      let q = db('leave_requests')
        .join('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .join('departments', 'leave_requests.department_id', 'departments.department_id')
        .select(
          'leave_requests.leave_id',
          'leave_requests.leave_date',
          'employees.employee_id',
          'employees.full_name as employee_name',
          'departments.department_name',
          'leave_requests.start_time',
          'leave_requests.end_time',
          'leave_requests.status',
          'leave_requests.rejection_reason'
        );
      if (status) q = q.andWhere('leave_requests.status', status);
      const rows = await q.orderBy('leave_requests.created_at', 'desc');
      const columns = [
        { header: 'Leave ID', value: (r) => r.leave_id },
        { header: 'Date', value: (r) => r.leave_date },
        { header: 'Employee ID', value: (r) => r.employee_id },
        { header: 'Employee', value: (r) => r.employee_name },
        { header: 'Department', value: (r) => r.department_name },
        { header: 'Start', value: (r) => r.start_time },
        { header: 'End', value: (r) => r.end_time },
        { header: 'Status', value: (r) => r.status },
        { header: 'Rejection Reason', value: (r) => r.rejection_reason },
      ];
      const csv = toCsv(rows, columns);
      res.attachment('leave_history.csv');
      return res.status(200).send(`\uFEFF${csv}`);
    }

    if (resource === 'scans') {
      const rows = await db('qr_scan_logs')
        .leftJoin('employees', 'qr_scan_logs.employee_id', 'employees.employee_id')
        .select(
          'qr_scan_logs.log_id',
          'qr_scan_logs.scan_time',
          'employees.employee_id',
          'employees.full_name as employee_name',
          'qr_scan_logs.qr_type',
          'qr_scan_logs.is_valid'
        )
        .orderBy('qr_scan_logs.scan_time', 'desc');
      const columns = [
        { header: 'Log ID', value: (r) => r.log_id },
        { header: 'Scan Time', value: (r) => r.scan_time },
        { header: 'Employee ID', value: (r) => r.employee_id },
        { header: 'Employee', value: (r) => r.employee_name },
        { header: 'Type', value: (r) => r.qr_type },
        { header: 'Valid', value: (r) => r.is_valid },
      ];
      const csv = toCsv(rows, columns);
      res.attachment('scan_history.csv');
      return res.status(200).send(`\uFEFF${csv}`);
    }

    if (resource === 'employees') {
      const rows = await db('employees')
        .leftJoin('departments', 'employees.department_id', 'departments.department_id')
        .select(
          'employees.employee_id',
          'employees.full_name',
          'employees.position',
          'departments.department_name',
          'employees.email',
          'employees.is_supervisor',
          'employees.is_admin',
          'employees.is_security',
          'employees.is_active'
        )
        .orderBy('employees.employee_id');
      const columns = [
        { header: 'Employee ID', value: (r) => r.employee_id },
        { header: 'Name', value: (r) => r.full_name },
        { header: 'Position', value: (r) => r.position },
        { header: 'Department', value: (r) => r.department_name },
        { header: 'Email', value: (r) => r.email },
        { header: 'Supervisor', value: (r) => r.is_supervisor },
        { header: 'Admin', value: (r) => r.is_admin },
        { header: 'Security', value: (r) => r.is_security },
        { header: 'Active', value: (r) => r.is_active },
      ];
      const csv = toCsv(rows, columns);
      res.attachment('employees.csv');
      return res.status(200).send(`\uFEFF${csv}`);
    }

    if (resource === 'audit') {
      let q = db('audit_logs').orderBy('created_at', 'desc');
      if (start_date) q = q.andWhere('created_at', '>=', `${start_date} 00:00:00`);
      if (end_date) q = q.andWhere('created_at', '<=', `${end_date} 23:59:59`);
      const rows = await q;
      const columns = [
        { header: 'Timestamp', value: (r) => r.created_at },
        { header: 'Actor ID', value: (r) => r.actor_id },
        { header: 'Actor Name', value: (r) => r.actor_name },
        { header: 'Role', value: (r) => r.actor_role },
        { header: 'Action', value: (r) => r.action },
        { header: 'Entity', value: (r) => r.entity },
        { header: 'Entity ID', value: (r) => r.entity_id },
        { header: 'Description', value: (r) => r.description },
        { header: 'IP Address', value: (r) => r.ip_address },
      ];
      const csv = toCsv(rows, columns);
      res.attachment('audit_log.csv');
      return res.status(200).send(`\uFEFF${csv}`);
    }

    throw createError(400, 'Unknown export resource');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createEmployee,
  listEmployees,
  updateEmployee,
  deleteEmployee,
  toggleSupervisor,
  toggleAdmin,
  toggleActive,
  getDepartments,
  createDepartment,
  updateDepartment,
  deleteDepartment,
  importEmployees,
  getReports,
  getAuditLog,
  exportData,
};
