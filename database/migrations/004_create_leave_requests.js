exports.up = function (knex) {
  return knex.schema.createTable('leave_requests', (table) => {
    table.string('leave_id', 30).primary();
    table.string('employee_id', 6).notNullable()
      .references('employee_id').inTable('employees');
    table.string('department_id', 20).notNullable()
      .references('department_id').inTable('departments');
    table.string('supervisor_id', 6).notNullable()
      .references('employee_id').inTable('employees');
    table.date('leave_date').notNullable();
    table.string('start_time', 8).notNullable();
    table.string('end_time', 8).notNullable();
    table.text('reason').notNullable();
    table.enu('status', ['pending', 'approved', 'rejected', 'active', 'completed', 'cancelled'])
      .defaultTo('pending');
    table.text('out_qr_code');
    table.text('in_qr_code');
    table.timestamp('out_scan_time');
    table.timestamp('in_scan_time');
    table.text('rejection_reason');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.index('employee_id');
    table.index('supervisor_id');
    table.index('status');
    table.index('leave_date');
    table.index(['department_id', 'status']);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('leave_requests');
};
