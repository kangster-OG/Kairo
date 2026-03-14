const { execFileSync } = require('node:child_process');
const { writeFileSync } = require('node:fs');
const { resolve } = require('node:path');

const adb = process.env.ADB_PATH || 'C:\\Users\\david\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe';
const packageName = process.env.ANDROID_PACKAGE || 'com.david.atlas';
const databasePath = process.env.ANDROID_DB_PATH || 'files/SQLite/atlas.db';
const outputPath = resolve(process.cwd(), process.argv[2] || 'tmp_atlas.db');

const output = execFileSync(
  adb,
  ['exec-out', 'run-as', packageName, 'cat', databasePath],
  { encoding: 'buffer' }
);

writeFileSync(outputPath, output);
console.log(outputPath);
