-- src/world/routeManager.lua
-- 地脉光轨物流管网、微粒发射批次与航线生命周期管理

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")
local NodeEntity = require("default_import_file/src/world/nodeEntity") or require("src/world/nodeEntity")

local RouteManager = {
    routes = {},           -- 活跃光轨列表: { fromId, toId, faction, sendTimer, boostedUntil }
    movingParticles = {}   -- 飞行中微粒: { fromId, toId, faction, progress, startX, startY, targetX, targetY, totalDist }
}

function RouteManager.Init()
    RouteManager.routes = {}
    RouteManager.movingParticles = {}
end

-- 建立单向光轨
function RouteManager.SetRoute(fromId, toId, faction, nodes)
    if not StarMap.AreNodesLinked(fromId, toId) then
        return false, "两灵穴间不存在直通地脉流道！"
    end

    local fromNode = StarMap.GetNode(nodes, fromId)
    local toNode = StarMap.GetNode(nodes, toId)
    if not fromNode or not toNode then return false end

    -- 单节点同一时间仅允许存在 1 条对外输出光轨
    RouteManager.RemoveRouteFrom(fromId, nodes)

    -- 仅限【同阵营内部调兵】防止死锁回环：若同阵营目标据点已在向源据点输送，切断原同向光轨
    -- 敌对阵营之间完全允许互相进攻交火，绝不打断敌方的进攻光轨！
    local revRoute = RouteManager.GetRouteFrom(toId)
    if revRoute and revRoute.toId == fromId and revRoute.faction == faction then
        RouteManager.RemoveRouteFrom(toId, nodes)
    end

    fromNode.routeTo = toId
    fromNode.isDefensive = false -- 开启输出自动解除纯驻阵固守

    table.insert(RouteManager.routes, {
        fromId = fromId,
        toId = toId,
        faction = faction,
        sendTimer = 0,
        boostedUntil = 0
    })

    if faction == "player" then
        BalanceConfig.PlayAudioSafe("ROUTE_LINK")
    end
    return true
end

-- 切断指定节点的对外光轨
function RouteManager.RemoveRouteFrom(fromId, nodes)
    for i = #RouteManager.routes, 1, -1 do
        local r = RouteManager.routes[i]
        if r.fromId == fromId then
            table.remove(RouteManager.routes, i)
            local node = nodes[fromId + 1]
            if node then
                node.routeTo = nil
            end
            return true
        end
    end
    return false
end

function RouteManager.GetRouteFrom(fromId)
    for _, r in ipairs(RouteManager.routes) do
        if r.fromId == fromId then return r end
    end
    return nil
end

