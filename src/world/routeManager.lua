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

    local fromNode = nodes[fromId + 1]
    local toNode = nodes[toId + 1]
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

-- 每帧更新：物流发射与微粒航行
function RouteManager.Update(dt, nodes, elapsedTime, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback)
    -- 1. 物流发射
    for _, route in ipairs(RouteManager.routes) do
        local fromNode = nodes[route.fromId + 1]
        local toNode = nodes[route.toId + 1]

        if fromNode and toNode and fromNode.faction == route.faction then
            route.sendTimer = (route.sendTimer or 0) + dt
            local rate = BalanceConfig.BASE_TRANSPORT_RATE
            if fromNode.anomaly == "WIND_FLOW" or route.boostedUntil > elapsedTime then
                rate = BalanceConfig.BOOST_TRANSPORT_RATE
            end

            local interval = 1.0 / rate
            if route.sendTimer >= interval then
                route.sendTimer = 0
                -- 节点保留基础守备兵力 (默认 3 粒，防止基地永久定格在 1 且防守空虚)
                local safeFloor = BalanceConfig.SAFE_GARRISON or 3
                if fromNode.particles > safeFloor then
                    fromNode.particles = fromNode.particles - 1
                    local dx = toNode.x - fromNode.x
                    local dy = toNode.y - fromNode.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    table.insert(RouteManager.movingParticles, {
                        fromId = fromNode.id,
                        toId = toNode.id,
                        faction = route.faction,
                        progress = 0,
                        startX = fromNode.x,
                        startY = fromNode.y,
                        targetX = toNode.x,
                        targetY = toNode.y,
                        totalDist = dist
                    })
                end
            end
        end
    end

    -- 2. 飞行微粒位移更新
    for i = #RouteManager.movingParticles, 1, -1 do
        local p = RouteManager.movingParticles[i]
        local step = (BalanceConfig.PARTICLE_SPEED * dt) / p.totalDist
        p.progress = p.progress + step

        if p.progress >= 1.0 then
            -- 到达目标节点
            local targetNode = nodes[p.toId + 1]
            if targetNode then
                RouteManager.OnParticleArrive(p, targetNode, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
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
