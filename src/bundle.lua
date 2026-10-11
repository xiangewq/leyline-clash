-- src/bundle.lua: Consolidated standalone bundle for Miliastra UGC
local _MODULES = {}
local _LOADED = {}
local _orig_require = require

local function local_require(name)
    local clean = tostring(name):gsub("^default_import_file/", ""):gsub("%.lua$", "")
    if _LOADED[clean] ~= nil then return _LOADED[clean] end
    if _MODULES[clean] ~= nil then
        _LOADED[clean] = _MODULES[clean]()
        return _LOADED[clean]
    end
    if _orig_require then
        local ok, res = pcall(_orig_require, name)
        if ok and res ~= nil then return res end
    end
    error("Module not found: " .. tostring(name))
end
local require = local_require

_MODULES["src/data/balanceConfig"] = function()
-- src/data/balanceConfig.lua
-- 《星轨交错：地脉争锋》核心数值平衡与音频配置

local BalanceConfig = {
    -- 基础对局时间 (秒)
    MATCH_DURATION = 360, -- 6 分钟紧凑快节奏

    -- 兵力孕育与生产
    SPAWN_INTERVAL = 0.75, -- 基础孕育周期 (秒)
    MAX_NODE_CAP = 50,     -- 普通灵穴兵力上限
    PLASMA_CAP = 25,       -- 赤阳熔核灵穴兵力硬封顶

    -- 物流与光轨
    PARTICLE_SPEED = 200,  -- 微粒基础航速 (像素/秒)
    BASE_TRANSPORT_RATE = 5, -- 标准输送率 (粒/秒)
    BOOST_TRANSPORT_RATE = 10, -- 疾风加速输送率 (粒/秒)

    -- 占领与共鸣度 (0% ~ 100%)
    CAPTURE_INTERVAL = 0.8, -- 占领共鸣判定步进周期 (秒)
    MAX_RESONANCE_GROWTH = 5, -- 核心防滚雪球封顶步进 (点/轮)
    NEUTRAL_THRESHOLD = 20, -- 跌破 20% 沦为中立争夺态

    -- 战火决算
    COMBAT_INTERVAL = 0.5, -- 交火结算周期 (秒)
    COMBAT_BASE_DAMAGE_MIN = 3,
    COMBAT_BASE_DAMAGE_MAX = 6,
    DEFENSIVE_DAMAGE_MIN = 2,
    DEFENSIVE_DAMAGE_MAX = 4,

    -- 战前构筑预算
    MAX_BUDGET = 12,

    -- 提瓦特音频 GUID 槽位映射表 (创作者可在编辑器中填入实机音频 GUID)
    AUDIO_SLOTS = {
        UI_CLICK = 0,       -- 节点选定与按钮点击
        ROUTE_LINK = 0,     -- 光轨连接建立
        ROUTE_CUT = 0,      -- 光轨切断与结界激活
        COMBAT_HIT = 0,     -- 微粒交火火花
        SKILL_BLAST = 0,    -- 轰轰烈焰与神罚轰爆
        MATCH_WIN = 0,      -- 全域大捷
        MATCH_LOSE = 0      -- 灵脉耗竭
    }
}

-- 安全播放音效包装器 (若未配置或ID无效，安全静音运行并以视觉动效兜底)
function BalanceConfig.PlayAudioSafe(audioSlotKey)
    local audioId = BalanceConfig.AUDIO_SLOTS[audioSlotKey]
    if audioId and audioId > 0 and game and game.PlayAudio2D then
        pcall(function()
            game.PlayAudio2D(audioId)
        end)
    end
end

return BalanceConfig

end
_MODULES["data/balanceConfig"] = _MODULES["src/data/balanceConfig"]

_MODULES["src/data/cardRegistry"] = function()
-- src/data/cardRegistry.lua
-- 《星轨交错：地脉争锋》17种提瓦特七大元素战术符印注册表

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local CardRegistry = {
    CARDS = {
        {
            id = "anemo_shield",
            name = "千风庇护",
            element = "anemo",
            cost = 2,
            cd = 30,
            duration = 20,
            targetType = "player_node",
            desc = "加持己方灵穴，20秒内免疫任何敌方侵蚀，本土共鸣恢复翻倍。",
            badgeColor = Layout.MakeColor(52, 211, 153, 255)
        },
        {
            id = "anemo_turb",
            name = "千风湍流",
            element = "anemo",
            cost = 3,
            cd = 20,
            duration = 30,
            targetType = "player_route_node",
            desc = "激发生发之风，30秒内从该灵穴出发的光轨流速翻倍至10粒/秒。",
            badgeColor = Layout.MakeColor(52, 211, 153, 255)
        },
        {
            id = "pyro_blast",
            name = "轰轰烈焰",
            element = "pyro",
            cost = 4,
            cd = 25,
            duration = 0,
            targetType = "enemy_node",
            desc = "引动燃素轰爆，瞬间消灭目标敌方灵穴上 80% 的驻留微粒！",
            badgeColor = Layout.MakeColor(244, 63, 94, 255)
        },
        {
            id = "hydro_bribe",
            name = "摩拉律法",
            element = "hydro",
            cost = 5,
            cd = 35,
            duration = 0,
            targetType = "any_node",
            desc = "水之契约与摩拉通神：中立灵穴直接秒占100%；敌方灵穴削减65%共鸣。",
            badgeColor = Layout.MakeColor(56, 189, 248, 255)
        },
        {
            id = "geo_wall",
            name = "坚岩重嶂",
            element = "geo",
            cost = 4,
            cd = 30,
            duration = 20,
            targetType = "player_node",
            desc = "凝结磐岩坚盾，20秒内己方战损减半，敌方承受双倍反震战损。",
            badgeColor = Layout.MakeColor(251, 191, 36, 255)
        },
        {
            id = "pyro_erosion",
            name = "烈焰侵蚀",
            element = "pyro",
            cost = 2,
            cd = 30,
            duration = 20,
            targetType = "enemy_node",
            desc = "炽火灼烧敌脉，20秒内目标敌方灵穴被我方微粒攻占的速度翻倍。",
            badgeColor = Layout.MakeColor(244, 63, 94, 255)
        }
    }
}

function CardRegistry.GetCardById(cardId)
    for _, card in ipairs(CardRegistry.CARDS) do
        if card.id == cardId then
            return card
        end
    end
    return nil
end

function CardRegistry.GetDefaultDeck()
    -- 默认装配 4 张核心卡：千风庇护(2) + 千风湍流(3) + 轰轰烈焰(4) + 摩拉律法(5) = 14 (若预算12点可自由替换)
    -- 初始推荐：千风庇护(2) + 千风湍流(3) + 轰轰烈焰(4) = 9点 或 自选组合
    return { "anemo_shield", "anemo_turb", "pyro_blast", "hydro_bribe" }
end

return CardRegistry

end
_MODULES["data/cardRegistry"] = _MODULES["src/data/cardRegistry"]

_MODULES["src/core/layout"] = function()
-- src/core/layout.lua
-- 坐标计算、几何变换与提瓦特纯代码调色板

local Layout = {}

