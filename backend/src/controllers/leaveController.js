const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const notificationService = require('../services/notificationService');
const { createError } = require('../middleware/errorHandler');
const { getLocalDateString } = require('../utils/date');

async function submitLeave(req, res, next) {
  try {
    const { leave_date, start_time, end_time, reason } = req.body;

    if (!leave_date || !start_time || !end_time || !reason) {
      throw createError(400, 'All fields are required');
    }

    if (start_time >= end_time) {
      throw createError(400, 'End time must be after start time');
    }

    if (getLocalDateString(new Date(leave_date)) !== getLocalDateString()) {
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

    const supervisors = await db('employees')
      .where({ department_id: req.user.department_id, is_supervisor: true, is_active: true });

    if (supervisors.length === 0) {
      if (req.user.is_admin) {
        supervisors.push(req.user);
      } else {
        throw createError(422, 'No supervisor found for your department');
      }
    }

    const leaveDateStr = getLocalDateString(leave_date);
    const leaveId = `LV-${leaveDateStr.replace(/-/g, '')}-${uuidv4().slice(0, 8).toUpperCase()}`;

    await db('leave_requests').insert({
      leave_id: leaveId,
      employee_id: req.user.employee_id,
      department_id: req.user.department_id,
      supervisor_id: supervisors[0].employee_id,
      leave_date,
      start_time,
      end_time,
      reason,
      status: 'pending',
      created_at: db.fn.now(),
      updated_at: db.fn.now(),
    });

    await Promise.allSettled(
      supervisors.map((sup) =>
        notificationService.sendToEmployee(sup.employee_id, {
          title: 'New Leave Request',
          body: `${req.user.full_name} requested leave (${start_time} - ${end_time})`,
          data: { leave_id: leaveId, type: 'new_request' },
        }).catch((err) => req.log?.error({ err }, 'Notification error (submit)'))
      )
    );

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
      throw createError(404, 'No active leave found');
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

async function cancelLeave(req, res, next) {
  try {
    const { id } = req.params;

    await db.transaction(async (trx) => {
      const leave = await trx('leave_requests').where({ leave_id: id }).forUpdate().first();
      if (!leave) {
        throw createError(404, 'Leave request not found');
      }

      if (leave.employee_id !== req.user.employee_id && !req.user.is_admin) {
        throw createError(403, 'You can only cancel your own leave requests');
      }

      if (!['approved', 'pending'].includes(leave.status)) {
        throw createError(400, `Cannot cancel a leave that is ${leave.status}`);
      }

      await trx('leave_requests').where({ leave_id: id }).update({
        status: 'cancelled',
        out_qr_code: null,
        in_qr_code: null,
        out_qr_image: null,
        in_qr_image: null,
        updated_at: trx.fn.now(),
      });
    });

    res.json({ success: true, message: 'Leave request cancelled' });
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

    await db.transaction(async (trx) => {
      const leave = await trx('leave_requests').where({ leave_id: id }).first();
      if (!leave) {
        throw createError(404, 'Leave request not found');
      }

      await trx('qr_scan_logs').where({ leave_id: id }).del();
      await trx('leave_requests').where({ leave_id: id }).del();
    });

    res.json({ success: true, message: 'Leave request deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = { submitLeave, getHistory, getActiveLeave, getLeaveById, cancelLeave, deleteLeave };
