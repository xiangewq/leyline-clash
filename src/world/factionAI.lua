-- src/world/factionAI.lua
-- 坎瑞亚遗迹推衍机（智能敌对 AI 调度逻辑）

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

    -- 遍历所有敌方节点
    for _, eNode in ipairs(nodes) do
        if eNode.faction == "enemy" then
            if eNode.particles > 12 and eNode.routeTo == nil then
                -- 兵力充足且未外调：寻找邻近中立或玩家灵穴推进
                local neighbors = StarMap.GetNeighbors(eNode.id)
                local targets = {}
                for _, nId in ipairs(neighbors) do
                    local n = nodes[nId + 1]
                    if n and n.faction ~= "enemy" then
                        table.insert(targets, n)
                    end
                end

                if #targets > 0 then
                    -- 优先夺取中立灵穴，其次进攻弱势玩家据点
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
                    routeManager.SetRoute(eNode.id, chosen.id, "enemy", nodes)
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
