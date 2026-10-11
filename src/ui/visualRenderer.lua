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
