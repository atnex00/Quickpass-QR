#!/usr/bin/env node

/**
 * HR System Sync Script — Catch-All Importer
 *
 * Interactive CLI with two modes:
 *   1. SQL File — drag & drop or pipe a .sql dump
 *   2. DB Link — connect directly to a PostgreSQL database
 *
 * Usage:
 *   node scripts/syncHR.js                    # Interactive menu
 *   node scripts/syncHR.js ./export.sql      # Quick file import (drag & drop)
 *   cat export.sql | node scripts/syncHR.js   # Pipe from stdin
 *
 * Non-interactive (env vars):
 *   HR_SYNC_DB_CONNECTION=postgresql://... \
 *     HR_SYNC_DRY_RUN=false \
 *     HR_SYNC_CREATE_DEPARTMENTS=true \
 *     node scripts/syncHR.js
 *
 * Environment variables:
 *   HR_SYNC_DB_CONNECTION          PostgreSQL connection string
 *   HR_SYNC_SQL_FILE               Path to .sql dump file
 *   HR_SYNC_TABLE                  Table name (omit for auto-detect)
 *   HR_SYNC_DRY_RUN=true           Preview only (default: true)
 *   HR_SYNC_DEFAULT_PASSWORD       Default login password (default: quickpass123)
 *   HR_SYNC_DEFAULT_DEPT           Default department ID (default: DEP-001)
 *   HR_SYNC_CREATE_DEPARTMENTS     Auto-create departments (default: false)
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', `.env.${process.env.NODE_ENV || 'dev'}`) });

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const knex = require('../src/config/database');
const prompts = require('prompts');

// ── Styling helpers ──

const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const GREEN = '\x1b[32m';
const CYAN = '\x1b[36m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const RESET = '\x1b[0m';

function br() { console.log(''); }

function banner() {
  console.log('');
  console.log(`  ${CYAN}╔══════════════════════════════════════════════════╗${RESET}`);
  console.log(`  ${CYAN}║${RESET}          ${BOLD}Quickpass HR Sync Tool${RESET}              ${CYAN}║${RESET}`);
  console.log(`  ${CYAN}║${RESET}    Import employees from any HR system         ${CYAN}║${RESET}`);
  console.log(`  ${CYAN}╚══════════════════════════════════════════════════╝${RESET}`);
  br();
}

function section(title) {
  console.log(`  ${CYAN}── ${BOLD}${title}${RESET} ${CYAN}${'─'.repeat(Math.max(0, 46 - title.length))}${RESET}`);
  br();
}

function info(label, value) {
  console.log(`  ${DIM}${label}:${RESET} ${value}`);
}

function success(msg) {
  console.log(`  ${GREEN}✓${RESET} ${msg}`);
}

function warn(msg) {
  console.log(`  ${YELLOW}⚠${RESET} ${msg}`);
}

function error(msg) {
  console.log(`  ${RED}✗${RESET} ${msg}`);
}

// ── Pattern definitions for column name matching ──

const FIELD_PATTERNS = {
  employee_id: [
    /^emp(?:loyee)?(?:_|\s*)?(?:id|no|code|number)$/i,
    /^employeeid$/i, /^empno$/i, /^empcode$/i, /^employee_number$/i,
    /^staff_id$/i, /^staffid$/i,
    /^(?:employee|emp)_?code$/i,
    /^id$/i, /^user_id$/i,
  ],
  full_name: [
    /^(?:full_)?name$/i, /^employee_name$/i, /^emp_name$/i,
    /^fullname$/i, /^employee_full_name$/i,
    /^staff_name$/i, /^person_name$/i, /^lastname$/i,
  ],
  position: [
    /^position$/i, /^job_title$/i, /^title$/i, /^jobtitle$/i,
    /^designation$/i, /^role$/i, /^job_role$/i, /^rank$/i,
  ],
  department_id: [
    /^dept(?:_?\w+)?$/i, /^department$/i, /^department_id$/i,
    /^department_code$/i, /^department_name$/i, /^dept_name$/i, /^dept_code$/i,
    /^division$/i, /^unit$/i, /^section$/i, /^office$/i,
    /^org_unit$/i, /^organization$/i,
  ],
  email: [
    /^email$/i, /^email_address$/i, /^emailaddress$/i,
    /^mail$/i, /^e_?mail$/i, /^work_email$/i, /^company_email$/i,
  ],
  is_supervisor: [
    /^is_supervisor$/i, /^supervisor$/i, /^ismanager$/i,
    /^manager$/i, /^is_manager$/i, /^role_type$/i,
    /^is_admin$/i, /^admin$/i, /^user_role$/i,
  ],
  is_active: [
    /^is_active$/i, /^active$/i, /^status$/i,
    /^is_enabled$/i, /^enabled$/i, /^is_inactive$/i,
    /^employment_status$/i,
  ],
  hire_date: [
    /^hire_date$/i, /^start_date$/i, /^date_joined$/i,
    /^joining_date$/i, /^employment_date$/i, /^date_hired$/i,
    /^started_on$/i, /^hired_on$/i, /^date_of_hire$/i,
  ],
};

const REQUIRED_FIELDS = ['employee_id', 'full_name'];

const CANDIDATE_TABLE_PATTERNS = [
  /employees?$/i, /staff$/i, /personnel$/i, /users?$/i,
  /workers?$/i, /people$/i, /hr_employees?$/i, /tblemployees?$/i,
];

// ── Column scoring ──

function scoreColumn(col) {
  const lower = col.toLowerCase();
  for (const [field, patterns] of Object.entries(FIELD_PATTERNS)) {
    for (const pat of patterns) {
      if (pat.test(col)) {
        const exactBonus = lower === field || lower === field.replace(/_/g, '') ? 10 : 0;
        return { field, score: 100 - Math.abs(col.length - field.length) * 5 + exactBonus };
      }
    }
  }
  if (/emp/i.test(lower) && /(id|no|code|num)/i.test(lower)) return { field: 'employee_id', score: 40 };
  if (/name/i.test(lower) && !/department|dept/i.test(lower)) return { field: 'full_name', score: 35 };
  if (/(position|designation|title|role|job)/i.test(lower)) return { field: 'position', score: 35 };
  if (/dept/i.test(lower) || /^department$/i.test(lower)) return { field: 'department_id', score: 35 };
  if (/(email|mail)/i.test(lower)) return { field: 'email', score: 35 };
  if (/(supervisor|manager|admin)/i.test(lower)) return { field: 'is_supervisor', score: 30 };
  if (/(active|status|enabled)/i.test(lower)) return { field: 'is_active', score: 30 };
  if (/(hire|start|joined|employment)/i.test(lower) && /(date|on|day)/i.test(lower)) return { field: 'hire_date', score: 30 };
  return null;
}

function autoMapColumns(columns) {
  const taken = new Set();
  const mapping = {};
  const scored = [];
  for (const col of columns) {
    const result = scoreColumn(col);
    if (result) scored.push({ col, field: result.field, score: result.score });
  }
  scored.sort((a, b) => b.score - a.score);
  for (const { col, field } of scored) {
    if (!taken.has(field)) {
      mapping[field] = col;
      taken.add(field);
    }
  }
  return mapping;
}

function normalizeValue(val, field) {
  if (val === null || val === undefined) return undefined;
  if (field === 'is_supervisor' || field === 'is_active') {
    if (typeof val === 'boolean') return val;
    if (typeof val === 'number') return val === 1;
    if (typeof val === 'string') {
      if (/^(true|yes|y|1|active|enabled|admin|manager|supervisor)$/i.test(val.trim())) return true;
      if (/^(false|no|n|0|inactive|disabled|staff|employee)$/i.test(val.trim())) return false;
    }
    return false;
  }
  if (field === 'hire_date') {
    if (val instanceof Date) return val.toISOString().split('T')[0];
    if (typeof val === 'string') {
      const d = new Date(val);
      if (!isNaN(d.getTime())) return d.toISOString().split('T')[0];
    }
    return val;
  }
  if (typeof val === 'string') return val.trim();
  return String(val);
}

function generateEmail(name, employeeId) {
  const slug = name.toLowerCase().replace(/[^a-z\s-]/g, '').split(/\s+/).slice(0, 2).join('.');
  return `${slug}@company.com`.replace(/--/g, '-');
}

// ── SQL Dump Parser ──

function parseSqlDump(content) {
  const INSERT_RE = /INSERT\s+INTO\s+(?:\w+\.)?(\w+)\s*\(([^)]+)\)\s*VALUES\s*((?:\([^)]*\)(?:\s*,\s*|\s*;?\s*))+)/gi;
  const VALUE_RE = /\(([^)]*)\)/g;

  const tableColumns = {};
  const tableRows = {};

  let match;
  while ((match = INSERT_RE.exec(content)) !== null) {
    const tableName = match[1];
    const cols = match[2].split(',').map(c => c.trim().replace(/"/g, ''));
    const valuesBlock = match[3];
    if (!tableColumns[tableName]) {
      tableColumns[tableName] = cols;
      tableRows[tableName] = [];
    }
    let vMatch;
    while ((vMatch = VALUE_RE.exec(valuesBlock)) !== null) {
      tableRows[tableName].push(parseSqlValues(vMatch[1]));
    }
  }
  return { tableColumns, tableRows };
}

function parseSqlValues(raw) {
  const values = [];
  let current = '';
  let inString = false;
  let parenDepth = 0;
  for (let i = 0; i < raw.length; i++) {
    const ch = raw[i];
    if (inString) {
      current += ch;
      if (ch === "'" && raw[i + 1] === "'") { current += "'"; i++; }
      else if (ch === "'") inString = false;
      continue;
    }
    if (ch === "'") { current += ch; inString = true; continue; }
    if (ch === '(') { parenDepth++; current += ch; continue; }
    if (ch === ')') { parenDepth--; current += ch; continue; }
    if (ch === ',' && parenDepth === 0) {
      values.push(parseSqlAtom(current.trim()));
      current = '';
      continue;
    }
    current += ch;
  }
  if (current.trim()) values.push(parseSqlAtom(current.trim()));
  return values;
}

function parseSqlAtom(atom) {
  if (atom === 'NULL' || atom === 'null') return null;
  if (atom.startsWith("'") && atom.endsWith("'")) return atom.slice(1, -1).replace(/''/g, "'");
  if (atom === 'true' || atom === 't') return true;
  if (atom === 'false' || atom === 'f') return false;
  const num = Number(atom);
  if (!isNaN(num) && atom !== '') return num;
  return atom;
}

// ── Table discovery (link mode) ──

async function discoverTable(client) {
  const tables = await client.query(`
    SELECT table_name FROM information_schema.tables t
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY (SELECT count(*) FROM information_schema.columns WHERE table_name = t.table_name) DESC
  `);
  if (tables.rows.length === 0) throw new Error('No tables found in the HR database.');
  const scored = [];
  for (const t of tables.rows) {
    const cols = await client.query(
      `SELECT column_name FROM information_schema.columns WHERE table_name = $1 AND table_schema = 'public'`,
      [t.table_name]
    );
    const colNames = cols.rows.map(r => r.column_name);
    const matchCount = colNames.filter(c => scoreColumn(c)).length;
    let tableScore = 0;
    if (CANDIDATE_TABLE_PATTERNS.some(p => p.test(t.table_name))) tableScore += 50;
    tableScore += matchCount * 10;
    scored.push({ name: t.table_name, score: tableScore, cols: colNames });
  }
  scored.sort((a, b) => b.score - a.score);
  if (scored[0].score < 10) {
    const names = tables.rows.map(t => t.table_name).join(', ');
    throw new Error(`Could not find an employee table. Available: ${names}`);
  }
  return scored[0];
}

// ── Import data ──

async function importData(hrEmployees, columns, mode, opts) {
  const mapping = autoMapColumns(columns);

  section('Field Mapping');
  for (const [field, col] of Object.entries(mapping)) {
    info(field, col);
  }
  const mappedCols = new Set(Object.values(mapping));
  const unmapped = columns.filter(c => !mappedCols.has(c));
  if (unmapped.length > 0) info('(unused)', unmapped.join(', '));
  br();

  const missingRequired = REQUIRED_FIELDS.filter(f => !mapping[f]);
  if (missingRequired.length > 0) {
    error(`Missing required fields: ${missingRequired.join(', ')}`);
    return;
  }

  info('Records', String(hrEmployees.length));
  br();

  const departments = await knex('departments').select('department_id', 'department_name');
  const deptByName = new Map(departments.map(d => [d.department_name.toLowerCase(), d.department_id]));
  const validDeptIds = new Set(departments.map(d => d.department_id));

  const dryRun = opts.dryRun;
  const defaultPassword = opts.defaultPassword;
  const defaultDept = opts.defaultDept;
  const createDepartments = opts.createDepartments;
  const passwordHash = await bcrypt.hash(defaultPassword, 10);

  const results = { created: 0, skipped: 0, errors: [], warnings: [] };

  for (const hrEmp of hrEmployees) {
    try {
      const mapped = {};
      for (const [field, col] of Object.entries(mapping)) {
        mapped[field] = normalizeValue(hrEmp[col], field);
      }
      if (!mapped.employee_id || !mapped.full_name) {
        results.errors.push({ employee_id: mapped.employee_id || 'unknown', reason: 'Missing employee_id or full_name' });
        continue;
      }
      mapped.employee_id = String(mapped.employee_id);
      if (!mapped.email) {
        mapped.email = generateEmail(mapped.full_name, mapped.employee_id);
        results.warnings.push(`${mapped.employee_id}: email generated (${mapped.email})`);
      }
      if (mapped.department_id) {
        const deptStr = String(mapped.department_id);
        if (!validDeptIds.has(deptStr)) {
          const found = deptByName.get(deptStr.toLowerCase());
          if (found) {
            mapped.department_id = found;
          } else if (createDepartments) {
            const newId = `DEP-${String(departments.length + 1).padStart(3, '0')}`;
            await knex('departments').insert({
              department_id: newId,
              department_name: deptStr,
              department_code: deptStr.toUpperCase().slice(0, 5),
              is_active: true,
            });
            departments.push({ department_id: newId, department_name: deptStr });
            validDeptIds.add(newId);
            deptByName.set(deptStr.toLowerCase(), newId);
            mapped.department_id = newId;
            results.warnings.push(`${mapped.employee_id}: created department "${deptStr}" as ${newId}`);
          } else {
            results.warnings.push(`${mapped.employee_id}: department "${deptStr}" not found — using default`);
            mapped.department_id = defaultDept;
          }
        }
      } else {
        mapped.department_id = defaultDept;
      }
      if (!mapped.position) mapped.position = 'Staff';
      mapped.is_supervisor = mapped.is_supervisor === true;
      mapped.is_active = mapped.is_active !== false;
      const existing = await knex('employees').where({ employee_id: mapped.employee_id }).first();
      if (existing) {
        results.skipped++;
        continue;
      }
      if (!dryRun) {
        await knex('employees').insert({
          employee_id: mapped.employee_id,
          full_name: mapped.full_name,
          position: mapped.position,
          department_id: mapped.department_id,
          email: mapped.email,
          is_supervisor: mapped.is_supervisor || false,
          is_active: mapped.is_active,
          hire_date: mapped.hire_date || null,
          password_hash: passwordHash,
          created_at: knex.fn.now(),
          updated_at: knex.fn.now(),
        });
      }
      results.created++;
    } catch (err) {
      results.errors.push({ employee_id: hrEmp[mapping.employee_id] || 'unknown', reason: err.message });
    }
  }

  section('Sync Results');
  info('Mode', mode);
  success(`Created: ${results.created}`);
  if (results.skipped > 0) info('Skipped', `${results.skipped} (already exist)`);
  if (results.errors.length > 0) error(`Errors: ${results.errors.length}`);
  br();
  if (results.warnings.length > 0) {
    const shown = results.warnings.slice(0, 5);
    shown.forEach(w => warn(w));
    if (results.warnings.length > 5) warn(`… and ${results.warnings.length - 5} more`);
    br();
  }
  if (results.errors.length > 0) {
    const shown = results.errors.slice(0, 5);
    shown.forEach(e => error(`${e.employee_id}: ${e.reason}`));
    if (results.errors.length > 5) error(`… and ${results.errors.length - 5} more`);
    br();
  }
  if (dryRun) info('Note', 'Dry-run mode — no changes were made');
}

// ── Interactive CLI ──

async function interactive() {
  banner();

  // Check for piped stdin
  let pipedContent = null;
  if (!process.stdin.isTTY) {
    pipedContent = await new Promise((resolve) => {
      const chunks = [];
      process.stdin.on('data', c => chunks.push(c));
      process.stdin.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    });
    pipedContent = pipedContent.trim();
    if (pipedContent) {
      section('Piped Input Detected');
      success(`Read ${pipedContent.length} bytes from stdin`);
      br();
    } else {
      pipedContent = null;
    }
  }

  // Check for CLI arg (drag & drop)
  const argFile = process.argv[2];
  if (argFile && fs.existsSync(argFile)) {
    section('File from Drag & Drop');
    info('Path', path.resolve(argFile));
    br();
    await runFileMode(argFile);
    return;
  }

  if (pipedContent) {
    const tmpFile = `/tmp/hr_sync_pipe_${Date.now()}.sql`;
    fs.writeFileSync(tmpFile, pipedContent);
    section('Processing Piped Input');
    success(`Saved to ${tmpFile}`);
    br();
    await runFileMode(tmpFile);
    fs.unlinkSync(tmpFile);
    return;
  }

  // Interactive menu
  const { mode } = await prompts({
    type: 'select',
    name: 'mode',
    message: 'Choose how to import employee data:',
    choices: [
      { title: '📄  SQL File', description: 'Drag a .sql dump file into this terminal, or type the path', value: 'file' },
      { title: '🔗  Database Connection', description: 'Connect to a PostgreSQL database', value: 'db' },
    ],
  });
  if (mode === undefined) { console.log(''); process.exit(0); }
  br();

  if (mode === 'file') await interactiveFileMode();
  else await interactiveDbMode();
}

async function interactiveFileMode() {
  section('SQL File Import');

  const { filePath } = await prompts({
    type: 'text',
    name: 'filePath',
    message: 'Path to .sql file (or drag & drop it here):',
    validate: v => fs.existsSync(v.trim()) ? true : 'File not found — check the path or drag the file here',
  });
  if (!filePath) { console.log(''); process.exit(0); }
  const resolved = path.resolve(filePath.trim());
  br();
  await runFileMode(resolved);
}

async function interactiveDbMode() {
  section('Database Connection');

  const { connStr } = await prompts({
    type: 'text',
    name: 'connStr',
    message: 'PostgreSQL connection string:',
    validate: v => v.startsWith('postgresql://') || v.startsWith('postgres://')
      ? true : 'Must start with postgresql://',
  });
  if (!connStr) { console.log(''); process.exit(0); }
  br();
  await runDbMode(connStr.trim());
}

async function runFileMode(filePath) {
  if (!fs.existsSync(filePath)) {
    error(`File not found: ${filePath}`);
    process.exit(1);
  }

  section('Parsing SQL Dump');
  const content = fs.readFileSync(filePath, 'utf8');
  const parsed = parseSqlDump(content);
  const tableNames = Object.keys(parsed.tableRows);
  if (tableNames.length === 0) {
    error('No INSERT statements found in the SQL file.');
    await knex.destroy();
    process.exit(1);
  }

  const scored = tableNames.map(name => {
    const cols = parsed.tableColumns[name];
    const matchCount = cols.filter(c => scoreColumn(c)).length;
    let score = matchCount * 10;
    if (CANDIDATE_TABLE_PATTERNS.some(p => p.test(name))) score += 50;
    return { name, score, cols, rows: parsed.tableRows[name] };
  });
  scored.sort((a, b) => b.score - a.score);
  const best = scored[0];

  if (best.score < 10) {
    error(`Could not identify an employee table. Found: ${tableNames.join(', ')}`);
    await knex.destroy();
    process.exit(1);
  }

  success(`Found table "${best.name}" with ${best.rows.length} records`);
  br();

  const employees = best.rows.map(row => {
    const obj = {};
    best.cols.forEach((col, i) => { obj[col] = row[i]; });
    return obj;
  });

  await confirmAndImport(employees, best.cols, `SQL File (${path.basename(filePath)})`);
}

async function runDbMode(connStr) {
  const hrClient = new Client({ connectionString: connStr });

  section('Connecting');
  try {
    await hrClient.connect();
    success('Connected');
  } catch (err) {
    error(`Connection failed: ${err.message}`);
    await knex.destroy();
    process.exit(1);
  }
  br();

  let tableName = process.env.HR_SYNC_TABLE;
  let columns;

  if (tableName) {
    const colResult = await hrClient.query(
      `SELECT column_name FROM information_schema.columns WHERE table_name = $1 AND table_schema = 'public' ORDER BY ordinal_position`,
      [tableName]
    );
    if (colResult.rows.length === 0) {
      error(`Table "${tableName}" not found.`);
      await hrClient.end();
      process.exit(1);
    }
    columns = colResult.rows.map(r => r.column_name);
    section('Table');
    info('Using', tableName);
    br();
  } else {
    section('Discovering Tables');
    try {
      const discovered = await discoverTable(hrClient);
      tableName = discovered.name;
      columns = discovered.cols;
      success(`Auto-detected table "${tableName}"`);
      br();
    } catch (err) {
      error(err.message);
      await hrClient.end();
      process.exit(1);
    }
  }

  const missingRequired = REQUIRED_FIELDS.filter(f => !autoMapColumns(columns)[f]);
  if (missingRequired.length > 0) {
    error(`Cannot proceed — missing required fields: ${missingRequired.join(', ')}`);
    await hrClient.end();
    process.exit(1);
  }

  let hrEmployees;
  try {
    const result = await hrClient.query(`SELECT * FROM "${tableName}"`);
    hrEmployees = result.rows;
    success(`Fetched ${hrEmployees.length} records`);
  } catch (err) {
    error(`Query failed: ${err.message}`);
    await hrClient.end();
    process.exit(1);
  }
  await hrClient.end();
  br();

  await confirmAndImport(hrEmployees, columns, 'DB Link');
}

async function confirmAndImport(employees, columns, mode) {
  const mapping = autoMapColumns(columns);

  section('Detected Column Mapping');
  for (const [field, col] of Object.entries(mapping)) {
    info(field, col);
  }
  const unmapped = columns.filter(c => !new Set(Object.values(mapping)).has(c));
  if (unmapped.length > 0) info('(unused)', unmapped.join(', '));
  br();

  const missingRequired = REQUIRED_FIELDS.filter(f => !mapping[f]);
  if (missingRequired.length > 0) {
    error(`Missing required fields: ${missingRequired.join(', ')}`);
    await knex.destroy();
    process.exit(1);
  }

  // Let user confirm/reject mapping
  const { confirmMapping } = await prompts({
    type: 'confirm',
    name: 'confirmMapping',
    message: 'Does this mapping look correct?',
    initial: true,
  });
  if (confirmMapping === false) {
    console.log('  Aborted. You can configure field mapping via HR_SYNC_FIELD_MAP env var.');
    await knex.destroy();
    process.exit(0);
  }
  br();

  // Options
  const { dryRun } = await prompts({
    type: 'confirm',
    name: 'dryRun',
    message: 'Run as dry-run first? (recommended — no changes will be made)',
    initial: true,
  });
  if (dryRun === undefined) { await knex.destroy(); process.exit(0); }
  br();

  let createDepartments = false;
  let defaultPassword = 'quickpass123';

  if (!dryRun) {
    const opts = await prompts([
      {
        type: 'confirm',
        name: 'createDepartments',
        message: 'Auto-create departments if they don\'t exist?',
        initial: false,
      },
      {
        type: 'text',
        name: 'defaultPassword',
        message: 'Default password for imported accounts:',
        initial: 'quickpass123',
      },
    ]);
    createDepartments = opts.createDepartments || false;
    defaultPassword = opts.defaultPassword || 'quickpass123';
    br();
  }

  section('Importing');
  await importData(employees, columns, mode, {
    dryRun,
    defaultPassword,
    defaultDept: process.env.HR_SYNC_DEFAULT_DEPT || 'DEP-001',
    createDepartments,
  });
  br();

  if (dryRun) {
    info('Next steps',
      'Run again and answer "No" to dry-run to apply changes, or set HR_SYNC_DRY_RUN=false');
    br();
  }

  info('Done', 'Press Ctrl+C to exit');
  await knex.destroy();
}

// ── Main ──

async function main() {
  const dbLink = process.env.HR_SYNC_DB_CONNECTION;
  const sqlFile = process.env.HR_SYNC_SQL_FILE;

  // Non-interactive mode (env vars set)
  if (dbLink || sqlFile) {
    const dryRun = process.env.HR_SYNC_DRY_RUN !== 'false';

    banner();
    if (dbLink) info('DB', dbLink.replace(/\/\/.*@/, '//***@'));
    if (sqlFile) info('File', path.resolve(sqlFile));
    info('Mode', 'Non-interactive (env vars)');
    if (dryRun) info('Dry-run', 'true');
    br();

    if (sqlFile) {
      if (!fs.existsSync(sqlFile)) {
        error(`File not found: ${sqlFile}`);
        process.exit(1);
      }
      section('Parsing SQL Dump');
      const content = fs.readFileSync(sqlFile, 'utf8');
      const parsed = parseSqlDump(content);
      const tableNames = Object.keys(parsed.tableRows);
      if (tableNames.length === 0) {
        error('No INSERT statements found.');
        process.exit(1);
      }
      const scored = tableNames.map(name => {
        const cols = parsed.tableColumns[name];
        const matchCount = cols.filter(c => scoreColumn(c)).length;
        let score = matchCount * 10;
        if (CANDIDATE_TABLE_PATTERNS.some(p => p.test(name))) score += 50;
        return { name, score, cols, rows: parsed.tableRows[name] };
      });
      scored.sort((a, b) => b.score - a.score);
      const best = scored[0];
      if (best.score < 10) {
        error(`No employee table found. Tables: ${tableNames.join(', ')}`);
        process.exit(1);
      }
      success(`Table "${best.name}" — ${best.rows.length} records`);
      br();
      const employees = best.rows.map(row => {
        const obj = {};
        best.cols.forEach((col, i) => { obj[col] = row[i]; });
        return obj;
      });
      await importData(employees, best.cols, `SQL File`, {
        dryRun,
        defaultPassword: process.env.HR_SYNC_DEFAULT_PASSWORD || 'quickpass123',
        defaultDept: process.env.HR_SYNC_DEFAULT_DEPT || 'DEP-001',
        createDepartments: process.env.HR_SYNC_CREATE_DEPARTMENTS === 'true',
      });
    }

    if (dbLink) {
      const hrClient = new Client({ connectionString: dbLink });
      await hrClient.connect();
      let tableName = process.env.HR_SYNC_TABLE;
      let columns;
      if (tableName) {
        const colResult = await hrClient.query(
          `SELECT column_name FROM information_schema.columns WHERE table_name = $1 AND table_schema = 'public' ORDER BY ordinal_position`,
          [tableName]
        );
        columns = colResult.rows.map(r => r.column_name);
      } else {
        const discovered = await discoverTable(hrClient);
        tableName = discovered.name;
        columns = discovered.cols;
      }
      const missingRequired = REQUIRED_FIELDS.filter(f => !autoMapColumns(columns)[f]);
      if (missingRequired.length > 0) {
        error(`Missing required fields: ${missingRequired.join(', ')}`);
        await hrClient.end();
        process.exit(1);
      }
      const result = await hrClient.query(`SELECT * FROM "${tableName}"`);
      await hrClient.end();
      success(`Table "${tableName}" — ${result.rows.length} records`);
      br();
      await importData(result.rows, columns, `DB Link`, {
        dryRun,
        defaultPassword: process.env.HR_SYNC_DEFAULT_PASSWORD || 'quickpass123',
        defaultDept: process.env.HR_SYNC_DEFAULT_DEPT || 'DEP-001',
        createDepartments: process.env.HR_SYNC_CREATE_DEPARTMENTS === 'true',
      });
    }

    await knex.destroy();
    return;
  }

  // Interactive mode
  await interactive();
}

main().catch(err => {
  if (err.message?.includes('User force closed')) return;
  console.error(`\n  ${RED}Sync failed:${RESET} ${err.message}`);
  process.exit(1);
});
