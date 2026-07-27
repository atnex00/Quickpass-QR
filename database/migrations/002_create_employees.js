exports.up = function (knex) {
  return knex.schema
    .raw('CREATE SEQUENCE IF NOT EXISTS employee_id_seq START 1')
    .createTable('employees', (table) => {
      table.string('employee_id', 6).primary();
      table.string('full_name', 100).notNullable();
      table.string('position', 50).notNullable();
      table.string('department_id', 20).notNullable()
        .references('department_id').inTable('departments');
      table.string('email', 100).notNullable().unique();
      table.boolean('is_supervisor').defaultTo(false);
      table.boolean('is_admin').defaultTo(false);
      table.boolean('is_active').defaultTo(true);
      table.string('profile_photo', 255);
      table.date('hire_date');
      table.string('password_hash', 255).notNullable();
      table.string('fcm_token', 255);
      table.timestamp('last_login');
      table.timestamp('created_at').defaultTo(knex.fn.now());
      table.timestamp('updated_at').defaultTo(knex.fn.now());

      table.index('department_id');
      table.index('is_supervisor');
      table.index(['department_id', 'is_supervisor']);
    });
};

exports.down = function (knex) {
  return knex.schema
    .dropTableIfExists('employees')
    .raw('DROP SEQUENCE IF EXISTS employee_id_seq');
};
