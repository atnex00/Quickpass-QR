const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const notificationService = require('../services/notificationService');
const { createError } = require('../middleware/errorHandler');

async function submitLeave(req, res, next) {
  try {
    const { leave_date, start_time, end_time, reason } = req.body;

    if (!leave_date || !start_time || !end_time || !reason) {
      throw createError(400, 'All fields are required');
    }

    if (start_time >= end_time) {
      throw createError(400, 'End time must be after start time');
    }

    const today = new Date().toISOString().split('T')[0];
    if (leave_date !== today) {
      throw createError(400, 'Leave date must be today');
    }

    const conflict = await db('leave_requests')
      .where({ employee_id: req.user.employee_id, leave_date })
      .whereNot('status', 'rejected')
      .whereNot('status', 'cancelled')
      .andWhere(function () {
        this.where(function () {
          this.where('start_time', '<', end_time)
              .andWhere('end_time', '>', start_time);
        });
      })
      .first();

    if (conflict) {
      throw createError(409, 'You already have a leave request for this time period');
    }

    let supervisor = await db('employees')
      .where({ department_id: req.user.department_id, is_supervisor: true, is_active: true })
      .first();

    if (!supervisor) {
      if (req.user.is_admin) {
        supervisor = req.user;
      } else {
        throw createError(500, 'No supervisor found for your department');
      }
    }

    const leaveId = `LV-${leave_date.replace(/-/g, '')}-${uuidv4().slice(0, 8).toUpperCase()}`;

    await db('leave_requests').insert({
      leave_id: leaveId,
      employee_id: req.user.employee_id,
      department_id: req.user.department_id,
      supervisor_id: supervisor.employee_id,
      leave_date,
      start_time,
      end_time,
      reason,
      status: 'pending',
      created_at: db.fn.now(),
      updated_at: db.fn.now(),
    });

    try {
      await notificationService.sendToEmployee(supervisor.employee_id, {
        title: 'New Leave Request',
        body: `${req.user.full_name} requested leave (${start_time} - ${end_time})`,
        data: { leave_id: leaveId, type: 'new_request' },
      });
    } catch (notifErr) {
      console.error('Notification error (submit):', notifErr.message);
    }

    const leave = await db('leave_requests')
      .leftJoin('employees', 'leave_requests.employee_id', 'employees.employee_id')
      .where('leave_requests.leave_id', leaveId)
      .select(
        'leave_requests.*',
        'employees.full_name as employee_name',
        'employees.position as employee_position',
        'employees.profile_photo as employee_photo'
      )
      .first();

    res.status(201).json({ success: true, data: leave, message: 'Leave request submitted' });
  } catch (err) {
    next(err);
  }
}

async function getHistory(req, res, next) {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = db('leave_requests')
      .where('leave_requests.employee_id', req.user.employee_id)
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

    if (status) {
      query = query.andWhere('leave_requests.status', status);
    }

    const { count } = await db('leave_requests')
      .where('leave_requests.employee_id', req.user.employee_id)
      .modify((qb) => { if (status) qb.andWhere('leave_requests.status', status); })
      .count('* as count')
      .first();
    const leaves = await query.limit(limit).offset(offset);

    res.json({
      success: true,
      data: leaves,
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

async function getActiveLeave(req, res, next) {
  try {
    const leave = await db('leave_requests')
      .where('leave_requests.employee_id', req.user.employee_id)
      .whereIn('status', ['approved', 'active'])
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .leftJoin('employees as sup', 'leave_requests.supervisor_id', 'sup.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position',
        'emp.profile_photo as employee_photo',
        'sup.full_name as supervisor_name'
      )
      .orderBy('leave_requests.created_at', 'desc')
      .first();

    if (!leave) {
      return res.status(404).json({ success: false, message: 'No active leave found' });
    }

    res.json({ success: true, data: leave });
  } catch (err) {
    next(err);
  }
}

async function getLeaveById(req, res, next) {
  try {
    const { id } = req.params;

    const leave = await db('leave_requests')
      .where('leave_requests.leave_id', id)
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .leftJoin('employees as sup', 'leave_requests.supervisor_id', 'sup.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position',
        'emp.profile_photo as employee_photo',
        'sup.full_name as supervisor_name'
      )
      .first();

    if (!leave) {
      throw createError(404, 'Leave request not found');
    }

    if (!req.user.is_admin) {
      if (leave.employee_id !== req.user.employee_id) {
        if (!req.user.is_supervisor) {
          throw createError(403, 'You can only view your own leave requests');
        }
        if (leave.department_id !== req.user.department_id) {
          throw createError(403, 'This leave request is not in your department');
        }
      }
    }

    res.json({ success: true, data: leave });
  } catch (err) {
    next(err);
  }
}

async function deleteLeave(req, res, next) {
  try {
    const { id } = req.params;

    if (!req.user.is_admin) {
      throw createError(403, 'Admin access required');
    }

    const leave = await db('leave_requests').where({ leave_id: id }).first();
    if (!leave) {
      throw createError(404, 'Leave request not found');
    }

    await db('qr_scan_logs').where({ leave_id: id }).del();
    await db('leave_requests').where({ leave_id: id }).del();

    res.json({ success: true, message: 'Leave request deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = { submitLeave, getHistory, getActiveLeave, getLeaveById, deleteLeave };
