-- src/main.lua
-- 《星轨交错：地脉争锋》千星奇域 2D 俯视角即时战略游戏主控脚本
-- 支持模式选择（剧情模式/挑战模式）、5大关卡章节推衍、2~4方大乱斗与动态权能预算阶梯

local BalanceConfig   = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local CardRegistry    = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local ChapterConfig   = require("default_import_file/src/data/chapterConfig") or require("src/data/chapterConfig")
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
local ModeSelectView  = require("default_import_file/src/ui/modeSelectView") or require("src/ui/modeSelectView")
local ChapterSelectView = require("default_import_file/src/ui/chapterSelectView") or require("src/ui/chapterSelectView")

-- 全局游戏状态机枚举
local STATE_MODE_SELECT    = "STATE_MODE_SELECT"
local STATE_CHAPTER_SELECT = "STATE_CHAPTER_SELECT"
local STATE_DIALOGUE       = "STATE_DIALOGUE"
local STATE_PREPARE        = "STATE_PREPARE"
local STATE_COUNTDOWN      = "STATE_COUNTDOWN"   -- 战前3秒倒计时 (3、2、1、开始)
local STATE_PLAYING        = "STATE_PLAYING"
local STATE_SETTLEMENT     = "STATE_SETTLEMENT"

local gameState = {
    currentState   = STATE_MODE_SELECT,
    elapsedTime    = 0,
    timeRemaining  = BalanceConfig.MATCH_DURATION,
    captureTimer   = 0,
    countdownTimer = 0,
    isGameOver     = false,
    nodes          = {}
}

-- UI 控件绑定容器
local UI = {
    root           = nil,
    cursorArea     = nil,
    dragLine       = nil,
    routeCtrls     = {},
    staticLinkCtrls= {},
    particleCtrls  = {},
    nodeUIList     = {},
    cardSlots      = {},

    -- 模式选择弹窗
    modeSelectModal  = nil,
    modeStoryBtn     = nil,
    modeChallengeBtn = nil,

    -- 章节选择弹窗
    chapterSelectModal = nil,
    chapterCards       = {},
    chapDesc           = nil,
    chapTitle          = nil,
    chapStartBtn       = nil,
    chapStartTxt       = nil,
    chapBackBtn        = nil,

    -- 顶部 HUD
    playerPctText  = nil,
    enemyPctText   = nil,
    timerText      = nil,
    barPlayer      = nil,
    barEnemy       = nil,
    toastContainer = nil,
    toastText      = nil,

    -- 战前3秒倒计时
    countdownModal = nil,
    countdownText  = nil,
    countdownSub   = nil,

    -- 左上角特殊灵穴说明与右上角操作说明
    hudAnomalyBox  = nil,
    hudAnomalyTitle= nil,
    hudAnomalyDesc = nil,
    hudGuideBox    = nil,
    hudGuideTitle  = nil,
    hudGuideDesc   = nil,

    -- 剧情弹窗
    dialogueModal  = nil,
    dlgSpeaker     = nil,
    dlgContent     = nil,
    dlgSkipBtn     = nil,
    dlgNextBtn     = nil,

    -- 模式选择弹窗
    modeSelectModal    = nil,
    modeStoryBtn       = nil,
    modeChallengeBtn   = nil,
    modeQuitBtn        = nil,

    -- 战前构筑弹窗
    prepareModal   = nil,
    prepBudgetText = nil,
    prepHint       = nil,
    prepTitle      = nil,
    prepStartBtn   = nil,
    prepCards      = {},

    -- 结算弹窗
    settleModal      = nil,
    settleTitle      = nil,
    settleDesc       = nil,
    settleStats      = nil,
    settleNextBtn    = nil,
    settleRetryBtn   = nil,
    settleChapBtn    = nil,
    settleRestartBtn = nil,
    settleQuitBtn    = nil
}

-- 初始化沙盘所有灵穴实体
local function InitNodes()
    gameState.nodes = {}
    for _, def in ipairs(StarMap.NODES_DEF) do
        table.insert(gameState.nodes, NodeEntity.Create(def))
    end
end

