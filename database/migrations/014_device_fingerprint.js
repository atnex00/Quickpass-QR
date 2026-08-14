exports.up = function (knex) {
  return knex.schema.alterTable('sessions', (table) => {
    table.text('device_fingerprint').nullable();
  });
};

exports.down = function (knex) {
  return knex.schema.alterTable('sessions', (table) => {
    table.dropColumn('device_fingerprint');
  });
};