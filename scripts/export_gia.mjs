// scripts/export_gia.mjs
// 将 starlink.save.json 导出为官方千星沙箱编辑器可导入的 .gia 资产包
import fs from 'node:fs';
import path from 'node:path';
import { createStudio } from '/mnt/d/Agent/miliastra-beyond-simulator/studio/index.js';

const SAVE_PATH = '/opt/starlink/starlink.save.json';
const OUT_DIR = '/opt/starlink';

const raw = fs.readFileSync(SAVE_PATH, 'utf8');
const studio = createStudio(JSON.parse(raw));

console.log('正在导出千星沙箱官方 GIA 格式资产包...');
const pkg = studio.exportData('save-gia');

for (const file of pkg.files) {
  const target = path.join(OUT_DIR, file.filename);
  fs.writeFileSync(target, Buffer.from(file.data, 'base64'));
  console.log(`✓ 导出成功: ${file.filename} (${(fs.statSync(target).size / 1024).toFixed(1)} KB)`);
}

const combined = studio.exportData('combined');
const combinedPath = path.join(OUT_DIR, combined.filename);
const combinedBuffer = Buffer.from(combined.data, 'base64');
fs.writeFileSync(combinedPath, combinedBuffer);
fs.writeFileSync(path.join(OUT_DIR, 'starlink.gia'), combinedBuffer);
console.log(`✓ 导出整合包: ${combined.filename} (${(fs.statSync(combinedPath).size / 1024).toFixed(1)} KB)`);
console.log(`✓ 同步别名: starlink.gia (${(fs.statSync(path.join(OUT_DIR, 'starlink.gia')).size / 1024).toFixed(1)} KB)`);

console.log('\n全部 GIA 文件导出完成！可直接在官方编辑器【导入模板】中使用。');
