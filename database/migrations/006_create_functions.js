exports.up = function (knex) {
  return knex.raw(`
    CREATE OR REPLACE FUNCTION generate_employee_id()
    RETURNS VARCHAR(6) AS $$
    DECLARE
      next_id INTEGER;
    BEGIN
      next_id := NEXTVAL('employee_id_seq');
      RETURN LPAD(next_id::TEXT, 6, '0');
    END;
    $$ LANGUAGE plpgsql;
  `);
};

exports.down = function (knex) {
  return knex.raw('DROP FUNCTION IF EXISTS generate_employee_id()');
};
