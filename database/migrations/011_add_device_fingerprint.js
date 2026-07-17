exports.up = function (knex) {
  return knex.schema.table('sessions', (table) => {
    table.string('device_fingerprint', 64).nullable();
  });
};

exports.down = function (knex) {
  return knex.schema.table('sessions', (table) => {
    table.dropColumn('device_fingerprint');
  });
};