-- 几何与数学工具
function Layout.Distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Layout.AngleDeg(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local rad = math.atan(dy, dx)
    return math.deg(rad)
end

function Layout.Clamp(val, minVal, maxVal)
    if val < minVal then return minVal end
    if val > maxVal then return maxVal end
    return val
end

-- 安全设置控件可见性 (支持真机与模拟器 SetVisible 方法)
function Layout.SetVisible(ctrl, isVisible)
    if not ctrl or not ctrl.alive then return end
    if ctrl.SetVisible then
        ctrl:SetVisible(isVisible)
    else
        pcall(function() ctrl.visible = isVisible end)
    end
end

-- 颜色构造工具 (适配千星沙箱 Color 构造函数与 packed uint32 整数)
function Layout.MakeColor(r, g, b, a)
    local R = (r <= 1 and r > 0) and math.floor(r * 255) or math.floor(r or 0)
    local G = (g <= 1 and g > 0) and math.floor(g * 255) or math.floor(g or 0)
    local B = (b <= 1 and b > 0) and math.floor(b * 255) or math.floor(b or 0)
    local rawA = a == nil and 255 or a
    local A = (rawA <= 1 and rawA > 0) and math.floor(rawA * 255) or math.floor(rawA)

    if Color then
        if Color.FromRGBA then
            local ok, col = pcall(function() return Color.FromRGBA(R, G, B, A) end)
            if ok and col and type(col) == "number" then return math.tointeger(col) or math.floor(col) end
        end
        local ok, col = pcall(function() return Color(R, G, B, A) end)
        if ok and col and type(col) == "number" then return math.tointeger(col) or math.floor(col) end
    end
    -- 回退：计算 AARRGGBB 打包数值 (标准 32 位无符号整数)
    local val = A * 16777216 + R * 65536 + G * 256 + B
    return math.tointeger(val) or math.floor(val)
end

-- 安全转换任何颜色输入（table/number/nil）为合法的整数 ColorValue
function Layout.ToColorInt(val)
    if type(val) == "number" then
        return math.tointeger(val) or math.floor(val)
    elseif type(val) == "table" then
        return Layout.MakeColor(val.r or 1, val.g or 1, val.b or 1, val.a or 1)
    end
    return 0xFFFFFFFF
end


-- 提瓦特地脉标准调色板 (使用 0..255 整数)
Layout.PALETTE = {
    BG_DARK      = Layout.MakeColor(11, 17, 30, 255),
    PANEL_BG     = Layout.MakeColor(15, 23, 42, 235),
    PLAYER       = Layout.MakeColor(56, 189, 248, 255),   -- 提瓦特天青蓝 #38bdf8
    PLAYER_GLOW  = Layout.MakeColor(56, 189, 248, 102),
    ENEMY        = Layout.MakeColor(244, 63, 94, 255),    -- 侵蚀猩红 #f43f5e
    ENEMY_GLOW   = Layout.MakeColor(244, 63, 94, 102),
    NEUTRAL      = Layout.MakeColor(148, 163, 184, 255),  -- 远古银岩灰 #94a3b8
    GOLD         = Layout.MakeColor(251, 191, 36, 255),   -- 固守金岩 #fbbf24
    GOLD_ALPHA   = Layout.MakeColor(251, 191, 36, 191),
    ANEMO        = Layout.MakeColor(52, 211, 153, 255),   -- 千风翠碧 #34d399
    AMBER        = Layout.MakeColor(245, 158, 11, 255),   -- 石珀金橙 #f59e0b
    TEXT_LIGHT   = Layout.MakeColor(248, 250, 252, 255),
    TEXT_MUTED   = Layout.MakeColor(100, 116, 139, 255),
    LINK_INACTIVE= Layout.MakeColor(51, 65, 85, 115)
}

function Layout.GetFactionColor(faction)
    if faction == "player" then
        return Layout.PALETTE.PLAYER
    elseif faction == "enemy" then
        return Layout.PALETTE.ENEMY
    else
        return Layout.PALETTE.NEUTRAL
    end
end

return Layout

end
_MODULES["core/layout"] = _MODULES["src/core/layout"]

_MODULES["src/core/runtime"] = function()
-- src/core/runtime.lua
-- 对象池管理、清理栈与沙箱安全调用边界

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local Runtime = {}

-- 微粒图元对象池 (复用已挂载的 UI 控件，杜绝单帧高频创建/销毁)
local ParticlePool = {
    controls = {},
    capacity = 80,
    activeCount = 0
}

function Runtime.InitParticlePool(controlList)
    ParticlePool.controls = controlList or {}
    ParticlePool.capacity = #ParticlePool.controls
    ParticlePool.activeCount = 0
    -- 默认隐藏所有池内微粒控件
    for _, ctrl in ipairs(ParticlePool.controls) do
        Layout.SetVisible(ctrl, false)
    end
end

function Runtime.GetPoolCapacity()
    return ParticlePool.capacity
end

function Runtime.UpdateParticles(movingParticles, factionColorGetter)
    local count = #movingParticles
    local maxAvail = ParticlePool.capacity

    for i = 1, maxAvail do
        local ctrl = ParticlePool.controls[i]
        if ctrl and ctrl.alive then
            if i <= count then
                local p = movingParticles[i]
                -- 计算当前插值坐标
                local curX = p.startX + (p.targetX - p.startX) * p.progress
                local curY = p.startY + (p.targetY - p.startY) * p.progress

                ctrl.anchoredPositionX = curX
                ctrl.anchoredPositionY = curY

                if factionColorGetter and p.faction then
                    ctrl.imageColor = factionColorGetter(p.faction)
                end

                Layout.SetVisible(ctrl, true)
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end
end

function Runtime.HideAllParticles()
    for _, ctrl in ipairs(ParticlePool.controls) do
        Layout.SetVisible(ctrl, false)
    end
end

-- 安全执行函数
function Runtime.SafeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        if printerr then
            printerr("[Starlink Runtime Error]: " .. tostring(res))
        else
            print("[Starlink Runtime Error]: " .. tostring(res))
        end
        return nil, res
    end
    return res
end

return Runtime

end
_MODULES["core/runtime"] = _MODULES["src/core/runtime"]

_MODULES["src/core/input"] = function()
-- src/core/input.lua
-- 全局全屏输入适配器与光标事件分发

local Input = {
    isDragging = false,
    dragSourceId = nil,
    dragCurrentX = 0,
    dragCurrentY = 0,
    pressStartX = 0,
    pressStartY = 0,
    selectedCardIndex = nil,

    -- 回调事件注册
    onNodeClicked = nil,      -- fun(nodeId)
    onRouteCreated = nil,     -- fun(fromId, toId)
    onCardCast = nil          -- fun(cardIndex, targetNodeId)
}

local DRAG_THRESHOLD = 15 -- 像素防抖阈值

function Input.SetSelectedCard(index)
    Input.selectedCardIndex = index
end

function Input.GetSelectedCard()
    return Input.selectedCardIndex
end

function Input.ClearSelectedCard()
    Input.selectedCardIndex = nil
end

function Input.FindNodeAtPos(x, y, nodes)
    for _, node in ipairs(nodes) do
        local dx = node.x - x
        local dy = node.y - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= (node.radius + 18) then
            return node
        end
    end
    return nil
end

function Input.OnCursorDown(x, y, nodes)
    Input.pressStartX = x
    Input.pressStartY = y
    Input.dragCurrentX = x
    Input.dragCurrentY = y

    local clickedNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Down at (%.1f, %.1f), hit = %s", x, y, clickedNode and clickedNode.name or "none"))

    -- 若当前已选中卡牌，直接作为技能目标拾取
    if Input.selectedCardIndex and clickedNode then
        if Input.onCardCast then
            Input.onCardCast(Input.selectedCardIndex, clickedNode.id)
        end
        Input.selectedCardIndex = nil
        return
    end

    -- 若点击己方灵穴，启动拖拽连线准备
    if clickedNode and clickedNode.faction == "player" then
        Input.isDragging = true
        Input.dragSourceId = clickedNode.id
    else
        Input.isDragging = false
        Input.dragSourceId = nil
    end
end

function Input.OnCursorDrag(x, y)
    if Input.isDragging then
        Input.dragCurrentX = x
        Input.dragCurrentY = y
    end
end

function Input.OnCursorUp(x, y, nodes)
    if not Input.isDragging and not Input.dragSourceId then
        return
    end

    local sourceId = Input.dragSourceId
    local targetNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Up at (%.1f, %.1f), target = %s", x, y, targetNode and targetNode.name or "none"))

    local movedDist = math.sqrt((x - Input.pressStartX) ^ 2 + (y - Input.pressStartY) ^ 2)

    if targetNode and targetNode.id ~= sourceId then
        -- 成功拖至不同节点：建立航线
        if Input.onRouteCreated then
            Input.onRouteCreated(sourceId, targetNode.id)
        end
    elseif movedDist < DRAG_THRESHOLD or (targetNode and targetNode.id == sourceId) then
        -- 原地轻点或微小位移：激活固守 / 切断光轨
        if Input.onNodeClicked and sourceId then
            Input.onNodeClicked(sourceId)
        end
    end

    Input.isDragging = false
    Input.dragSourceId = nil
end

return Input

end
_MODULES["core/input"] = _MODULES["src/core/input"]

_MODULES["src/world/starMap"] = function()
-- src/world/starMap.lua
-- 提瓦特五灵穴沙盘拓扑、连通性矩阵与几何规格

local StarMap = {
    -- 基础 5 节点规格
    NODES_DEF = {
        {
            id = 0,
            name = "西风枢纽",
            x = 320,
            y = 450,
            radius = 54,
            faction = "player",
            particles = 25,
            control = 100,
            anomaly = "NORMAL",
            desc = "蒙德前哨枢纽"
        },
        {
            id = 1,
            name = "石珀晶矿",
            x = 650,
            y = 280,
            radius = 46,
            faction = "neutral",
            particles = 10,
            control = 0,
            anomaly = "AMBER_MINE",
            desc = "石珀富矿（产能翻倍）"
        },
        {
            id = 2,
            name = "千风隘口",
            x = 800,
            y = 520,
            radius = 48,
            faction = "neutral",
            particles = 15,
            control = 0,
            anomaly = "WIND_FLOW",
            desc = "千风汇聚（输送翻倍）"
        },
        {
            id = 3,
            name = "迷雾荒墟",
            x = 950,
            y = 300,
            radius = 44,
            faction = "neutral",
            particles = 8,
            control = 0,
            anomaly = "MIST_RUINS",
            desc = "迷雾缓冲（产能减半）"
        },
        {
            id = 4,
            name = "愚人坚垒",
            x = 1280,
            y = 450,
            radius = 54,
            faction = "enemy",
            particles = 25,
            control = 100,
            anomaly = "NORMAL",
            desc = "敌对推衍要塞"
        }
    },

    -- 拓扑连线 (无交叉网络)
    LINKS = {
        { 0, 1 },
        { 0, 2 },
        { 1, 2 },
        { 1, 3 },
        { 2, 3 },
        { 2, 4 },
        { 3, 4 }
    }
}

-- 判定两节点间是否存在地脉直通流道
function StarMap.AreNodesLinked(idA, idB)
    for _, link in ipairs(StarMap.LINKS) do
        if (link[1] == idA and link[2] == idB) or (link[1] == idB and link[2] == idA) then
            return true
        end
    end
    return false
end

-- 获取指定节点的所有物理相邻邻居列表
function StarMap.GetNeighbors(nodeId)
    local list = {}
    for _, link in ipairs(StarMap.LINKS) do
        if link[1] == nodeId then
            table.insert(list, link[2])
        elseif link[2] == nodeId then
            table.insert(list, link[1])
        end
    end
    return list
end

return StarMap

end
_MODULES["world/starMap"] = _MODULES["src/world/starMap"]

_MODULES["src/world/nodeEntity"] = function()
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

-- 判定腹地休眠：无对外输出光轨、无入侵敌军且所有邻居均为同阵营领地
function NodeEntity.CheckInlandDormant(node, allNodes)
    if node.faction == "neutral" then
        node.isIdle = false
        return false
    end

    if node.routeTo ~= nil then
        node.isIdle = false
        return false
    end

    local neighbors = StarMap.GetNeighbors(node.id)
    local allAllies = true
    for _, nId in ipairs(neighbors) do
        local n = allNodes[nId + 1]
        if n and n.faction ~= node.faction then
            allAllies = false
            break
        end
    end

    node.isIdle = allAllies
    return allAllies
end

-- 帧更新生产逻辑
function NodeEntity.TickSpawn(node, dt, allNodes, elapsedTime)
    if node.faction == "neutral" then return end

    -- 判定内陆休眠
    if NodeEntity.CheckInlandDormant(node, allNodes) then
        return
    end

    -- 生产周期换算 (富矿产速翻倍，贫瘠产速减半，共鸣度不足拉长周期)
    local baseInterval = BalanceConfig.SPAWN_INTERVAL
    if node.anomaly == "AMBER_MINE" then
        baseInterval = baseInterval * 0.5
    elseif node.anomaly == "MIST_RUINS" then
        baseInterval = baseInterval * 1.5
    end

    -- 共鸣度衰减曲线
    local effRatio = math.max(0.3, node.control / 100)
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

-- 占领共鸣度步进结算 (0.8s 周期，封顶 5 点/轮防滚雪球)
function NodeEntity.TickCapture(node, elapsedTime, onCaptureCallback, onRevertNeutralCallback)
    if node.protectedUntil > elapsedTime then
        return -- 受千风庇护免疫侵蚀
    end

    if node.contenderFaction and node.contenderParticles > 0 then
        local excess = node.contenderParticles
        local baseGrowth = math.min(BalanceConfig.MAX_RESONANCE_GROWTH, math.max(1, math.floor(excess / 5 + 0.5)))

        if node.faction == "neutral" then
            node.control = math.min(100, node.control + baseGrowth * 6)
            if node.control >= 100 then
                node.faction = node.contenderFaction
                node.particles = 5
                node.contenderParticles = 0
                node.contenderFaction = nil
                node.isDefensive = true
                if onCaptureCallback then
                    onCaptureCallback(node)
                end
            end
        elseif node.faction ~= node.contenderFaction then
            -- 削减原主控方控制度
            node.control = math.max(0, node.control - baseGrowth * 4)
            if node.control <= BalanceConfig.NEUTRAL_THRESHOLD then
                -- 沦为中立争夺态
                node.faction = "neutral"
                node.routeTo = nil
                node.isDefensive = false
                if onRevertNeutralCallback then
                    onRevertNeutralCallback(node)
                end
            end
        end

        node.contenderParticles = math.max(0, node.contenderParticles - 1)
    end
end

return NodeEntity

end
_MODULES["world/nodeEntity"] = _MODULES["src/world/nodeEntity"]

_MODULES["src/world/routeManager"] = function()
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
                -- 节点保留至少 1 粒驻扎微粒
                if fromNode.particles > 1 then
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
        -- 敌对交火与侵蚀
        if node.particles > 0 then
            local defenseDamp = (node.isDefensive and 0.5 or 1.0)
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

end
_MODULES["world/routeManager"] = _MODULES["src/world/routeManager"]

_MODULES["src/world/combatResolver"] = function()
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
        color = color or 0xFFF43F5E
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

end
_MODULES["world/combatResolver"] = _MODULES["src/world/combatResolver"]

_MODULES["src/world/abilitySystem"] = function()
-- src/world/abilitySystem.lua
-- 战术符印权能执行器、法术冷却计时与战场逆转效果驱动

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")

local AbilitySystem = {
    deck = {},             -- 当前装配的4张卡片元数据
    cooldowns = { 0, 0, 0, 0 }
}

function AbilitySystem.InitDeck(cardIdList)
    AbilitySystem.deck = {}
    AbilitySystem.cooldowns = { 0, 0, 0, 0 }
    for i, id in ipairs(cardIdList) do
        if i <= 4 then
            local card = CardRegistry.GetCardById(id)
            if card then
                table.insert(AbilitySystem.deck, card)
            end
        end
    end
end

function AbilitySystem.UpdateCooldowns(dt)
    for i = 1, #AbilitySystem.cooldowns do
        if AbilitySystem.cooldowns[i] > 0 then
            AbilitySystem.cooldowns[i] = math.max(0, AbilitySystem.cooldowns[i] - dt)
        end
    end
end

-- 施放指定符印
function AbilitySystem.CastAbility(slotIndex, targetNodeId, nodes, routeManager, elapsedTime, onSparkCallback)
    local card = AbilitySystem.deck[slotIndex]
    if not card then return false, "未找到该符印" end

    if AbilitySystem.cooldowns[slotIndex] > 0 then
        return false, "符印权能仍在凝聚冷却中！"
    end

    local targetNode = nodes[targetNodeId + 1]
    if not targetNode then return false, "未选中合法灵穴" end

    if card.id == "anemo_shield" then
        -- 千风庇护：仅己方节点
        if targetNode.faction ~= "player" then
            return false, "【千风庇护】只能施加于我方灵穴！"
        end
        targetNode.protectedUntil = elapsedTime + card.duration
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        return true, "【千风庇护】生效！20秒内免疫侵蚀！"

    elseif card.id == "anemo_turb" then
        -- 千风湍流：需正在向外输送的己方节点
        if targetNode.faction ~= "player" or targetNode.routeTo == nil then
            return false, "【千风湍流】需要施加在正在向外输送的己方灵穴上！"
        end
        local route = routeManager.GetRouteFrom(targetNode.id)
        if route then
            route.boostedUntil = elapsedTime + card.duration
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【千风湍流】激发！地脉输送流速翻倍！"
        end
        return false, "未检测到活跃输出光轨"

    elseif card.id == "pyro_blast" then
        -- 轰轰烈焰：轰炸敌方据点
        if targetNode.faction ~= "enemy" and targetNode.particles <= 0 then
            return false, "【轰轰烈焰】只能轰击敌对势力据点！"
        end
        local eliminated = math.floor(targetNode.particles * 0.8)
        targetNode.particles = targetNode.particles - eliminated

        if onSparkCallback then
            for _ = 1, 10 do
                onSparkCallback(targetNode.x, targetNode.y, 0xFFFF3F20)
            end
        end

        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("SKILL_BLAST")
        return true, "【轰轰烈焰】轰爆了 " .. tostring(eliminated) .. " 粒敌对微粒！"

    elseif card.id == "hydro_bribe" then
        -- 摩拉律法：中立秒占，敌方削弱
        if targetNode.faction == "neutral" then
            targetNode.faction = "player"
            targetNode.control = 100
            targetNode.particles = 15
            targetNode.isDefensive = true
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【摩拉律法】生效！已直接同化掌管中立灵穴！"
        elseif targetNode.faction == "enemy" then
            targetNode.control = math.max(0, targetNode.control - 65)
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【摩拉律法】生效！瓦解敌方 65% 共鸣！"
        else
            return false, "不可对己方灵穴使用摩拉律法"
        end

    elseif card.id == "geo_wall" then
        -- 坚岩重嶂：己方据点坚盾加持，增加10微粒并固守20秒
        if targetNode.faction ~= "player" then
            return false, "【坚岩重嶂】只能施加于我方灵穴！"
        end
        targetNode.isDefensive = true
        targetNode.protectedUntil = elapsedTime + card.duration
        targetNode.particles = targetNode.particles + 10
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        return true, "【坚岩重嶂】磐岩升起！增生10微粒并展开20秒坚盾！"

    elseif card.id == "pyro_erosion" then
        -- 烈焰侵蚀：重创敌对据点并切断其输出航线
        if targetNode.faction ~= "enemy" then
            return false, "【烈焰侵蚀】只能施加于敌方灵穴！"
        end
        local cut = math.max(8, math.floor(targetNode.particles * 0.4))
        targetNode.particles = math.max(0, targetNode.particles - cut)
        if routeManager and routeManager.RemoveRouteFrom then
            routeManager.RemoveRouteFrom(targetNode.id, nodes)
        end
        if onSparkCallback then
            for _ = 1, 8 do
                onSparkCallback(targetNode.x, targetNode.y, 0xFFFF3F20)
            end
        end
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("SKILL_BLAST")
        return true, "【烈焰侵蚀】灼烧敌穴！削减 " .. cut .. " 微粒并截断其输出！"
    end

    return false, "未知符印效果"
end

return AbilitySystem

end
_MODULES["world/abilitySystem"] = _MODULES["src/world/abilitySystem"]

_MODULES["src/world/factionAI"] = function()
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

end
_MODULES["world/factionAI"] = _MODULES["src/world/factionAI"]

_MODULES["src/ui/visualRenderer"] = function()
-- src/ui/visualRenderer.lua
-- 纯 Lua 几何视觉渲染器（光轨条带变换、共鸣环填充、固守结界与导引线绘制）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local VisualRenderer = {}

-- 动态绘制/变换单条线段条带控件 (使用 width = dist, height = thickness, pivot = (0, 0.5), rotationZ = angle)
function VisualRenderer.SetLineTransform(lineCtrl, x1, y1, x2, y2, thickness, color)
    if not lineCtrl or not lineCtrl.alive then return end

    local dist = Layout.Distance(x1, y1, x2, y2)
    local angle = Layout.AngleDeg(x1, y1, x2, y2)

    lineCtrl.anchoredPositionX = x1
    lineCtrl.anchoredPositionY = y1
    lineCtrl.sizeDeltaX = dist
    lineCtrl.sizeDeltaY = thickness or 4
    lineCtrl.localRotationZ = angle

    if color then
        lineCtrl.imageColor = color
    end

    Layout.SetVisible(lineCtrl, true)
end

-- 更新所有活跃光轨与拖拽连线
function VisualRenderer.UpdateRoutes(routeCtrls, routes, nodes, dragLineCtrl, inputState, elapsedTime)
    -- 1. 活跃光轨
    local activeCount = #routes
    local maxCtrls = #routeCtrls

    for i = 1, maxCtrls do
        local ctrl = routeCtrls[i]
        if ctrl and ctrl.alive then
            if i <= activeCount then
                local r = routes[i]
                local nA = nodes[r.fromId + 1]
                local nB = nodes[r.toId + 1]

                if nA and nB then
                    local col = Layout.GetFactionColor(r.faction)
                    local thickness = 4
                    if nA.anomaly == "WIND_FLOW" or r.boostedUntil > elapsedTime then
                        col = Layout.PALETTE.ANEMO
                        thickness = 6
                    end
                    VisualRenderer.SetLineTransform(ctrl, nA.x, nA.y, nB.x, nB.y, thickness, col)
                else
                    Layout.SetVisible(ctrl, false)
                end
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end

    -- 2. 拖拽实时导引线
    if dragLineCtrl and dragLineCtrl.alive then
        if inputState.isDragging and inputState.dragSourceId ~= nil then
            local sourceNode = nodes[inputState.dragSourceId + 1]
            if sourceNode then
                VisualRenderer.SetLineTransform(
                    dragLineCtrl,
                    sourceNode.x, sourceNode.y,
                    inputState.dragCurrentX, inputState.dragCurrentY,
                    3,
                    Layout.PALETTE.GOLD
                )
            else
                Layout.SetVisible(dragLineCtrl, false)
            end
        else
            Layout.SetVisible(dragLineCtrl, false)
        end
    end
end

-- 更新地脉节点各层视觉呈现
function VisualRenderer.UpdateNodes(nodeUIList, nodes, elapsedTime)
    for i, node in ipairs(nodes) do
        local ui = nodeUIList[i]
        if ui then
            local factionColor = Layout.GetFactionColor(node.faction)

            -- 1. 固守结界环
            if ui.defenseRing and ui.defenseRing.alive then
                if node.isDefensive and node.routeTo == nil then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.GOLD_ALPHA
                elseif node.protectedUntil > elapsedTime then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.ANEMO
                else
                    Layout.SetVisible(ui.defenseRing, false)
                end
            end

            -- 2. 节点主体共鸣外环 (使用 SetFillRadial360 或 fillAmount 呈现 0%~100% 进度)
            if ui.resonanceRing and ui.resonanceRing.alive then
                ui.resonanceRing.imageColor = factionColor
                local progress = Layout.Clamp(node.control / 100, 0.05, 1.0)
                if ui.resonanceRing.SetFillRadial360 then
                    pcall(function()
                        ui.resonanceRing:SetFillRadial360(Enum.ImageFillRadialType.Top, progress)
                    end)
                else
                    ui.resonanceRing.fillAmount = progress
                end
            end

            -- 3. 兵力数值显示 (高对比度纯白亮色，帧级实时刷新)
            if ui.particleText and ui.particleText.alive then
                ui.particleText.text = tostring(math.floor(node.particles or 0))
                ui.particleText.fontColor = Layout.PALETTE.TEXT_LIGHT
                Layout.SetVisible(ui.particleText, true)
            end

            -- 4. 异象标识文本
            if ui.anomalyText and ui.anomalyText.alive then
                if node.anomaly == "AMBER_MINE" then
                    ui.anomalyText.text = "【石珀晶矿】"
                    ui.anomalyText.fontColor = Layout.PALETTE.AMBER
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "WIND_FLOW" then
                    ui.anomalyText.text = "【疾风流道】"
                    ui.anomalyText.fontColor = Layout.PALETTE.ANEMO
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "MIST_RUINS" then
                    ui.anomalyText.text = "【迷雾荒墟】"
                    ui.anomalyText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.anomalyText, true)
                else
                    Layout.SetVisible(ui.anomalyText, false)
                end
            end

            -- 5. 占领进度与状态标签 (占领中/动摇中/输送中/固守中/休眠中)
            if ui.statusText and ui.statusText.alive then
                if node.faction == "neutral" and (node.control > 0 or (node.contenderParticles and node.contenderParticles > 0)) then
                    local fName = (node.contenderFaction == "player") and "我方" or (node.contenderFaction == "enemy" and "敌方" or "")
                    local col = (node.contenderFaction == "player") and Layout.PALETTE.PLAYER or Layout.PALETTE.ENEMY
                    ui.statusText.text = string.format("[%s占领中 %d%%]", fName, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction ~= "neutral" and node.control < 100 then
                    local statusDesc = (node.faction == "player") and "敌袭动摇" or "我方攻克"
                    local col = (node.faction == "player") and Layout.PALETTE.ENEMY or Layout.PALETTE.PLAYER
                    ui.statusText.text = string.format("[%s %d%%]", statusDesc, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isIdle then
                    ui.statusText.text = "[腹地休眠]"
                    ui.statusText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isDefensive and node.routeTo == nil then
                    ui.statusText.text = "[驻阵固守]"
                    ui.statusText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.statusText, true)
                elseif node.routeTo ~= nil then
                    ui.statusText.text = "[输送中 ➔]"
                    ui.statusText.fontColor = factionColor
                    Layout.SetVisible(ui.statusText, true)
                else
                    Layout.SetVisible(ui.statusText, false)
                end
            end
        end
    end
end

return VisualRenderer

end
_MODULES["ui/visualRenderer"] = _MODULES["src/ui/visualRenderer"]

_MODULES["src/ui/dialoguePlayer"] = function()
-- src/ui/dialoguePlayer.lua
-- 开场逐字剧情演播器（阿贝多与派蒙台词演出、跳过与推进）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local DialoguePlayer = {
    DIALOGUES = {
        {
            speaker = "派蒙",
            color = Layout.PALETTE.GOLD,
            content = "哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！"
        },
        {
            speaker = "阿贝多",
            color = Layout.PALETTE.PLAYER,
            content = "呵呵，派蒙，这可不能吃。这是我和教令院学者共同复原的\n古代战争推衍法器——「地脉星图棋盘」。"
        },
        {
            speaker = "阿贝多",
            color = Layout.PALETTE.PLAYER,
            content = "盘面上每一个光点都象征着一处地脉灵穴，而流动的光尘则是纯净元素微粒。\n拖拽己方灵穴铺设光轨，轻点灵穴收拢防御。"
        },
        {
            speaker = "派蒙",
            color = Layout.PALETTE.GOLD,
            content = "听起来很有意思！旅行者，快调配你的战术符印，\n我们一起执掌星盘赢得推衍吧！"
        }
    },
    currentIndex = 1,
    charIndex = 0,
    charTimer = 0,
    isComplete = false,
    onFinished = nil
}

function DialoguePlayer.Init(onFinishedCallback)
    DialoguePlayer.currentIndex = 1
    DialoguePlayer.charIndex = 0
    DialoguePlayer.charTimer = 0
    DialoguePlayer.isComplete = false
    DialoguePlayer.onFinished = onFinishedCallback
end

function DialoguePlayer.GetCurrentLine()
    return DialoguePlayer.DIALOGUES[DialoguePlayer.currentIndex]
end

function DialoguePlayer.Update(dt, speakerTextCtrl, contentTextCtrl)
    if DialoguePlayer.isComplete then return end

    local line = DialoguePlayer.GetCurrentLine()
    if not line then
        DialoguePlayer.Finish()
        return
    end

    if speakerTextCtrl and speakerTextCtrl.alive then
        speakerTextCtrl.text = "【" .. line.speaker .. "】"
        if line.color then
            local col = type(line.color) == "number" and line.color or (Layout and Layout.ToColorInt and Layout.ToColorInt(line.color) or Layout.PALETTE.GOLD)
            pcall(function() speakerTextCtrl.fontColor = col end)
        end
    end


    DialoguePlayer.charTimer = DialoguePlayer.charTimer + dt
    if DialoguePlayer.charTimer >= 0.03 then
        DialoguePlayer.charTimer = 0
        local totalLen = utf8 and utf8.len(line.content) or string.len(line.content)
        if DialoguePlayer.charIndex < totalLen then
            DialoguePlayer.charIndex = DialoguePlayer.charIndex + 1
        end
    end

    if contentTextCtrl and contentTextCtrl.alive then
        -- 简易截取或直接呈现全段文字
        contentTextCtrl.text = line.content
    end
end

function DialoguePlayer.Next()
    if DialoguePlayer.currentIndex < #DialoguePlayer.DIALOGUES then
        DialoguePlayer.currentIndex = DialoguePlayer.currentIndex + 1
        DialoguePlayer.charIndex = 0
    else
        DialoguePlayer.Finish()
    end
end

function DialoguePlayer.Skip()
    DialoguePlayer.Finish()
end

function DialoguePlayer.Finish()
    DialoguePlayer.isComplete = true
    if DialoguePlayer.onFinished then
        DialoguePlayer.onFinished()
    end
end

return DialoguePlayer

end
_MODULES["ui/dialoguePlayer"] = _MODULES["src/ui/dialoguePlayer"]

_MODULES["src/ui/prepareView"] = function()
-- src/ui/prepareView.lua
-- 战前符印调配界面（12点权能预算、自选卡组装配、视觉差分效果与确认开启）

local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local PrepareView = {
    selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }, -- 初始预选 9 点预算 (2+3+4)
    maxBudget = 12,
    maxCards = 4,
    onStartMatch = nil,

    POOL_ORDER = {
        "anemo_shield",
        "anemo_turb",
        "pyro_blast",
        "hydro_bribe",
        "geo_wall",
        "pyro_erosion"
    }
}

