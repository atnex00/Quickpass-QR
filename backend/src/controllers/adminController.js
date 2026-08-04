const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { createError } = require('../middleware/errorHandler');
const { getLocalDateString } = require('../utils/date');
const auditService = require('../services/auditService');

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

    auditService.log({
      action: 'create',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: employee_id,
      description: `Created employee ${full_name} (${employee_id}) as ${position}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
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

    let updated;
    let changedFields;
    await db.transaction(async (trx) => {
      const employee = await trx('employees').where({ employee_id: id }).forUpdate().first();
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

      toUpdate.updated_at = trx.fn.now();

      await trx('employees').where({ employee_id: id }).update(toUpdate);

      if (updates.password) {
        await trx('sessions').where({ employee_id: id }).update({ is_active: false });
      }

      changedFields = Object.keys(toUpdate).filter((k) => k !== 'updated_at' && k !== 'password_hash');

      updated = await trx('employees')
        .leftJoin('departments', 'employees.department_id', 'departments.department_id')
        .where('employees.employee_id', id)
        .select('employees.*', 'departments.department_name')
        .first();
    });

    res.json({ success: true, data: updated });

    auditService.log({
      action: 'update',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: id,
      description: `Updated employee ${updated.full_name} (${id}): ${changedFields.join(', ')}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function toggleSupervisor(req, res, next) {
  try {
    const { id } = req.params;

    let toggledTo;
    let fullName;
    await db.transaction(async (trx) => {
      const employee = await trx('employees').where({ employee_id: id }).forUpdate().first();
      if (!employee) {
        throw createError(404, 'Employee not found');
      }

      fullName = employee.full_name;
      toggledTo = !employee.is_supervisor;
      await trx('employees').where({ employee_id: id }).update({
        is_supervisor: toggledTo,
        updated_at: trx.fn.now(),
      });
    });

    res.json({
      success: true,
      message: `Supervisor status toggled to ${toggledTo}`,
    });

    auditService.log({
      action: 'toggle_supervisor',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: id,
      description: `Toggled supervisor status of ${fullName} (${id}) to ${toggledTo}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function toggleAdmin(req, res, next) {
  try {
    const { id } = req.params;

    let toggledTo;
    let fullName;
    await db.transaction(async (trx) => {
      const employee = await trx('employees').where({ employee_id: id }).forUpdate().first();
      if (!employee) {
        throw createError(404, 'Employee not found');
      }

      if (id === req.user.employee_id && employee.is_admin) {
        throw createError(400, 'You cannot remove your own admin access');
      }

      if (employee.is_admin) {
        const adminCount = await trx('employees')
          .where({ is_admin: true, is_active: true })
          .count('* as count')
          .first();
        if (parseInt(adminCount?.count || 0) <= 1) {
          throw createError(400, 'Cannot demote the last active admin');
        }
      }

      fullName = employee.full_name;
      toggledTo = !employee.is_admin;
      await trx('employees').where({ employee_id: id }).update({
        is_admin: toggledTo,
        updated_at: trx.fn.now(),
      });
    });

    res.json({
      success: true,
      message: `Admin status toggled to ${toggledTo}`,
    });

    auditService.log({
      action: 'toggle_admin',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: id,
      description: `Toggled admin status of ${fullName} (${id}) to ${toggledTo}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function toggleActive(req, res, next) {
  try {
    const { id } = req.params;

    let isNowActive;
    let wasActive;
    let fullName;
    await db.transaction(async (trx) => {
      const employee = await trx('employees').where({ employee_id: id }).forUpdate().first();
      if (!employee) {
        throw createError(404, 'Employee not found');
      }

      if (id === req.user.employee_id && employee.is_active) {
        throw createError(400, 'You cannot deactivate your own account');
      }

      fullName = employee.full_name;
      wasActive = employee.is_active;
      isNowActive = !employee.is_active;
      await trx('employees').where({ employee_id: id }).update({
        is_active: isNowActive,
        updated_at: trx.fn.now(),
      });
    });

    res.json({
      success: true,
      message: `Employee ${wasActive ? 'deactivated' : 'activated'}`,
      data: { is_active: isNowActive },
    });

    auditService.log({
      action: wasActive ? 'deactivate' : 'activate',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: id,
      description: `${wasActive ? 'Deactivated' : 'Activated'} employee ${fullName} (${id})`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
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

    auditService.log({
      action: 'create',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'department',
      entityId: department_id,
      description: `Created department ${department_name} (${department_id})`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
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

    auditService.log({
      action: 'update',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'department',
      entityId: id,
      description: `Updated department ${updated.department_name} (${id})`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function deleteDepartment(req, res, next) {
  try {
    const { id } = req.params;

    let deptName;
    await db.transaction(async (trx) => {
      const dept = await trx('departments').where({ department_id: id }).forUpdate().first();
      if (!dept) {
        throw createError(404, 'Department not found');
      }

      deptName = dept.department_name;
      const empCount = await trx('employees').where({ department_id: id }).count('* as count').first();
      if (parseInt(empCount?.count || 0) > 0) {
        throw createError(400, `Cannot delete: ${empCount.count} employee(s) still belong to this department`);
      }

      const leaveCount = await trx('leave_requests').where({ department_id: id }).count('* as count').first();
      if (parseInt(leaveCount?.count || 0) > 0) {
        throw createError(400, `Cannot delete: ${leaveCount.count} leave request(s) reference this department`);
      }

      await trx('departments').where({ department_id: id }).del();
    });
    res.json({ success: true, message: 'Department deleted' });

    auditService.log({
      action: 'delete',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'department',
      entityId: id,
      description: `Deleted department ${deptName} (${id})`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
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

      if (id === req.user.employee_id) {
        throw createError(400, 'You cannot delete your own account');
      }

      const superviseCount = await trx('leave_requests').where({ supervisor_id: id }).count('* as count').first();
      if (parseInt(superviseCount?.count || 0) > 0) {
        throw createError(400, 'Cannot delete: employee has supervised leave requests. Deactivate instead.');
      }

      const leaveIds = await trx('leave_requests').where({ employee_id: id }).select('leave_id');
      const ids = leaveIds.map((l) => l.leave_id);

      if (ids.length > 0) {
        await trx('qr_scan_logs').whereIn('leave_id', ids).del();
      }
      await trx('qr_scan_logs').where({ scanned_by: id }).del();
      await trx('sessions').where({ employee_id: id }).del();
      await trx('audit_logs').where({ actor_id: id }).update({ actor_id: null });
      await trx('leave_requests').where({ employee_id: id }).del();
      await trx('employees').where({ employee_id: id }).del();
    });

    res.json({ success: true, message: 'Employee deleted' });

    auditService.log({
      action: 'delete',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: id,
      description: `Deleted employee ${id}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
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

    auditService.log({
      action: 'import',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: 'admin' },
      entity: 'employee',
      entityId: 'bulk',
      description: `Imported ${results.created} employees (${results.skipped} skipped, ${results.errors.length} errors)`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function getReports(req, res, next) {
  try {
    const { type, start_date, end_date } = req.query;

    let reportData;

    if (type === 'daily') {
      const date = start_date || getLocalDateString();
      reportData = await db('leave_requests')
        .where({ leave_date: date })
        .leftJoin('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .leftJoin('departments', 'leave_requests.department_id', 'departments.department_id')
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
        .leftJoin('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .leftJoin('departments', 'leave_requests.department_id', 'departments.department_id')
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
};
