-- src/ui/uiBinder.lua
-- 控件树深度检索、各层图元容器集中缓存与生命周期辅助管理

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local UIBinder = {}

-- 深度递归查找指定名称的子控件
function UIBinder.FindDeepChild(parent, name)
    if not parent or not parent.alive then return nil end
    local direct = parent:FindChild(name)
    if direct then return direct end
    local children = parent:GetChildren()
    if children then
        for _, child in ipairs(children) do
            local found = UIBinder.FindDeepChild(child, name)
            if found then return found end
        end
    end
    return nil
end

-- 辅助：静音原生按钮 clickAudioId，避免引擎底层默认点击音效与脚本 PlayAudioSafe 重叠双响
function UIBinder.SilenceButton(btn)
    if btn and btn.alive then
        pcall(function() btn.clickAudioId = 0 end)
    end
end

-- 集中缓存全量 UI 控件树结构
function UIBinder.BindControls(script, game)
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

    local UI = {
        root = root
    }

    -- 1. 全局输入检测层与拖拽导引线
    UI.cursorArea = UIBinder.FindDeepChild(root, "GlobalCursorArea")
    UI.dragLine   = UIBinder.FindDeepChild(root, "DragLine")

    -- 2. 模式选择弹窗
    UI.modeSelectModal = UIBinder.FindDeepChild(root, "ModeSelectModal")
    if UI.modeSelectModal then
        UI.modeStoryBtn     = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeStoryBtn")
        UI.modeChallengeBtn = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeChallengeBtn")
        UI.modeQuitBtn      = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeQuitBtn")
    end

    -- 3. 关卡章节选择弹窗
    UI.chapterSelectModal = UIBinder.FindDeepChild(root, "ChapterSelectModal")
    UI.chapterCards = {}
    if UI.chapterSelectModal then
        UI.chapDesc     = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterDesc")
        UI.chapTitle    = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterTitle")
        UI.chapStartBtn = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterStartBtn")
        if UI.chapStartBtn then
            UI.chapStartTxt = UIBinder.FindDeepChild(UI.chapStartBtn, "Text")
        end
        UI.chapBackBtn  = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterBackBtn")

        for idx = 1, 5 do
            local cardBtn = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterCard_" .. idx)
            if cardBtn then
                table.insert(UI.chapterCards, {
                    button     = cardBtn,
                    tagCtrl    = UIBinder.FindDeepChild(cardBtn, "TagText"),
                    infoCtrl   = UIBinder.FindDeepChild(cardBtn, "InfoText"),
                    budgetCtrl = UIBinder.FindDeepChild(cardBtn, "BudgetText"),
                    titleCtrl  = UIBinder.FindDeepChild(cardBtn, "TitleText"),
                    bgCtrl     = UIBinder.FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = UIBinder.FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 4. 光轨条带池与静态连线池 (20 条动态光轨 + 30 条静态底轨)
    UI.routeCtrls = {}
    UI.staticLinkCtrls = {}
    UI.linksLayer = UIBinder.FindDeepChild(root, "LinksLayer")
    if UI.linksLayer then
        for i = 1, 20 do
            local line = UIBinder.FindDeepChild(UI.linksLayer, "RouteLine_" .. i)
            if line then table.insert(UI.routeCtrls, line) end
        end
        for i = 0, 29 do
            local sLine = UIBinder.FindDeepChild(UI.linksLayer, "StaticLink_" .. i)
            if sLine then table.insert(UI.staticLinkCtrls, sLine) end
        end
    end

    -- 5. 微粒对象池 (120个全量池化)
    UI.particleCtrls = {}
    UI.particlesLayer = UIBinder.FindDeepChild(root, "ParticlesLayer")
    if UI.particlesLayer then
        for i = 1, 120 do
            local p = UIBinder.FindDeepChild(UI.particlesLayer, "P_" .. i)
            if p then table.insert(UI.particleCtrls, p) end
        end
    end

    -- 6. 22 座地脉灵穴 UI 组
    UI.nodeUIList = {}
    UI.nodesLayer = UIBinder.FindDeepChild(root, "NodesLayer")
    if UI.nodesLayer then
        for i = 0, 21 do
            local grp = UIBinder.FindDeepChild(UI.nodesLayer, "NodeGroup_" .. i)
            if grp then
                table.insert(UI.nodeUIList, {
                    group        = grp,
                    defenseRing  = UIBinder.FindDeepChild(grp, "DefenseRing"),
                    baseDisc     = UIBinder.FindDeepChild(grp, "BaseDisc"),
                    resonanceRing= UIBinder.FindDeepChild(grp, "ResonanceRing"),
                    titleText    = UIBinder.FindDeepChild(grp, "TitleText"),
                    particleText = UIBinder.FindDeepChild(grp, "ParticleText"),
                    anomalyText  = UIBinder.FindDeepChild(grp, "AnomalyText"),
                    statusText   = UIBinder.FindDeepChild(grp, "StatusText")
                })
            end
        end
    end

    -- 7. 顶部 HUD 与战术情报
    UI.hudLayer = UIBinder.FindDeepChild(root, "HudLayer")
    local hud = UI.hudLayer
    if hud then
        UI.playerPctText  = UIBinder.FindDeepChild(hud, "HudPlayerPct")
        UI.enemyPctText   = UIBinder.FindDeepChild(hud, "HudEnemyPct")
        UI.timerText      = UIBinder.FindDeepChild(hud, "HudTimer")
        UI.barPlayer      = UIBinder.FindDeepChild(hud, "BarPlayer")
        UI.barEnemy       = UIBinder.FindDeepChild(hud, "BarEnemy")
        UI.toastContainer = UIBinder.FindDeepChild(root, "ToastContainer")
        if UI.toastContainer then
            UI.toastText  = UIBinder.FindDeepChild(UI.toastContainer, "ToastText")
        end

        -- 战前3秒倒计时
        UI.countdownModal = UIBinder.FindDeepChild(root, "CountdownModal")
        if UI.countdownModal then
            UI.countdownText = UIBinder.FindDeepChild(UI.countdownModal, "CountdownText")
            UI.countdownSub  = UIBinder.FindDeepChild(UI.countdownModal, "CountdownSub")
        end

        -- 左上角地脉说明与右上角指引
        UI.hudAnomalyBox   = UIBinder.FindDeepChild(hud, "HudAnomalyBox")
        if UI.hudAnomalyBox then
            UI.hudAnomalyTitle = UIBinder.FindDeepChild(UI.hudAnomalyBox, "AnomalyTitle")
            UI.hudAnomalyDesc  = UIBinder.FindDeepChild(UI.hudAnomalyBox, "AnomalyDesc")
        end
        UI.hudGuideBox     = UIBinder.FindDeepChild(hud, "HudGuideBox")
        if UI.hudGuideBox then
            UI.hudGuideTitle   = UIBinder.FindDeepChild(UI.hudGuideBox, "GuideTitle")
            UI.hudGuideDesc    = UIBinder.FindDeepChild(UI.hudGuideBox, "GuideDesc")
        end

        UI.cardSlots = {}
        for j = 1, 4 do
            local slotGrp = UIBinder.FindDeepChild(hud, "CardSlot_" .. j)
            if slotGrp then
                table.insert(UI.cardSlots, {
                    container  = slotGrp,
                    borderCtrl = UIBinder.FindDeepChild(slotGrp, "Border"),
                    nameCtrl   = UIBinder.FindDeepChild(slotGrp, "NameText"),
                    costCtrl   = UIBinder.FindDeepChild(slotGrp, "CostText"),
                    maskCtrl   = UIBinder.FindDeepChild(slotGrp, "CdMask"),
                    cdTextCtrl = UIBinder.FindDeepChild(slotGrp, "CdText")
                })
            end
        end
    end

    -- 8. 剧情演播弹窗
    UI.dialogueModal = UIBinder.FindDeepChild(root, "DialogueModal")
    if UI.dialogueModal then
        UI.dlgSpeaker = UIBinder.FindDeepChild(UI.dialogueModal, "DlgSpeaker")
        UI.dlgContent = UIBinder.FindDeepChild(UI.dialogueModal, "DlgContent")
        UI.dlgSkipBtn = UIBinder.FindDeepChild(UI.dialogueModal, "DlgSkipBtn")
        UI.dlgNextBtn = UIBinder.FindDeepChild(UI.dialogueModal, "DlgNextBtn")
    end

    -- 9. 战前调配弹窗
    UI.prepareModal = UIBinder.FindDeepChild(root, "PrepareModal")
    UI.prepCards = {}
    if UI.prepareModal then
        UI.prepBudgetText = UIBinder.FindDeepChild(UI.prepareModal, "PrepBudgetText")
        UI.prepHint       = UIBinder.FindDeepChild(UI.prepareModal, "PrepHint")
        UI.prepTitle      = UIBinder.FindDeepChild(UI.prepareModal, "PrepTitle")
        UI.prepStartBtn   = UIBinder.FindDeepChild(UI.prepareModal, "PrepStartBtn")
        for k = 1, 6 do
            local cardBtn = UIBinder.FindDeepChild(UI.prepareModal, "PrepCard_" .. k)
            if cardBtn then
                table.insert(UI.prepCards, {
                    button     = cardBtn,
                    checkCtrl  = UIBinder.FindDeepChild(cardBtn, "CheckTag"),
                    costCtrl   = UIBinder.FindDeepChild(cardBtn, "CostText"),
                    descCtrl   = UIBinder.FindDeepChild(cardBtn, "DescText"),
                    nameCtrl   = UIBinder.FindDeepChild(cardBtn, "NameText"),
                    bgCtrl     = UIBinder.FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = UIBinder.FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 10. 常驻侧边导航栏 (除剧情演播外常驻于左上角)
    UI.quickNavLayer = UIBinder.FindDeepChild(root, "QuickNavLayer")
    if UI.quickNavLayer then
        UI.sideRestartBtn = UIBinder.FindDeepChild(UI.quickNavLayer, "SideRestartBtn")
        UI.sideSettleBtn  = UIBinder.FindDeepChild(UI.quickNavLayer, "SideSettleBtn")
    end

    -- 11. 退出挑战 / 游玩结算二次确认弹窗
    UI.settleConfirmModal = UIBinder.FindDeepChild(root, "SettleConfirmModal")
    if UI.settleConfirmModal then
        UI.confirmResumeBtn  = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmResumeBtn")
        UI.confirmRestartBtn = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmRestartBtn")
        UI.confirmQuitBtn    = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmQuitBtn")
        UI.confirmDesc       = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmDesc")
        UI.confirmTitle      = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmTitle")
    end

    -- 12. 终局结算演出弹窗
    UI.settleModal = UIBinder.FindDeepChild(root, "SettleModal")
    if UI.settleModal then
        UI.settleTitle      = UIBinder.FindDeepChild(UI.settleModal, "SettleTitle")
        UI.settleDesc       = UIBinder.FindDeepChild(UI.settleModal, "SettleDesc")
        UI.settleStats      = UIBinder.FindDeepChild(UI.settleModal, "SettleStats")
        UI.settleNextBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleNextBtn")
        UI.settleRetryBtn   = UIBinder.FindDeepChild(UI.settleModal, "SettleRetryBtn")
        UI.settleChapBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleChapterBtn")
        UI.settleRestartBtn = UIBinder.FindDeepChild(UI.settleModal, "SettleRestartBtn")
        UI.settleQuitBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleQuitBtn")
    end

    return UI
end

-- 控制战斗核心沙盘层（灵穴、光轨、微粒、HUD）可见性
function UIBinder.SetGameplayLayersVisible(UI, visible)
    if not UI then return end
    Layout.SetVisible(UI.nodesLayer, visible)
    Layout.SetVisible(UI.linksLayer, visible)
    Layout.SetVisible(UI.particlesLayer, visible)
    Layout.SetVisible(UI.hudLayer, visible)
end

return UIBinder
