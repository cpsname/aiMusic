const fs=require('fs'),path=require('path');
const root=process.cwd();
const roots=['lib','packages/songlet_kit/lib','packages/songlet_kit/test','mock_server/lib','mock_server/test','test','integration_test'];
const excluded=new Set(['songlet_api.g.dart']);
function walk(dir){let out=[];if(!fs.existsSync(dir))return out;for(const e of fs.readdirSync(dir,{withFileTypes:true})){const f=path.join(dir,e.name);if(e.isDirectory())out.push(...walk(f));else if(f.endsWith('.dart')&&!excluded.has(e.name))out.push(f)}return out}
const files=roots.flatMap(r=>walk(path.join(root,r))).sort();
const backup=path.join(root,'rename_migration','batch-05-strict-backup');
for(const f of files){const t=path.join(backup,path.relative(root,f));fs.mkdirSync(path.dirname(t),{recursive:true});fs.copyFileSync(f,t)}
const mapping=new Map();
const decl=/^\s*(?:(?:abstract|sealed|final)\s+)*(?:class|enum|mixin|typedef)\s+([A-Z][A-Za-z0-9_]*)/gm;
const source=files.filter(f=>!f.includes(`${path.sep}test${path.sep}`)&&!f.includes(`${path.sep}integration_test${path.sep}`));
for(const f of source){const s=fs.readFileSync(f,'utf8');let m;while((m=decl.exec(s))){const n=m[1];if(n.startsWith('Music')||n.startsWith('_'))continue;if(['SongletNativeApi','SongletFlutterApi','SKProductDto','PurchaseResultDto','PigeonError','Product','Failure'].includes(n))continue;mapping.set(n,`Music${n}`)}}
for(const f of files){let s=fs.readFileSync(f,'utf8'),n=s;for(const [a,b] of mapping)n=n.replace(new RegExp(`\\b${a}\\b`,'g'),b);if(n!==s)fs.writeFileSync(f,n)}
fs.writeFileSync(path.join(root,'rename_migration','batch-05-strict-map.json'),JSON.stringify({count:mapping.size,mapping:Object.fromEntries(mapping)},null,2));
console.log('strict declarations renamed',mapping.size,'files backed up',files.length);