function PrepareView.Init(onStartMatchCallback)
    PrepareView.selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }
    PrepareView.maxBudget = BalanceConfig.MAX_BUDGET or 12
    PrepareView.maxCards = 4
    if onStartMatchCallback then
        PrepareView.onStartMatch = onStartMatchCallback
    end
end

function PrepareView.GetUsedBudget()
    local sum = 0
    for _, id in ipairs(PrepareView.selectedIds) do
        local card = CardRegistry.GetCardById(id)
        if card then sum = sum + card.cost end
    end
    return sum
end

function PrepareView.IsCardSelected(cardId)
    for _, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then return true end
    end
    return false
end

function PrepareView.ToggleCard(cardId)
    -- 若已选，则反选移除
    for idx, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then
            table.remove(PrepareView.selectedIds, idx)
            return true, nil
        end
    end

    -- 尝试添加装配
    if #PrepareView.selectedIds >= PrepareView.maxCards then
        return false, string.format("最多仅能装配 %d 张战术符印！请先点击卸下已选符印。", PrepareView.maxCards)
    end

    local card = CardRegistry.GetCardById(cardId)
    if not card then return false, "未知符印类型！" end

    local currentUsed = PrepareView.GetUsedBudget()
    if (currentUsed + card.cost) > PrepareView.maxBudget then
        return false, string.format("权能预算不足！当前已用 %d 点，该符印需 %d 点（上限 %d 点）。", currentUsed, card.cost, PrepareView.maxBudget)
    end

    table.insert(PrepareView.selectedIds, cardId)
    return true, nil
