-- src/world/factionAI.lua
-- 坎瑞亚遗迹推衍机（多阵营全员大乱斗 AI 智能调度与争端决策）

local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local FactionAI = {
    aiTimer = 0,
    AI_INTERVAL = 1.5 -- 1.5 秒决策一轮，反应敏捷
}

-- 辅助判定灵穴是否处于接敌前线 (拥有非己方邻居)
local function HasHostileNeighbor(node, allNodes, fac)
    local neighbors = StarMap.GetNeighbors(node.id)
    for _, nId in ipairs(neighbors) do
        local n = allNodes[nId + 1]
        if n and n.faction ~= fac then
            return true
        end
    end
    return false
end

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

            -- 1. 活跃光轨动态监测与适时切断 (核心防死循环机制)
            if eNode.routeTo ~= nil then
                local targetNode = nodes[eNode.routeTo + 1]
                local shouldCut = false

                if targetNode then
                    if targetNode.faction == fac then
                        -- 目标为友军据点：
                        -- a) 目标守军充裕 (已达 14 粒) -> 增援任务圆满达成，立即切断，防止持续抽干源节点
                        -- b) 源节点自身兵力降至 8 粒 -> 保留自身驻防底线，停止无底洞抽血
                        -- c) 目标节点正向源节点反向输送 -> 严重对冲，立即切断
                        if targetNode.particles >= 14 or eNode.particles <= 8 or targetNode.routeTo == eNode.id then
                            shouldCut = true
                        end
                    else
                        -- 目标为敌方/中立据点：
                        -- a) 自身兵力消耗至危急水平 (< 5 粒) -> 进攻受挫，撤退固守
                        if eNode.particles < 5 then
                            shouldCut = true
                        end
                    end
                else
                    shouldCut = true
                end

                if shouldCut then
                    routeManager.RemoveRouteFrom(eNode.id, nodes)
                    eNode.isDefensive = true
                end

            -- 2. 空闲节点决策与目标选择 (仅当 routeTo 为 nil 时执行)
            elseif eNode.particles >= 10 then
                local neighbors = StarMap.GetNeighbors(eNode.id)

                -- 2.1 战术互援判定 (严格前线受困条件，杜绝后方无意义对流)
                local needAlly = nil
                -- 只有当自身兵力充裕 (>= 16 粒) 且自身未面临直接受袭威胁时，才考虑增援邻近友军
                if eNode.particles >= 16 and not eNode.hasEnemyThreat then
                    for _, nId in ipairs(neighbors) do
                        local n = nodes[nId + 1]
                        if n and n.faction == fac and n.id ~= eNode.id then
                            -- 关键约束：
                            -- a) 友军不能已经在向我输送 (杜绝互援死锁)
                            -- b) 友军处于前线或面临敌情
                            -- c) 友军兵力确实不足 (< 8 粒)
                            if n.routeTo ~= eNode.id and n.particles < 8 and (n.hasEnemyThreat or HasHostileNeighbor(n, nodes, fac)) then
                                needAlly = n
                                break
                            end
                        end
                    end
                end

                if needAlly then
                    routeManager.SetRoute(eNode.id, needAlly.id, fac, nodes)
                else
                    -- 2.2 战线拓展与针对性进攻
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
                end
            end
        end
    end
end

return FactionAI
