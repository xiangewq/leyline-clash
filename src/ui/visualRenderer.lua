-- src/ui/visualRenderer.lua
-- 提瓦特星象仪级几何视觉渲染器
-- 包含：三层文字分离黄金分割排版、三层差速星环与易主动态弹性波、柔边羽化光轨、正弦呼吸脉冲与拓扑交互指引

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local VisualRenderer = {
    isLayoutInitialized = false,
    hasRadialApiChecked = false,
    hasRadialApi = false
}

-- 异象视觉风格表
local ANOMALY_STYLE = {
    AMBER_MINE      = { label = "✦ 石珀晶矿", colorKey = "AMBER" },
    WIND_FLOW       = { label = "❖ 疾风流道", colorKey = "ANEMO" },
    MIST_RUINS      = { label = "◈ 迷雾荒墟", colorKey = "TEXT_MUTED" },
    DEFENSE_BASTION = { label = "❖ 雷暴要塞", colorKey = "GOLD" },
    PURE_WATER      = { label = "✦ 纯水枢纽", colorKey = "PLAYER" },
    PLASMA          = { label = "✴ 赤阳熔核", colorKey = "ENEMY" }
}

-- 初始化连线柔边羽化 (消除矩形生硬折角，构建星轨能量束)
function VisualRenderer.InitLineSoftEdge(routeCtrls, staticLinkCtrls)
    if routeCtrls then
        for _, lineCtrl in ipairs(routeCtrls) do
            if lineCtrl and lineCtrl.alive then
                pcall(function()
                    lineCtrl.enableSoftEdge = true
                    if lineCtrl.SetSoftEdgeWidth then
                        lineCtrl:SetSoftEdgeWidth(2, 4)
                    end
                end)
            end
        end
    end
    if staticLinkCtrls then
        for _, sCtrl in ipairs(staticLinkCtrls) do
            if sCtrl and sCtrl.alive then
                pcall(function()
                    sCtrl.enableSoftEdge = true
                    if sCtrl.SetSoftEdgeWidth then
                        sCtrl:SetSoftEdgeWidth(1, 2)
                    end
                end)
            end
        end
    end
end

-- 一次性初始化所有灵穴节点的三层文字排版锚点与深色描边样式 (避免每帧重复调用造成额外开销)
local function EnsureNodeLayoutInitialized(nodeUIList)
    if VisualRenderer.isLayoutInitialized then return end
    VisualRenderer.isLayoutInitialized = true

    if not nodeUIList then return end
    for _, ui in ipairs(nodeUIList) do
        -- 1. 核心兵力大字 (居中锚定于圆盘正中央)
        if ui.particleText and ui.particleText.alive then
            Layout.ApplyTextStyle(ui.particleText, 20, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.particleText.anchoredPositionX = 0
                ui.particleText.anchoredPositionY = 0
            end)
        end
        -- 2. 底部灵穴名称 (下移至圆盘正下方外侧，不遮挡核心兵力)
        if ui.titleText and ui.titleText.alive then
            Layout.ApplyTextStyle(ui.titleText, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.titleText.anchoredPositionX = 0
                ui.titleText.anchoredPositionY = -34
            end)
        end
        -- 3. 顶部异象标识 (上移至圆盘外侧上方)
        if ui.anomalyText and ui.anomalyText.alive then
            Layout.ApplyTextStyle(ui.anomalyText, 11, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.anomalyText.anchoredPositionX = 0
                ui.anomalyText.anchoredPositionY = 34
            end)
        end
        -- 4. 顶部战术状态提示 (置于异象上方或交替呈现)
        if ui.statusText and ui.statusText.alive then
            Layout.ApplyTextStyle(ui.statusText, 11, Layout.PALETTE.ANEMO, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.statusText.anchoredPositionX = 0
                ui.statusText.anchoredPositionY = 48
            end)
        end
    end
end

-- 动态绘制/变换单条线段条带控件
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

