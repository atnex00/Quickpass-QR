const db = require('../config/database');
const qrService = require('../services/qrService');
const notificationService = require('../services/notificationService');
const { createError } = require('../middleware/errorHandler');

async function validateScan(req, res, next) {
  try {
    const { qr_data } = req.body;
    const scannedById = req.user.employee_id;

    if (!qr_data) {
      throw createError(400, 'QR data is required');
    }

    const decoded = qrService.decodeQrData(qr_data);
    if (!decoded) {
      throw createError(400, 'Invalid QR code');
    }

    const { leave_id, employee_id, type, timestamp, signature } = decoded;

    if (!qrService.verifySignature(leave_id, employee_id, type, timestamp, signature)) {
      throw createError(400, 'QR code signature is invalid');
    }

    if (type === 'OUT') {
      const timeValid = qrService.isWithinTimeWindow(timestamp, process.env.QR_VALIDITY_WINDOW_MINUTES || 15);
      if (!timeValid) {
        throw createError(400, 'QR code has expired');
      }
    }

    let leave;

    await db.transaction(async (trx) => {
      leave = await trx('leave_requests')
        .where({ leave_id })
        .join('employees', 'leave_requests.employee_id', 'employees.employee_id')
        .select(
          'leave_requests.*',
          'employees.full_name as employee_name',
          'employees.profile_photo as employee_photo',
          'employees.position as employee_position',
          'employees.department_id as emp_department_id'
        )
        .forUpdate()
        .first();

      if (!leave) {
        throw createError(404, 'Leave request not found');
      }

      if (leave.employee_id !== employee_id) {
        throw createError(400, 'QR code employee mismatch');
      }

      const existingScan = await trx('qr_scan_logs')
        .where({ leave_id, qr_type: type })
        .first();

      if (existingScan) {
        throw createError(400, `This ${type} QR code has already been scanned`);
      }

      if (type === 'OUT') {
        if (leave.status !== 'approved') {
          throw createError(400, `Cannot scan OUT QR: leave must be approved first (current status: ${leave.status})`);
        }

        await trx('leave_requests').where({ leave_id }).update({
          status: 'active',
          out_scan_time: trx.fn.now(),
          updated_at: trx.fn.now(),
        });
      } else if (type === 'IN') {
        if (leave.status === 'approved') {
          throw createError(400, 'Scan the OUT (exit) QR code first before scanning the IN (entry) QR');
        }
        if (leave.status !== 'active') {
          throw createError(400, `Cannot scan IN QR: leave must be active (current status: ${leave.status})`);
        }

        if (!leave.out_scan_time) {
          throw createError(400, 'OUT QR must be scanned before IN QR');
        }

        await trx('leave_requests').where({ leave_id }).update({
          status: 'completed',
          in_scan_time: trx.fn.now(),
          updated_at: trx.fn.now(),
        });
      } else {
        throw createError(400, 'Invalid QR type');
      }

      await trx('qr_scan_logs').insert({
        leave_id,
        qr_type: type,
        scanned_by: scannedById,
        scan_time: trx.fn.now(),
        ip_address: req.ip,
        is_valid: true,
        validation_message: `${type} scan successful`,
      });
    });

    try {
      await notificationService.sendToEmployee(leave.employee_id, {
        title: type === 'OUT' ? 'Gate Exit' : 'Gate Entry',
        body: type === 'OUT'
          ? `You have exited the premises. Remember to scan IN before ${leave.end_time}`
          : `You have returned to the premises. Leave completed.`,
        data: { leave_id, type: type === 'OUT' ? 'scanned_out' : 'scanned_in' },
      });
    } catch (notifErr) {
      req.log?.error({ err: notifErr }, 'Notification error (scan)');
    }

    res.json({
      success: true,
      message: type === 'OUT' ? 'Exit recorded successfully' : 'Entry recorded successfully',
      data: {
        employee_name: leave.employee_name,
        employee_id: leave.employee_id,
        employee_photo: leave.employee_photo,
        position: leave.employee_position,
        department_id: leave.emp_department_id,
        leave_date: leave.leave_date,
        start_time: leave.start_time,
        end_time: leave.end_time,
        type,
        new_status: type === 'OUT' ? 'active' : 'completed',
      },
    });
  } catch (err) {
    if (err.code === '23505') {
      return next(createError(400, 'This QR code has already been scanned'));
    }
    next(err);
  }
}

