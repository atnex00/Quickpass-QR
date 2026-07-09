exports.seed = async function (knex) {
  await knex.raw('TRUNCATE TABLE employees, departments, sessions, leave_requests, qr_scan_logs RESTART IDENTITY CASCADE');

  await knex('departments').insert([
    { department_id: 'DEP-001', department_name: 'Institutional Services Department', department_code: 'ISD', head_of_department: 'Alex Turner', is_active: true },
    { department_id: 'DEP-002', department_name: 'Technical Services Department', department_code: 'TSD', head_of_department: 'Ethan White', is_active: true },
    { department_id: 'DEP-003', department_name: 'Finance Services Department', department_code: 'FSD', head_of_department: 'Isabella Anderson', is_active: true },
    { department_id: 'DEP-004', department_name: 'Internal Audit Department', department_code: 'IAD', head_of_department: 'Charlotte Martin', is_active: true },
    { department_id: 'DEP-005', department_name: 'Human Resource & Administration Department', department_code: 'HRAD', head_of_department: 'Noah Taylor', is_active: true },
    { department_id: 'DEP-006', department_name: 'Corporate Planning Department', department_code: 'CPD', head_of_department: 'Lucas Harris', is_active: true },
  ]);
};
