-- src/ui/prepareView.lua
-- 战前符印调配界面（12点权能预算、自选卡组装配、视觉差分效果与确认开启）

local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local PrepareView = {
    selectedIds = { "anemo_shield", "pyro_erosion" }, -- 初始预选低耗核心
    maxBudget = 12,
    maxCards = 4,
    onStartMatch = nil,
    lastWarning = nil,
    warningTimer = 0,

    -- 战术符印按权能消耗升序排列 (2点 -> 2点 -> 3点 -> 4点 -> 4点 -> 5点)
    POOL_ORDER = {
        "anemo_shield",  -- 2点
        "pyro_erosion",  -- 2点
        "anemo_turb",    -- 3点
        "pyro_blast",    -- 4点
        "geo_wall",      -- 4点
        "hydro_bribe"    -- 5点
    }
}

function PrepareView.Init(budgetOrCb, onStartMatchCallback)
    local budget = 12
    local cb = nil
    if type(budgetOrCb) == "number" then
        budget = budgetOrCb
        cb = onStartMatchCallback
    else
        cb = budgetOrCb
        budget = BalanceConfig.MAX_BUDGET or 12
    end
    PrepareView.maxBudget = budget
    PrepareView.maxCards = 4
    PrepareView.lastWarning = nil
    PrepareView.warningTimer = 0
    if cb then
        PrepareView.onStartMatch = cb
    end

    if not PrepareView.selectedIds or #PrepareView.selectedIds == 0 then
        PrepareView.selectedIds = { "anemo_shield" }
    end

    -- 自动校验修剪超限符印
    while #PrepareView.selectedIds > 0 and PrepareView.GetUsedBudget() > PrepareView.maxBudget do
        table.remove(PrepareView.selectedIds)
    end
    if #PrepareView.selectedIds == 0 then
        for _, cKey in ipairs(PrepareView.POOL_ORDER) do
            local c = CardRegistry.GetCardById(cKey)
            if c and c.cost <= PrepareView.maxBudget then
                table.insert(PrepareView.selectedIds, cKey)
                break
            end
        end
    end

    -- 确保装配卡片默认按消耗权能升序排列
    table.sort(PrepareView.selectedIds, function(a, b)
        local cA = CardRegistry.GetCardById(a)
        local cB = CardRegistry.GetCardById(b)
        if cA and cB and cA.cost ~= cB.cost then
            return cA.cost < cB.cost
        end
        return false
    end)
end

function PrepareView.Update(dt)
    if PrepareView.warningTimer and PrepareView.warningTimer > 0 then
        PrepareView.warningTimer = PrepareView.warningTimer - dt
        if PrepareView.warningTimer <= 0 then
            PrepareView.lastWarning = nil
        end
    end
end

function PrepareView.GetUsedBudget()
    local sum = 0
    for _, id in ipairs(PrepareView.selectedIds) do
        local card = CardRegistry.GetCardById(id)
        if card then sum = sum + card.cost end
    end
    return sum
end

function PrepareView.IsCardSelected(cardId)
    for _, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then return true end
    end
    return false
end

function PrepareView.ToggleCard(cardId)
    -- 若已选，则反选移除
    for idx, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then
            table.remove(PrepareView.selectedIds, idx)
            PrepareView.lastWarning = nil
            PrepareView.warningTimer = 0
            return true, "unequipped", cardId
        end
    end

    -- 尝试添加装配
    if #PrepareView.selectedIds >= PrepareView.maxCards then
        local warnMsg = string.format("符印槽位已满！最多仅能装配 %d 张符印", PrepareView.maxCards)
        PrepareView.lastWarning = warnMsg
        PrepareView.warningTimer = 3.0
        return false, string.format("最多仅能装配 %d 张战术符印！请先点击卸下已选符印。", PrepareView.maxCards)
    end

    local card = CardRegistry.GetCardById(cardId)
    if not card then return false, "未知符印类型！" end

    local currentUsed = PrepareView.GetUsedBudget()
    if (currentUsed + card.cost) > PrepareView.maxBudget then
        local warnMsg = string.format("权能预算不足！超限 %d 点（已用 %d/%d，该符印需 %d 点）", (currentUsed + card.cost) - PrepareView.maxBudget, currentUsed, PrepareView.maxBudget, card.cost)
        PrepareView.lastWarning = warnMsg
        PrepareView.warningTimer = 3.0
        return false, string.format("【预算不足】当前已用 %d 点，该符印需 %d 点（上限 %d 点）！", currentUsed, card.cost, PrepareView.maxBudget)
    end

    PrepareView.lastWarning = nil
    PrepareView.warningTimer = 0
    table.insert(PrepareView.selectedIds, cardId)

    -- 保持装配卡牌按权能消耗升序排列
    table.sort(PrepareView.selectedIds, function(a, b)
        local cA = CardRegistry.GetCardById(a)
        local cB = CardRegistry.GetCardById(b)
        if cA and cB and cA.cost ~= cB.cost then
            return cA.cost < cB.cost
        end
        return false
    end)

    return true, "equipped", cardId
