-- src/world/combatResolver.lua
-- 轨道交火决算、威胁态判定与战火特效数据维护

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")

local CombatResolver = {
    sparks = {} -- { x, y, life, maxLife, color }
}

function CombatResolver.Init()
    CombatResolver.sparks = {}
end

function CombatResolver.AddSpark(x, y, color)
    table.insert(CombatResolver.sparks, {
        x = x + (math.random() - 0.5) * 24,
        y = y + (math.random() - 0.5) * 24,
        life = 0.35,
        maxLife = 0.35,
        color = color or { r = 1.0, g = 0.4, b = 0.3, a = 1.0 }
    })
end

function CombatResolver.Update(dt, nodes, movingParticles)
    -- 1. 更新火花生命周期
    for i = #CombatResolver.sparks, 1, -1 do
        local sp = CombatResolver.sparks[i]
        sp.life = sp.life - dt
        if sp.life <= 0 then
            table.remove(CombatResolver.sparks, i)
        end
    end

    -- 2. 威胁判定与防空提示
    for _, node in ipairs(nodes) do
        node.hasEnemyThreat = false
        if node.faction ~= "neutral" then
            for _, p in ipairs(movingParticles) do
                if p.toId == node.id and p.faction ~= node.faction then
                    node.hasEnemyThreat = true
                    break
                end
            end
        end
    end
end

return CombatResolver