-- 更新所有活跃光轨与拖拽连线（支持正弦能量呼吸脉冲与拖拽导引）
function VisualRenderer.UpdateRoutes(routeCtrls, routes, nodes, dragLineCtrl, inputState, elapsedTime)
    local activeCount = #routes
    local maxCtrls = #routeCtrls

    for i = 1, maxCtrls do
        local ctrl = routeCtrls[i]
        if ctrl and ctrl.alive then
            if i <= activeCount then
                local r = routes[i]
                local nA = StarMap.GetNode(nodes, r.fromId)
                local nB = StarMap.GetNode(nodes, r.toId)

                if nA and nB then
                    local baseCol = Layout.GetFactionColor(r.faction)
                    local isBoosted = (nA.anomaly == "WIND_FLOW" or (r.boostedUntil and r.boostedUntil > elapsedTime))

                    if isBoosted then
                        baseCol = Layout.PALETTE.ANEMO
                    end

                    -- 正弦能量脉冲：粗细 5.5px~8.5px 呼吸，透明度 170~250 流转
                    local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 5.0 + (r.fromId or 0))
                    local baseThickness = isBoosted and 7.5 or 5.0
                    local thickness = baseThickness + pulse * 2.2
                    local alpha = math.floor(170 + pulse * 80)
                    local pulseCol = Layout.WithAlpha(baseCol, alpha)

                    VisualRenderer.SetLineTransform(ctrl, nA.x, nA.y, nB.x, nB.y, thickness, pulseCol)
                else
                    Layout.SetVisible(ctrl, false)
                end
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end

    -- 拖拽实时导引线 (曜金星轨引导)
    if dragLineCtrl and dragLineCtrl.alive then
        if inputState.isDragging and inputState.dragSourceId ~= nil then
            local sourceNode = StarMap.GetNode(nodes, inputState.dragSourceId)
            if sourceNode then
                local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 8.0)
                local dragThickness = 3.2 + pulse * 1.5
                local dragColor = Layout.WithAlpha(Layout.PALETTE.GOLD, math.floor(160 + pulse * 95))
                VisualRenderer.SetLineTransform(
                    dragLineCtrl,
                    sourceNode.x, sourceNode.y,
                    inputState.dragCurrentX, inputState.dragCurrentY,
                    dragThickness,
                    dragColor
                )
            else
                Layout.SetVisible(dragLineCtrl, false)
            end
        else
            Layout.SetVisible(dragLineCtrl, false)
        end
    end
end

