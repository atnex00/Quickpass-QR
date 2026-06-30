exports.seed = async function (knex) {
  await knex('departments').del();

  await knex('departments').insert([
    { department_id: 'DEP-001', department_name: 'Engineering', department_code: 'ENG', head_of_department: 'David Kim', is_active: true },
    { department_id: 'DEP-002', department_name: 'Marketing', department_code: 'MKT', head_of_department: 'Emma Brown', is_active: true },
    { department_id: 'DEP-003', department_name: 'Human Resources', department_code: 'HR', head_of_department: 'Frank Green', is_active: true },
    { department_id: 'DEP-004', department_name: 'Finance', department_code: 'FIN', head_of_department: 'Lisa Johnson', is_active: true },
    { department_id: 'DEP-005', department_name: 'Operations', department_code: 'OPS', head_of_department: 'Mark Taylor', is_active: true },
    { department_id: 'DEP-006', department_name: 'Sales', department_code: 'SAL', head_of_department: 'Sarah Wilson', is_active: true },
    { department_id: 'DEP-007', department_name: 'Information Technology', department_code: 'IT', head_of_department: 'James Anderson', is_active: true },
    { department_id: 'DEP-008', department_name: 'Research & Development', department_code: 'RND', head_of_department: 'Rachel Chen', is_active: true },
  ]);
};
