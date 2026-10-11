// scripts/build_all.mjs
// 一键自动化构建全流程：源码打包 -> 存档生成 -> 官方整合包 GIA 导出
import { execSync } from 'node:child_process';
import path from 'node:path';

const SCRIPTS_DIR = '/opt/starlink/scripts';

function run(scriptName, desc) {
  console.log(`\n==================================================`);
  console.log(`[BUILD STEP] ${desc} (${scriptName})`);
  console.log(`==================================================`);
  execSync(`node ${path.join(SCRIPTS_DIR, scriptName)}`, { stdio: 'inherit' });
}

console.log('>>> 开始全自动构建《星轨交错：地脉争锋》发布资产包...');
run('pack_bundle.mjs', '1. 打包 Lua 模块为 standalone bundle.lua');
run('build_save.mjs',  '2. 编译 259 控件全量树并存入 starlink.save.json');
run('export_gia.mjs',   '3. 导出官方规范整合包 GIA (含 UI 控件与预挂载脚本)');
console.log('\n>>> 全量构建成功完成！整合包 GIA 已就绪供千星沙箱一键部署。');
