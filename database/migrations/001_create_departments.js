exports.up = function (knex) {
  return knex.schema.createTable('departments', (table) => {
    table.string('department_id', 20).primary();
    table.string('department_name', 100).notNullable().unique();
    table.string('department_code', 10).unique();
    table.string('head_of_department', 100);
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('departments');
};
