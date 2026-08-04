exports.up = async function(knex) {
  await knex.schema.table('leave_requests', (table) => {
    table.string('department_id', 20).nullable().alter();
  });
};

exports.down = async function(knex) {
  await knex.schema.table('leave_requests', (table) => {
    table.string('department_id', 20).notNullable().alter();
  });
};