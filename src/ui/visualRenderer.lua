-- src/ui/visualRenderer.lua
-- 提瓦特星图几何视觉渲染器（光轨羽化光束、正弦能量脉冲、三层差速星轨自转、拓扑交互高亮）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local VisualRenderer = {
    -- 缓存探测特性：消除每帧热点循环内的匿名 pcall 闭包
    hasRadialApiChecked = false,
    hasRadialApi = false
}

-- 初始化连线图元柔边羽化 (消除矩形生硬感，形成流光能量束)
function VisualRenderer.InitLineSoftEdge(routeCtrls, staticLinkCtrls)
    if routeCtrls then
        for _, lineCtrl in ipairs(routeCtrls) do
            if lineCtrl and lineCtrl.alive then
                pcall(function()
                    lineCtrl.enableSoftEdge = true
                    if lineCtrl.SetSoftEdgeWidth then
                        lineCtrl:SetSoftEdgeWidth(2, 4) -- 左右微羽化，上下边缘强羽化形成光柱感
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

-- 更新所有活跃光轨与拖拽连线（支持正弦能量呼吸脉冲与拖拽导引）
function VisualRenderer.UpdateRoutes(routeCtrls, routes, nodes, dragLineCtrl, inputState, elapsedTime)
    -- 1. 活跃光轨
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

                    -- 处于「疾风流道」或「千风湍流」：千风翠碧色
                    if isBoosted then
                        baseCol = Layout.PALETTE.ANEMO
                    end

                    -- 正弦能量脉冲：粗细在 6px~9px 间平滑呼吸，透明度在 170~250 之间流转
                    local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 5.0 + (r.fromId or 0))
                    local baseThickness = isBoosted and 8.0 or 5.5
                    local thickness = baseThickness + pulse * 2.5
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

    -- 2. 拖拽实时导引线 (金岩光芒引导线)
    if dragLineCtrl and dragLineCtrl.alive then
        if inputState.isDragging and inputState.dragSourceId ~= nil then
            local sourceNode = StarMap.GetNode(nodes, inputState.dragSourceId)
            if sourceNode then
                local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 8.0)
                local dragThickness = 3.5 + pulse * 1.5
                VisualRenderer.SetLineTransform(
                    dragLineCtrl,
                    sourceNode.x, sourceNode.y,
                    inputState.dragCurrentX, inputState.dragCurrentY,
                    dragThickness,
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

-- 更新地脉节点各层视觉呈现（差速自转、心跳呼吸、拖拽拓扑高亮、文字描边与字号动态映射）
function VisualRenderer.UpdateNodes(nodeUIList, nodes, elapsedTime, inputState)
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
            local isSource = (isDragging and node.id == dragSourceId)
            local isValidNeighbor = (isDragging and validNeighborsMap[node.id])

            -- 0. 节点整体缩放与明暗处理 (拖拽连线时合法邻居高亮并轻微放大，非邻居半透明压暗)
            if isDragging then
                if isSource then
                    ui.group.localScaleX = 1.18
                    ui.group.localScaleY = 1.18
                elseif isValidNeighbor then
                    local neighPulse = 1.12 + 0.05 * math.sin(elapsedTime * 6.0 + node.id)
                    ui.group.localScaleX = neighPulse
                    ui.group.localScaleY = neighPulse
                else
                    ui.group.localScaleX = 0.95
                    ui.group.localScaleY = 0.95
                end
            else
                -- 正常对局底盘心跳呼吸：休眠节点缩小，活跃节点轻微脉动
                local baseScale = node.isIdle and 0.88 or (1.0 + 0.035 * math.sin(elapsedTime * 3.2 + node.id))
                ui.group.localScaleX = baseScale
                ui.group.localScaleY = baseScale
            end

            -- 1. 固守结界环 (第一层：顺时针差速自转，护盾激活时加速旋转 90 deg/s)
            if ui.defenseRing and ui.defenseRing.alive then
                local isShielded = (node.protectedUntil and node.protectedUntil > elapsedTime)
                local rotSpeed = isShielded and 90 or 18
                ui.defenseRing.localRotationZ = (elapsedTime * rotSpeed + node.id * 37) % 360

                if node.isDefensive and node.routeTo == nil then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.GOLD_ALPHA
                elseif isShielded then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.ANEMO
                elseif isValidNeighbor then
                    -- 拖拽经过合法邻居时闪耀金环指引
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.GOLD
                else
                    Layout.SetVisible(ui.defenseRing, false)
                end
            end

            -- 2. 节点主体共鸣外环 (第二层：逆时针微转，平滑填充过渡，消除每帧 pcall)
            if ui.resonanceRing and ui.resonanceRing.alive then
                ui.resonanceRing.localRotationZ = -(elapsedTime * 12 + node.id * 23) % 360

                if isDragging and not isSource and not isValidNeighbor then
                    ui.resonanceRing.imageColor = Layout.WithAlpha(factionColor, 95)
                else
                    ui.resonanceRing.imageColor = factionColor
                end

                local targetProgress = Layout.Clamp(node.control / 100, 0.05, 1.0)
                ui.currentFill = (ui.currentFill or targetProgress) + (targetProgress - (ui.currentFill or targetProgress)) * 0.2

                if not VisualRenderer.hasRadialApiChecked then
                    VisualRenderer.hasRadialApiChecked = true
                    VisualRenderer.hasRadialApi = (ui.resonanceRing.SetFillRadial360 ~= nil)
                end

                if VisualRenderer.hasRadialApi then
                    ui.resonanceRing:SetFillRadial360(Enum.ImageFillRadialType.Top, ui.currentFill)
                else
                    ui.resonanceRing.fillAmount = ui.currentFill
                end
            end

            -- 3. 兵力与灵穴名称统筹呈现 (统一深色描边 + 兵力字号动态映射)
            local currentParts = math.floor(node.particles or 0)
            if ui.titleText and ui.titleText.alive then
                -- 启用深色描边
                if ui.titleText.enableOutline ~= nil and not ui.titleText._outlined then
                    ui.titleText.enableOutline = true
                    ui.titleText.outlineColor = Layout.MakeColor(15, 20, 35, 230)
                    ui.titleText._outlined = true
                end

                -- 动态映射字号：兵力越充沛越具威慑感 (12 ~ 15)
                local dynamicFontSize = math.floor(Layout.Clamp(12 + currentParts * 0.08, 12, 15))
                if ui.titleText.fontSize ~= dynamicFontSize then
                    ui.titleText.fontSize = dynamicFontSize
                end

                ui.titleText.text = string.format("%s (%d)", node.name, currentParts)
                if isDragging and not isSource and not isValidNeighbor then
                    ui.titleText.fontColor = Layout.WithAlpha(Layout.PALETTE.TEXT_LIGHT, 120)
                else
                    ui.titleText.fontColor = Layout.PALETTE.TEXT_LIGHT
                end
                Layout.SetVisible(ui.titleText, true)
            end

            if ui.particleText and ui.particleText.alive then
                Layout.SetVisible(ui.particleText, false)
            end

            -- 4. 异象标识文本 (统一加深色描边)
            if ui.anomalyText and ui.anomalyText.alive then
                if ui.anomalyText.enableOutline ~= nil and not ui.anomalyText._outlined then
                    ui.anomalyText.enableOutline = true
                    ui.anomalyText.outlineColor = Layout.MakeColor(15, 20, 35, 230)
                    ui.anomalyText._outlined = true
                end

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
                elseif node.anomaly == "DEFENSE_BASTION" then
                    ui.anomalyText.text = "【雷暴要塞】"
                    ui.anomalyText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "PURE_WATER" then
                    ui.anomalyText.text = "【纯水枢纽】"
                    ui.anomalyText.fontColor = Layout.PALETTE.PLAYER
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "PLASMA" then
                    ui.anomalyText.text = "【赤阳熔核】"
                    ui.anomalyText.fontColor = Layout.PALETTE.ENEMY
                    Layout.SetVisible(ui.anomalyText, true)
                else
                    Layout.SetVisible(ui.anomalyText, false)
                end
            end

            -- 5. 占领进度与状态标签
            if ui.statusText and ui.statusText.alive then
                if ui.statusText.enableOutline ~= nil and not ui.statusText._outlined then
                    ui.statusText.enableOutline = true
                    ui.statusText.outlineColor = Layout.MakeColor(15, 20, 35, 230)
                    ui.statusText._outlined = true
                end

                if node.faction == "neutral" then
                    if (node.control or 0) > 0 and node.contenderFaction then
                        local fName = Layout.GetFactionName(node.contenderFaction)
                        local col = Layout.GetFactionColor(node.contenderFaction)
                        ui.statusText.text = string.format("[%s掌控 %d%%]", fName, math.floor(node.control))
                        ui.statusText.fontColor = col
                        Layout.SetVisible(ui.statusText, true)
                    else
                        Layout.SetVisible(ui.statusText, false)
                    end
                elseif node.faction ~= "neutral" and (node.control or 100) < 100 then
                    local fName = Layout.GetFactionName(node.faction)
                    local col = Layout.GetFactionColor(node.faction)
                    ui.statusText.text = string.format("[%s动摇 %d%%]", fName, math.floor(node.control or 100))
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

-- 关卡拓扑几何重布局 (按当前章节的节点坐标与连线刷新沙盘)
function VisualRenderer.ApplyStageLayout(nodeUIList, nodes, staticLinkCtrls, links)
    -- 1. 更新节点位置与可见性
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

    -- 2. 更新静态底轨连线
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
