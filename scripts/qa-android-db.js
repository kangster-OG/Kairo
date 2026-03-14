const { execFileSync } = require('node:child_process');

const adb = process.env.ADB_PATH || 'C:\\Users\\david\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe';
const packageName = process.env.ANDROID_PACKAGE || 'com.david.atlas';
const databasePath = process.env.ANDROID_DB_PATH || 'files/SQLite/atlas.db';

function usage() {
  console.log('Usage: node scripts/qa-android-db.js "<sql>"');
}

const [, , ...restArgs] = process.argv;
const sql = restArgs.join(' ').trim();

if (!sql) {
  usage();
  process.exit(1);
}

const output = execFileSync(
  adb,
  ['shell', 'run-as', packageName, 'sh', '-c', `echo ${JSON.stringify(sql)} | sqlite3 ${databasePath}`],
  { encoding: 'utf8' }
);

process.stdout.write(output);
