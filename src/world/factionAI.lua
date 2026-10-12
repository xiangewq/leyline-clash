-- src/world/factionAI.lua
-- 坎瑞亚遗迹推衍机（多阵营全员大乱斗 AI 智能调度与争端决策）

local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local FactionAI = {
    aiTimer = 0,
    AI_INTERVAL = 2.0 -- 2 秒决策一轮
}

function FactionAI.Update(dt, nodes, routeManager)
    FactionAI.aiTimer = FactionAI.aiTimer + dt
    if FactionAI.aiTimer < FactionAI.AI_INTERVAL then
        return
    end
    FactionAI.aiTimer = 0

    -- 遍历所有非玩家、非中立的敌对势力节点 (enemy_red / enemy_purple / enemy_green / enemy)
    for _, eNode in ipairs(nodes) do
        local fac = eNode.faction
        if fac ~= "player" and fac ~= "neutral" then
            if eNode.particles > 12 and eNode.routeTo == nil then
                -- 兵力充足且未外调：寻找邻近非本阵营领地（包括中立、玩家及其他敌对势力）
                local neighbors = StarMap.GetNeighbors(eNode.id)
                local targets = {}
                for _, nId in ipairs(neighbors) do
                    local n = nodes[nId + 1]
                    if n and n.faction ~= fac then
                        table.insert(targets, n)
                    end
                end

                if #targets > 0 then
                    -- 优先级：优先夺取中立薄弱灵穴，其次进攻弱势敌对/玩家据点
                    table.sort(targets, function(a, b)
                        if a.faction == "neutral" and b.faction ~= "neutral" then
                            return true
                        elseif a.faction ~= "neutral" and b.faction == "neutral" then
                            return false
                        else
                            return a.particles < b.particles
                        end
                    end)

                    local chosen = targets[1]
                    routeManager.SetRoute(eNode.id, chosen.id, fac, nodes)
                end

            elseif eNode.particles < 5 and eNode.routeTo ~= nil then
                -- 兵力紧缺危急：主动切断光轨收拢力量固守
                routeManager.RemoveRouteFrom(eNode.id, nodes)
                eNode.isDefensive = true
            end
        end
    end
end

return FactionAI
