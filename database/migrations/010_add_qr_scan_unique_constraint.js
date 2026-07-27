exports.up = async function (knex) {
  await knex.schema.alterTable('qr_scan_logs', (table) => {
    table.unique(['leave_id', 'qr_type']);
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('qr_scan_logs', (table) => {
    table.dropUnique(['leave_id', 'qr_type']);
  });
};
