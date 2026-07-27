exports.up = function (knex) {
  return knex.schema.createTable('qr_scan_logs', (table) => {
    table.bigIncrements('log_id');
    table.string('leave_id', 30).notNullable()
      .references('leave_id').inTable('leave_requests');
    table.enu('qr_type', ['OUT', 'IN']).notNullable();
    table.string('scanned_by', 6);
    table.timestamp('scan_time').defaultTo(knex.fn.now());
    table.string('ip_address', 45);
    table.string('location', 100);
    table.boolean('is_valid').defaultTo(true);
    table.text('validation_message');

    table.index('leave_id');
    table.index('scan_time');
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('qr_scan_logs');
};
