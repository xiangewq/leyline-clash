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