end

-- 刷新调配界面差分视觉表现（边框高亮、背景深浅、角标切换与预算提示）
function PrepareView.Render(cardUIList, budgetTextCtrl, hintTextCtrl)
    if cardUIList then
        for idx, cardKey in ipairs(PrepareView.POOL_ORDER) do
            local ui = cardUIList[idx]
            local card = CardRegistry.GetCardById(cardKey)
            if ui and card then
                local isSel = PrepareView.IsCardSelected(cardKey)

                -- 1. 边框高光差分
                if ui.borderCtrl and ui.borderCtrl.alive then
                    ui.borderCtrl.imageColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(71, 85, 105, 255)
                end

                -- 2. 背景明暗差分
                if ui.bgCtrl and ui.bgCtrl.alive then
                    ui.bgCtrl.imageColor = isSel and Layout.MakeColor(30, 58, 95, 255) or Layout.MakeColor(15, 23, 42, 255)
                end

                -- 3. 名称文本差分
                if ui.nameCtrl and ui.nameCtrl.alive then
                    ui.nameCtrl.fontColor = isSel and Layout.PALETTE.TEXT_LIGHT or Layout.PALETTE.TEXT_MUTED
                end

                -- 4. 选中状态角标
                if ui.checkCtrl and ui.checkCtrl.alive then
                    ui.checkCtrl.text = isSel and "【✓ 已装配】" or "【点击装配】"
                    ui.checkCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(100, 116, 139, 255)
                end
            end
        end
    end

    local used = PrepareView.GetUsedBudget()
    local count = #PrepareView.selectedIds

    -- 5. 预算文字更新
    if budgetTextCtrl and budgetTextCtrl.alive then
        budgetTextCtrl.text = string.format("当前调配权能预算：%d / %d 点 （已装配 %d / %d 张）", used, PrepareView.maxBudget, count, PrepareView.maxCards)
    end

    -- 6. 卡组概要提示更新
    if hintTextCtrl and hintTextCtrl.alive then
        if count > 0 then
            local names = {}
            for _, id in ipairs(PrepareView.selectedIds) do
                local c = CardRegistry.GetCardById(id)
                if c then
                    table.insert(names, string.format("%s(%d点)", c.name, c.cost))
                end
            end
            hintTextCtrl.text = "已选符印：" .. table.concat(names, " + ")
        else
            hintTextCtrl.text = "尚未装配任何符印，请点击上方卡牌进行调配！"
        end
    end
