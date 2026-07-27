const db = require('../config/database');
const { getMessaging } = require('../config/firebase');

async function sendToEmployee(employeeId, payload) {
  const messaging = getMessaging();
  if (!messaging) return;

  const employee = await db('employees')
    .where({ employee_id: employeeId, is_active: true })
    .select('fcm_token')
    .first();

  if (!employee || !employee.fcm_token) {
    return;
  }

  const message = {
    token: employee.fcm_token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data || {},
    android: {
      priority: 'high',
      notification: {
        channel_id: 'leave_notifications',
        priority: 'high',
      },
    },
  };

  try {
    await messaging.send(message);
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered') {
      await db('employees').where({ employee_id: employeeId }).update({ fcm_token: null });
    }
    throw err;
  }
}

module.exports = { sendToEmployee };
