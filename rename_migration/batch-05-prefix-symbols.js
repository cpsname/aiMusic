const fs = require('fs');
const path = require('path');

const root = process.cwd();
const roots = ['lib', 'packages/songlet_kit/lib', 'packages/songlet_kit/test', 'mock_server/lib', 'mock_server/test', 'test', 'integration_test'];
const excluded = new Set(['songlet_api.g.dart']);
const files = [];
function walk(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.isFile() && full.endsWith('.dart') && !excluded.has(entry.name)) files.push(full);
  }
}
for (const dir of roots) walk(path.join(root, dir));
files.sort();
const backupRoot = path.join(root, 'rename_migration', 'batch-05-backup');
for (const file of files) {
  const relative = path.relative(root, file);
  const target = path.join(backupRoot, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(file, target);
}
const sourceFiles = files.filter(f => !f.includes(`${path.sep}test${path.sep}`) && !f.includes(`${path.sep}integration_test${path.sep}`));
const declarations = new Set();
const declaration = /\b(?:abstract\s+final\s+class|abstract\s+class|sealed\s+class|final\s+class|class|enum|mixin|typedef)\s+([A-Za-z_][A-Za-z0-9_]*)/g;
for (const file of sourceFiles) {
  const text = fs.readFileSync(file, 'utf8');
  let match;
  while ((match = declaration.exec(text))) {
    const name = match[1];
    if (name.startsWith('_') || name.startsWith('Music')) continue;
    declarations.add(name);
  }
}
// Generated bridge names and external API names are explicit compatibility anchors.
for (const name of ['SongletNativeApi', 'SongletFlutterApi', 'SKProductDto', 'PurchaseResultDto', 'PigeonError', 'Product', 'Failure']) declarations.delete(name);
const mapping = {};
for (const name of [...declarations].sort()) mapping[name] = `Music${name}`;
for (const file of files) {
  let text = fs.readFileSync(file, 'utf8');
  let next = text;
  for (const [oldName, newName] of Object.entries(mapping)) {
    next = next.replace(new RegExp(`\\b${oldName}\\b`, 'g'), newName);
  }
  if (next !== text) fs.writeFileSync(file, next);
}
fs.writeFileSync(path.join(root, 'rename_migration', 'batch-05-symbol-map.json'), JSON.stringify({ count: Object.keys(mapping).length, mapping }, null, 2));
fs.writeFileSync(path.join(root, 'rename_migration', 'batch-05-files.txt'), files.map(f => path.relative(root, f)).join('\n') + '\n');
console.log(`backed up ${files.length} files; renamed ${Object.keys(mapping).length} declarations`);
