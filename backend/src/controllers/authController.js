const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { createError } = require('../middleware/errorHandler');

async function login(req, res, next) {
  try {
    const { employee_id, password } = req.body;

    const employee = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', employee_id)
      .select(
        'employees.*',
        'departments.department_name'
      )
      .first();

    if (!employee || !employee.is_active) {
      throw createError(401, 'Invalid employee ID or password');
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
      expires_at: db.raw("NOW() + ?::interval", [process.env.SESSION_EXPIRES_IN || '7 days']),
      is_active: true,
    });

    await db('employees').where({ employee_id }).update({ last_login: db.fn.now() });

    const accessToken = jwt.sign(
      {
        employee_id: employee.employee_id,
        session_id: sessionId,
        role: employee.is_admin ? 'admin' : employee.is_security ? 'security' : employee.is_supervisor ? 'supervisor' : 'employee',
      },
      process.env.JWT_SECRET,
      { algorithm: 'HS256', expiresIn: '15m' }
    );

    res.cookie('refresh_sid', sessionId, {
      signed: true,
      httpOnly: true,
      secure: isSecureRequest(req),
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    const responsePayload = {
      success: true,
      token: accessToken,
      user: {
        employee_id: employee.employee_id,
        full_name: employee.full_name,
        position: employee.position,
        department_id: employee.department_id,
        department_name: employee.department_name,
        email: employee.email,
        is_supervisor: employee.is_supervisor,
        is_admin: employee.is_admin,
        is_security: employee.is_security,
        profile_photo: employee.profile_photo,
        hire_date: employee.hire_date,
      },
    };
    if (isMobileClient(req)) {
      responsePayload.refresh_sid = sessionId;
    }
    res.json(responsePayload);
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    const sessionId = req.signedCookies.refresh_sid || req.session_id;
    if (sessionId) {
      await db('sessions').where({ session_id: sessionId }).update({ is_active: false });
    }
    res.clearCookie('refresh_sid');
    res.json({ success: true, message: 'Logged out' });
  } catch (err) {
    next(err);
  }
}

async function refreshToken(req, res, next) {
  try {
    const isMobile = isMobileClient(req);
    const sessionId = req.signedCookies.refresh_sid || (isMobile && req.body?.refresh_sid);
    if (!sessionId) {
      throw createError(401, 'No refresh token');
    }

    let token;
    let newSessionId;

    await db.transaction(async (trx) => {
      const session = await trx('sessions')
        .where({ session_id: sessionId, is_active: true })
        .where('expires_at', '>', trx.fn.now())
        .forUpdate()
        .first();

      if (!session) {
        throw createError(401, 'Session expired');
      }

      const employee = await trx('employees').where({ employee_id: session.employee_id }).first();
      if (!employee || !employee.is_active) {
        await trx('sessions').where({ session_id: sessionId }).update({ is_active: false });
        throw createError(401, 'Employee not found or deactivated');
      }

      newSessionId = uuidv4();
      await trx('sessions').insert({
        session_id: newSessionId,
        employee_id: employee.employee_id,
        created_at: trx.fn.now(),
        expires_at: trx.raw("NOW() + ?::interval", [process.env.SESSION_EXPIRES_IN || '7 days']),
        is_active: true,
      });
      await trx('sessions').where({ session_id: sessionId }).update({ is_active: false });

      token = jwt.sign(
        {
          employee_id: employee.employee_id,
          session_id: newSessionId,
          role: employee.is_admin ? 'admin' : employee.is_security ? 'security' : employee.is_supervisor ? 'supervisor' : 'employee',
        },
        process.env.JWT_SECRET,
        { algorithm: 'HS256', expiresIn: '15m' }
      );
    });

    res.cookie('refresh_sid', newSessionId, {
      signed: true,
      httpOnly: true,
      secure: isSecureRequest(req),
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    const responsePayload = { success: true, token };
    if (isMobile) {
      responsePayload.refresh_sid = newSessionId;
    }
    res.json(responsePayload);
  } catch (err) {
    if (err.status === 401) {
      res.clearCookie('refresh_sid');
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
    if (password) {
      toUpdate.password_hash = await bcrypt.hash(password, 10);
      await db('sessions').where({ employee_id: req.user.employee_id }).update({ is_active: false });
    }

    if (Object.keys(toUpdate).length === 0) {
      throw createError(400, 'No valid fields to update');
    }

    toUpdate.updated_at = db.fn.now();

    await db('employees').where({ employee_id: req.user.employee_id }).update(toUpdate);

    const updated = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', req.user.employee_id)
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

async function uploadProfilePhoto(req, res, next) {
  try {
    if (!req.file) {
      throw createError(400, 'No photo file provided');
    }

    const buf = req.file.buffer;
    if (!buf || buf.length < 4) {
      throw createError(400, 'Invalid file');
    }
    const valid = (buf[0] === 0xFF && buf[1] === 0xD8) ||
                  (buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4E && buf[3] === 0x47) ||
                  (buf[0] === 0x47 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x38) ||
                  (buf[0] === 0x52 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x46);
    if (!valid) {
      throw createError(400, 'Only JPEG, PNG, GIF, and WebP images are accepted');
    }

    let ext = '.jpg';
    try {
      const meta = await sharp(buf).metadata();
      const formatExt = { jpeg: '.jpg', png: '.png', gif: '.gif', webp: '.webp' }[meta.format];
      if (!formatExt) {
        throw createError(400, 'Only JPEG, PNG, GIF, and WebP images are accepted');
      }
      ext = formatExt;
    } catch (err) {
      if (err.statusCode) throw err;
      throw createError(400, 'Invalid image file');
    }

    const uploadDir = path.join(__dirname, '../../uploads/photos');
    await fs.promises.mkdir(uploadDir, { recursive: true });

    const oldFiles = await fs.promises.readdir(uploadDir);
    const stale = oldFiles.filter((f) => f.startsWith(req.user.employee_id));
    await Promise.all(stale.map((f) => fs.promises.unlink(path.join(uploadDir, f)).catch(() => {})));
    const filename = `${req.user.employee_id}_${crypto.randomUUID()}${ext}`;
    await fs.promises.writeFile(path.join(uploadDir, filename), buf);

    const photoUrl = `/uploads/photos/${filename}`;
    await db('employees').where({ employee_id: req.user.employee_id }).update({
      profile_photo: photoUrl,
      updated_at: db.fn.now(),
    });

    const updated = await db('employees')
      .leftJoin('departments', 'employees.department_id', 'departments.department_id')
      .where('employees.employee_id', req.user.employee_id)
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

    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
}

function isMobileClient(req) {
  const ua = req.headers['user-agent'] || '';
  return ua.includes('Dart');
}

const isSecureRequest = (req) =>
  process.env.COOKIE_SECURE === 'true' ||
  (process.env.COOKIE_SECURE !== 'false' && (req.secure || process.env.NODE_ENV === 'production'));

module.exports = { login, logout, refreshToken, getProfile, updateProfile, fcmToken, uploadProfilePhoto };