end

function PrepareView.ConfirmAndStart()
    if #PrepareView.selectedIds == 0 then
        -- 兜底：若未选任何卡则自动装配推荐卡
        PrepareView.selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }
    end
    if PrepareView.onStartMatch then
        PrepareView.onStartMatch(PrepareView.selectedIds)
    end
end

return PrepareView

end
_MODULES["ui/prepareView"] = _MODULES["src/ui/prepareView"]

_MODULES["src/ui/hudView"] = function()
-- src/ui/hudView.lua
-- HUD 顶部掌控进度、倒计时、浮窗 Toast 播报与终局结算面板

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local HudView = {
    toastText = "",
    toastTimer = 0,
    isSettled = false,
    onRetry = nil
}

function HudView.Init(onRetryCallback)
    HudView.toastText = ""
    HudView.toastTimer = 0
    HudView.isSettled = false
    HudView.onRetry = onRetryCallback
end

function HudView.ShowToast(msg)
    HudView.toastText = msg or ""
    HudView.toastTimer = 2.5
end

function HudView.UpdateToast(dt, toastContainer, toastTextCtrl)
    if HudView.toastTimer > 0 then
        HudView.toastTimer = HudView.toastTimer - dt
        Layout.SetVisible(toastContainer, true)
        if toastTextCtrl and toastTextCtrl.alive then
            toastTextCtrl.text = HudView.toastText
        end
    else
        Layout.SetVisible(toastContainer, false)
    end
end

