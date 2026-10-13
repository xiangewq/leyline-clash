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
        elseif n.faction ~= "neutral" then
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
function HudView.ShowSettlement(isWin, nodes, elapsedTime, modalCtrl, titleCtrl, descCtrl, statsCtrl, nextBtnCtrl)
    HudView.isSettled = true
    Layout.SetVisible(modalCtrl, true)

    if nextBtnCtrl and nextBtnCtrl.alive then
        Layout.SetVisible(nextBtnCtrl, isWin)
    end

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

-- 关卡特殊灵穴效果说明映射表与重要度排序
local ANOMALY_DESC_MAP = {
    PLASMA          = "● 赤阳熔核：上限强制限25粒，极速绞肉战场",
    DEFENSE_BASTION = "● 雷暴要塞：雷暴灵障固守，战损减半",
    PURE_WATER      = "● 纯水枢纽：纯水激荡，微粒孕育速度提升54%",
    WIND_FLOW       = "● 疾风流道：地脉输送流速翻倍 (双倍流速)",
    AMBER_MINE      = "● 石珀富矿：石珀滋养，微粒孕育速度翻倍",
    MIST_RUINS      = "● 迷雾荒墟：迷雾遮蔽，微粒孕育速度减半"
}

local ANOMALY_PRIORITY = {
    PLASMA          = 1,
    DEFENSE_BASTION = 2,
    PURE_WATER      = 3,
    WIND_FLOW       = 4,
    AMBER_MINE      = 5,
    MIST_RUINS      = 6
}

-- 更新左上角关卡特殊灵穴说明与右上角战术操作说明
function HudView.UpdateStageInfo(chap, anomalyTitleCtrl, anomalyDescCtrl, guideTitleCtrl, guideDescCtrl)
    if guideTitleCtrl and guideTitleCtrl.alive then
        pcall(function()
            guideTitleCtrl.text = "【战术操作指引】"
            guideTitleCtrl.fontColor = Layout.PALETTE.GOLD
        end)
    end
    if guideDescCtrl and guideDescCtrl.alive then
        pcall(function()
            guideDescCtrl.text = "● 连线：拖拽己方灵穴至相邻据点建立输送\n● 固守：轻点己方灵穴展开/收拢固守结界\n● 符印：点击下方符印后点击目标灵穴释放"
        end)
    end

    if anomalyTitleCtrl and anomalyTitleCtrl.alive then
        pcall(function()
            local stageTag = "战场"
            if chap and chap.title then
                local m = string.match(chap.title, "第 %d+ 关")
                if m then
                    stageTag = m
                elseif chap.id then
                    stageTag = string.format("第 %d 关", chap.id)
                end
            elseif chap and chap.id then
                stageTag = string.format("第 %d 关", chap.id)
            end
            anomalyTitleCtrl.text = string.format("【%s · 地脉情报】", stageTag)
            anomalyTitleCtrl.fontColor = Layout.PALETTE.PLAYER
        end)
    end

    if anomalyDescCtrl and anomalyDescCtrl.alive then
        pcall(function()
            local anomalyKeys = {}
            local seen = {}
            if chap and chap.nodes then
                for _, n in ipairs(chap.nodes) do
                    if n.anomaly and n.anomaly ~= "NORMAL" and not seen[n.anomaly] then
                        seen[n.anomaly] = true
                        table.insert(anomalyKeys, n.anomaly)
                    end
                end
            end

            table.sort(anomalyKeys, function(a, b)
                return (ANOMALY_PRIORITY[a] or 99) < (ANOMALY_PRIORITY[b] or 99)
            end)

            local lines = {}
            for _, k in ipairs(anomalyKeys) do
                local desc = ANOMALY_DESC_MAP[k]
                if desc then
                    table.insert(lines, desc)
                end
            end

            if #lines == 0 then
                anomalyDescCtrl.text = "● 标准地脉：常规孕育与输送，前线激战，后方休整\n● 固守结界：驻防灵穴战损削减30%"
            else
                anomalyDescCtrl.text = table.concat(lines, "\n")
            end
        end)
    end
end

-- 战前 3 秒倒计时更新 (3、2、1、开始)
function HudView.UpdateCountdown(timer, countdownModal, countdownTextCtrl, countdownSubCtrl)
    if not countdownModal or not countdownModal.alive then return end

    if timer > 0 then
        Layout.SetVisible(countdownModal, true)
        local countNum = math.ceil(timer)
        if countNum > 3 then countNum = 3 end
        if countNum < 1 then countNum = 1 end

        if countdownTextCtrl and countdownTextCtrl.alive then
            pcall(function()
                countdownTextCtrl.text = tostring(countNum)
                countdownTextCtrl.fontColor = Layout.PALETTE.GOLD
            end)
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            pcall(function()
                if countNum == 3 then
                    countdownSubCtrl.text = "【3 秒】全域地脉连接调配完成..."
                elseif countNum == 2 then
                    countdownSubCtrl.text = "【2 秒】星轨推衍回路展开中..."
                else
                    countdownSubCtrl.text = "【1 秒】元素微粒正在凝聚！"
                end
                countdownSubCtrl.fontColor = Layout.PALETTE.PLAYER
            end)
        end
    elseif timer > -0.6 then
        Layout.SetVisible(countdownModal, true)
        if countdownTextCtrl and countdownTextCtrl.alive then
            pcall(function()
                countdownTextCtrl.text = "开 始 ！"
                countdownTextCtrl.fontColor = Layout.PALETTE.PLAYER
            end)
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            pcall(function()
                countdownSubCtrl.text = "【开战】执掌星轨，克敌制胜！"
                countdownSubCtrl.fontColor = Layout.PALETTE.GOLD
            end)
        end
    else
        Layout.SetVisible(countdownModal, false)
    end
end

return HudView
