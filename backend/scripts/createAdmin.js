const bcrypt = require('bcryptjs');
const knex = require('../src/config/database');

(async () => {
  const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'admin123', 10);
  await knex('employees').insert({
    employee_id: '999999',
    full_name: 'System Admin',
    position: 'Administrator',
    department_id: 'DEP-004',
    email: 'admin@quickpass.com',
    is_supervisor: false,
    is_admin: true,
    is_active: true,
    password_hash: hash,
  });
  console.log('Admin account created!');
  console.log('Employee ID: 999999');
  console.log('Password: (set via ADMIN_PASSWORD env var or default)');
  await knex.destroy();
})().catch(e => { console.error(e); process.exit(1); });
