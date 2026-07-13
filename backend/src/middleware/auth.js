const jwt = require('jsonwebtoken');
const db = require('../config/database');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const session = await db('sessions')
      .where({ session_id: decoded.session_id, is_active: true })
      .where('expires_at', '>', db.fn.now())
      .first();

    if (!session) {
      return res.status(401).json({ success: false, message: 'Session expired' });
    }

    const employee = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', decoded.employee_id)
      .select(
        'employees.employee_id',
        'employees.full_name',
        'employees.position',
        'employees.department_id',
        'departments.department_name',
        'employees.email',
        'employees.is_supervisor',
        'employees.is_admin',
        'employees.is_security',
        'employees.is_active',
        'employees.profile_photo',
        'employees.hire_date'
      )
      .first();

    if (!employee) {
      return res.status(401).json({ success: false, message: 'Employee not found' });
    }

    if (!employee.is_active) {
      return res.status(403).json({ success: false, message: 'Account deactivated' });
    }

    req.user = employee;
    req.session_id = decoded.session_id;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
}

function requireSupervisor(req, res, next) {
  if (!req.user.is_supervisor && !req.user.is_admin) {
    return res.status(403).json({ success: false, message: 'Supervisor access required' });
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.user.is_admin) {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
}

function requireSecurity(req, res, next) {
  if (!req.user.is_security && !req.user.is_admin) {
    return res.status(403).json({ success: false, message: 'Security access required' });
  }
  next();
}

module.exports = { authenticate, requireSupervisor, requireAdmin, requireSecurity };
