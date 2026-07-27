exports.up = function (knex) {
  return knex.schema.alterTable('leave_requests', (table) => {
    table.string('out_qr_image', 500);
    table.string('in_qr_image', 500);
  });
};

exports.down = function (knex) {
  return knex.schema.alterTable('leave_requests', (table) => {
    table.dropColumn('out_qr_image');
    table.dropColumn('in_qr_image');
  });
};