-- 每帧更新：物流发射、中途相向空间分桶碰撞决算与微粒航行
function RouteManager.Update(dt, nodes, elapsedTime, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback)
    -- 1. 物流发射（含高负荷自动数据包聚合 Packet Merging 机制）
    local activeParticleCount = #RouteManager.movingParticles
    local isHighLoad = (activeParticleCount >= 96) -- 超过 120 容积的 80% 触发聚合

    for _, route in ipairs(RouteManager.routes) do
        local fromNode = StarMap.GetNode(nodes, route.fromId)
        local toNode = StarMap.GetNode(nodes, route.toId)

        if fromNode and toNode and fromNode.faction == route.faction then
            route.sendTimer = (route.sendTimer or 0) + dt
            local isBoosted = (fromNode.anomaly == "WIND_FLOW" or (route.boostedUntil and route.boostedUntil > elapsedTime))
            local rate = isBoosted and BalanceConfig.BOOST_TRANSPORT_RATE or BalanceConfig.BASE_TRANSPORT_RATE

            local interval = 1.0 / rate
            if route.sendTimer >= interval then
                route.sendTimer = 0
                -- 节点保留基础守备兵力 (默认 3 粒，防止基地永久定格在 1 且防守空虚)
                local safeFloor = BalanceConfig.SAFE_GARRISON or 3
                local available = fromNode.particles - safeFloor
                if available > 0 then
                    -- 数据包聚合计算：高负载时单次发射 2~3 粒
                    local payload = 1
                    if isHighLoad and available >= 2 then
                        payload = math.min(3, available)
                    end
                    fromNode.particles = fromNode.particles - payload

                    local dx = toNode.x - fromNode.x
                    local dy = toNode.y - fromNode.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist <= 0.001 then dist = 1 end

                    local nx = -dy / dist
                    local ny = dx / dist
                    local rad = math.atan(dy, dx)
                    local angle = math.deg(rad)

                    table.insert(RouteManager.movingParticles, {
                        fromId = fromNode.id,
                        toId = toNode.id,
                        edgeKey = StarMap.GetEdgeKey(fromNode.id, toNode.id),
                        faction = route.faction,
                        payload = payload,
                        progress = 0,
                        startX = fromNode.x,
                        startY = fromNode.y,
                        targetX = toNode.x,
                        targetY = toNode.y,
                        totalDist = dist,
                        nx = nx,
                        ny = ny,
                        angle = angle,
                        seed = (fromNode.id * 17 + toNode.id * 31) % 100,
                        isBoosted = isBoosted
                    })
                end
            end
        end
    end

    -- 2. 飞行微粒位移更新
    for _, p in ipairs(RouteManager.movingParticles) do
        local step = (BalanceConfig.PARTICLE_SPEED * dt) / p.totalDist
        p.progress = p.progress + step
    end

    -- 3. O(N) 空间边分桶中途碰撞决算 (同一条边相向而行的大对撞)
    local edgeBuckets = {}
    for i, p in ipairs(RouteManager.movingParticles) do
        if p.progress < 1.0 and (p.payload or 1) > 0 then
            local k = p.edgeKey
            if not edgeBuckets[k] then
                edgeBuckets[k] = { i }
            else
                table.insert(edgeBuckets[k], i)
            end
        end
    end

    for _, indices in pairs(edgeBuckets) do
        if #indices >= 2 then
            for idxA = 1, #indices do
                local i = indices[idxA]
                local pA = RouteManager.movingParticles[i]
                if pA and (pA.payload or 1) > 0 then
                    for idxB = idxA + 1, #indices do
                        local j = indices[idxB]
                        local pB = RouteManager.movingParticles[j]
                        -- 仅在相向对流且不同阵营时发生交汇湮灭
                        if pB and (pB.payload or 1) > 0 and pA.faction ~= pB.faction and pA.fromId == pB.toId and pA.toId == pB.fromId then
                            -- 一维交汇比对：两相向质点进度之和 >= 1.0 即说明在航道中途相撞！
                            if (pA.progress + pB.progress) >= 1.0 then
                                local colX = pA.startX + (pA.targetX - pA.startX) * pA.progress
                                local colY = pA.startY + (pA.targetY - pA.startY) * pA.progress
                                if onCombatHitCallback then
                                    onCombatHitCallback({ x = colX, y = colY })
                                end
                                BalanceConfig.PlayAudioSafe("NODE_DEFEND")

                                local payA = pA.payload or 1
                                local payB = pB.payload or 1
                                if payA == payB then
                                    pA.payload = 0
                                    pB.payload = 0
                                elseif payA > payB then
                                    pA.payload = payA - payB
                                    pB.payload = 0
                                else
                                    pB.payload = payB - payA
                                    pA.payload = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 4. 到达目标节点或中途湮灭结算
    for i = #RouteManager.movingParticles, 1, -1 do
        local p = RouteManager.movingParticles[i]
        local payload = p.payload or 1

        if payload <= 0 then
            -- 中途碰撞完全消散
            table.remove(RouteManager.movingParticles, i)
        elseif p.progress >= 1.0 then
            -- 成功抵达目标据点
            local targetNode = StarMap.GetNode(nodes, p.toId)
            if targetNode then
                for _ = 1, payload do
                    RouteManager.OnParticleArrive(p, targetNode, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
                end
            end
            table.remove(RouteManager.movingParticles, i)
        end
    end
end

-- 微粒到达目标节点结算 (委托至 NodeEntity.ApplyArrival 拔河对消决算)
function RouteManager.OnParticleArrive(particle, node, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    if NodeEntity and NodeEntity.ApplyArrival then
        NodeEntity.ApplyArrival(node, particle.faction, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    else
        -- 兜底逻辑
        if node.faction == particle.faction then
            node.particles = node.particles + 1
        elseif (node.protectedUntil or 0) > (elapsedTime or 0) then
            -- 受千风庇护免疫
            BalanceConfig.PlayAudioSafe("NODE_DEFEND")
            if onCombatHitCallback then onCombatHitCallback(node) end
        elseif node.particles > 0 then
            node.particles = node.particles - 1
            if onCombatHitCallback then onCombatHitCallback(node) end
        end
    end
end

return RouteManager