async function getScanHistory(req, res, next) {
  try {
    const { page = 1, limit = 50, department } = req.query;
    const offset = (page - 1) * limit;

    const base = db('qr_scan_logs')
      .leftJoin('leave_requests', 'qr_scan_logs.leave_id', 'leave_requests.leave_id')
      .leftJoin('employees', 'leave_requests.employee_id', 'employees.employee_id')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .leftJoin('employees as scanner', 'qr_scan_logs.scanned_by', 'scanner.employee_id');
    if (department) {
      base.where('departments.department_name', department);
    }

    const { count } = await base.clone().count('* as count').first();
    const logs = await base
      .select(
        'qr_scan_logs.*',
        'employees.full_name as employee_name',
        'employees.employee_id as employee_id',
        'departments.department_name as department_name',
        'departments.department_code as department_code',
        'scanner.full_name as scanned_by_name'
      )
      .orderBy('qr_scan_logs.scan_time', 'desc')
      .limit(limit)
      .offset(offset);

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

async function getScanHistoryDepartments(req, res, next) {
  try {
    const departments = await db('departments')
      .leftJoin('employees', 'employees.department_id', 'departments.department_id')
      .leftJoin('leave_requests', 'leave_requests.employee_id', 'employees.employee_id')
      .leftJoin('qr_scan_logs', 'qr_scan_logs.leave_id', 'leave_requests.leave_id')
      .select(
        'departments.department_name as department_name',
        'departments.department_code as department_code'
      )
      .count('qr_scan_logs.log_id as scan_count')
      .groupBy('departments.department_id')
      .orderBy('departments.department_name', 'asc');

    res.json({
      success: true,
      data: departments.map((d) => ({
        department_name: d.department_name,
        department_code: d.department_code,
        scan_count: parseInt(d.scan_count) || 0,
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function getScanStats(req, res, next) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const stats = await db('qr_scan_logs')
      .select(
        db.raw('COUNT(*) as total'),
        db.raw('COUNT(*) FILTER (WHERE is_valid = true) as valid'),
        db.raw('COUNT(*) FILTER (WHERE is_valid = false) as invalid'),
        db.raw("COUNT(*) FILTER (WHERE qr_type = 'OUT') as out_count"),
        db.raw("COUNT(*) FILTER (WHERE qr_type = 'IN') as in_count"),
      )
      .where('scan_time', '>=', today)
      .first();

    const recent = await db('qr_scan_logs')
      .leftJoin('leave_requests', 'qr_scan_logs.leave_id', 'leave_requests.leave_id')
      .leftJoin('employees', 'leave_requests.employee_id', 'employees.employee_id')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .leftJoin('employees as scanner', 'qr_scan_logs.scanned_by', 'scanner.employee_id')
      .select(
        'qr_scan_logs.*',
        'employees.full_name as employee_name',
        'employees.employee_id as employee_id',
        'departments.department_name as department_name',
        'departments.department_code as department_code',
        'scanner.full_name as scanned_by_name'
      )
      .where('qr_scan_logs.scan_time', '>=', today)
      .orderBy('qr_scan_logs.scan_time', 'desc')
      .limit(10);

    res.json({
      success: true,
      data: {
        today_total: parseInt(stats.total) || 0,
        today_valid: parseInt(stats.valid) || 0,
        today_invalid: parseInt(stats.invalid) || 0,
        today_out: parseInt(stats.out_count) || 0,
        today_in: parseInt(stats.in_count) || 0,
        recent,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { validateScan, getScanHistory, getScanHistoryDepartments, getScanStats };
