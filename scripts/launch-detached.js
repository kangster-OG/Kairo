const { spawn } = require('node:child_process');
const path = require('node:path');

const target = process.argv[2];

if (!target) {
  console.error('Usage: node scripts/launch-detached.js <script>');
  process.exit(1);
}

const targetPath = path.resolve(target);
const child = spawn('cmd.exe', ['/d', '/c', targetPath], {
  cwd: path.dirname(targetPath),
  detached: true,
  stdio: 'ignore',
  windowsHide: true,
});

child.unref();