-- 更新顶部掌控条与计时
function HudView.UpdateTopBar(timeRemaining, nodes, playerPctCtrl, enemyPctCtrl, timerCtrl, barPlayerCtrl, barEnemyCtrl)
    local pNodes, eNodes = 0, 0
    local pParticles, eParticles = 0, 0

    for _, n in ipairs(nodes) do
        if n.faction == "player" then
            pNodes = pNodes + 1
            pParticles = pParticles + n.particles
        elseif n.faction == "enemy" then
            eNodes = eNodes + 1
            eParticles = eParticles + n.particles
        end
    end

    local pScore = pNodes * 100 + pParticles
    local eScore = eNodes * 100 + eParticles
    local total = pScore + eScore
    if total <= 0 then total = 1 end

    local pPct = math.floor(pScore / total * 100)
    local ePct = 100 - pPct

    if playerPctCtrl and playerPctCtrl.alive then
        playerPctCtrl.text = "我方掌控 " .. tostring(pPct) .. "%"
    end
    if enemyPctCtrl and enemyPctCtrl.alive then
        enemyPctCtrl.text = "敌方压制 " .. tostring(ePct) .. "%"
    end

    if barPlayerCtrl and barPlayerCtrl.alive then
        barPlayerCtrl.sizeDeltaX = math.max(10, math.floor(320 * (pPct / 100)))
    end
    if barEnemyCtrl and barEnemyCtrl.alive then
        barEnemyCtrl.sizeDeltaX = math.max(10, math.floor(320 * (ePct / 100)))
    end

    if timerCtrl and timerCtrl.alive then
        local t = math.max(0, math.floor(timeRemaining))
        local m = math.floor(t / 60)
        local s = t % 60
        timerCtrl.text = string.format("%02d:%02d", m, s)
    end
end

