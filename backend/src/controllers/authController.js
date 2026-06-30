const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { createError } = require('../middleware/errorHandler');

async function login(req, res, next) {
  try {
    const { employee_id, password } = req.body;

    const employee = await db('employees')
      .where({ employee_id })
      .first();

    if (!employee) {
      throw createError(401, 'Invalid employee ID or password');
    }

    if (!employee.is_active) {
      throw createError(403, 'Account is deactivated');
    }

    const valid = await bcrypt.compare(password, employee.password_hash);
    if (!valid) {
      throw createError(401, 'Invalid employee ID or password');
    }

    const sessionId = uuidv4();

    await db('sessions').insert({
      session_id: sessionId,
      employee_id: employee.employee_id,
      created_at: db.fn.now(),
      expires_at: db.raw(`NOW() + INTERVAL '${process.env.SESSION_EXPIRES_IN || '7 days'}'`),
      is_active: true,
    });

    const token = jwt.sign(
      {
        employee_id: employee.employee_id,
        session_id: sessionId,
        role: employee.is_security ? 'security' : employee.is_supervisor ? 'supervisor' : 'employee',
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    await db('employees').where({ employee_id }).update({ last_login: db.fn.now() });

    res.json({
      success: true,
      token,
      user: {
        employee_id: employee.employee_id,
        full_name: employee.full_name,
        position: employee.position,
        department_id: employee.department_id,
        email: employee.email,
        is_supervisor: employee.is_supervisor,
        is_admin: employee.is_admin,
        is_security: employee.is_security,
        profile_photo: employee.profile_photo,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    if (req.session_id) {
      await db('sessions').where({ session_id: req.session_id }).update({ is_active: false });
    }
    res.json({ success: true, message: 'Logged out' });
  } catch (err) {
    next(err);
  }
}

async function refreshToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw createError(401, 'No token provided');
    }

    const oldToken = authHeader.split(' ')[1];
    const decoded = jwt.verify(oldToken, process.env.JWT_SECRET);

    const session = await db('sessions')
      .where({ session_id: decoded.session_id, is_active: true })
      .first();

    if (!session) {
      throw createError(401, 'Session expired');
    }

    const employee = await db('employees').where({ employee_id: decoded.employee_id }).first();
    if (!employee || !employee.is_active) {
      throw createError(401, 'Employee not found or deactivated');
    }

    const token = jwt.sign(
      {
        employee_id: employee.employee_id,
        session_id: decoded.session_id,
        role: employee.is_security ? 'security' : employee.is_supervisor ? 'supervisor' : 'employee',
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.json({ success: true, token });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    next(err);
  }
}

async function getProfile(req, res, next) {
  try {
    res.json({
      success: true,
      data: {
        employee_id: req.user.employee_id,
        full_name: req.user.full_name,
        position: req.user.position,
        department_id: req.user.department_id,
        department_name: req.user.department_name,
        email: req.user.email,
        is_supervisor: req.user.is_supervisor,
        is_admin: req.user.is_admin,
        is_security: req.user.is_security,
        profile_photo: req.user.profile_photo,
        hire_date: req.user.hire_date,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const { full_name, position, email, password } = req.body;
    const toUpdate = {};

    if (full_name !== undefined) toUpdate.full_name = full_name;
    if (position !== undefined) toUpdate.position = position;
    if (email !== undefined) toUpdate.email = email;
    if (password) toUpdate.password_hash = await bcrypt.hash(password, 10);

    if (Object.keys(toUpdate).length === 0) {
      throw createError(400, 'No valid fields to update');
    }

    toUpdate.updated_at = db.fn.now();

    await db('employees').where({ employee_id: req.user.employee_id }).update(toUpdate);

    const updated = await db('employees')
      .join('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', req.user.employee_id)
      .select('employees.*', 'departments.department_name')
      .first();

    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
}

async function fcmToken(req, res, next) {
  try {
    const { fcm_token } = req.body;
    await db('employees').where({ employee_id: req.user.employee_id }).update({ fcm_token });
    res.json({ success: true, message: 'FCM token updated' });
  } catch (err) {
    next(err);
  }
}

module.exports = { login, logout, refreshToken, getProfile, updateProfile, fcmToken };
