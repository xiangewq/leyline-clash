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
                    -- 处于「疾风流道」(千风隘口) 或施加「千风湍流」符印：激活提瓦特千风翠绿粗流道特效 (10粒/秒高速流)
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

            -- 3. 兵力与灵穴名称显示 (由 TitleText 居中统筹呈现：灵穴名称 (兵力)，如 西风前哨 (20))
            local currentParts = math.floor(node.particles or 0)
            if ui.titleText and ui.titleText.alive then
                ui.titleText.text = string.format("%s (%d)", node.name, currentParts)
                ui.titleText.fontColor = Layout.PALETTE.TEXT_LIGHT
                Layout.SetVisible(ui.titleText, true)
            end

            -- particleText 隐藏，避免在 52px 紧凑圆盘中与 TitleText 产生双层重叠
            if ui.particleText and ui.particleText.alive then
                Layout.SetVisible(ui.particleText, false)
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

            -- 5. 占领进度与状态标签 (占领中/动摇中/输送中/固守中/休眠中)
            if ui.statusText and ui.statusText.alive then
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
                local nA = nodes[link[1] + 1]
                local nB = nodes[link[2] + 1]
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
