exports.up = function (knex) {
  return knex.schema.alterTable('employees', (table) => {
    table.string('department_id', 20).nullable().alter();
  });
};

exports.down = function (knex) {
  return knex.schema.alterTable('employees', (table) => {
    table.string('department_id', 20).notNullable().alter();
  });
};
