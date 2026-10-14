// scripts/pack_bundle.mjs
// 打包 src/**/*.lua 为独立的 standalone bundle.lua
import fs from 'node:fs';
import path from 'node:path';

const SRC_DIR = '/opt/starlink/src';
const OUT_FILE = '/opt/starlink/src/bundle.lua';

const modules = [
  'data/balanceConfig',
  'data/cardRegistry',
  'data/chapterConfig',
  'core/layout',
  'core/runtime',
  'core/input',
  'world/starMap',
  'world/nodeEntity',
  'world/routeManager',
  'world/combatResolver',
  'world/abilitySystem',
  'world/factionAI',
  'ui/visualRenderer',
  'ui/dialoguePlayer',
  'ui/prepareView',
  'ui/hudView',
  'ui/cardBar',
  'ui/modeSelectView',
  'ui/chapterSelectView',
  'ui/uiBinder',
];

let bundle = `-- src/bundle.lua: Consolidated standalone bundle for Miliastra UGC
local _MODULES = {}
local _LOADED = {}
local _orig_require = require

local function local_require(name)
    local clean = tostring(name):gsub("^default_import_file/", ""):gsub("%.lua$", "")
    if _LOADED[clean] ~= nil then return _LOADED[clean] end
    if _MODULES[clean] ~= nil then
        _LOADED[clean] = _MODULES[clean]()
        return _LOADED[clean]
    end
    if _orig_require then
        local ok, res = pcall(_orig_require, name)
        if ok and res ~= nil then return res end
    end
    error("Module not found: " .. tostring(name))
end
local require = local_require

`;

for (const mod of modules) {
  const filePath = path.join(SRC_DIR, `${mod}.lua`);
  const content = fs.readFileSync(filePath, 'utf8');
  bundle += `_MODULES["src/${mod}"] = function()\n${content}\nend\n_MODULES["${mod}"] = _MODULES["src/${mod}"]\n\n`;
}

// Append main.lua
const mainContent = fs.readFileSync(path.join(SRC_DIR, 'main.lua'), 'utf8');
bundle += `\n-- ========== MAIN ENTRYPOINT ==========\n${mainContent}\n`;

fs.writeFileSync(OUT_FILE, bundle, 'utf8');
console.log('Successfully generated bundle.lua, size:', bundle.length, 'bytes');
