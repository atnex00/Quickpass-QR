const express = require('express');
const Joi = require('joi');
const multer = require('multer');
const { validate, validateQuery, validateParams } = require('../middleware/validate');
const { authenticate, requireSupervisor, requireAdmin, requireSecurity } = require('../middleware/auth');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

function handleMulterError(err, req, res, next) {
  if (err instanceof multer.MulterError) {
    const messages = {
      LIMIT_FILE_SIZE: 'File too large — max 5MB',
      LIMIT_UNEXPECTED_FILE: 'Unexpected file field',
    };
    return res.status(400).json({ success: false, message: messages[err.code] || err.message });
  }
  if (err) {
    return res.status(400).json({ success: false, message: err.message });
  }
  next();
}

const authController = require('../controllers/authController');
const leaveController = require('../controllers/leaveController');
const supervisorController = require('../controllers/supervisorController');
const scanController = require('../controllers/scanController');
const adminController = require('../controllers/adminController');
const auditController = require('../controllers/auditController');
const panelController = require('../controllers/panelController');

const router = express.Router();

// ── Health Check ──
router.get('/health', async (req, res, next) => {
  try {
    const db = require('../config/database');
    await db.raw('SELECT 1');
    res.json({ success: true, message: 'OK', timestamp: new Date().toISOString() });
  } catch (err) {
    next(err);
  }
});

// ── Auth Routes ──
router.post('/auth/login', validate(Joi.object({
  employee_id: Joi.string().pattern(/^\d{6}$/).required().messages({
    'string.pattern.base': 'Employee ID must be exactly 6 digits',
    'any.required': 'Employee ID is required',
  }),
  password: Joi.string().min(8).required(),
})), authController.login);

router.post('/auth/logout', authenticate, validate(Joi.object({
  refresh_sid: Joi.string().optional(),
}).min(0)), authController.logout);

router.post('/auth/refresh', validate(Joi.object({
  refresh_sid: Joi.string().optional(),
})), authController.refreshToken);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, validate(Joi.object({
  full_name: Joi.string().min(2).max(100),
  position: Joi.string().min(2).max(50),
  email: Joi.string().email(),
  password: Joi.string().min(8),
}).min(1)), authController.updateProfile);

router.post('/auth/profile/photo', authenticate, upload.single('photo'), handleMulterError, authController.uploadProfilePhoto);

router.put('/auth/fcm-token', authenticate, validate(Joi.object({
  fcm_token: Joi.string().required(),
})), authController.fcmToken);

// ── Employee Leave Routes ──
router.post('/leave/request', authenticate, validate(Joi.object({
  leave_date: Joi.date().iso().required(),
  start_time: Joi.string().pattern(/^\d{2}:\d{2}(:\d{2})?$/).required(),
  end_time: Joi.string().pattern(/^\d{2}:\d{2}(:\d{2})?$/).required(),
  reason: Joi.string().min(5).max(500).required(),
})), leaveController.submitLeave);

router.get('/leave/history', authenticate, validateQuery(Joi.object({
  status: Joi.string().valid('pending', 'approved', 'active', 'completed', 'rejected', 'cancelled').optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
})), leaveController.getHistory);
router.get('/leave/active', authenticate, leaveController.getActiveLeave);
router.get('/leave/:id', authenticate, validateParams(Joi.object({
  id: Joi.string().required(),
})), leaveController.getLeaveById);
router.post('/leave/:id/cancel', authenticate, validateParams(Joi.object({
  id: Joi.string().required(),
})), leaveController.cancelLeave);
router.delete('/leave/:id', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), leaveController.deleteLeave);

// ── Supervisor Routes ──
router.get('/supervisor/pending', authenticate, requireSupervisor, supervisorController.getPendingRequests);
router.post('/supervisor/approve/:leaveId', authenticate, requireSupervisor, validateParams(Joi.object({
  leaveId: Joi.string().required(),
})), supervisorController.approveLeave);
router.get('/supervisor/approved', authenticate, requireSupervisor, supervisorController.getApprovedLeaves);
router.post('/supervisor/revoke/:leaveId', authenticate, requireSupervisor, validateParams(Joi.object({
  leaveId: Joi.string().required(),
})), supervisorController.revokeApproval);
router.post('/supervisor/reject/:leaveId', authenticate, requireSupervisor, validate(Joi.object({
  reason: Joi.string().min(2).max(500).required(),
})), supervisorController.rejectLeave);
router.get('/supervisor/team-leaves', authenticate, requireSupervisor, validateQuery(Joi.object({
  date: Joi.string().isoDate().optional(),
  start_date: Joi.string().isoDate().optional(),
  end_date: Joi.string().isoDate().optional(),
})), supervisorController.getTeamLeaves);

// ── Scan Routes ──
router.post('/scan/validate', authenticate, requireSecurity, validate(Joi.object({
  qr_data: Joi.string().required(),
})), scanController.validateScan);
router.get('/scan/stats', authenticate, requireSecurity, scanController.getScanStats);

