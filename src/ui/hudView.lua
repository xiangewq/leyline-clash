-- src/ui/hudView.lua
-- HUD 顶部掌控进度、倒计时、提瓦特敕令风 Toast 浮窗与终局结算面板

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local HudView = {
    toastText = "",
    toastTimer = 0,
    toastDuration = 2.4,
    toastRGB = { r = 251, g = 191, b = 36 },
    isSettled = false,
    isStyleInitialized = false,
    onRetry = nil
}

function HudView.Init(onRetryCallback)
    HudView.toastText = ""
    HudView.toastTimer = 0
    HudView.toastDuration = 2.4
    HudView.toastRGB = { r = 251, g = 191, b = 36 }
    HudView.isSettled = false
    HudView.isStyleInitialized = false
    HudView.onRetry = onRetryCallback
end

-- 根据提示文本内容自动推断视觉语义与提瓦特配色
local function ResolveToastStyle(msg, explicitType)
    local t = explicitType
    if not t then
        if string.find(msg, "不足") or string.find(msg, "无法") or string.find(msg, "冷却") or string.find(msg, "警告") or string.find(msg, "失守") or string.find(msg, "未连通") then
            t = "warn"
        elseif string.find(msg, "符印") or string.find(msg, "施加") or string.find(msg, "激活") or string.find(msg, "守护") then
            t = "spell"
        else
            t = "info"
        end
    end

    if t == "warn" then
        return "❖ ──  " .. msg .. "  ── ❖", { r = 244, g = 63, b = 94 }   -- 绯红警示
    elseif t == "spell" then
        return "✦ ──  " .. msg .. "  ── ✦", { r = 52, g = 211, b = 153 }  -- 千风翠碧敕令
    else
        return "✦ ──  " .. msg .. "  ── ✦", { r = 251, g = 191, b = 36 }  -- 曜金星轨播报
    end
end

function HudView.ShowToast(msg, toastType)
    local rawMsg = msg or ""
    local styledText, rgb = ResolveToastStyle(rawMsg, toastType)
    HudView.toastText = styledText
    HudView.toastRGB = rgb
    HudView.toastDuration = 2.4
    HudView.toastTimer = HudView.toastDuration
end

function HudView.UpdateToast(dt, toastContainer, toastTextCtrl)
    if HudView.toastTimer > 0 then
        HudView.toastTimer = HudView.toastTimer - dt
        Layout.SetVisible(toastContainer, true)

        -- 计算弹出回弹缩放 (Pop-in) 与尾部淡出 (Fade-out)
        local elapsed = HudView.toastDuration - HudView.toastTimer
        local scale = 1.0
        if elapsed < 0.18 then
            -- 0 ~ 0.18s: 从 0.84 快速弹至 1.05
            scale = Layout.Lerp(0.84, 1.05, elapsed / 0.18)
        elseif elapsed < 0.30 then
            -- 0.18 ~ 0.30s: 从 1.05 回落至 1.0
            scale = Layout.Lerp(1.05, 1.0, (elapsed - 0.18) / 0.12)
        end

        local alpha = 255
        if HudView.toastTimer < 0.45 then
            alpha = math.floor(Layout.Clamp(HudView.toastTimer / 0.45, 0, 1) * 255)
        end

        if toastContainer and toastContainer.alive then
            pcall(function()
                toastContainer.localScaleX = scale
                toastContainer.localScaleY = scale
            end)
        end

        if toastTextCtrl and toastTextCtrl.alive then
            Layout.ApplyTextStyle(toastTextCtrl, 18, nil, Layout.PALETTE.BG_DARK)
            toastTextCtrl.text = HudView.toastText
            local c = HudView.toastRGB
            toastTextCtrl.fontColor = Layout.MakeColor(c.r, c.g, c.b, alpha)
        end
    else
        Layout.SetVisible(toastContainer, false)
    end
end

