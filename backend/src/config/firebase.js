const admin = require('firebase-admin');

let firebaseApp = null;

function initFirebase() {
  if (firebaseApp) return firebaseApp;

  const required = [
    'FCM_PROJECT_ID', 'FCM_PRIVATE_KEY_ID', 'FCM_PRIVATE_KEY',
    'FCM_CLIENT_EMAIL', 'FCM_CLIENT_ID',
  ];

  const missing = required.filter(k => !process.env[k]);
  if (missing.length > 0) {
    console.warn(`Firebase: missing env vars (${missing.join(', ')}). Push notifications disabled.`);
    return null;
  }

  try {
    const privateKey = process.env.FCM_PRIVATE_KEY.startsWith('"')
      ? JSON.parse(process.env.FCM_PRIVATE_KEY)
      : process.env.FCM_PRIVATE_KEY.replace(/\\n/g, '\n');

    firebaseApp = admin.initializeApp({
      credential: admin.cert({
        type: process.env.FCM_TYPE || 'service_account',
        project_id: process.env.FCM_PROJECT_ID,
        private_key_id: process.env.FCM_PRIVATE_KEY_ID,
        private_key: privateKey,
        client_email: process.env.FCM_CLIENT_EMAIL,
        client_id: process.env.FCM_CLIENT_ID,
        auth_uri: process.env.FCM_AUTH_URI || 'https://accounts.google.com/o/oauth2/auth',
        token_uri: process.env.FCM_TOKEN_URI || 'https://oauth2.googleapis.com/token',
      }),
    });
    console.log('Firebase initialized');
    return firebaseApp;
  } catch (err) {
    console.warn('Firebase init failed:', err.message);
    return null;
  }
}

function getMessaging() {
  if (!firebaseApp) return null;
  return admin.messaging();
}

module.exports = { initFirebase, getMessaging };
