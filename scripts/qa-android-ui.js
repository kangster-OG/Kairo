const { execFileSync } = require('node:child_process');

const adb = process.env.ADB_PATH || 'C:\\Users\\david\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe';

function runAdb(args) {
  return execFileSync(adb, args, { encoding: 'utf8' });
}

function dumpUiXml() {
  return runAdb(['exec-out', 'uiautomator', 'dump', '/dev/tty']);
}

function parseNodes(xml) {
  const nodes = [];
  const nodeRegex = /<node\b([^>]*?)\/?>/g;
  const attrRegex = /([\w-]+)="([^"]*)"/g;
  let nodeMatch;

  while ((nodeMatch = nodeRegex.exec(xml))) {
    const rawAttrs = nodeMatch[1];
    const attrs = {};
    let attrMatch;

    while ((attrMatch = attrRegex.exec(rawAttrs))) {
      attrs[attrMatch[1]] = attrMatch[2];
    }

    const text = attrs['text'] || attrs['content-desc'] || '';
    const bounds = attrs['bounds'] || '';
    const clickable = attrs['clickable'] === 'true';
    const enabled = attrs['enabled'] === 'true';

    nodes.push({
      bounds,
      center: getCenter(bounds),
      className: attrs['class'] || '',
      clickable,
      contentDesc: attrs['content-desc'] || '',
      enabled,
      text: attrs['text'] || '',
      textOrDesc: text,
    });
  }

  return nodes;
}

function getCenter(bounds) {
  const match = /^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$/.exec(bounds);

  if (!match) {
    return null;
  }

  const [, x1, y1, x2, y2] = match.map(Number);

  return {
    x: Math.round((x1 + x2) / 2),
    y: Math.round((y1 + y2) / 2),
  };
}

function listNodes(query) {
  const xml = dumpUiXml();
  const normalizedQuery = query ? query.toLowerCase() : null;
  const nodes = parseNodes(xml).filter((node) => {
    if (!normalizedQuery) {
      return node.textOrDesc;
    }

    return node.textOrDesc.toLowerCase().includes(normalizedQuery);
  });

  nodes.forEach((node, index) => {
    const target = node.text || node.contentDesc;
    const center = node.center ? `${node.center.x},${node.center.y}` : '?,?';
    console.log(
      `${index}: ${target} | ${node.className} | clickable=${node.clickable} enabled=${node.enabled} | center=${center} | bounds=${node.bounds}`
    );
  });
}

function listClickableNodes() {
  const xml = dumpUiXml();
  const nodes = parseNodes(xml).filter((node) => node.enabled && node.clickable);

  nodes.forEach((node, index) => {
    const target = node.text || node.contentDesc || '<no-text>';
    const center = node.center ? `${node.center.x},${node.center.y}` : '?,?';
    console.log(
      `${index}: ${target} | ${node.className} | center=${center} | bounds=${node.bounds}`
    );
  });
}

function tapNode(query, occurrenceIndex = 0) {
  const xml = dumpUiXml();
  const normalizedQuery = query.toLowerCase();
  const nodes = parseNodes(xml).filter(
    (node) => node.enabled && node.clickable && node.textOrDesc.toLowerCase().includes(normalizedQuery)
  );

  const target = nodes[occurrenceIndex];

  if (!target || !target.center) {
    console.error(`No tappable node found for query "${query}" at index ${occurrenceIndex}.`);
    process.exit(1);
  }

  runAdb(['shell', 'input', 'tap', String(target.center.x), String(target.center.y)]);
  console.log(`Tapped "${target.text || target.contentDesc}" at ${target.center.x},${target.center.y}`);
}

function usage() {
  console.log('Usage: node scripts/qa-android-ui.js list [query]');
  console.log('       node scripts/qa-android-ui.js list-clickable');
  console.log('       node scripts/qa-android-ui.js tap <query> [index]');
  console.log('       node scripts/qa-android-ui.js tapxy <x> <y>');
}

const [, , command, ...restArgs] = process.argv;

if (!command) {
  usage();
  process.exit(1);
}

if (command === 'list') {
  listNodes(restArgs.join(' '));
  process.exit(0);
}

if (command === 'list-clickable') {
  listClickableNodes();
  process.exit(0);
}

if (command === 'tap' && restArgs.length > 0) {
  const maybeIndex = Number(restArgs[restArgs.length - 1]);
  const hasIndex = Number.isInteger(maybeIndex) && String(maybeIndex) === restArgs[restArgs.length - 1];
  const query = hasIndex ? restArgs.slice(0, -1).join(' ') : restArgs.join(' ');
  tapNode(query, hasIndex ? maybeIndex : 0);
  process.exit(0);
}

if (command === 'tapxy' && restArgs.length === 2) {
  const [x, y] = restArgs.map(Number);

  if (!Number.isFinite(x) || !Number.isFinite(y)) {
    console.error('tapxy requires numeric x and y values.');
    process.exit(1);
  }

  runAdb(['shell', 'input', 'tap', String(x), String(y)]);
  console.log(`Tapped ${x},${y}`);
  process.exit(0);
}

usage();
process.exit(1);