end

-- 刷新调配界面差分视觉表现（边框高亮、背景深浅、角标切换与预算提示）
function PrepareView.Render(cardUIList, budgetTextCtrl, hintTextCtrl)
    if cardUIList then
        for idx, cardKey in ipairs(PrepareView.POOL_ORDER) do
            local ui = cardUIList[idx]
            local card = CardRegistry.GetCardById(cardKey)
            if ui and card then
                local isSel = PrepareView.IsCardSelected(cardKey)

                -- 1. 边框高光差分
                if ui.borderCtrl and ui.borderCtrl.alive then
                    ui.borderCtrl.imageColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(71, 85, 105, 255)
                end

                -- 2. 背景明暗差分
                if ui.bgCtrl and ui.bgCtrl.alive then
                    ui.bgCtrl.imageColor = isSel and Layout.MakeColor(30, 58, 95, 255) or Layout.MakeColor(15, 23, 42, 255)
                end

                -- 3. 名称文本差分 (选中附带醒目 [✓] 标识)
                if ui.nameCtrl and ui.nameCtrl.alive then
                    ui.nameCtrl.text = isSel and ("[✓] " .. card.name) or card.name
                    ui.nameCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.PALETTE.TEXT_MUTED
                end

                -- 4. 选中状态角标
                if ui.checkCtrl and ui.checkCtrl.alive then
                    ui.checkCtrl.text = isSel and "【★ 已装配】" or "【点击装配】"
                    ui.checkCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(100, 116, 139, 255)
                end

                -- 5. 消耗与 CD 明确标注 (要求2: 符印CD写在配置界面)
                if ui.costCtrl and ui.costCtrl.alive then
                    ui.costCtrl.text = string.format("消耗: %d 权能  |  CD: %d秒", card.cost, card.cd)
                    ui.costCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(251, 191, 36, 255)
                end

                -- 6. 描述文本
                if ui.descCtrl and ui.descCtrl.alive then
                    ui.descCtrl.text = card.desc
                end
            end
        end
    end

    local used = PrepareView.GetUsedBudget()
    local count = #PrepareView.selectedIds
    local isWarning = (PrepareView.warningTimer and PrepareView.warningTimer > 0 and PrepareView.lastWarning ~= nil)

    -- 5. 预算文字更新 (若预算超限，文字变红高亮警示)
    if budgetTextCtrl and budgetTextCtrl.alive then
        budgetTextCtrl.text = string.format("当前调配权能预算：%d / %d 点 （已装配 %d / %d 张）", used, PrepareView.maxBudget, count, PrepareView.maxCards)
        if isWarning then
            budgetTextCtrl.fontColor = Layout.MakeColor(244, 63, 94, 255) -- 警示玫瑰红
        else
            budgetTextCtrl.fontColor = Layout.MakeColor(56, 189, 248, 255) -- 正常青蓝
        end
    end

    -- 6. 卡组概要/超限告警更新 (要求3: 界面内显眼大字提示预算不足)
    if hintTextCtrl and hintTextCtrl.alive then
        if isWarning then
            hintTextCtrl.text = "⚠️ " .. PrepareView.lastWarning
            hintTextCtrl.fontColor = Layout.MakeColor(244, 63, 94, 255) -- 醒目赤红预警
        elseif count > 0 then
            local names = {}
            for _, id in ipairs(PrepareView.selectedIds) do
                local c = CardRegistry.GetCardById(id)
                if c then
                    table.insert(names, string.format("%s(%d点·CD%ds)", c.name, c.cost, c.cd))
                end
            end
            hintTextCtrl.text = "已选符印：" .. table.concat(names, " + ")
            hintTextCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
        else
            hintTextCtrl.text = "尚未装配任何符印，请点击上方卡牌进行调配！"
            hintTextCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
        end
    end
end

function PrepareView.ConfirmAndStart()
    if #PrepareView.selectedIds == 0 then
        return false, "请至少装配 1 张战术符印后再启阵出征！"
    end
    if PrepareView.onStartMatch then
        PrepareView.onStartMatch(PrepareView.selectedIds)
    end
    return true
end

return PrepareView
