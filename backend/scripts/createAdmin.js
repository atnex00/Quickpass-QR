const bcrypt = require('bcryptjs');
const knex = require('../src/config/database');

(async () => {
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (!adminPassword) {
    console.error('ERROR: ADMIN_PASSWORD environment variable is required');
    process.exit(1);
  }

  const hash = await bcrypt.hash(adminPassword, 10);
  await knex('employees').insert({
    employee_id: '999999',
    full_name: process.env.ADMIN_NAME || 'System Admin',
    position: process.env.ADMIN_POSITION || 'Administrator',
    department_id: process.env.ADMIN_DEPT || 'DEP-004',
    email: process.env.ADMIN_EMAIL || 'admin@quickpass.com',
    is_supervisor: false,
    is_admin: true,
    is_active: true,
    password_hash: hash,
  });
  console.log('Admin account created!');
  console.log('Employee ID: 999999');
  await knex.destroy();
})().catch(e => { console.error(e); process.exit(1); });
