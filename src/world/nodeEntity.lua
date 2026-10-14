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
        control = def.control or (def.faction == "neutral" and 0 or 100),
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
    local effRatio = math.max(0.6, (node.control or 100) / 100)
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

-- 微粒到达时对灵穴归属与占领度的拔河对消结算 (Tug-of-War / Influence Pool)
function NodeEntity.ApplyArrival(node, particleFaction, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    if node.faction == particleFaction then
        -- 1. 友军微粒汇入
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
        -- 若据点此前受创但未失守，友军微粒同时修复防守共鸣度
        if (node.control or 100) < 100 then
            node.control = math.min(100, (node.control or 100) + 5)
        end
        if node.particles > 0 then
            node.contenderFaction = nil
        end
        return
    end

    -- 2. 敌对微粒进攻结算
    -- 核心防御保障：检查目标灵穴是否处于【千风庇护/守护】神圣保护期间
    if (node.protectedUntil or 0) > (elapsedTime or 0) then
        -- 千风结界绝对阻挡与湮灭一切敌方微粒！
        -- 守备兵力不扣减、控制度不扣减、绝不沦陷为中立态！
        BalanceConfig.PlayAudioSafe("NODE_DEFEND")
        if type(onCombatHitCallback) == "function" then
            onCombatHitCallback(node)
        end
        return
    end

    if node.particles > 0 then
        -- 仍有驻军守备：交火决算
        local defenseDamp = (node.isDefensive and 0.7 or 1.0)
        if math.random() <= defenseDamp then
            node.particles = node.particles - 1
            -- COMBAT_HIT 保持静音，依靠视觉闪烁
        else
            BalanceConfig.PlayAudioSafe("NODE_DEFEND")
        end
        if onCombatHitCallback then
            onCombatHitCallback(node)
        end
        return
    end

    -- 3. 守军已清零，进入侵蚀与占领结算 (防守空虚)
    if node.faction ~= "neutral" then
        -- 3.1 敌对微粒侵蚀现有掌控者 (动摇沦陷阶段)
        -- 每颗微粒削减 10% 控制度
        node.control = math.max(0, (node.control or 100) - 10)
        node.contenderFaction = particleFaction
        if node.control <= (BalanceConfig.NEUTRAL_THRESHOLD or 20) then
            -- 彻底沦为中立争夺态！
            node.faction = "neutral"
            node.control = 0
            node.routeTo = nil
            node.isDefensive = false
            node.contenderFaction = particleFaction -- 攻破者确立为中立争夺先锋
            if onRevertNeutralCallback then
                onRevertNeutralCallback(node)
            end
        end
        if onCombatHitCallback then
            onCombatHitCallback(node)
        end
        return
    end

    -- 3.2 中立争夺态：多阵营拔河对消模型 (Tug-of-War)
    -- node.control 统一表示当前主导方 (node.contenderFaction) 的占领进度 (0 ~ 100)
    if node.contenderFaction == nil or (node.control or 0) <= 0 then
        -- 当前无主导方：该阵营微粒直接确立为主导方
        node.contenderFaction = particleFaction
        node.control = 10
    elseif node.contenderFaction == particleFaction then
        -- 同阵营微粒：推进占领进度
        node.control = math.min(100, (node.control or 0) + 10)
        if node.control >= 100 then
            -- 占领成功！成为正式据点
            node.faction = particleFaction
            node.control = 100
            node.particles = 2 -- 初始赠予 2 粒守军
            node.contenderFaction = nil
            node.isDefensive = true
            if onCaptureCallback then
                onCaptureCallback(node)
            end
            if particleFaction == "player" then
                BalanceConfig.PlayAudioSafe("NODE_CAPTURE")
            end
        end
    else
        -- 异阵营微粒：拔河对消！反向削减当前主导方的占领度
        node.control = (node.control or 0) - 10
        if node.control < 0 then
            -- 彻底击穿原主导方！新阵营确立并继承穿透进度
            node.contenderFaction = particleFaction
            node.control = math.abs(node.control)
        elseif node.control == 0 then
            -- 正好完全抵消归零，阵地重归中立争夺态
            node.contenderFaction = nil
            node.control = 0
        end
    end

    if onCombatHitCallback then
        onCombatHitCallback(node)
    end
end

-- 占领共鸣度周期自然维稳 (0.8s 周期)
function NodeEntity.TickCapture(node, elapsedTime, onCaptureCallback, onRevertNeutralCallback)
    local isProtected = (node.protectedUntil or 0) > (elapsedTime or 0)

    -- 若已有主据点守军充裕且无敌情侵蚀，受损控制度逐步平稳回满
    -- 若处于【千风庇护】守护期，即使兵力空虚也受神圣结界庇护并享受双倍共鸣恢复 (每次恢复 20%)
    if node.faction ~= "neutral" and (node.control or 0) < 100 and ((node.particles or 0) > 0 or isProtected) then
        local healRate = isProtected and 20 or 10
        node.control = math.min(100, (node.control or 0) + healRate)
    end
end

return NodeEntity
