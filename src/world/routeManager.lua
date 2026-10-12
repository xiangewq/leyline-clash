-- src/world/routeManager.lua
-- 地脉光轨物流管网、微粒发射批次与航线生命周期管理

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

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

    fromNode.routeTo = toId
    fromNode.isDefensive = false -- 开启输出自动解除纯驻阵固守

    table.insert(RouteManager.routes, {
        fromId = fromId,
        toId = toId,
        faction = faction,
        sendTimer = 0,
        boostedUntil = 0
    })

    BalanceConfig.PlayAudioSafe("ROUTE_LINK")
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
function RouteManager.Update(dt, nodes, elapsedTime, onCombatHitCallback)
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
                RouteManager.OnParticleArrive(p, targetNode, onCombatHitCallback)
            end
            table.remove(RouteManager.movingParticles, i)
        end
    end
end

-- 微粒到达目标节点结算
function RouteManager.OnParticleArrive(particle, node, onCombatHitCallback)
    if node.faction == particle.faction then
        -- 友军增援汇入
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
    else
        -- 敌对交火与侵蚀 (固守减伤 30%，命中率 70%，兼顾防御阵地坚韧度与攻坚可行性)
        if node.particles > 0 then
            local defenseDamp = (node.isDefensive and 0.7 or 1.0)
            if math.random() <= defenseDamp then
                node.particles = node.particles - 1
            end
            BalanceConfig.PlayAudioSafe("COMBAT_HIT")
            if onCombatHitCallback then
                onCombatHitCallback(node)
            end
        else
            -- 节点防守空虚，微粒转化为侵蚀共鸣点
            node.contenderFaction = particle.faction
            node.contenderParticles = (node.contenderParticles or 0) + 1
        end
    end
end

return RouteManager