-- 更新顶部掌控条与计时
function HudView.UpdateTopBar(timeRemaining, nodes, playerPctCtrl, enemyPctCtrl, timerCtrl, barPlayerCtrl, barEnemyCtrl)
    if not HudView.isStyleInitialized then
        HudView.isStyleInitialized = true
        Layout.ApplyTextStyle(playerPctCtrl, 15, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
        Layout.ApplyTextStyle(enemyPctCtrl, 15, Layout.PALETTE.ENEMY, Layout.PALETTE.BG_DARK)
        Layout.ApplyTextStyle(timerCtrl, 20, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
    end

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
        playerPctCtrl.text = string.format("✦ 我方星轨 %d%% (%d穴)", pPct, pNodes)
    end
    if enemyPctCtrl and enemyPctCtrl.alive then
        enemyPctCtrl.text = string.format("敌方侵蚀 %d%% (%d穴) ❖", ePct, eNodes)
    end

    if barPlayerCtrl and barPlayerCtrl.alive then
        local targetW = math.max(10, math.floor(320 * (pPct / 100)))
        barPlayerCtrl.sizeDeltaX = math.floor(Layout.Lerp(barPlayerCtrl.sizeDeltaX or targetW, targetW, 0.2))
    end
    if barEnemyCtrl and barEnemyCtrl.alive then
        local targetW = math.max(10, math.floor(320 * (ePct / 100)))
        barEnemyCtrl.sizeDeltaX = math.floor(Layout.Lerp(barEnemyCtrl.sizeDeltaX or targetW, targetW, 0.2))
    end

    if timerCtrl and timerCtrl.alive then
        local t = math.max(0, math.floor(timeRemaining))
        local m = math.floor(t / 60)
        local s = t % 60
        timerCtrl.text = string.format("%02d : %02d", m, s)
        -- 剩余不足 30 秒时切换为曜金/猩红闪烁警示
        if t <= 30 then
            local blink = (math.floor(timeRemaining * 4) % 2 == 0)
            timerCtrl.fontColor = blink and Layout.PALETTE.ENEMY or Layout.PALETTE.GOLD
        else
            timerCtrl.fontColor = Layout.PALETTE.TEXT_LIGHT
        end
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
        Layout.ApplyTextStyle(titleCtrl, 24, nil, Layout.PALETTE.BG_DARK)
        if isWin then
            titleCtrl.text = "✦ ──  地 脉 推 衍 · 大 捷  ── ✦"
            titleCtrl.fontColor = Layout.PALETTE.GOLD
        else
            titleCtrl.text = "❖ ──  星 轨 崩 碎 · 惜 败  ── ❖"
            titleCtrl.fontColor = Layout.PALETTE.ENEMY
        end
    end

    if descCtrl and descCtrl.alive then
        Layout.ApplyTextStyle(descCtrl, 15, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
        if isWin then
            descCtrl.text = "星盘之理尽在掌控，地脉灵流归于统御。全域敌对据点已被彻底肃清！"
        else
            descCtrl.text = "地脉紊乱，推衍消散。我方地脉源枢失守，不妨重新调配战术符印后再战。"
        end
    end

    if statsCtrl and statsCtrl.alive then
        Layout.ApplyTextStyle(statsCtrl, 14, Layout.PALETTE.AMBER, Layout.PALETTE.BG_DARK)
        statsCtrl.text = string.format("占领灵穴：%d/%d  |  存活兵力：%d  |  耗时：%s", pCount, #nodes, pParts, timeStr)
    end
end

-- 关卡特殊灵穴效果说明映射表与重要度排序
local ANOMALY_DESC_MAP = {
    PLASMA          = "【赤阳熔核】上限强制限25粒，极速绞肉战场",
    DEFENSE_BASTION = "【雷暴要塞】雷暴灵障固守，战损减半",
    PURE_WATER      = "【纯水枢纽】纯水核心与微粒快速回流 (+54%)",
    WIND_FLOW       = "【疾风流道】地脉输送流速翻倍 (双倍极速)",
    AMBER_MINE      = "【石珀晶矿】灵穴能量产出速率翻倍 (+100%)",
    MIST_RUINS      = "【迷雾荒墟】据点驻防加成，微粒孕育减半"
}

local ANOMALY_PRIORITY = {
    PLASMA          = 1,
    DEFENSE_BASTION = 2,
    PURE_WATER      = 3,
    WIND_FLOW       = 4,
    AMBER_MINE      = 5,
    MIST_RUINS      = 6
}

-- 更新左上角关卡特殊灵穴说明与右上角战术操作说明 (支持去重与 ×N 统计数量)
function HudView.UpdateStageInfo(chap, anomalyTitleCtrl, anomalyDescCtrl, guideTitleCtrl, guideDescCtrl)
    if guideTitleCtrl and guideTitleCtrl.alive then
        Layout.ApplyTextStyle(guideTitleCtrl, 14, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
        guideTitleCtrl.text = "✦ 【战术操作指引】"
    end
    if guideDescCtrl and guideDescCtrl.alive then
        Layout.ApplyTextStyle(guideDescCtrl, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
        guideDescCtrl.text = "● 连线：拖拽己方灵穴至相邻据点建立输送\n● 固守：轻点己方灵穴展开/收拢固守结界\n● 符印：点击下方符印后点击目标灵穴释放"
    end

    if anomalyTitleCtrl and anomalyTitleCtrl.alive then
        Layout.ApplyTextStyle(anomalyTitleCtrl, 14, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
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
        anomalyTitleCtrl.text = string.format("✦ 【%s · 地脉情报】", stageTag)
    end

    if anomalyDescCtrl and anomalyDescCtrl.alive then
        Layout.ApplyTextStyle(anomalyDescCtrl, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)

        -- 对战场异象进行去重与数量统计，避免同类型异象刷屏
        local counts = {}
        if chap and chap.nodes then
            for _, n in ipairs(chap.nodes) do
                if n.anomaly and n.anomaly ~= "NORMAL" and ANOMALY_DESC_MAP[n.anomaly] then
                    counts[n.anomaly] = (counts[n.anomaly] or 0) + 1
                end
            end
        end

        local anomalyKeys = {}
        for k, _ in pairs(counts) do
            table.insert(anomalyKeys, k)
        end
        table.sort(anomalyKeys, function(a, b)
            return (ANOMALY_PRIORITY[a] or 99) < (ANOMALY_PRIORITY[b] or 99)
        end)

        local lines = {}
        for _, k in ipairs(anomalyKeys) do
            local desc = ANOMALY_DESC_MAP[k]
            local cnt = counts[k]
            if desc and cnt then
                local suffix = (cnt > 1) and string.format(" ×%d", cnt) or ""
                table.insert(lines, "  ◆ " .. desc .. suffix)
            end
        end

        if #lines == 0 then
            anomalyDescCtrl.text = "● 标准地脉：常规孕育与输送，前线激战\n● 固守结界：驻防灵穴战损削减30%"
        else
            anomalyDescCtrl.text = table.concat(lines, "\n")
        end
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
            Layout.ApplyTextStyle(countdownTextCtrl, 52, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            countdownTextCtrl.text = tostring(countNum)
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            Layout.ApplyTextStyle(countdownSubCtrl, 18, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
            if countNum == 3 then
                countdownSubCtrl.text = "【3 秒】全域地脉连接调配完成..."
            elseif countNum == 2 then
                countdownSubCtrl.text = "【2 秒】星轨推衍回路展开中..."
            else
                countdownSubCtrl.text = "【1 秒】元素微粒正在凝聚！"
            end
        end
    elseif timer > -0.6 then
        Layout.SetVisible(countdownModal, true)
        if countdownTextCtrl and countdownTextCtrl.alive then
            Layout.ApplyTextStyle(countdownTextCtrl, 44, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
            countdownTextCtrl.text = "开 始 ！"
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            Layout.ApplyTextStyle(countdownSubCtrl, 18, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            countdownSubCtrl.text = "【开战】执掌星轨，克敌制胜！"
        end
    else
        Layout.SetVisible(countdownModal, false)
    end
end

return HudView
