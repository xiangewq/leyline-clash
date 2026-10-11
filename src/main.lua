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
    if UI.prepareModal then
        UI.prepBudgetText = FindDeepChild(UI.prepareModal, "PrepBudgetText")
        UI.prepStartBtn   = FindDeepChild(UI.prepareModal, "PrepStartBtn")
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

    -- 4. 战前调配确认按钮
    if UI.prepStartBtn and UI.prepStartBtn.AddCursorEventListener then
        UI.prepStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            PrepareView.ConfirmAndStart()
        end)
    end

    -- 5. 符印槽位点击选择
    for idx, slot in ipairs(UI.cardSlots) do
        if slot.container and slot.container.AddCursorEventListener then
            slot.container:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                if gameState.currentState == STATE_PLAYING then
                    if Input.GetSelectedCard() == idx then
                        Input.ClearSelectedCard()
                    else
                        Input.SetSelectedCard(idx)
                    end
                end
            end)
        end
    end

    -- 6. 重试按钮
    if UI.settleRetryBtn and UI.settleRetryBtn.AddCursorEventListener then
        UI.settleRetryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            -- 重新开启一局
            InitNodes()
            RouteManager.Init()
            CombatResolver.Init()
            gameState.elapsedTime = 0
            gameState.timeRemaining = BalanceConfig.MATCH_DURATION
            gameState.isGameOver = false
            gameState.currentState = STATE_PLAYING
            Layout.SetVisible(UI.settleModal, false)
            HudView.ShowToast("【重新注灵】对局开始，执掌地脉星盘！")
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

    -- 初始化剧情回调
    DialoguePlayer.Init(function()
        print("[Starlink] 剧情演播完毕，进入战前符印调配...")
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.prepareModal, true)
        gameState.currentState = STATE_PREPARE
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
        if UI.prepBudgetText and UI.prepBudgetText.alive then
            local used = PrepareView.GetUsedBudget()
            UI.prepBudgetText.text = string.format("当前调配权能预算：%d / 12 点", used)
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