-- 显示终局结算
function HudView.ShowSettlement(isWin, nodes, elapsedTime, modalCtrl, titleCtrl, descCtrl, statsCtrl)
    HudView.isSettled = true
    Layout.SetVisible(modalCtrl, true)

    local pCount = 0
    local pParts = 0
    for _, n in ipairs(nodes) do
        if n.faction == "player" then
            pCount = pCount + 1
            pParts = pParts + n.particles
        end
    end

    local t = math.floor(elapsedTime)
    local timeStr = string.format("%02d:%02d", math.floor(t / 60), t % 60)

    if titleCtrl and titleCtrl.alive then
        if isWin then
            titleCtrl.text = "【推衍大捷·全域共鸣】"
            titleCtrl.fontColor = Layout.PALETTE.PLAYER
        else
            titleCtrl.text = "【推衍中止·灵脉耗竭】"
            titleCtrl.fontColor = Layout.PALETTE.ENEMY
        end
    end

    if descCtrl and descCtrl.alive then
        if isWin then
            descCtrl.text = "星盘之理尽在掌控，地脉灵流归于统御。全域敌对势力已被彻底肃清！"
        else
            descCtrl.text = "地脉紊乱，推衍消散。我方灵穴已全部失守，请重新注灵推演。"
        end
    end

    if statsCtrl and statsCtrl.alive then
        statsCtrl.text = string.format("占领灵穴：%d/%d  |  存活兵力：%d  |  耗时：%s", pCount, #nodes, pParts, timeStr)
    end
end

return HudView

end
_MODULES["ui/hudView"] = _MODULES["src/ui/hudView"]

_MODULES["src/ui/cardBar"] = function()
-- src/ui/cardBar.lua
-- 底部战术符印栏渲染（卡牌名称、权能能耗、冷却遮罩与选中态）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local CardBar = {}

function CardBar.Update(cardSlots, deck, cooldowns, selectedSlotIndex)
    for i = 1, 4 do
        local slot = cardSlots[i]
        local card = deck[i]
        local cd = cooldowns[i] or 0

        if slot and slot.container and slot.container.alive then
            if card then
                Layout.SetVisible(slot.container, true)

                if slot.nameCtrl and slot.nameCtrl.alive then
                    slot.nameCtrl.text = card.name
                end

                if slot.costCtrl and slot.costCtrl.alive then
                    slot.costCtrl.text = tostring(card.cost) .. "点"
                end

                if slot.borderCtrl and slot.borderCtrl.alive then
                    if selectedSlotIndex == i then
                        slot.borderCtrl.imageColor = Layout.PALETTE.GOLD
                    else
                        slot.borderCtrl.imageColor = card.badgeColor or Layout.PALETTE.TEXT_MUTED
                    end
                end

                -- 冷却遮罩
                if cd > 0 then
                    Layout.SetVisible(slot.maskCtrl, true)
                    if slot.cdTextCtrl and slot.cdTextCtrl.alive then
                        Layout.SetVisible(slot.cdTextCtrl, true)
                        slot.cdTextCtrl.text = string.format("%ds", math.ceil(cd))
                    end
                else
                    Layout.SetVisible(slot.maskCtrl, false)
                    Layout.SetVisible(slot.cdTextCtrl, false)
                end
            else
                Layout.SetVisible(slot.container, false)
            end
        end
    end
end

return CardBar

end
_MODULES["ui/cardBar"] = _MODULES["src/ui/cardBar"]


-- ========== MAIN ENTRYPOINT ==========
-- src/main.lua
-- 《星轨交错：地脉争锋》千星奇域 2D 俯视角即时战略游戏主控脚本

local BalanceConfig   = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local CardRegistry    = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local Layout          = require("default_import_file/src/core/layout") or require("src/core/layout")
local Runtime         = require("default_import_file/src/core/runtime") or require("src/core/runtime")
local Input           = require("default_import_file/src/core/input") or require("src/core/input")

local StarMap         = require("default_import_file/src/world/starMap") or require("src/world/starMap")
local NodeEntity      = require("default_import_file/src/world/nodeEntity") or require("src/world/nodeEntity")
local RouteManager    = require("default_import_file/src/world/routeManager") or require("src/world/routeManager")
local CombatResolver  = require("default_import_file/src/world/combatResolver") or require("src/world/combatResolver")
local AbilitySystem   = require("default_import_file/src/world/abilitySystem") or require("src/world/abilitySystem")
local FactionAI       = require("default_import_file/src/world/factionAI") or require("src/world/factionAI")

local VisualRenderer  = require("default_import_file/src/ui/visualRenderer") or require("src/ui/visualRenderer")
local DialoguePlayer  = require("default_import_file/src/ui/dialoguePlayer") or require("src/ui/dialoguePlayer")
local PrepareView     = require("default_import_file/src/ui/prepareView") or require("src/ui/prepareView")
local HudView         = require("default_import_file/src/ui/hudView") or require("src/ui/hudView")
local CardBar         = require("default_import_file/src/ui/cardBar") or require("src/ui/cardBar")

-- 全局游戏状态机枚举
local STATE_DIALOGUE   = "STATE_DIALOGUE"
local STATE_PREPARE    = "STATE_PREPARE"
local STATE_PLAYING    = "STATE_PLAYING"
local STATE_SETTLEMENT = "STATE_SETTLEMENT"

local gameState = {
    currentState   = STATE_DIALOGUE,
    elapsedTime    = 0,
    timeRemaining  = BalanceConfig.MATCH_DURATION,
    captureTimer   = 0,
    isGameOver     = false,
    nodes          = {}
}

-- UI 控件绑定容器
local UI = {
    root           = nil,
    cursorArea     = nil,
    dragLine       = nil,
    routeCtrls     = {},
    particleCtrls  = {},
    nodeUIList     = {},
    cardSlots      = {},

    -- 顶部 HUD
    playerPctText  = nil,
    enemyPctText   = nil,
    timerText      = nil,
    barPlayer      = nil,
    barEnemy       = nil,
    toastContainer = nil,
    toastText      = nil,

    -- 剧情弹窗
    dialogueModal  = nil,
    dlgSpeaker     = nil,
    dlgContent     = nil,
    dlgSkipBtn     = nil,
    dlgNextBtn     = nil,

    -- 战前构筑弹窗
    prepareModal   = nil,
    prepBudgetText = nil,
    prepStartBtn   = nil,

    -- 结算弹窗
    settleModal    = nil,
    settleTitle    = nil,
    settleDesc     = nil,
    settleStats    = nil,
    settleRetryBtn = nil
}

-- 初始化沙盘所有灵穴
local function InitNodes()
    gameState.nodes = {}
    for _, def in ipairs(StarMap.NODES_DEF) do
        table.insert(gameState.nodes, NodeEntity.Create(def))
    end
end

-- 胜负判定
local function CheckMatchEnd(isTimeout)
    if gameState.isGameOver then return end

    local pNodes, eNodes = 0, 0
    local pParts, eParts = 0, 0
    for _, n in ipairs(gameState.nodes) do
        if n.faction == "player" then
            pNodes = pNodes + 1
            pParts = pParts + n.particles
        elseif n.faction == "enemy" then
            eNodes = eNodes + 1
            eParts = eParts + n.particles
        end
    end

    local inFlightPlayer = 0
    local inFlightEnemy = 0
    for _, p in ipairs(RouteManager.movingParticles) do
        if p.faction == "player" then inFlightPlayer = inFlightPlayer + 1
        elseif p.faction == "enemy" then inFlightEnemy = inFlightEnemy + 1 end
    end

    if eNodes == 0 and inFlightEnemy == 0 then
        -- 玩家胜利
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowSettlement(true, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats)
    elseif pNodes == 0 and inFlightPlayer == 0 then
        -- 玩家失败
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        HudView.ShowSettlement(false, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats)
    elseif isTimeout then
        -- 6 分钟压哨结算
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        local isWin = (pNodes * 1000 + pParts * 10) >= (eNodes * 1000 + eParts * 10)
        HudView.ShowSettlement(isWin, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats)
    end
end

-- 深度递归查找指定名称的子控件
local function FindDeepChild(parent, name)
    if not parent or not parent.alive then return nil end
    local direct = parent:FindChild(name)
    if direct then return direct end
    local children = parent:GetChildren()
    if children then
        for _, child in ipairs(children) do
            local found = FindDeepChild(child, name)
            if found then return found end
        end
    end
    return nil
end

-- 缓存控件树引用
local function CacheUIControls()
    local root = nil
    -- 1. 优先尝试脚本变量绑定（如在编辑器中配置了客户端控件ID变量）
    if script and script.GetParam then
        local pId = script:GetParam("RootCanvasID")
        if pId and type(pId) == "number" and game and game.GetClientUIControl then
            root = game.GetClientUIControl(pId)
        end
    end
    -- 2. 其次获取挂载宿主对象
    if not root and script and script.object then
        root = script.object
    end
    -- 3. 再次通过名称查找全局根
    if not root and game and game.FindClientUIRoot then
        root = game.FindClientUIRoot("StarlinkCanvas") or game.FindClientUIRoot("GameRoot")
    end
    -- 4. 兜底获取当前活跃的第一个根容器
    if not root and game and game.GetClientUIRoots then
        local roots = game.GetClientUIRoots()
        if roots and #roots > 0 then root = roots[1] end
    end
    UI.root = root

    -- 全局检测层与拖拽导引线
    UI.cursorArea = FindDeepChild(root, "GlobalCursorArea")
    UI.dragLine   = FindDeepChild(root, "DragLine")

    -- 光轨条带池
    UI.routeCtrls = {}
    local linksLayer = FindDeepChild(root, "LinksLayer")
    if linksLayer then
        for i = 1, 10 do
            local line = FindDeepChild(linksLayer, "RouteLine_" .. i)
            if line then table.insert(UI.routeCtrls, line) end
        end
    end

    -- 微粒对象池
    UI.particleCtrls = {}
    local pLayer = FindDeepChild(root, "ParticlesLayer")
    if pLayer then
        for i = 1, 80 do
            local p = FindDeepChild(pLayer, "P_" .. i)
            if p then table.insert(UI.particleCtrls, p) end
        end
    end
    Runtime.InitParticlePool(UI.particleCtrls)

    -- 5 座地脉灵穴 UI 组
    UI.nodeUIList = {}
    local nodesLayer = FindDeepChild(root, "NodesLayer")
    if nodesLayer then
        for i = 0, 4 do
            local grp = FindDeepChild(nodesLayer, "NodeGroup_" .. i)
            if grp then
                table.insert(UI.nodeUIList, {
                    group        = grp,
                    defenseRing  = FindDeepChild(grp, "DefenseRing"),
                    baseDisc     = FindDeepChild(grp, "BaseDisc"),
                    resonanceRing= FindDeepChild(grp, "ResonanceRing"),
                    titleText    = FindDeepChild(grp, "TitleText"),
                    particleText = FindDeepChild(grp, "ParticleText"),
                    anomalyText  = FindDeepChild(grp, "AnomalyText"),
                    statusText   = FindDeepChild(grp, "StatusText")
                })
            end
        end
    end

    -- 顶部 HUD
    local hud = FindDeepChild(root, "HudLayer")
    if hud then
        UI.playerPctText  = FindDeepChild(hud, "HudPlayerPct")
        UI.enemyPctText   = FindDeepChild(hud, "HudEnemyPct")
        UI.timerText      = FindDeepChild(hud, "HudTimer")
        UI.barPlayer      = FindDeepChild(hud, "BarPlayer")
        UI.barEnemy       = FindDeepChild(hud, "BarEnemy")
        UI.toastContainer = FindDeepChild(hud, "ToastContainer")
        if UI.toastContainer then
            UI.toastText  = FindDeepChild(UI.toastContainer, "ToastText")
        end

        -- 4 战术符印槽
        UI.cardSlots = {}
        for j = 1, 4 do
            local slotGrp = FindDeepChild(hud, "CardSlot_" .. j)
            if slotGrp then
                table.insert(UI.cardSlots, {
                    container  = slotGrp,
                    borderCtrl = FindDeepChild(slotGrp, "Border"),
                    nameCtrl   = FindDeepChild(slotGrp, "NameText"),
                    costCtrl   = FindDeepChild(slotGrp, "CostText"),
                    maskCtrl   = FindDeepChild(slotGrp, "CdMask"),
                    cdTextCtrl = FindDeepChild(slotGrp, "CdText")
                })
            end
        end
    end

    -- 剧情弹窗
    UI.dialogueModal = FindDeepChild(root, "DialogueModal")
    if UI.dialogueModal then
        UI.dlgSpeaker = FindDeepChild(UI.dialogueModal, "DlgSpeaker")
        UI.dlgContent = FindDeepChild(UI.dialogueModal, "DlgContent")
        UI.dlgSkipBtn = FindDeepChild(UI.dialogueModal, "DlgSkipBtn")
        UI.dlgNextBtn = FindDeepChild(UI.dialogueModal, "DlgNextBtn")
    end

    -- 战前调配弹窗
    UI.prepareModal = FindDeepChild(root, "PrepareModal")
    UI.prepCards = {}
    if UI.prepareModal then
        UI.prepBudgetText = FindDeepChild(UI.prepareModal, "PrepBudgetText")
        UI.prepHint       = FindDeepChild(UI.prepareModal, "PrepHint")
        UI.prepTitle      = FindDeepChild(UI.prepareModal, "PrepTitle")
        UI.prepStartBtn   = FindDeepChild(UI.prepareModal, "PrepStartBtn")
        for k = 1, 6 do
            local cardBtn = FindDeepChild(UI.prepareModal, "PrepCard_" .. k)
            if cardBtn then
                table.insert(UI.prepCards, {
                    button     = cardBtn,
                    checkCtrl  = FindDeepChild(cardBtn, "CheckTag"),
                    costCtrl   = FindDeepChild(cardBtn, "CostText"),
                    descCtrl   = FindDeepChild(cardBtn, "DescText"),
                    nameCtrl   = FindDeepChild(cardBtn, "NameText"),
                    bgCtrl     = FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 结算弹窗
    UI.settleModal = FindDeepChild(root, "SettleModal")
    if UI.settleModal then
        UI.settleTitle    = FindDeepChild(UI.settleModal, "SettleTitle")
        UI.settleDesc     = FindDeepChild(UI.settleModal, "SettleDesc")
        UI.settleStats    = FindDeepChild(UI.settleModal, "SettleStats")
        UI.settleRetryBtn = FindDeepChild(UI.settleModal, "SettleRetryBtn")
    end
end

-- 提取光标事件位置助手
local function GetEventPos(data)
    if not data then return 0, 0 end
    if data.GetUIPos then
        local ok, pos, maybeY = pcall(function() return data:GetUIPos() end)
        if ok then
            if type(pos) == "table" then
                return pos[1] or pos.x or 0, pos[2] or pos.y or 0
            elseif type(pos) == "number" then
                return pos, maybeY or 0
            end
        end
    end
    if type(data.x) == "number" and type(data.y) == "number" then
        return data.x, data.y
    end
    if type(data.positionX) == "number" and type(data.positionY) == "number" then
        return data.positionX, data.positionY
    end
    return 0, 0
end

-- 注册所有交互监听
local function SetupEventHandlers()
    -- 1. 全屏光标事件 (连线与轻点)
    if UI.cursorArea and UI.cursorArea.AddCursorEventListener then
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDown, function(data)
            local x, y = GetEventPos(data)
            Input.OnCursorDown(x, y, gameState.nodes)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDrag, function(data)
            local x, y = GetEventPos(data)
            Input.OnCursorDrag(x, y)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorUp, function(data)
            local x, y = GetEventPos(data)
            Input.OnCursorUp(x, y, gameState.nodes)
        end)
    end

    -- 2. 输入事件回调分发
    Input.onNodeClicked = function(nodeId)
        local node = gameState.nodes[nodeId + 1]
        if node and node.faction == "player" then
            if node.routeTo ~= nil then
                RouteManager.RemoveRouteFrom(node.id, gameState.nodes)
                node.isDefensive = true
                BalanceConfig.PlayAudioSafe("ROUTE_CUT")
                HudView.ShowToast("【固守结界已展开】" .. node.name .. " 损耗削减 50%！")
            else
                node.isDefensive = not node.isDefensive
                if node.isDefensive then
                    HudView.ShowToast("【固守结界已展开】" .. node.name .. " 损伤削减 50%！")
                else
                    HudView.ShowToast("【解除驻防】" .. node.name .. " 待命准备输送。")
                end
            end
        end
    end

    Input.onRouteCreated = function(fromId, toId)
        local ok, msg = RouteManager.SetRoute(fromId, toId, "player", gameState.nodes)
        if ok then
            local nA = gameState.nodes[fromId + 1]
            local nB = gameState.nodes[toId + 1]
            HudView.ShowToast("灵流通道已建立：" .. nA.name .. " ➔ " .. nB.name)
        elseif msg then
            HudView.ShowToast(msg)
        end
    end

    Input.onCardCast = function(slotIndex, targetNodeId)
        local ok, msg = AbilitySystem.CastAbility(
            slotIndex,
            targetNodeId,
            gameState.nodes,
            RouteManager,
            gameState.elapsedTime,
            function(x, y, col) CombatResolver.AddSpark(x, y, col) end
        )
        if msg then HudView.ShowToast(msg) end
    end

    -- 3. 剧情按钮监听
    if UI.dlgNextBtn and UI.dlgNextBtn.AddCursorEventListener then
        UI.dlgNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Next()
        end)
    end
    if UI.dlgSkipBtn and UI.dlgSkipBtn.AddCursorEventListener then
        UI.dlgSkipBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Skip()
        end)
    end

    -- 4. 战前调配卡牌点击选择与差分渲染
    for idx, cardUI in ipairs(UI.prepCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
            local cardKey = PrepareView.POOL_ORDER[idx]
            cardUI.button:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                local ok, err = PrepareView.ToggleCard(cardKey)
                if not ok and err then
                    HudView.ShowToast(err)
                end
                PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
            end)
        end
    end

    if UI.prepStartBtn and UI.prepStartBtn.AddCursorEventListener then
        UI.prepStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            PrepareView.ConfirmAndStart()
        end)
    end

    -- 5. 符印槽位点击选择 (冷却中拦截)
    for idx, slot in ipairs(UI.cardSlots) do
        if slot.container and slot.container.AddCursorEventListener then
            slot.container:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                if gameState.currentState == STATE_PLAYING then
                    if AbilitySystem.cooldowns[idx] and AbilitySystem.cooldowns[idx] > 0 then
                        local card = AbilitySystem.deck[idx]
                        local name = card and card.name or "符印"
                        HudView.ShowToast(string.format("【%s】仍在冷却中（还剩 %d 秒）", name, math.ceil(AbilitySystem.cooldowns[idx])))
                        return
                    end
                    if Input.GetSelectedCard() == idx then
                        Input.ClearSelectedCard()
                    else
                        Input.SetSelectedCard(idx)
                    end
                end
            end)
        end
    end

    -- 6. 重试按钮 (重开时重置并返回符印调配环节)
    if UI.settleRetryBtn and UI.settleRetryBtn.AddCursorEventListener then
        UI.settleRetryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            print("[Starlink] 玩家选择重新演练，重置战场并返回战前调配环节...")
            InitNodes()
            RouteManager.Init()
            CombatResolver.Init()
            gameState.elapsedTime = 0
            gameState.timeRemaining = BalanceConfig.MATCH_DURATION
            gameState.isGameOver = false
            AbilitySystem.cooldowns = { 0, 0, 0, 0 }

            -- 隐藏结算弹窗，打开战前调配弹窗
            Layout.SetVisible(UI.settleModal, false)
            Layout.SetVisible(UI.prepareModal, true)
            gameState.currentState = STATE_PREPARE

            -- 重新初始化调配界面并刷新差分呈现
            PrepareView.Init(function(selectedDeck)
                print("[Starlink] 战前构筑完成，开启动态推演！")
                AbilitySystem.InitDeck(selectedDeck)
                Layout.SetVisible(UI.prepareModal, false)
                gameState.currentState = STATE_PLAYING
                HudView.ShowToast("【推衍开启】铺设光轨，争夺中立灵穴！")
            end)
            PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
            HudView.ShowToast("【重新演练】请调配本局战术符印！")
        end)
    end
