const bcrypt = require('bcryptjs');

exports.seed = async function (knex) {
  await knex('employees').del();

  const hash = await bcrypt.hash('pass1234', 10);

  await knex.raw("SELECT setval('employee_id_seq', 1, false)");

  await knex('employees').insert([
    // ── ISD — Institutional Services Department ──
    {
      employee_id: '000005', full_name: 'Alex Turner', position: 'Operations Staff',
      department_id: 'DEP-001', email: 'alex.turner@zaneco.com',
      is_active: true, hire_date: '2024-05-20', password_hash: hash,
    },
    {
      employee_id: '000006', full_name: 'Emily Davis', position: 'Services Coordinator',
      department_id: 'DEP-001', email: 'emily.davis@zaneco.com',
      is_active: true, hire_date: '2024-06-10', password_hash: hash,
    },
    {
      employee_id: '000015', full_name: 'Liam Thomas', position: 'ISD Supervisor',
      department_id: 'DEP-001', email: 'liam.thomas@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2020-08-05', password_hash: hash,
    },
    {
      employee_id: '090901', full_name: 'Mike Ross', position: 'Head of Security',
      department_id: 'DEP-001', email: 'mike.ross@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-01-10', password_hash: hash,
    },
    {
      employee_id: '090902', full_name: 'Sarah Connor', position: 'Security Guard',
      department_id: 'DEP-001', email: 'sarah.connor@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-03-15', password_hash: hash,
    },
    {
      employee_id: '090903', full_name: 'John Smith', position: 'Security Guard',
      department_id: 'DEP-001', email: 'john.smith@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-04-01', password_hash: hash,
    },
    {
      employee_id: '090904', full_name: 'David Miller', position: 'Security Guard',
      department_id: 'DEP-001', email: 'david.miller@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-05-20', password_hash: hash,
    },
    {
      employee_id: '090905', full_name: 'Chris Evans', position: 'Security Guard',
      department_id: 'DEP-001', email: 'chris.evans@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-06-10', password_hash: hash,
    },
    {
      employee_id: '090906', full_name: 'Tony Stark', position: 'Security Guard',
      department_id: 'DEP-001', email: 'tony.stark@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-07-01', password_hash: hash,
    },
    {
      employee_id: '090907', full_name: 'Natasha Romanoff', position: 'Security Guard',
      department_id: 'DEP-001', email: 'natasha.romanoff@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-08-15', password_hash: hash,
    },
    {
      employee_id: '090908', full_name: 'Steve Rogers', position: 'Security Guard',
      department_id: 'DEP-001', email: 'steve.rogers@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-09-01', password_hash: hash,
    },
    {
      employee_id: '090909', full_name: 'Bruce Banner', position: 'Security Guard',
      department_id: 'DEP-001', email: 'bruce.banner@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-10-01', password_hash: hash,
    },
    {
      employee_id: '090910', full_name: 'Clint Barton', position: 'Security Guard',
      department_id: 'DEP-001', email: 'clint.barton@zaneco.com',
      is_security: true, is_active: true, hire_date: '2023-11-01', password_hash: hash,
    },

    // ── TSD — Technical Services Department ──
    {
      employee_id: '000001', full_name: 'James Wilson', position: 'Software Engineer',
      department_id: 'DEP-002', email: 'james.wilson@zaneco.com',
      is_active: true, hire_date: '2024-01-15', password_hash: hash,
    },
    {
      employee_id: '000009', full_name: 'Daniel Kim', position: 'Junior Developer',
      department_id: 'DEP-002', email: 'daniel.kim@zaneco.com',
      is_active: true, hire_date: '2024-09-01', password_hash: hash,
    },
    {
      employee_id: '000011', full_name: 'Ethan White', position: 'TSD Manager',
      department_id: 'DEP-002', email: 'ethan.white@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2020-03-01', password_hash: hash,
    },
    {
      employee_id: '000019', full_name: 'Mason Thompson', position: 'Tech Lead',
      department_id: 'DEP-002', email: 'mason.thompson@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2021-07-15', password_hash: hash,
    },

    // ── FSD — Finance Services Department ──
    {
      employee_id: '000004', full_name: 'Sara Patel', position: 'Financial Analyst',
      department_id: 'DEP-003', email: 'sara.patel@zaneco.com',
      is_active: true, hire_date: '2024-04-05', password_hash: hash,
    },
    {
      employee_id: '000008', full_name: 'Olivia Brown', position: 'Finance Associate',
      department_id: 'DEP-003', email: 'olivia.brown@zaneco.com',
      is_active: true, hire_date: '2024-08-15', password_hash: hash,
    },
    {
      employee_id: '000014', full_name: 'Isabella Anderson', position: 'FSD Manager',
      department_id: 'DEP-003', email: 'isabella.anderson@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2021-01-10', password_hash: hash,
    },

    // ── IAD — Internal Audit Department ──
    {
      employee_id: '000002', full_name: 'Maria Garcia', position: 'Audit Associate',
      department_id: 'DEP-004', email: 'maria.garcia@zaneco.com',
      is_active: true, hire_date: '2024-02-01', password_hash: hash,
    },
    {
      employee_id: '000018', full_name: 'Charlotte Martin', position: 'IAD Manager',
      department_id: 'DEP-004', email: 'charlotte.martin@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2020-05-20', password_hash: hash,
    },

    // ── HRAD — Human Resource & Administration Department ──
    {
      employee_id: '000003', full_name: 'John Lee', position: 'HR Coordinator',
      department_id: 'DEP-005', email: 'john.lee@zaneco.com',
      is_active: true, hire_date: '2024-03-10', password_hash: hash,
    },
    {
      employee_id: '000013', full_name: 'Noah Taylor', position: 'HRAD Manager',
      department_id: 'DEP-005', email: 'noah.taylor@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2020-02-20', password_hash: hash,
    },

    // ── CPD — Corporate Planning Department ──
    {
      employee_id: '000007', full_name: 'Ryan Chen', position: 'IT Support Specialist',
      department_id: 'DEP-006', email: 'ryan.chen@zaneco.com',
      is_active: true, hire_date: '2024-07-01', password_hash: hash,
    },
    {
      employee_id: '000010', full_name: 'Sophia Martinez', position: 'Planning Associate',
      department_id: 'DEP-006', email: 'sophia.martinez@zaneco.com',
      is_active: true, hire_date: '2024-10-01', password_hash: hash,
    },
    {
      employee_id: '000012', full_name: 'Ava Johnson', position: 'CPD Supervisor',
      department_id: 'DEP-006', email: 'ava.johnson@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2019-06-15', password_hash: hash,
    },
    {
      employee_id: '000016', full_name: 'Mia Jackson', position: 'CPD Supervisor',
      department_id: 'DEP-006', email: 'mia.jackson@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2021-03-12', password_hash: hash,
    },
    {
      employee_id: '000017', full_name: 'Lucas Harris', position: 'CPD Manager',
      department_id: 'DEP-006', email: 'lucas.harris@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2019-11-01', password_hash: hash,
    },
    {
      employee_id: '000020', full_name: 'Amelia Robinson', position: 'CPD Supervisor',
      department_id: 'DEP-006', email: 'amelia.robinson@zaneco.com',
      is_supervisor: true, is_active: true, hire_date: '2021-09-01', password_hash: hash,
    },

    // ── Admin ──
    {
      employee_id: '999999', full_name: 'System Admin', position: 'System Administrator',
      department_id: 'DEP-001', email: 'admin@zaneco.com',
      is_supervisor: true, is_admin: true, is_security: true, is_active: true, hire_date: '2024-01-01', password_hash: hash,
    },
  ]);

  await knex.raw("SELECT setval('employee_id_seq', 999999, true)");
};
