-- src/world/nodeEntity.lua
-- 地脉灵穴实体生命周期、内陆休眠、共鸣度渐进与固守状态

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local NodeEntity = {}

-- 实体构造函数
function NodeEntity.Create(def)
    return {
        id = def.id,
        name = def.name,
        x = def.x,
        y = def.y,
        radius = def.radius,
        faction = def.faction,
        particles = def.particles or 0,
        control = def.control or 0,
        anomaly = def.anomaly or "NORMAL",

        -- 状态标签
        routeTo = nil,          -- 当前对外输出的目标节点ID (nil 为无输出)
        isDefensive = (def.faction ~= "neutral"), -- 默认初始若无输出则固守
        isIdle = false,         -- 内陆腹地休眠标记
        protectedUntil = 0,     -- 千风庇护失效时间戳
        boostedUntil = 0,       -- 生产/流速加速时间戳

        -- 生产与占领内部计时器
        spawnTimer = 0,
        contenderFaction = nil,
        contenderParticles = 0
    }
end

-- 判定是否为腹地节点：所有物理相邻灵穴均为同阵营领地
function NodeEntity.CheckIsInland(node, allNodes)
    if node.faction == "neutral" then
        return false
    end
    local neighbors = StarMap.GetNeighbors(node.id)
    if #neighbors == 0 then return false end
    for _, nId in ipairs(neighbors) do
        local n = allNodes[nId + 1]
        if not n or n.faction ~= node.faction then
            return false
        end
    end
    return true
end

-- 判定腹地休眠与状态维护
function NodeEntity.CheckInlandDormant(node, allNodes)
    local isInland = NodeEntity.CheckIsInland(node, allNodes)
    if not isInland then
        node.isIdle = false
        return false
    end

    -- 核心理性机制：若灵穴处于安全腹地且未向外输送，储备达到 15 粒时自动休眠停止造兵
    if node.routeTo == nil and node.particles >= 15 then
        node.isIdle = true
        return true
    end

    node.isIdle = false
    return false
end

-- 帧更新生产逻辑
function NodeEntity.TickSpawn(node, dt, allNodes, elapsedTime)
    if node.faction == "neutral" then return end

    -- 判定内陆休眠 (未外调且储备充足则完全停产)
    if NodeEntity.CheckInlandDormant(node, allNodes) then
        return
    end

    local isInland = NodeEntity.CheckIsInland(node, allNodes)

    -- 生产周期换算
    local baseInterval = BalanceConfig.SPAWN_INTERVAL
    if isInland then
        -- 核心理性机制：腹地远离前线战火，地脉平息，产能衰减为前线的 40% (周期延长 2.5 倍)
        -- 避免后方节点无限造兵串联成超级水泵碾压前线
        baseInterval = baseInterval * 2.5
    end

    if node.anomaly == "AMBER_MINE" then
        baseInterval = baseInterval * 0.5
    elseif node.anomaly == "MIST_RUINS" then
        baseInterval = baseInterval * 1.25 -- 迷雾轻度减产
    elseif node.anomaly == "PURE_WATER" then
        baseInterval = baseInterval * 0.65 -- 纯水激荡：产速提升约 54%
    end

    -- 共鸣度衰减曲线（底线提高至 0.6，防止受创灵穴产兵完全停摆）
    local effRatio = math.max(0.6, node.control / 100)
    local actualInterval = baseInterval / effRatio

    node.spawnTimer = node.spawnTimer + dt
    if node.spawnTimer >= actualInterval then
        node.spawnTimer = 0
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
    end
end

-- 占领共鸣度步进结算 (0.8s 周期)
function NodeEntity.TickCapture(node, elapsedTime, onCaptureCallback, onRevertNeutralCallback)
    if (node.protectedUntil or 0) > (elapsedTime or 0) then
        return -- 受千风庇护免疫侵蚀
    end

    if node.contenderFaction and node.contenderParticles > 0 then
        local excess = node.contenderParticles
        local baseGrowth = math.min(BalanceConfig.MAX_RESONANCE_GROWTH, math.max(1, math.floor(excess / 5 + 0.5)))

        if node.faction == "neutral" then
            -- 中立节点占领进度平衡：每轮 +14~20 共鸣度，需 5~6 轮 (约 4 秒) 完成掌控
            node.control = math.min(100, node.control + 14 + baseGrowth * 3)
            if node.control >= 100 then
                node.faction = node.contenderFaction
                -- 占领后初始守军：侵蚀微粒按 25% 比例转化，保底 2 粒，上限 5 粒 (防止瞬间获得满编大军继续碾压)
                node.particles = math.min(5, math.max(2, math.floor(node.contenderParticles * 0.25) + 2))
                node.contenderParticles = 0
                node.contenderFaction = nil
                node.isDefensive = true
                if onCaptureCallback then
                    onCaptureCallback(node)
                end
            end
        elseif node.faction ~= node.contenderFaction then
            -- 削减原主控方控制度：每轮削减 10 + baseGrowth * 3
            node.control = math.max(0, node.control - (10 + baseGrowth * 3))
            if node.control <= BalanceConfig.NEUTRAL_THRESHOLD then
                -- 沦为中立争夺态，控制度清零以便攻占方迅速掌控
                node.faction = "neutral"
                node.control = 0
                node.routeTo = nil
                node.isDefensive = false
                if onRevertNeutralCallback then
                    onRevertNeutralCallback(node)
                end
            end
        end

        node.contenderParticles = math.max(0, node.contenderParticles - 1)
    else
        -- 核心机制修复：已占领灵穴在无敌军侵蚀且防守稳固时，共鸣度自然逐步回满至 100%
        if node.faction ~= "neutral" and node.control < 100 then
            node.control = math.min(100, node.control + 10)
        end
    end
end

return NodeEntity
