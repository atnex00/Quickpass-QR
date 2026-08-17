const db = require('../config/database');
const { createError } = require('../middleware/errorHandler');
const qrService = require('../services/qrService');

const MEMBER_SELECT = [
  'employees.employee_id',
  'employees.full_name',
  'employees.position',
  'employees.department_id',
  'departments.department_name',
  'departments.department_code',
  'employees.is_supervisor',
  'employees.is_active',
  'employees.profile_photo',
];

async function getTeam(req, res, next) {
  try {
    const rows = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .leftJoin('leave_requests', 'leave_requests.employee_id', 'employees.employee_id')
      .where('employees.department_id', req.user.department_id)
      .andWhere('employees.is_active', true)
      .groupBy('employees.employee_id', 'departments.department_id')
      .select(...MEMBER_SELECT)
      .select(db.raw('count(leave_requests.leave_id)::int as leave_count'))
      .orderBy('employees.full_name', 'asc');

    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
}

async function getDirectory(req, res, next) {
  try {
    const query = db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.is_active', true)
      .whereNotNull('employees.department_id')
      .select(...MEMBER_SELECT)
      .orderBy('departments.department_name', 'asc')
      .orderBy('employees.full_name', 'asc');

    if (!req.user.is_admin && !req.user.is_security) {
      query.where('employees.department_id', req.user.department_id);
    }

    const rows = await query;

    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
}

async function getTeamMemberLeaves(req, res, next) {
  try {
    const { employeeId } = req.params;

    const member = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', employeeId)
      .select(...MEMBER_SELECT)
      .first();

    if (!member || !member.is_active) {
      throw createError(404, 'Employee not found');
    }

    if (!req.user.is_admin && member.department_id !== req.user.department_id) {
      throw createError(403, 'You can only view employees in your own department');
    }

    const leaves = await db('leave_requests')
      .where('leave_requests.employee_id', employeeId)
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .leftJoin('employees as sup', 'leave_requests.supervisor_id', 'sup.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position',
        'emp.profile_photo as employee_photo',
        'sup.full_name as supervisor_name'
      )
      .orderBy('leave_requests.created_at', 'desc');

    const withExpiry = leaves.map((l) => ({
      ...l,
      out_qr_code: null,
      in_qr_code: null,
      is_expired: qrService.isOutQrExpired(l),
    }));

    res.json({
      success: true,
      data: withExpiry,
      employee: member,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getTeam, getDirectory, getTeamMemberLeaves };