-- 胜负判定 (支持 2~4 方多阵营混战)
local function CheckMatchEnd(isTimeout)
    if gameState.isGameOver then return end

    local pNodes, pParts = 0, 0
    local enemyFactionScores = {}

    for _, n in ipairs(gameState.nodes) do
        if n.faction == "player" then
            pNodes = pNodes + 1
            pParts = pParts + n.particles
        elseif n.faction ~= "neutral" then
            local fac = n.faction
            if not enemyFactionScores[fac] then
                enemyFactionScores[fac] = { nodes = 0, parts = 0 }
            end
            enemyFactionScores[fac].nodes = enemyFactionScores[fac].nodes + 1
            enemyFactionScores[fac].parts = enemyFactionScores[fac].parts + n.particles
        end
    end

    local inFlightPlayer = 0
    local inFlightEnemy = {}
    for _, p in ipairs(RouteManager.movingParticles) do
        if p.faction == "player" then
            inFlightPlayer = inFlightPlayer + 1
        elseif p.faction ~= "neutral" then
            inFlightEnemy[p.faction] = (inFlightEnemy[p.faction] or 0) + 1
        end
    end

    -- 判定所有敌对势力是否已全部被歼灭
    local allEnemiesDefeated = true
    for fac, data in pairs(enemyFactionScores) do
        local flying = inFlightEnemy[fac] or 0
        if data.nodes > 0 or flying > 0 then
            allEnemiesDefeated = false
            break
        end
    end
    for fac, cnt in pairs(inFlightEnemy) do
        if cnt > 0 then
            allEnemiesDefeated = false
            break
        end
    end

    if allEnemiesDefeated then
        -- 玩家大获全胜！
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        ChapterSelectView.UnlockNextStage(StarMap.currentStage)
        BalanceConfig.StopAllAudios()
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowSettlement(true, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    elseif pNodes == 0 and inFlightPlayer == 0 then
        -- 玩家兵力全军覆没
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        BalanceConfig.StopAllAudios()
        BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        HudView.ShowSettlement(false, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    elseif isTimeout then
        -- 倒计时归零压哨决胜
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        local pScore = pNodes * 1000 + pParts * 10
        local isWin = true
        for _, data in pairs(enemyFactionScores) do
            local eScore = data.nodes * 1000 + data.parts * 10
            if eScore >= pScore then
                isWin = false
                break
            end
        end
        BalanceConfig.StopAllAudios()
        if isWin then
            ChapterSelectView.UnlockNextStage(StarMap.currentStage)
            BalanceConfig.PlayAudioSafe("MATCH_WIN")
        else
            BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        end
        HudView.ShowSettlement(isWin, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
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
    if script and script.GetParam then
        local pId = script:GetParam("RootCanvasID")
        if pId and type(pId) == "number" and game and game.GetClientUIControl then
            root = game.GetClientUIControl(pId)
        end
    end
    if not root and script and script.object then
        root = script.object
    end
    if not root and game and game.FindClientUIRoot then
        root = game.FindClientUIRoot("StarlinkCanvas") or game.FindClientUIRoot("GameRoot")
    end
    if not root and game and game.GetClientUIRoots then
        local roots = game.GetClientUIRoots()
        if roots and #roots > 0 then root = roots[1] end
    end
    UI.root = root

    -- 全局检测层与拖拽导引线
    UI.cursorArea = FindDeepChild(root, "GlobalCursorArea")
    UI.dragLine   = FindDeepChild(root, "DragLine")

    -- 模式选择弹窗
    UI.modeSelectModal  = FindDeepChild(root, "ModeSelectModal")
    if UI.modeSelectModal then
        UI.modeStoryBtn     = FindDeepChild(UI.modeSelectModal, "ModeStoryBtn")
        UI.modeChallengeBtn = FindDeepChild(UI.modeSelectModal, "ModeChallengeBtn")
        UI.modeQuitBtn      = FindDeepChild(UI.modeSelectModal, "ModeQuitBtn")
    end

    -- 关卡章节选择弹窗
    UI.chapterSelectModal = FindDeepChild(root, "ChapterSelectModal")
    UI.chapterCards = {}
    if UI.chapterSelectModal then
        UI.chapDesc     = FindDeepChild(UI.chapterSelectModal, "ChapterDesc")
        UI.chapTitle    = FindDeepChild(UI.chapterSelectModal, "ChapterTitle")
        UI.chapStartBtn = FindDeepChild(UI.chapterSelectModal, "ChapterStartBtn")
        if UI.chapStartBtn then
            UI.chapStartTxt = FindDeepChild(UI.chapStartBtn, "Text")
        end
        UI.chapBackBtn  = FindDeepChild(UI.chapterSelectModal, "ChapterBackBtn")

        for idx = 1, 5 do
            local cardBtn = FindDeepChild(UI.chapterSelectModal, "ChapterCard_" .. idx)
            if cardBtn then
                table.insert(UI.chapterCards, {
                    button     = cardBtn,
                    tagCtrl    = FindDeepChild(cardBtn, "TagText"),
                    infoCtrl   = FindDeepChild(cardBtn, "InfoText"),
                    budgetCtrl = FindDeepChild(cardBtn, "BudgetText"),
                    titleCtrl  = FindDeepChild(cardBtn, "TitleText"),
                    bgCtrl     = FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 光轨条带池与静态连线池 (25 条动态光轨 + 40 条静态底轨)
    UI.routeCtrls = {}
    UI.staticLinkCtrls = {}
    UI.linksLayer = FindDeepChild(root, "LinksLayer")
    if UI.linksLayer then
        for i = 1, 25 do
            local line = FindDeepChild(UI.linksLayer, "RouteLine_" .. i)
            if line then table.insert(UI.routeCtrls, line) end
        end
        for i = 0, 39 do
            local sLine = FindDeepChild(UI.linksLayer, "StaticLink_" .. i)
            if sLine then table.insert(UI.staticLinkCtrls, sLine) end
        end
    end

    -- 微粒对象池 (120个)
    UI.particleCtrls = {}
    UI.particlesLayer = FindDeepChild(root, "ParticlesLayer")
    if UI.particlesLayer then
        for i = 1, 120 do
            local p = FindDeepChild(UI.particlesLayer, "P_" .. i)
            if p then table.insert(UI.particleCtrls, p) end
        end
    end
    Runtime.InitParticlePool(UI.particleCtrls)

    -- 22 座地脉灵穴 UI 组 (支持全5关剧情模式最大18座并预留富余预算)
    UI.nodeUIList = {}
    UI.nodesLayer = FindDeepChild(root, "NodesLayer")
    if UI.nodesLayer then
        for i = 0, 21 do
            local grp = FindDeepChild(UI.nodesLayer, "NodeGroup_" .. i)
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
    UI.hudLayer = FindDeepChild(root, "HudLayer")
    local hud = UI.hudLayer
    if hud then
        UI.playerPctText  = FindDeepChild(hud, "HudPlayerPct")
        UI.enemyPctText   = FindDeepChild(hud, "HudEnemyPct")
        UI.timerText      = FindDeepChild(hud, "HudTimer")
        UI.barPlayer      = FindDeepChild(hud, "BarPlayer")
        UI.barEnemy       = FindDeepChild(hud, "BarEnemy")
        UI.toastContainer = FindDeepChild(root, "ToastContainer")
        if UI.toastContainer then
            UI.toastText  = FindDeepChild(UI.toastContainer, "ToastText")
        end

        -- 战前3秒倒计时弹窗
        UI.countdownModal = FindDeepChild(root, "CountdownModal")
        if UI.countdownModal then
            UI.countdownText = FindDeepChild(UI.countdownModal, "CountdownText")
            UI.countdownSub  = FindDeepChild(UI.countdownModal, "CountdownSub")
        end

        -- 左上角特殊灵穴说明与右上角操作指引
        UI.hudAnomalyBox   = FindDeepChild(hud, "HudAnomalyBox")
        if UI.hudAnomalyBox then
            UI.hudAnomalyTitle = FindDeepChild(UI.hudAnomalyBox, "AnomalyTitle")
            UI.hudAnomalyDesc  = FindDeepChild(UI.hudAnomalyBox, "AnomalyDesc")
        end
        UI.hudGuideBox     = FindDeepChild(hud, "HudGuideBox")
        if UI.hudGuideBox then
            UI.hudGuideTitle   = FindDeepChild(UI.hudGuideBox, "GuideTitle")
            UI.hudGuideDesc    = FindDeepChild(UI.hudGuideBox, "GuideDesc")
        end

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

    -- 常驻侧边导航栏 (除剧情演播外常驻于左上角)
    UI.quickNavLayer = FindDeepChild(root, "QuickNavLayer")
    if UI.quickNavLayer then
        UI.sideRestartBtn = FindDeepChild(UI.quickNavLayer, "SideRestartBtn")
        UI.sideSettleBtn  = FindDeepChild(UI.quickNavLayer, "SideSettleBtn")
    end

    -- 官方风格退出挑战 / 游玩结算二次确认弹窗
    UI.settleConfirmModal = FindDeepChild(root, "SettleConfirmModal")
    if UI.settleConfirmModal then
        UI.confirmResumeBtn  = FindDeepChild(UI.settleConfirmModal, "ConfirmResumeBtn")
        UI.confirmRestartBtn = FindDeepChild(UI.settleConfirmModal, "ConfirmRestartBtn")
        UI.confirmQuitBtn    = FindDeepChild(UI.settleConfirmModal, "ConfirmQuitBtn")
        UI.confirmDesc       = FindDeepChild(UI.settleConfirmModal, "ConfirmDesc")
        UI.confirmTitle      = FindDeepChild(UI.settleConfirmModal, "ConfirmTitle")
    end

    -- 结算弹窗
    UI.settleModal = FindDeepChild(root, "SettleModal")
    if UI.settleModal then
        UI.settleTitle      = FindDeepChild(UI.settleModal, "SettleTitle")
        UI.settleDesc       = FindDeepChild(UI.settleModal, "SettleDesc")
        UI.settleStats      = FindDeepChild(UI.settleModal, "SettleStats")
        UI.settleNextBtn    = FindDeepChild(UI.settleModal, "SettleNextBtn")
        UI.settleRetryBtn   = FindDeepChild(UI.settleModal, "SettleRetryBtn")
        UI.settleChapBtn    = FindDeepChild(UI.settleModal, "SettleChapterBtn")
        UI.settleRestartBtn = FindDeepChild(UI.settleModal, "SettleRestartBtn")
        UI.settleQuitBtn    = FindDeepChild(UI.settleModal, "SettleQuitBtn")
    end
end

-- 控制战斗核心层（灵穴、光轨、微粒、HUD）的可见性
local function SetGameplayLayersVisible(visible)
    Layout.SetVisible(UI.nodesLayer, visible)
    Layout.SetVisible(UI.linksLayer, visible)
    Layout.SetVisible(UI.particlesLayer, visible)
    Layout.SetVisible(UI.hudLayer, visible)
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

-- 载入并启动指定章节
local function StartStage(stageId)
    local chap = StarMap.LoadStage(stageId)
    print(string.format("[Starlink] 加载章节: 第 %d 关【%s】(节点数: %d, 权能预算: %d, 时限: %ds)", chap.id, chap.title, #chap.nodes, chap.budget, chap.duration))

    InitNodes()
    RouteManager.Init()
    CombatResolver.Init()
    AbilitySystem.cooldowns = { 0, 0, 0, 0 }

    -- 彻底清除旧关卡残留连线、微粒与拖拽线
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    gameState.elapsedTime   = 0
    gameState.timeRemaining = chap.duration or BalanceConfig.MATCH_DURATION
    gameState.isGameOver    = false

    -- 呈现战场沙盘层
    SetGameplayLayersVisible(true)

    -- 刷新沙盘节点与静态连线几何布局
    VisualRenderer.ApplyStageLayout(UI.nodeUIList, gameState.nodes, UI.staticLinkCtrls, StarMap.LINKS)
    VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()

    -- 立即刷新左上角地脉情报与右上角操作指引
    HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

    -- 隐藏其他面板，进入战前剧情
    Layout.SetVisible(UI.modeSelectModal, false)
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.countdownModal, false)
    CloseSettleConfirmModal()

    -- 剧情演播阶段隐藏侧边常驻导航按钮，剧情结束后重新显示
    Layout.SetVisible(UI.quickNavLayer, false)

    -- 1. 剧情演播
    DialoguePlayer.Init(chap.dialogues, function()
        print("[Starlink] 章节剧情完毕，进入战前符印调配...")
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.prepareModal, true)
        Layout.SetVisible(UI.quickNavLayer, true)
        gameState.currentState = STATE_PREPARE

        -- 2. 调配面板初始化 (动态预算)
        PrepareView.Init(chap.budget, function(selectedDeck)
            print("[Starlink] 战前符印装配完成，进入战前 3 秒倒计时...")
            AbilitySystem.InitDeck(selectedDeck)
            Layout.SetVisible(UI.prepareModal, false)
            Layout.SetVisible(UI.quickNavLayer, true)
            SetGameplayLayersVisible(true)

            -- 刷新左上角特殊灵穴说明与右上角战术操作指引
            HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

            -- 启动 3 秒倒计时 (3、2、1、开始)
            gameState.countdownTimer = 3.6
            gameState.currentState = STATE_COUNTDOWN
            Layout.SetVisible(UI.countdownModal, true)
            HudView.UpdateCountdown(gameState.countdownTimer, UI.countdownModal, UI.countdownText, UI.countdownSub)
            BalanceConfig.PlayAudioSafe("UI_CLICK")
        end)
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
    end)

    gameState.currentState = STATE_DIALOGUE
    Layout.SetVisible(UI.dialogueModal, true)
end

-- 关闭千星奇域退出挑战 / 游玩结算二次确认弹窗
local function CloseSettleConfirmModal()
    if UI.settleConfirmModal then
        Layout.SetVisible(UI.settleConfirmModal, false)
    end
end

-- 打开千星奇域退出挑战 / 游玩结算二次确认弹窗（动态提示当前进度与成功/失败判定预测）
local function OpenSettleConfirmModal()
    BalanceConfig.PlayAudioSafe("UI_CLICK")
    local completed4 = ChapterSelectView.HasCompletedFirst4Stages()
    local clearedCount = ChapterSelectView.GetClearedCount and ChapterSelectView.GetClearedCount() or 0
    if UI.confirmDesc and UI.confirmDesc.alive then
        if completed4 then
            UI.confirmDesc.text = string.format("已通关 %d/4 关 · 当前中断将判定为【大捷成功】", clearedCount)
            UI.confirmDesc.fontColor = Layout.PALETTE.GOLD
        else
            UI.confirmDesc.text = string.format("已通关 %d/4 关 · 未达成前4关，中断将判定为【失败】", clearedCount)
            UI.confirmDesc.fontColor = Layout.PALETTE.ENEMY
        end
    end
    if UI.settleConfirmModal then
        Layout.SetVisible(UI.settleConfirmModal, true)
    end
end

-- 触发千星奇域原生系统个人结算 (按规则判定成功/失败)
local function TriggerNativePersonalSettlement()
    CloseSettleConfirmModal()
    local completed4 = ChapterSelectView.HasCompletedFirst4Stages()
    local isSuccess = completed4
    local clearedCount = ChapterSelectView.GetClearedCount and ChapterSelectView.GetClearedCount() or (isSuccess and 4 or 0)
    print(string.format("[Starlink] 触发原生系统个人结算: completedFirst4Stages=%s (已通关%d关) => 结算状态: %s",
        tostring(completed4), clearedCount, isSuccess and "成功" or "失败"))

    gameState.isGameOver = true
    gameState.currentState = STATE_SETTLEMENT

    BalanceConfig.StopAllAudios()
    if isSuccess then
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowToast("【推衍圆满·结算成功】已达成前4关推衍，正在结算并退出...")
    else
        BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        HudView.ShowToast("【推衍未成·结算失败】未达成前4关推衍，已中断挑战...")
    end

    -- 停止战场动态
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    -- 展现终局全屏游玩结算演出（参考原神/千星奇域关卡结算弹窗大捷/未成界面）
    if UI.settleModal then
        Layout.SetVisible(UI.modeSelectModal, false)
        Layout.SetVisible(UI.chapterSelectModal, false)
        Layout.SetVisible(UI.prepareModal, false)
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.countdownModal, false)
        SetGameplayLayersVisible(false)
        HudView.ShowSettlement(isSuccess, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
        if UI.settleNextBtn then
            -- 如果是退出挑战结算，下一关按钮改为不可用或直接隐藏，保留重开模式与重新挑战
            Layout.SetVisible(UI.settleNextBtn, false)
        end
    end

    -- 上报千星奇域原生系统结算 (个人结算)
    if game then
        pcall(function()
            if game.ServerSignal then
                game.ServerSignal("SettlePersonalGame", {
                    isSuccess = isSuccess,
                    result = isSuccess and 1 or 0,
                    clearedCount = clearedCount,
                    currentStage = StarMap.currentStage
                })
                game.ServerSignal("QuitGame", {
                    isSuccess = isSuccess,
                    result = isSuccess and 1 or 0
                })
            end
        end)
        pcall(function()
            if game.SettleGame then
                game.SettleGame(isSuccess)
            end
        end)
        pcall(function()
            if game.QuitGame then
                game.QuitGame()
            end
        end)
    end
end

-- 重开模式：回退到模式选择界面，保留剧情模式关卡解锁与通关进度
local function HandleRestartToModeSelect()
    CloseSettleConfirmModal()
    print("[Starlink] 重开模式：回退到模式选择界面（保留剧情模式关卡进度: 已解锁第 " .. tostring(ChapterSelectView.unlockedStage) .. " 关）")
    BalanceConfig.PlayAudioSafe("UI_CLICK")
    BalanceConfig.StopAllAudios()
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    -- 隐藏所有战斗与演播面板
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.dialogueModal, false)
    Layout.SetVisible(UI.countdownModal, false)
    SetGameplayLayersVisible(false)

    -- 打开模式选择主面板并显示常驻快捷栏
    Layout.SetVisible(UI.modeSelectModal, true)
    Layout.SetVisible(UI.quickNavLayer, true)
    gameState.currentState = STATE_MODE_SELECT
    HudView.ShowToast("已返回模式选择界面，关卡进度已保留。")
end

-- 注册全屏与各面板交互监听
local function SetupEventHandlers()
    -- 辅助：静音原生按钮 clickAudioId，避免引擎底层默认点击音效与脚本 PlayAudioSafe 重叠双响
    local function SilenceButton(btn)
        if btn and btn.alive then
            pcall(function() btn.clickAudioId = 0 end)
        end
    end

    -- 1. 全屏光标事件 (连线与轻点)
    if UI.cursorArea and UI.cursorArea.AddCursorEventListener then
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDown, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
            local x, y = GetEventPos(data)
            Input.OnCursorDown(x, y, gameState.nodes)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDrag, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
            local x, y = GetEventPos(data)
            Input.OnCursorDrag(x, y)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorUp, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
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
        if ok then
            BalanceConfig.PlayAudioSafe("SKILL_BLAST")
            if msg then HudView.ShowToast(msg) end
        else
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            if msg then HudView.ShowToast("【释放失败】" .. msg) end
        end
        Input.ClearSelectedCard()
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    end

    Input.onCardCancelled = function(slotIndex)
        local card = AbilitySystem.deck[slotIndex]
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        HudView.ShowToast(string.format("【取消施法】%s", card and card.name or ""))
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    end

    -- 3. 模式选择按钮监听
    if UI.modeStoryBtn and UI.modeStoryBtn.AddCursorEventListener then
        SilenceButton(UI.modeStoryBtn)
        UI.modeStoryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            print("[Starlink] 玩家选择【剧情模式】，打开战役章节选择面板...")
            Layout.SetVisible(UI.modeSelectModal, false)
            Layout.SetVisible(UI.chapterSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_CHAPTER_SELECT
            ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
        end)
    end

    if UI.modeChallengeBtn and UI.modeChallengeBtn.AddCursorEventListener then
        SilenceButton(UI.modeChallengeBtn)
        UI.modeChallengeBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            print("[Starlink] 玩家点击【挑战模式】（筹备中提示）...")
            HudView.ShowToast("【挑战模式】正在筹备中，敬请期待！")
        end)
    end

    if UI.modeQuitBtn and UI.modeQuitBtn.AddCursorEventListener then
        SilenceButton(UI.modeQuitBtn)
        UI.modeQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            TriggerNativePersonalSettlement()
        end)
    end

    -- 4. 章节选择按钮监听
    for idx, cardUI in ipairs(UI.chapterCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
            SilenceButton(cardUI.button)
            cardUI.button:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                BalanceConfig.PlayAudioSafe("UI_CLICK")
                local ok, err = ChapterSelectView.SelectStage(idx)
                if not ok then
                    HudView.ShowToast(err or "该关卡尚未解锁！")
                else
                    ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
                end
            end)
        end
    end

    if UI.chapStartBtn and UI.chapStartBtn.AddCursorEventListener then
        SilenceButton(UI.chapStartBtn)
        UI.chapStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            StartStage(ChapterSelectView.selectedStage)
        end)
    end

    if UI.chapBackBtn and UI.chapBackBtn.AddCursorEventListener then
        SilenceButton(UI.chapBackBtn)
        UI.chapBackBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            Layout.SetVisible(UI.chapterSelectModal, false)
            Layout.SetVisible(UI.modeSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_MODE_SELECT
        end)
    end

    -- 5. 剧情按钮监听
    if UI.dlgNextBtn and UI.dlgNextBtn.AddCursorEventListener then
        SilenceButton(UI.dlgNextBtn)
        UI.dlgNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Next()
        end)
    end
    if UI.dlgSkipBtn and UI.dlgSkipBtn.AddCursorEventListener then
        SilenceButton(UI.dlgSkipBtn)
        UI.dlgSkipBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Skip()
        end)
    end

    -- 6. 战前调配卡牌点击选择
    for idx, cardUI in ipairs(UI.prepCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
            SilenceButton(cardUI.button)
            local cardKey = PrepareView.POOL_ORDER[idx]
            cardUI.button:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                local ok, action, cardId = PrepareView.ToggleCard(cardKey)
                local card = CardRegistry.GetCardById(cardKey)
                BalanceConfig.PlayAudioSafe("UI_CLICK")
                if not ok then
                    HudView.ShowToast(action or "调配失败")
                else
                    local used = PrepareView.GetUsedBudget()
                    local count = #PrepareView.selectedIds
                    if action == "equipped" then
                        HudView.ShowToast(string.format("【已装配】%s (耗能%d·CD%ds) | 预算 %d/%d，已选 %d/4 张", card and card.name or "符印", card and card.cost or 0, card and card.cd or 0, used, PrepareView.maxBudget, count))
                    elseif action == "unequipped" then
                        HudView.ShowToast(string.format("【已卸下】%s (归还%d) | 预算 %d/%d，已选 %d/4 张", card and card.name or "符印", card and card.cost or 0, used, PrepareView.maxBudget, count))
                    end
                end
                PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
            end)
        end
    end

    if UI.prepStartBtn and UI.prepStartBtn.AddCursorEventListener then
        SilenceButton(UI.prepStartBtn)
        UI.prepStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            local ok, err = PrepareView.ConfirmAndStart()
            if not ok and err then
                HudView.ShowToast(err)
            end
        end)
    end

    -- 7. 符印槽位点击选择
    for idx, slot in ipairs(UI.cardSlots) do
        if slot.container and slot.container.AddCursorEventListener then
            SilenceButton(slot.container)
            slot.container:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                if gameState.currentState == STATE_PLAYING then
                    local card = AbilitySystem.deck[idx]
                    if not card then return end

                    if AbilitySystem.cooldowns[idx] and AbilitySystem.cooldowns[idx] > 0 then
                        BalanceConfig.PlayAudioSafe("UI_CLICK")
                        HudView.ShowToast(string.format("【%s】仍在冷却中（还剩 %d 秒）", card.name, math.ceil(AbilitySystem.cooldowns[idx])))
                        return
                    end

                    -- 取消智能释放：如果当前已选中该卡牌，再次点击则直接取消选定
                    if Input.GetSelectedCard() == idx then
                        Input.ClearSelectedCard()
                        BalanceConfig.PlayAudioSafe("UI_CLICK")
                        HudView.ShowToast(string.format("【已取消选定】%s", card.name))
                        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
                        return
                    end

                    -- 选定符印，等待玩家点击目标灵穴
                    Input.SetSelectedCard(idx)
                    BalanceConfig.PlayAudioSafe("UI_CLICK")
                    local targetHint = ""
                    if card.targetType == "enemy_node" then
                        targetHint = "请轻点敌方灵穴释放"
                    elseif card.targetType == "player_node" then
                        targetHint = "请轻点我方灵穴加持"
                    elseif card.targetType == "player_route_node" then
                        targetHint = "请轻点正在输送中的我方灵穴提速"
                    else
                        targetHint = "请轻点目标灵穴释放"
                    end
                    HudView.ShowToast(string.format("【已选定】%s（%s，再点符印取消）", card.name, targetHint))
                    CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, idx)
                end
            end)
        end
    end

    -- 8. 常驻侧边导航栏按钮监听 (重开推衍 & 结算退出)
    if UI.sideRestartBtn and UI.sideRestartBtn.AddCursorEventListener then
        SilenceButton(UI.sideRestartBtn)
        UI.sideRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    if UI.sideSettleBtn and UI.sideSettleBtn.AddCursorEventListener then
        SilenceButton(UI.sideSettleBtn)
        UI.sideSettleBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            OpenSettleConfirmModal()
        end)
    end

    -- 9. 退出挑战 / 游玩结算二次确认弹窗按钮监听
    if UI.confirmResumeBtn and UI.confirmResumeBtn.AddCursorEventListener then
        SilenceButton(UI.confirmResumeBtn)
        UI.confirmResumeBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            CloseSettleConfirmModal()
        end)
    end

    if UI.confirmRestartBtn and UI.confirmRestartBtn.AddCursorEventListener then
        SilenceButton(UI.confirmRestartBtn)
        UI.confirmRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    if UI.confirmQuitBtn and UI.confirmQuitBtn.AddCursorEventListener then
        SilenceButton(UI.confirmQuitBtn)
        UI.confirmQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            TriggerNativePersonalSettlement()
        end)
    end

    -- 10. 结算弹窗按钮
    -- 进军下一关
    if UI.settleNextBtn and UI.settleNextBtn.AddCursorEventListener then
        SilenceButton(UI.settleNextBtn)
        UI.settleNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            local nextStageId = StarMap.currentStage + 1
            if nextStageId <= 5 then
                print(string.format("[Starlink] 进军下一关: 第 %d 关...", nextStageId))
                ChapterSelectView.selectedStage = nextStageId
                StartStage(nextStageId)
            else
                HudView.ShowToast("【恭喜】已通关全部 5 大战役章节！")
                Layout.SetVisible(UI.settleModal, false)
                Layout.SetVisible(UI.chapterSelectModal, true)
                SetGameplayLayersVisible(false)
                gameState.currentState = STATE_CHAPTER_SELECT
                ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
            end
        end)
    end

    -- 重新演练
    if UI.settleRetryBtn and UI.settleRetryBtn.AddCursorEventListener then
        SilenceButton(UI.settleRetryBtn)
        UI.settleRetryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            print(string.format("[Starlink] 重新演练当前关卡: 第 %d 关...", StarMap.currentStage))
            StartStage(StarMap.currentStage)
        end)
    end

    -- 返回章节选择
    if UI.settleChapBtn and UI.settleChapBtn.AddCursorEventListener then
        SilenceButton(UI.settleChapBtn)
        UI.settleChapBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            Layout.SetVisible(UI.settleModal, false)
            Layout.SetVisible(UI.chapterSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_CHAPTER_SELECT
            ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
        end)
    end

    -- 重开模式 (回退到模式选择界面并保留关卡进度)
    if UI.settleRestartBtn and UI.settleRestartBtn.AddCursorEventListener then
        SilenceButton(UI.settleRestartBtn)
        UI.settleRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    -- 退出推衍 (原生系统个人结算)
    if UI.settleQuitBtn and UI.settleQuitBtn.AddCursorEventListener then
        SilenceButton(UI.settleQuitBtn)
        UI.settleQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            OpenSettleConfirmModal()
        end)
    end
