const admin = require('firebase-admin');
const logger = require('./logger');

let firebaseApp = null;

function initFirebase() {
  if (firebaseApp) return firebaseApp;

  const required = [
    'FCM_PROJECT_ID', 'FCM_PRIVATE_KEY_ID', 'FCM_PRIVATE_KEY',
    'FCM_CLIENT_EMAIL', 'FCM_CLIENT_ID',
  ];

  const missing = required.filter(k => !process.env[k]);
  if (missing.length > 0) {
    logger.warn({ missing }, 'Firebase env vars missing — push notifications disabled');
    return null;
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.cert({
        type: process.env.FCM_TYPE,
        project_id: process.env.FCM_PROJECT_ID,
        private_key_id: process.env.FCM_PRIVATE_KEY_ID,
        private_key: process.env.FCM_PRIVATE_KEY.replace(/\\n/g, '\n'),
        client_email: process.env.FCM_CLIENT_EMAIL,
        client_id: process.env.FCM_CLIENT_ID,
        auth_uri: process.env.FCM_AUTH_URI,
        token_uri: process.env.FCM_TOKEN_URI,
      }),
    });
    logger.info('Firebase initialized');
    return firebaseApp;
  } catch (err) {
    logger.warn({ err }, 'Firebase init failed');
    return null;
  }
}

function getMessaging() {
  if (!firebaseApp) return null;
  return firebaseApp.messaging();
}

module.exports = { initFirebase, getMessaging };
