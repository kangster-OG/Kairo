const fs = require('node:fs');
const path = require('node:path');

const args = process.argv.slice(2);
const filePath = args[0];
const terms = [];
const ranges = [];

for (let index = 1; index < args.length; index += 1) {
  const value = args[index];

  if (value === '--range') {
    const start = Number(args[index + 1]);
    const end = Number(args[index + 2]);

    if (!Number.isInteger(start) || !Number.isInteger(end)) {
      console.error('Usage for ranges: --range <start> <end>');
      process.exit(1);
    }

    ranges.push([start, end]);
    index += 2;
    continue;
  }

  terms.push(value);
}

if (!filePath || (terms.length === 0 && ranges.length === 0)) {
  console.error(
    'Usage: node scripts/debug-dump-inspect.js <file> <term> [term...] [--range <start> <end>]'
  );
  process.exit(1);
}

const resolvedPath = path.resolve(filePath);
const content = fs.readFileSync(resolvedPath, 'utf8');
const lines = content.split(/\r?\n/);

for (const term of terms) {
  console.log(`=== ${term} ===`);
  let count = 0;

  lines.forEach((line, index) => {
    if (line.includes(term)) {
      console.log(`${index + 1}: ${line}`);
      count += 1;
    }
  });

  if (count === 0) {
    console.log('none');
  }
}

for (const [start, end] of ranges) {
  console.log(`=== range ${start}-${end} ===`);

  lines.slice(start - 1, end).forEach((line, index) => {
    console.log(`${start + index}: ${line}`);
  });
}
