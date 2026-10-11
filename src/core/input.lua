-- src/core/input.lua
-- 全局全屏输入适配器与光标事件分发

local Input = {
    isDragging = false,
    dragSourceId = nil,
    dragCurrentX = 0,
    dragCurrentY = 0,
    pressStartX = 0,
    pressStartY = 0,
    selectedCardIndex = nil,

    -- 回调事件注册
    onNodeClicked = nil,      -- fun(nodeId)
    onRouteCreated = nil,     -- fun(fromId, toId)
    onCardCast = nil          -- fun(cardIndex, targetNodeId)
}

local DRAG_THRESHOLD = 15 -- 像素防抖阈值

function Input.SetSelectedCard(index)
    Input.selectedCardIndex = index
end

function Input.GetSelectedCard()
    return Input.selectedCardIndex
end

function Input.ClearSelectedCard()
    Input.selectedCardIndex = nil
end

function Input.FindNodeAtPos(x, y, nodes)
    for _, node in ipairs(nodes) do
        local dx = node.x - x
        local dy = node.y - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= (node.radius + 18) then
            return node
        end
    end
    return nil
end

function Input.OnCursorDown(x, y, nodes)
    Input.pressStartX = x
    Input.pressStartY = y
    Input.dragCurrentX = x
    Input.dragCurrentY = y

    local clickedNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Down at (%.1f, %.1f), hit = %s", x, y, clickedNode and clickedNode.name or "none"))

    -- 若当前已选中卡牌，直接作为技能目标拾取
    if Input.selectedCardIndex and clickedNode then
        if Input.onCardCast then
            Input.onCardCast(Input.selectedCardIndex, clickedNode.id)
        end
        Input.selectedCardIndex = nil
        return
    end

    -- 若点击己方灵穴，启动拖拽连线准备
    if clickedNode and clickedNode.faction == "player" then
        Input.isDragging = true
        Input.dragSourceId = clickedNode.id
    else
        Input.isDragging = false
        Input.dragSourceId = nil
    end
end

function Input.OnCursorDrag(x, y)
    if Input.isDragging then
        Input.dragCurrentX = x
        Input.dragCurrentY = y
    end
end

function Input.OnCursorUp(x, y, nodes)
    if not Input.isDragging and not Input.dragSourceId then
        return
    end

    local sourceId = Input.dragSourceId
    local targetNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Up at (%.1f, %.1f), target = %s", x, y, targetNode and targetNode.name or "none"))

    local movedDist = math.sqrt((x - Input.pressStartX) ^ 2 + (y - Input.pressStartY) ^ 2)

    if targetNode and targetNode.id ~= sourceId then
        -- 成功拖至不同节点：建立航线
        if Input.onRouteCreated then
            Input.onRouteCreated(sourceId, targetNode.id)
        end
    elseif movedDist < DRAG_THRESHOLD or (targetNode and targetNode.id == sourceId) then
        -- 原地轻点或微小位移：激活固守 / 切断光轨
        if Input.onNodeClicked and sourceId then
            Input.onNodeClicked(sourceId)
        end
    end

    Input.isDragging = false
    Input.dragSourceId = nil
end

return Input
