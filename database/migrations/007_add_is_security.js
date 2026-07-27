exports.up = function (knex) {
  return knex.schema.table('employees', (table) => {
    table.boolean('is_security').defaultTo(false);
    table.index('is_security');
  });
};

exports.down = function (knex) {
  return knex.schema.table('employees', (table) => {
    table.dropIndex('is_security');
    table.dropColumn('is_security');
  });
};
