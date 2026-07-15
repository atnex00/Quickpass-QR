const bcrypt = require('bcryptjs');

exports.seed = async function (knex) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Seeds must not be run in production');
  }

  await knex('employees').del();

  const hash = await bcrypt.hash('pass1234', 10);

  // Reset sequence
  await knex.raw("SELECT setval('employee_id_seq', 1, false)");

  await knex('employees').insert([
    {
      employee_id: '000001', full_name: 'Alice Chen', position: 'Software Engineer',
      department_id: 'DEP-001', email: 'alice@company.com',
      is_supervisor: false, is_active: true, hire_date: '2024-01-15', password_hash: hash,
    },
    {
      employee_id: '000002', full_name: 'Bob Smith', position: 'Marketing Specialist',
      department_id: 'DEP-002', email: 'bob@company.com',
      is_supervisor: false, is_active: true, hire_date: '2024-02-01', password_hash: hash,
    },
    {
      employee_id: '000003', full_name: 'Carol White', position: 'HR Coordinator',
      department_id: 'DEP-003', email: 'carol@company.com',
      is_supervisor: false, is_active: true, hire_date: '2024-03-10', password_hash: hash,
    },
    {
      employee_id: '000004', full_name: 'David Kim', position: 'Engineering Manager',
      department_id: 'DEP-001', email: 'david@company.com',
      is_supervisor: true, is_active: true, hire_date: '2020-06-01', password_hash: hash,
    },
    {
      employee_id: '000005', full_name: 'Emma Brown', position: 'Marketing Director',
      department_id: 'DEP-002', email: 'emma@company.com',
      is_supervisor: true, is_active: true, hire_date: '2019-08-15', password_hash: hash,
    },
    {
      employee_id: '000006', full_name: 'Frank Green', position: 'HR Manager',
      department_id: 'DEP-003', email: 'frank@company.com',
      is_supervisor: true, is_active: true, hire_date: '2020-01-20', password_hash: hash,
    },
    {
      employee_id: '000007', full_name: 'Grace Lee', position: 'Senior Developer',
      department_id: 'DEP-001', email: 'grace@company.com',
      is_supervisor: false, is_active: true, hire_date: '2022-05-01', password_hash: hash,
    },
    {
      employee_id: '000008', full_name: 'Henry Wilson', position: 'Product Manager',
      department_id: 'DEP-001', email: 'henry@company.com',
      is_supervisor: true, is_active: true, hire_date: '2022-03-10', password_hash: hash,
    },
    {
      employee_id: '000009', full_name: 'Michael Park', position: 'Software Engineer',
      department_id: 'DEP-001', email: 'michael@company.com',
      is_supervisor: false, is_active: true, hire_date: '2024-04-01', password_hash: hash,
    },
    {
      employee_id: '000010', full_name: 'Sarah Johnson', position: 'Tech Lead',
      department_id: 'DEP-001', email: 'sarah@company.com',
      is_supervisor: true, is_active: true, hire_date: '2023-06-15', password_hash: hash,
    },
    {
      employee_id: '999999', full_name: 'System Admin', position: 'System Administrator',
      department_id: 'DEP-001', email: 'admin@company.com',
      is_supervisor: true, is_admin: true, is_security: true, is_active: true, hire_date: '2024-01-01', password_hash: hash,
    },
    {
      employee_id: '090901', full_name: 'Guard Mike', position: 'Security Guard',
      department_id: null, email: 'guard@company.com',
      is_security: true, is_active: true, hire_date: '2024-06-01', password_hash: hash,
    },
  ]);

  // Update sequence to max ID
  await knex.raw("SELECT setval('employee_id_seq', 999999, true)");
};
