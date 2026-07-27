const db = require('../config/database');
const qrService = require('../services/qrService');
const qrImageService = require('../services/qrImageService');
const { createError } = require('../middleware/errorHandler');
const { getLocalDateString } = require('../utils/date');
const auditService = require('../services/auditService');

function fmtDate(d) {
  if (d instanceof Date) return d.toISOString().split('T')[0];
  return String(d).split('T')[0];
}

async function getPendingRequests(req, res, next) {
  try {
    let query = db('leave_requests')
      .where('leave_requests.status', 'pending')
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .leftJoin('employees as sup', 'leave_requests.supervisor_id', 'sup.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position',
        'emp.profile_photo as employee_photo',
        'sup.full_name as supervisor_name'
      )
      .orderBy('leave_requests.created_at', 'asc');

    if (!req.user.is_admin) {
      query = query.andWhere('leave_requests.supervisor_id', req.user.employee_id);
    }

    const requests = await query;

    res.json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
}

async function approveLeave(req, res, next) {
  try {
    const { leaveId } = req.params;

    let leave;
    let outQrCode;
    let inQrCode;
    let outQrImage = null;
    let inQrImage = null;

    await db.transaction(async (trx) => {
      leave = await trx('leave_requests')
        .where({ leave_id: leaveId, status: 'pending' })
        .forUpdate()
        .first();

      if (!leave) {
        throw createError(404, 'Leave request not found or already processed');
      }

      if (!req.user.is_admin) {
        if (leave.supervisor_id !== req.user.employee_id) {
          throw createError(403, 'You are not the assigned supervisor for this request');
        }

        if (leave.department_id !== req.user.department_id) {
          throw createError(403, 'This request is not in your department');
        }
      }

      const leaveDate = fmtDate(leave.leave_date);
      const todayStr = getLocalDateString();

      const now = new Date();
      const schedOut = new Date(`${leaveDate}T${leave.start_time}`);
      const outRef = schedOut > now ? leave.start_time : new Date().toTimeString().slice(0, 8);
      const outDate = schedOut > now ? leaveDate : todayStr;
      const schedIn = new Date(`${leaveDate}T${leave.end_time}`);
      const inRef = schedIn > now ? leave.end_time : new Date().toTimeString().slice(0, 8);
      const inDate = schedIn > now ? leaveDate : todayStr;

      const outQrData = qrService.generateQrData(leave.leave_id, leave.employee_id, 'OUT', outDate, outRef);
      const inQrData = qrService.generateQrData(leave.leave_id, leave.employee_id, 'IN', inDate, inRef);

      outQrCode = qrService.encodeQrData(outQrData);
      inQrCode = qrService.encodeQrData(inQrData);

      try {
        outQrImage = await qrImageService.generateQrImage(outQrCode, 'OUT', leave.leave_id);
        inQrImage = await qrImageService.generateQrImage(inQrCode, 'IN', leave.leave_id);
      } catch (qrErr) {
        req.log?.error({ err: qrErr }, 'QR image generation failed (approval continues)');
      }

      await trx('leave_requests')
        .where({ leave_id: leaveId })
        .update({
          status: 'approved',
          out_qr_code: outQrCode,
          in_qr_code: inQrCode,
          out_qr_image: outQrImage,
          in_qr_image: inQrImage,
          updated_at: trx.fn.now(),
        });
    });

    const updated = await db('leave_requests')
      .where({ leave_id: leaveId })
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

    res.json({ success: true, data: updated, message: 'Leave approved' });

    auditService.log({
      action: 'approve',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: req.user.is_admin ? 'admin' : 'supervisor' },
      entity: 'leave_request',
      entityId: leaveId,
      description: `Approved leave for ${updated.employee_name} on ${fmtDate(leave.leave_date)}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function rejectLeave(req, res, next) {
  try {
    const { leaveId } = req.params;
    const { reason } = req.body;

    if (!reason || reason.trim().length === 0) {
      throw createError(400, 'Rejection reason is required');
    }

    const leave = await db('leave_requests')
      .where({ leave_id: leaveId, status: 'pending' })
      .first();

    if (!leave) {
      throw createError(404, 'Leave request not found or already processed');
    }

    if (!req.user.is_admin) {
      if (leave.supervisor_id !== req.user.employee_id) {
        throw createError(403, 'You are not the assigned supervisor for this request');
      }
      if (leave.department_id !== req.user.department_id) {
        throw createError(403, 'This request is not in your department');
      }
    }

    await db('leave_requests')
      .where({ leave_id: leaveId })
      .update({
        status: 'rejected',
        rejection_reason: reason.trim(),
        updated_at: db.fn.now(),
      });

    const updated = await db('leave_requests')
      .where({ leave_id: leaveId })
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

    res.json({ success: true, data: updated, message: 'Leave rejected' });

    auditService.log({
      action: 'reject',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: req.user.is_admin ? 'admin' : 'supervisor' },
      entity: 'leave_request',
      entityId: leaveId,
      description: `Rejected leave for ${updated.employee_name} on ${fmtDate(leave.leave_date)}: ${reason.trim()}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function getApprovedLeaves(req, res, next) {
  try {
    let query = db('leave_requests')
      .where('leave_requests.status', 'approved')
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .leftJoin('employees as sup', 'leave_requests.supervisor_id', 'sup.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position',
        'emp.profile_photo as employee_photo',
        'sup.full_name as supervisor_name'
      )
      .orderBy('leave_requests.updated_at', 'desc');

    if (!req.user.is_admin) {
      query = query.andWhere(function () {
        this.where('leave_requests.supervisor_id', req.user.employee_id)
          .orWhere('leave_requests.department_id', req.user.department_id);
      });
    }

    const requests = await query;
    res.json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
}

async function revokeApproval(req, res, next) {
  try {
    const { leaveId } = req.params;

    const leave = await db('leave_requests')
      .where({ leave_id: leaveId, status: 'approved' })
      .first();

    if (!leave) {
      throw createError(404, 'Approved leave request not found');
    }

    if (!req.user.is_admin) {
      if (leave.supervisor_id !== req.user.employee_id) {
        throw createError(403, 'You are not the assigned supervisor for this request');
      }
      if (leave.department_id !== req.user.department_id) {
        throw createError(403, 'This request is not in your department');
      }
    }

    qrImageService.deleteQrImages(leaveId);

    const updateData = {
      status: 'pending',
      out_qr_code: null,
      in_qr_code: null,
      out_qr_image: null,
      in_qr_image: null,
      updated_at: db.fn.now(),
    };
    if (!leave.out_scan_time) {
      updateData.out_scan_time = null;
    }
    if (!leave.in_scan_time) {
      updateData.in_scan_time = null;
    }

    await db('leave_requests')
      .where({ leave_id: leaveId })
      .update(updateData);

    const updated = await db('leave_requests')
      .where({ leave_id: leaveId })
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

    res.json({ success: true, data: updated, message: 'Approval revoked' });

    auditService.log({
      action: 'revoke',
      actor: { id: req.user.employee_id, name: req.user.full_name, role: req.user.is_admin ? 'admin' : 'supervisor' },
      entity: 'leave_request',
      entityId: leaveId,
      description: `Revoked approval for ${updated.employee_name} on ${fmtDate(leave.leave_date)}`,
      ip: req.ip,
    }).catch((err) => req.log?.error({ err }, 'Audit log error'));
  } catch (err) {
    next(err);
  }
}

async function getTeamLeaves(req, res, next) {
  try {
    const { date, start_date, end_date } = req.query;

    let query = db('leave_requests')
      .where('leave_requests.department_id', req.user.department_id)
      .whereIn('leave_requests.status', ['approved', 'active', 'pending'])
      .leftJoin('employees as emp', 'leave_requests.employee_id', 'emp.employee_id')
      .select(
        'leave_requests.*',
        'emp.full_name as employee_name',
        'emp.position as employee_position'
      );

    if (date) {
      query = query.andWhere('leave_requests.leave_date', date);
    } else if (start_date && end_date) {
      query = query.whereBetween('leave_requests.leave_date', [start_date, end_date]);
    }

    const leaves = await query.orderBy('leave_requests.leave_date', 'asc');

    res.json({ success: true, data: leaves });
  } catch (err) {
    next(err);
  }
}

module.exports = { getPendingRequests, getApprovedLeaves, approveLeave, rejectLeave, revokeApproval, getTeamLeaves };