end

--------------------------------------------------------------------------------
-- 千星沙箱标准客户端脚本生命周期钩子
--------------------------------------------------------------------------------

function OnInit()
    print("[Starlink] OnInit: 装配 2D 纯代码关卡模式沙盘...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    CacheUIControls()
    StarMap.LoadStage(1)
    InitNodes()
    RouteManager.Init()
    CombatResolver.Init()
    HudView.Init()

    -- 初始应用第 1 关布局
    VisualRenderer.ApplyStageLayout(UI.nodeUIList, gameState.nodes, UI.staticLinkCtrls, StarMap.LINKS)
    VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
    CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)
    local chap = StarMap.currentChapterDef
    HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

    SetupEventHandlers()
    print("[Starlink] OnInit: 装配完成！准备就绪。")
end

function OnStart()
    print("[Starlink] OnStart: 启动模式选择主界面...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    gameState.currentState = STATE_MODE_SELECT
    SetGameplayLayersVisible(false)
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Layout.SetVisible(UI.modeSelectModal, true)
    Layout.SetVisible(UI.quickNavLayer, true)
    Layout.SetVisible(UI.settleConfirmModal, false)
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.dialogueModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.countdownModal, false)
end

function OnUpdate(dt)
    if gameState.currentState == STATE_MODE_SELECT then
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_CHAPTER_SELECT then
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_DIALOGUE then
        DialoguePlayer.Update(dt, UI.dlgSpeaker, UI.dlgContent)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_PREPARE then
        PrepareView.Update(dt)
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_COUNTDOWN then
        local prevSec = math.ceil(gameState.countdownTimer)
        gameState.countdownTimer = gameState.countdownTimer - dt
        local currSec = math.ceil(gameState.countdownTimer)
        if prevSec > 0 and currSec < prevSec and currSec >= 1 then
            BalanceConfig.PlayAudioSafe("UI_CLICK")
        end

        HudView.UpdateCountdown(gameState.countdownTimer, UI.countdownModal, UI.countdownText, UI.countdownSub)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)
        VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
        HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)

        if gameState.countdownTimer <= -0.6 then
            Layout.SetVisible(UI.countdownModal, false)
            gameState.currentState = STATE_PLAYING
            gameState.elapsedTime = 0
            BalanceConfig.PlayAudioSafe("ROUTE_LINK")
            local chap = StarMap.currentChapterDef
            HudView.ShowToast(string.format("【%s】推衍启阵！全速进军！", chap and chap.title or "开战"))
        end

    elseif gameState.currentState == STATE_PLAYING then
        gameState.elapsedTime = gameState.elapsedTime + dt
        gameState.timeRemaining = gameState.timeRemaining - dt

        if not gameState._lastHeartbeat or (gameState.elapsedTime - gameState._lastHeartbeat >= 2.0) then
            gameState._lastHeartbeat = gameState.elapsedTime
            local p0 = gameState.nodes[1]
            print(string.format("[Starlink Battle] Stage %d, t=%.1fs, routes=%d, flying=%d | p0 particles=%d",
                StarMap.currentStage, gameState.elapsedTime, #RouteManager.routes, #RouteManager.movingParticles,
                p0 and p0.particles or 0
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
                        local facName = Layout.GetFactionName(capturedNode.faction)
                        HudView.ShowToast(string.format("【%s】已被【%s】完全掌控！", capturedNode.name, facName))
                        BalanceConfig.PlayAudioSafe("NODE_CAPTURE")
                        CheckMatchEnd()
                    end,
                    function(lostNode)
                        HudView.ShowToast(string.format("【%s】统治动摇，已沦为中立争夺！", lostNode.name))
                    end
                )
            end
        end

        -- 3. 物流发射与微粒流动 (包含微粒到达即时拔河对消占领决算)
        RouteManager.Update(
            dt,
            gameState.nodes,
            gameState.elapsedTime,
            function(hitNode)
                CombatResolver.AddSpark(hitNode.x, hitNode.y)
            end,
            function(capturedNode)
                local facName = Layout.GetFactionName(capturedNode.faction)
                HudView.ShowToast(string.format("【%s】已被【%s】完全掌控！", capturedNode.name, facName))
                CheckMatchEnd()
            end,
            function(lostNode)
                HudView.ShowToast(string.format("【%s】统治动摇，已沦为中立争夺！", lostNode.name))
            end
        )

        -- 4. 战火与威胁判定
        CombatResolver.Update(dt, gameState.nodes, RouteManager.movingParticles)

        -- 5. 敌方 AI 推进 (多阵营全员大乱斗)
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
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)
    end
end
