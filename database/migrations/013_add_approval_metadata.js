exports.up = function (knex) {
  return knex.schema
    .alterTable('leave_requests', (table) => {
      table.timestamp('approved_at');
      table.string('approved_by', 6)
        .references('employee_id').inTable('employees')
        .onDelete('SET NULL');
    })
    .then(() =>
      knex.raw('DROP FUNCTION IF EXISTS generate_employee_id()')
    )
    .then(() =>
      knex.raw('DROP SEQUENCE IF EXISTS employee_id_seq')
    );
};

exports.down = function (knex) {
  return knex.schema
    .alterTable('leave_requests', (table) => {
      table.dropColumn('approved_by');
      table.dropColumn('approved_at');
    })
    .then(() =>
      knex.raw('CREATE SEQUENCE IF NOT EXISTS employee_id_seq START 1')
    )
    .then(() =>
      knex.raw(`
        CREATE OR REPLACE FUNCTION generate_employee_id()
        RETURNS VARCHAR(6) AS $$
        DECLARE
          next_id INTEGER;
        BEGIN
          next_id := NEXTVAL('employee_id_seq');
          RETURN LPAD(next_id::TEXT, 6, '0');
        END;
        $$ LANGUAGE plpgsql;
      `)
    );
};
