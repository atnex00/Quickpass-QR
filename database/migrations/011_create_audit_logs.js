exports.up = function (knex) {
  return knex.schema.createTable('audit_logs', (table) => {
    table.increments('audit_log_id').primary();
    table.string('actor_id', 6).references('employee_id').inTable('employees');
    table.string('actor_name', 120).notNullable();
    table.string('actor_role', 20).notNullable();
    table.string('action', 40).notNullable();
    table.string('entity', 40).notNullable();
    table.string('entity_id', 40);
    table.text('description');
    table.string('ip_address', 45);
    table.timestamp('created_at').defaultTo(knex.fn.now());

    table.index('actor_id');
    table.index('action');
    table.index('entity');
    table.index('created_at');
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('audit_logs');
};