-- 更新地脉节点视觉呈现 (三层文字黄金分割排版、差速旋转、易主/受击弹性波、拓扑连通高亮)
function VisualRenderer.UpdateNodes(nodeUIList, nodes, elapsedTime, inputState)
    EnsureNodeLayoutInitialized(nodeUIList)

    local isDragging = inputState and inputState.isDragging and inputState.dragSourceId ~= nil
    local dragSourceId = isDragging and inputState.dragSourceId or nil
    local validNeighborsMap = {}

    if isDragging and dragSourceId ~= nil then
        local nList = StarMap.GetNeighbors(dragSourceId)
        for _, nId in ipairs(nList) do
            validNeighborsMap[nId] = true
        end
    end

    for i, node in ipairs(nodes) do
        local ui = nodeUIList[i]
        if ui then
            local factionColor = Layout.GetFactionColor(node.faction)
            local currentParts = math.floor(node.particles or 0)
            local isSource = (isDragging and node.id == dragSourceId)
            local isValidNeighbor = (isDragging and validNeighborsMap[node.id])
            local phase = (node.id or i) * 1.5

            -- 1. 监测易主与兵力跳变，驱动动效弹性缩放冲击波 (Scale Pop)
            if ui.lastFaction ~= nil and ui.lastFaction ~= node.faction then
                ui.capturePulse = 1.0 -- 易主爆发强烈冲击波
            end
            if ui.lastParticles ~= nil and ui.lastParticles ~= currentParts then
                ui.numberPulse = math.min(1.0, (ui.numberPulse or 0) + 0.45)
            end
            ui.lastFaction = node.faction
            ui.lastParticles = currentParts
            ui.capturePulse = math.max(0, (ui.capturePulse or 0) - 0.05)
            ui.numberPulse  = math.max(0, (ui.numberPulse or 0) - 0.08)

            -- 2. 节点整体缩放与明暗处理 (拖拽连线时合法邻居高亮并放大，非邻居半透明压暗)
            if ui.group and ui.group.alive then
                if isDragging then
                    if isSource then
                        ui.group.localScaleX = 1.18
                        ui.group.localScaleY = 1.18
                    elseif isValidNeighbor then
                        local neighPulse = 1.12 + 0.05 * math.sin(elapsedTime * 6.0 + phase)
                        ui.group.localScaleX = neighPulse
                        ui.group.localScaleY = neighPulse
                    else
                        ui.group.localScaleX = 0.94
                        ui.group.localScaleY = 0.94
                    end
                else
                    -- 平时底盘自呼吸脉冲
                    local baseScale = node.isIdle and 0.88 or (1.0 + 0.03 * math.sin(elapsedTime * 3.0 + phase))
                    ui.group.localScaleX = baseScale
                    ui.group.localScaleY = baseScale
                end
            end

            -- 3. 固守防御环 (第一层：顺时针差速自转 + 庇护/固守状态展示)
            if ui.defenseRing and ui.defenseRing.alive then
                local isShielded = (node.protectedUntil and node.protectedUntil > elapsedTime)
                local isFortified = (node.isDefensive and node.routeTo == nil and node.faction ~= "neutral")

                if isShielded or isFortified or isValidNeighbor then
                    Layout.SetVisible(ui.defenseRing, true)
                    local rotSpeed = isShielded and 80 or 20
                    ui.defenseRing.localRotationZ = (elapsedTime * rotSpeed + phase * 20) % 360
                    local ringScale = 1.04 + 0.05 * math.sin(elapsedTime * 4.5 + phase)
                    pcall(function()
                        ui.defenseRing.localScaleX = ringScale
                        ui.defenseRing.localScaleY = ringScale
                    end)

                    if isShielded then
                        local pulseA = 170 + 80 * (0.5 + 0.5 * math.sin(elapsedTime * 7.0))
                        ui.defenseRing.imageColor = Layout.WithAlpha(Layout.PALETTE.ANEMO, pulseA)
                    elseif isFortified then
                        ui.defenseRing.imageColor = Layout.PALETTE.GOLD_ALPHA
                    elseif isValidNeighbor then
                        ui.defenseRing.imageColor = Layout.PALETTE.GOLD
                    end
                else
                    Layout.SetVisible(ui.defenseRing, false)
                end
            end

            -- 4. 灵穴核心底盘 (BaseDisc)：阵营暗底染色 + 内陆休眠微缩 / 易主回弹
            if ui.baseDisc and ui.baseDisc.alive then
                local breathe = node.isIdle and -0.06 or (0.03 * math.sin(elapsedTime * 3.0 + phase))
                local discScale = 1.0 + breathe + (ui.capturePulse * 0.32)
                local discAlpha = node.isIdle and 140 or 225
                ui.baseDisc.imageColor = Layout.GetFactionGlowColor(node.faction, discAlpha)
                pcall(function()
                    ui.baseDisc.localScaleX = discScale
                    ui.baseDisc.localScaleY = discScale
                end)
            end

            -- 5. 灵穴主体共鸣外环 (第二层：逆时针微转 + Lerp 阻尼平滑进度)
            if ui.resonanceRing and ui.resonanceRing.alive then
                ui.resonanceRing.localRotationZ = -(elapsedTime * 14 + phase * 15) % 360

                if isDragging and not isSource and not isValidNeighbor then
                    ui.resonanceRing.imageColor = Layout.WithAlpha(factionColor, 90)
                else
                    ui.resonanceRing.imageColor = factionColor
                end

                local targetProgress = Layout.Clamp((node.control or 100) / 100, 0.06, 1.0)
                ui.smoothProgress = Layout.Lerp(ui.smoothProgress or targetProgress, targetProgress, 0.2)

                local ringPop = 1.0 + (ui.capturePulse * 0.25)
                pcall(function()
                    ui.resonanceRing.localScaleX = ringPop
                    ui.resonanceRing.localScaleY = ringPop
                end)

                if not VisualRenderer.hasRadialApiChecked then
                    VisualRenderer.hasRadialApiChecked = true
                    VisualRenderer.hasRadialApi = (ui.resonanceRing.SetFillRadial360 ~= nil and Enum and Enum.ImageFillRadialType ~= nil)
                end

                if VisualRenderer.hasRadialApi then
                    ui.resonanceRing:SetFillRadial360(Enum.ImageFillRadialType.Top, ui.smoothProgress)
                else
                    ui.resonanceRing.fillAmount = ui.smoothProgress
                end
            end

            -- 6. 核心兵力数字与底部灵穴名称分离渲染 (黄金分割排版)
            if ui.particleText and ui.particleText.alive then
                Layout.SetVisible(ui.particleText, true)
                ui.particleText.text = tostring(currentParts)
                local dynamicFontSize = math.floor(Layout.Clamp(17 + currentParts * 0.12 + ui.numberPulse * 3, 17, 25))
                pcall(function()
                    ui.particleText.fontSize = dynamicFontSize
                    local numScale = 1.0 + ui.numberPulse * 0.16
                    ui.particleText.localScaleX = numScale
                    ui.particleText.localScaleY = numScale
                end)
                ui.particleText.fontColor = (currentParts >= 40) and Layout.PALETTE.GOLD or Layout.PALETTE.TEXT_LIGHT
            end

            if ui.titleText and ui.titleText.alive then
                Layout.SetVisible(ui.titleText, true)
                ui.titleText.text = "「" .. tostring(node.name or "星枢") .. "」"
                if isDragging and not isSource and not isValidNeighbor then
                    ui.titleText.fontColor = Layout.WithAlpha(Layout.PALETTE.TEXT_LIGHT, 110)
                else
                    ui.titleText.fontColor = (node.faction == "neutral") and Layout.PALETTE.NEUTRAL or Layout.PALETTE.TEXT_LIGHT
                end
            end

            -- 7. 顶部异象标签 (提瓦特星象符号与专属配色)
            local hasAnomaly = false
            if ui.anomalyText and ui.anomalyText.alive then
                local style = node.anomaly and ANOMALY_STYLE[node.anomaly]
                if style then
                    hasAnomaly = true
                    ui.anomalyText.text = style.label
                    ui.anomalyText.fontColor = Layout.PALETTE[style.colorKey] or Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.anomalyText, true)
                else
                    Layout.SetVisible(ui.anomalyText, false)
                end
            end

            -- 8. 顶部实时战术状态小字 (护盾倒计时、固守、掌控动摇、内陆休眠)
            if ui.statusText and ui.statusText.alive then
                pcall(function()
                    ui.statusText.anchoredPositionY = hasAnomaly and 50 or 34
                end)

                if node.protectedUntil and node.protectedUntil > elapsedTime then
                    local remain = math.max(0.1, node.protectedUntil - elapsedTime)
                    ui.statusText.text = string.format("❖ 庇护 %.1fs", remain)
                    ui.statusText.fontColor = Layout.PALETTE.ANEMO
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction == "neutral" and (node.control or 0) > 0 and node.contenderFaction then
                    local fName = Layout.GetFactionName(node.contenderFaction)
                    local col = Layout.GetFactionColor(node.contenderFaction)
                    ui.statusText.text = string.format("[%s掌控 %d%%]", fName, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction ~= "neutral" and (node.control or 100) < 100 then
                    local fName = Layout.GetFactionName(node.faction)
                    local col = Layout.GetFactionColor(node.faction)
                    ui.statusText.text = string.format("[%s动摇 %d%%]", fName, math.floor(node.control or 100))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isIdle then
                    ui.statusText.text = "◈ 腹地休眠"
                    ui.statusText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isDefensive and node.routeTo == nil and node.faction ~= "neutral" then
                    ui.statusText.text = "✦ 固守结界"
                    ui.statusText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.statusText, true)
                elseif node.routeTo ~= nil then
                    ui.statusText.text = "➔ 输送中"
                    ui.statusText.fontColor = factionColor
                    Layout.SetVisible(ui.statusText, true)
                else
                    Layout.SetVisible(ui.statusText, false)
                end
            end
        end
    end
