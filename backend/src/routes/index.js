const express = require('express');
const Joi = require('joi');
const multer = require('multer');
const { validate } = require('../middleware/validate');
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

const authController = require('../controllers/authController');
const leaveController = require('../controllers/leaveController');
const supervisorController = require('../controllers/supervisorController');
const scanController = require('../controllers/scanController');
const adminController = require('../controllers/adminController');

const router = express.Router();

// ── Health Check ──
router.get('/health', (req, res) => {
  res.json({ success: true, message: 'Quickpass API is running', timestamp: new Date().toISOString() });
});

// ── Auth Routes ──
router.post('/auth/login', validate(Joi.object({
  employee_id: Joi.string().pattern(/^\d{6}$/).required().messages({
    'string.pattern.base': 'Employee ID must be exactly 6 digits',
    'any.required': 'Employee ID is required',
  }),
  password: Joi.string().min(8).required(),
})), authController.login);

router.post('/auth/logout', authenticate, authController.logout);
router.post('/auth/refresh', authController.refreshToken);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, validate(Joi.object({
  full_name: Joi.string().min(2).max(100),
  position: Joi.string().min(2).max(50),
  email: Joi.string().email(),
  password: Joi.string().min(8),
}).min(1)), authController.updateProfile);

router.post('/auth/profile/photo', authenticate, upload.single('photo'), authController.uploadProfilePhoto);

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

router.get('/leave/history', authenticate, leaveController.getHistory);
router.get('/leave/active', authenticate, leaveController.getActiveLeave);
router.get('/leave/:id', authenticate, leaveController.getLeaveById);
router.delete('/leave/:id', authenticate, requireAdmin, leaveController.deleteLeave);

// ── Supervisor Routes ──
router.get('/supervisor/pending', authenticate, requireSupervisor, supervisorController.getPendingRequests);
router.post('/supervisor/approve/:leaveId', authenticate, requireSupervisor, supervisorController.approveLeave);
router.get('/supervisor/approved', authenticate, requireSupervisor, supervisorController.getApprovedLeaves);
router.post('/supervisor/revoke/:leaveId', authenticate, requireSupervisor, supervisorController.revokeApproval);
router.post('/supervisor/reject/:leaveId', authenticate, requireSupervisor, validate(Joi.object({
  reason: Joi.string().min(2).max(500).required(),
})), supervisorController.rejectLeave);
router.get('/supervisor/team-leaves', authenticate, requireSupervisor, supervisorController.getTeamLeaves);

// ── Scan Routes ──
router.post('/scan/validate', authenticate, requireSecurity, validate(Joi.object({
  qr_data: Joi.string().required(),
})), scanController.validateScan);
router.get('/scan/history', authenticate, requireSecurity, scanController.getScanHistory);

// ── Admin Routes ──
router.post('/admin/employees', authenticate, requireAdmin, validate(Joi.object({
  employee_id: Joi.string().pattern(/^\d{6}$/).required(),
  full_name: Joi.string().min(2).max(100).required(),
  position: Joi.string().min(2).max(50).required(),
  department_id: Joi.string().optional(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  is_supervisor: Joi.boolean().optional(),
  is_admin: Joi.boolean().optional(),
  is_security: Joi.boolean().optional(),
})), adminController.createEmployee);
router.get('/admin/employees', authenticate, requireAdmin, adminController.listEmployees);
router.put('/admin/employees/:id', authenticate, requireAdmin, validate(Joi.object({
  full_name: Joi.string().min(2).max(100),
  position: Joi.string().min(2).max(50),
  department_id: Joi.string().allow(null, ''),
  email: Joi.string().email(),
  password: Joi.string().min(8),
  is_supervisor: Joi.boolean(),
  is_admin: Joi.boolean(),
  is_security: Joi.boolean(),
  is_active: Joi.boolean(),
}).min(1)), adminController.updateEmployee);
router.put('/admin/employees/:id/supervisor', authenticate, requireAdmin, adminController.toggleSupervisor);
router.put('/admin/employees/:id/admin', authenticate, requireAdmin, adminController.toggleAdmin);
router.put('/admin/employees/:id/status', authenticate, requireAdmin, adminController.toggleActive);
router.delete('/admin/employees/:id', authenticate, requireAdmin, adminController.deleteEmployee);
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
router.delete('/admin/departments/:id', authenticate, requireAdmin, adminController.deleteDepartment);
router.get('/admin/reports', authenticate, requireAdmin, adminController.getReports);

module.exports = router;
