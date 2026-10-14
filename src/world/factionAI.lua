-- src/world/factionAI.lua
-- 坎瑞亚遗迹推衍机（多阵营全员大乱斗 AI 智能调度与梯次争端决策）

local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local FactionAI = {
    aiTimer = 0,
    AI_INTERVAL = 1.2 -- 1.2 秒决策一轮，反应敏捷高效
}

-- 辅助：广度优先遍历计算每个节点到最近非己方节点的最短跳数 (战线梯度)
local function ComputeFrontierDistances(allNodes, fac)
    local distMap = {}
    local queue = {}

    -- 1. 所有非己方节点作为距离源点 (距离为 0)
    for _, node in ipairs(allNodes) do
        if node.faction ~= fac then
            distMap[node.id] = 0
            table.insert(queue, node.id)
        end
    end

    -- 2. BFS 向内陆扩散标记跳数
    local head = 1
    while head <= #queue do
        local currId = queue[head]
        head = head + 1
        local currDist = distMap[currId]

        local neighbors = StarMap.GetNeighbors(currId)
        for _, nId in ipairs(neighbors) do
            if distMap[nId] == nil then
                distMap[nId] = currDist + 1
                table.insert(queue, nId)
            end
        end
    end

    return distMap
end

function FactionAI.Update(dt, nodes, routeManager)
    FactionAI.aiTimer = FactionAI.aiTimer + dt
    if FactionAI.aiTimer < FactionAI.AI_INTERVAL then
        return
    end
    FactionAI.aiTimer = 0

    -- 1. 收集当前场上所有活跃的 AI 势力阵营
    local activeFactions = {}
    for _, node in ipairs(nodes) do
        local fac = node.faction
        if fac ~= "player" and fac ~= "neutral" and not activeFactions[fac] then
            activeFactions[fac] = true
        end
    end

    -- 2. 针对每个 AI 阵营独立推衍战局
    for fac, _ in pairs(activeFactions) do
        local distMap = ComputeFrontierDistances(nodes, fac)

        for _, eNode in ipairs(nodes) do
            if eNode.faction == fac then
                local nodeDist = distMap[eNode.id] or 99

                -- ========================================================
                -- 阶段 1：活跃光轨动态监测与适时切断 (防止死循环抽干)
                -- ========================================================
                if eNode.routeTo ~= nil then
                    local targetNode = nodes[eNode.routeTo + 1]
                    local shouldCut = false

                    if targetNode then
                        if targetNode.faction == fac then
                            -- 目标为友军据点：
                            -- a) 目标守军已极大饱和 (>= 22 粒) -> 增援圆满达成
                            -- b) 源节点兵力降至防守底线 (<= 4 粒) -> 停止抽血
                            -- c) 目标节点正向源节点反向输送 -> 严重对冲死锁
                            if targetNode.particles >= 22 or eNode.particles <= 4 or targetNode.routeTo == eNode.id then
                                shouldCut = true
                            end
                        else
                            -- 目标为敌方/中立据点：
                            -- a) 自身兵力消耗至危急水平 (< 3 粒) -> 进攻受挫，撤退固守
                            if eNode.particles < 3 then
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

                -- ========================================================
                -- 阶段 2：空闲节点决策与目标选择 (当 routeTo 为 nil 时执行)
                -- ========================================================
                else
                    local neighbors = StarMap.GetNeighbors(eNode.id)

                    if nodeDist > 1 then
                        -- ----------------------------------------------------
                        -- 分支 A：后方腹地节点 (战线跳数 > 1，远离前线)
                        -- 核心策略：梯次推进输送带 (Conveyor Belt)
                        -- 只要兵力充足 (>= 12 粒)，向更靠近前线的友军邻居调兵！
                        -- ----------------------------------------------------
                        if eNode.particles >= 12 then
                            local bestForwardAlly = nil
                            local minAllyParts = 999

                            for _, nId in ipairs(neighbors) do
                                local n = StarMap.GetNode(nodes, nId)
                                local nDist = distMap[nId] or 99
                                -- 必须是同阵营友军，且距离前线更近 (nDist < nodeDist)
                                if n and n.faction == fac and nDist < nodeDist then
                                    if n.routeTo ~= eNode.id and n.particles < 22 then
                                        if n.particles < minAllyParts then
                                            minAllyParts = n.particles
                                            bestForwardAlly = n
                                        end
                                    end
                                end
                            end

                            if bestForwardAlly then
                                routeManager.SetRoute(eNode.id, bestForwardAlly.id, fac, nodes)
                            end
                        end

                    else
                        -- ----------------------------------------------------
                        -- 分支 B：前线接触据点 (nodeDist == 1，直接毗邻敌方/中立)
                        -- 核心策略：动态斩首突击与战线拓展
                        -- ----------------------------------------------------
                        local hostileTargets = {}
                        for _, nId in ipairs(neighbors) do
                            local n = StarMap.GetNode(nodes, nId)
                            if n and n.faction ~= fac then
                                table.insert(hostileTargets, n)
                            end
                        end

                        local chosenTarget = nil
                        if #hostileTargets > 0 and eNode.particles >= 4 then
                            -- 优先夺取中立据点
                            local neutralTargets = {}
                            local enemyTargets = {}
                            for _, t in ipairs(hostileTargets) do
                                if t.faction == "neutral" then
                                    table.insert(neutralTargets, t)
                                else
                                    table.insert(enemyTargets, t)
                                end
                            end

                            if #neutralTargets > 0 then
                                -- 抢占中立：优先兵力较少的
                                table.sort(neutralTargets, function(a, b) return a.particles < b.particles end)
                                chosenTarget = neutralTargets[1]
                            elseif #enemyTargets > 0 then
                                table.sort(enemyTargets, function(a, b) return a.particles < b.particles end)
                                local weakestEnemy = enemyTargets[1]

                                -- 动态门槛斩首判定：
                                -- 1) 敌方据点极为空虚 (<= 3 粒，甚至 0 粒无防守)：只要我方 >= 4 粒且多于敌方，果断斩首！
                                -- 2) 敌方据点防守充裕 (> 3 粒)：我方集结达到 8 粒以上且占优，发起总攻！
                                if weakestEnemy.particles <= 3 then
                                    if eNode.particles >= 4 and eNode.particles > weakestEnemy.particles then
                                        chosenTarget = weakestEnemy
                                    end
                                else
                                    if eNode.particles >= 8 and eNode.particles >= weakestEnemy.particles then
                                        chosenTarget = weakestEnemy
                                    end
                                end
                            end
                        end

                        if chosenTarget then
                            routeManager.SetRoute(eNode.id, chosenTarget.id, fac, nodes)
                        elseif eNode.particles >= 14 then
                            -- 前线防守充沛但无合适进攻机会时，协助相邻受困的前线友军
                            for _, nId in ipairs(neighbors) do
                                local n = nodes[nId + 1]
                                if n and n.faction == fac and n.particles < 8 and n.routeTo ~= eNode.id then
                                    routeManager.SetRoute(eNode.id, n.id, fac, nodes)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return FactionAI
