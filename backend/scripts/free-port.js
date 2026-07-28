const { execSync } = require('child_process');
const port = process.argv[2] || '3000';

try {
  if (process.platform === 'win32') {
    execSync(
      `for /f "tokens=5" %a in ('netstat -ano ^| findstr :${port}') do `
      + `if not "%a"=="" taskkill /F /PID %a`,
      { stdio: 'pipe' }
    );
  } else {
    execSync(`lsof -ti:${port} | xargs kill -9 2>/dev/null || true`, { stdio: 'pipe' });
  }
} catch {
  // No process to kill — that's fine
}