end

--------------------------------------------------------------------------------
-- 千星沙箱标准客户端脚本生命周期钩子
--------------------------------------------------------------------------------

function OnInit()
    print("[Starlink] OnInit: 开始装配 2D 纯代码推衍沙盘...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    CacheUIControls()
    InitNodes()
    RouteManager.Init()
    CombatResolver.Init()

    -- 初始化剧情回调 (演播完毕后进入符印调配并初始化差分样式)
    DialoguePlayer.Init(function()
        print("[Starlink] 剧情演播完毕，进入战前符印调配...")
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.prepareModal, true)
        gameState.currentState = STATE_PREPARE
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
    end)

    -- 初始化战前构筑回调
    PrepareView.Init(function(selectedDeck)
        print("[Starlink] 战前构筑完成，开启动态推演！")
        AbilitySystem.InitDeck(selectedDeck)
        Layout.SetVisible(UI.prepareModal, false)
        gameState.currentState = STATE_PLAYING
        HudView.ShowToast("【推衍开启】铺设光轨，争夺中立灵穴！")
    end)

    -- 初始化 HUD
    HudView.Init()

    -- 首次初始画面渲染填充 (确保文字与状态在开局立即呈现)
    VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
    CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)

    -- 注册输入
    SetupEventHandlers()
    print("[Starlink] OnInit: 装配完成！")
end

function OnStart()
    print("[Starlink] OnStart: 启动剧情状态...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    gameState.currentState = STATE_DIALOGUE
    Layout.SetVisible(UI.dialogueModal, true)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.settleModal, false)
end

function OnUpdate(dt)
    if gameState.currentState == STATE_DIALOGUE then
        DialoguePlayer.Update(dt, UI.dlgSpeaker, UI.dlgContent)

    elseif gameState.currentState == STATE_PREPARE then
        if not gameState._prepRendered then
            gameState._prepRendered = true
            PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
        end

    elseif gameState.currentState == STATE_PLAYING then
        gameState.elapsedTime = gameState.elapsedTime + dt
        gameState.timeRemaining = gameState.timeRemaining - dt

        if not gameState._lastHeartbeat or (gameState.elapsedTime - gameState._lastHeartbeat >= 2.0) then
            gameState._lastHeartbeat = gameState.elapsedTime
            local p0 = gameState.nodes[1]
            local n2 = gameState.nodes[3]
            local e4 = gameState.nodes[5]
            print(string.format("[Starlink Battle] t=%.1fs, routes=%d, flying=%d | 枢纽0:%d, 隘口2:%d(ctrl:%d), 敌垒4:%d",
                gameState.elapsedTime, #RouteManager.routes, #RouteManager.movingParticles,
                p0 and p0.particles or 0, n2 and n2.particles or 0, n2 and n2.control or 0, e4 and e4.particles or 0
            ))
        end

        -- 1. 灵穴微粒孕育
        for _, n in ipairs(gameState.nodes) do
            NodeEntity.TickSpawn(n, dt, gameState.nodes, gameState.elapsedTime)
        end

        -- 2. 共鸣度连续步进 (0.8s 周期)
        gameState.captureTimer = gameState.captureTimer + dt
        if gameState.captureTimer >= BalanceConfig.CAPTURE_INTERVAL then
            gameState.captureTimer = 0
            for _, n in ipairs(gameState.nodes) do
                NodeEntity.TickCapture(
                    n,
                    gameState.elapsedTime,
                    function(capturedNode)
                        HudView.ShowToast("【" .. capturedNode.name .. "】已被 " .. (capturedNode.faction == "player" and "我方" or "敌方") .. " 完全掌控！")
                        CheckMatchEnd()
                    end,
                    function(lostNode)
                        HudView.ShowToast("【" .. lostNode.name .. "】原统治动摇，已沦为中立争夺！")
                    end
                )
            end
        end

        -- 3. 物流发射与微粒流动
        RouteManager.Update(dt, gameState.nodes, gameState.elapsedTime, function(hitNode)
            CombatResolver.AddSpark(hitNode.x, hitNode.y)
        end)

        -- 4. 战火与威胁判定
        CombatResolver.Update(dt, gameState.nodes, RouteManager.movingParticles)

        -- 5. 敌方 AI 推进
        FactionAI.Update(dt, gameState.nodes, RouteManager)

        -- 6. 符印冷却计时
        AbilitySystem.UpdateCooldowns(dt)

        -- 7. 纯代码视觉渲染刷新
        Runtime.UpdateParticles(RouteManager.movingParticles, Layout.GetFactionColor)
        VisualRenderer.UpdateRoutes(UI.routeCtrls, RouteManager.routes, gameState.nodes, UI.dragLine, Input, gameState.elapsedTime)
        VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, gameState.elapsedTime)
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, Input.GetSelectedCard())
        HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

        -- 8. 胜负检定
        if gameState.timeRemaining <= 0 then
            CheckMatchEnd(true)
        else
            CheckMatchEnd(false)
        end

    elseif gameState.currentState == STATE_SETTLEMENT then
        -- 结算停顿时仅维持 Toast 与动效衰减
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)
    end
end