router.get('/scan/history', authenticate, requireSecurity, validateQuery(Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
})), scanController.getScanHistory);

// ── Admin Routes ──
router.post('/admin/employees', authenticate, requireAdmin, validate(Joi.object({
  employee_id: Joi.string().pattern(/^\d{6}$/).required(),
  full_name: Joi.string().min(2).max(100).required(),
  position: Joi.string().min(2).max(50).required(),
  department_id: Joi.string().optional(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).messages({
    'string.pattern.base': 'Password must contain at least one uppercase, one lowercase, and one number',
  }).required(),
  is_supervisor: Joi.boolean().optional(),
  is_admin: Joi.boolean().optional(),
  is_security: Joi.boolean().optional(),
})), adminController.createEmployee);
router.get('/admin/employees', authenticate, requireAdmin, validateQuery(Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  search: Joi.string().max(100).optional().allow(''),
  department_id: Joi.string().max(20).optional().allow(''),
  is_active: Joi.string().valid('true', 'false').optional(),
  role: Joi.string().valid('admin', 'supervisor', 'security').optional(),
})), adminController.listEmployees);
router.put('/admin/employees/:id', authenticate, requireAdmin, validate(Joi.object({
  full_name: Joi.string().min(2).max(100),
  position: Joi.string().min(2).max(50),
  department_id: Joi.string().allow(null, ''),
  email: Joi.string().email(),
  password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).messages({
    'string.pattern.base': 'Password must contain at least one uppercase, one lowercase, and one number',
  }),
  is_supervisor: Joi.boolean(),
  is_admin: Joi.boolean(),
  is_security: Joi.boolean(),
  is_active: Joi.boolean(),
}).min(1)), adminController.updateEmployee);
router.put('/admin/employees/:id/supervisor', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), adminController.toggleSupervisor);
router.put('/admin/employees/:id/admin', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), adminController.toggleAdmin);
router.put('/admin/employees/:id/status', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), adminController.toggleActive);
router.delete('/admin/employees/:id', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), adminController.deleteEmployee);
router.post('/admin/import/hr', authenticate, requireAdmin, validate(Joi.object({
  employees: Joi.array().items(Joi.object({
    employee_id: Joi.string().pattern(/^\d{6}$/).required(),
    full_name: Joi.string().min(2).max(100).required(),
    position: Joi.string().min(2).max(50).required(),
    department_id: Joi.string().required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(8).optional(),
    is_supervisor: Joi.boolean().optional(),
  })).min(1).required(),
})), adminController.importEmployees);
router.get('/admin/departments', authenticate, requireAdmin, adminController.getDepartments);
router.post('/admin/departments', authenticate, requireAdmin, validate(Joi.object({
  department_id: Joi.string().max(20).required(),
  department_name: Joi.string().min(2).max(100).required(),
  department_code: Joi.string().max(20).optional(),
  head_of_department: Joi.string().optional(),
})), adminController.createDepartment);
router.put('/admin/departments/:id', authenticate, requireAdmin, validate(Joi.object({
  department_name: Joi.string().min(2).max(100),
  department_code: Joi.string().max(20).allow(null, ''),
  head_of_department: Joi.string().allow(null, ''),
  is_active: Joi.boolean(),
}).min(1)), adminController.updateDepartment);
router.delete('/admin/departments/:id', authenticate, requireAdmin, validateParams(Joi.object({
  id: Joi.string().required(),
})), adminController.deleteDepartment);
router.get('/admin/reports', authenticate, requireAdmin, validateQuery(Joi.object({
  type: Joi.string().valid('daily', 'department', 'summary').optional(),
  start_date: Joi.string().isoDate().optional(),
  end_date: Joi.string().isoDate().optional(),
})), adminController.getReports);

// ── Audit Routes ──
router.get('/admin/audit', authenticate, requireAdmin, validateQuery(Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  actor_id: Joi.string().pattern(/^\d{6}$/).optional(),
})), auditController.getAuditLogs);

router.get('/admin/export', authenticate, requireAdmin, validateQuery(Joi.object({
  resource: Joi.string().valid('audit').optional(),
  actor_id: Joi.string().pattern(/^\d{6}$/).optional(),
})), auditController.exportAuditLogs);

// ── Admin Panel Routes ──
router.get('/admin/panel/status', authenticate, requireAdmin, panelController.getStatus);
router.post('/admin/panel/migrate', authenticate, requireAdmin, panelController.runMigrate);
router.post('/admin/panel/seed', authenticate, requireAdmin, panelController.runSeed);
router.get('/admin/panel/logs', authenticate, requireAdmin, panelController.getLogs);
router.get('/admin/panel/metrics', authenticate, requireAdmin, panelController.getMetrics);
router.post('/admin/panel/restart', authenticate, requireAdmin, panelController.restartServer);

module.exports = router;