end

-- 关卡拓扑几何重布局 (按当前章节的节点坐标与连线刷新沙盘)
function VisualRenderer.ApplyStageLayout(nodeUIList, nodes, staticLinkCtrls, links)
    for i, ui in ipairs(nodeUIList) do
        local node = nodes[i]
        if node and ui.group and ui.group.alive then
            ui.group.anchoredPositionX = node.x
            ui.group.anchoredPositionY = node.y
            Layout.SetVisible(ui.group, true)
        elseif ui.group and ui.group.alive then
            Layout.SetVisible(ui.group, false)
        end
    end

    if staticLinkCtrls and links then
        for i, linkCtrl in ipairs(staticLinkCtrls) do
            local link = links[i]
            if link and linkCtrl and linkCtrl.alive then
                local nA = StarMap.GetNode(nodes, link[1])
                local nB = StarMap.GetNode(nodes, link[2])
                if nA and nB then
                    VisualRenderer.SetLineTransform(linkCtrl, nA.x, nA.y, nB.x, nB.y, 2, Layout.PALETTE.LINK_INACTIVE)
                else
                    Layout.SetVisible(linkCtrl, false)
                end
            elseif linkCtrl and linkCtrl.alive then
                Layout.SetVisible(linkCtrl, false)
            end
        end
    end
end

-- 彻底清除并隐藏所有光轨连线与导引线
function VisualRenderer.HideAllRoutes(routeCtrls, dragLineCtrl)
    if routeCtrls then
        for _, ctrl in ipairs(routeCtrls) do
            if ctrl and ctrl.alive then
                Layout.SetVisible(ctrl, false)
            end
        end
    end
    if dragLineCtrl and dragLineCtrl.alive then
        Layout.SetVisible(dragLineCtrl, false)
    end
end

return VisualRenderer
