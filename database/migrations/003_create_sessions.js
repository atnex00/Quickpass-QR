exports.up = function (knex) {
  return knex.schema.createTable('sessions', (table) => {
    table.string('session_id', 36).primary();
    table.string('employee_id', 6).notNullable()
      .references('employee_id').inTable('employees');
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('expires_at').notNullable();

    table.index('employee_id');
    table.index('is_active');
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('sessions');
};
