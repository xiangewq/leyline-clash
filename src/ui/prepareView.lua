-- src/ui/prepareView.lua
-- 战前符印调配界面（12点权能预算、自选卡组装配、视觉差分效果与确认开启）

local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local PrepareView = {
    selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }, -- 初始预选 9 点预算 (2+3+4)
    maxBudget = 12,
    maxCards = 4,
    onStartMatch = nil,

    POOL_ORDER = {
        "anemo_shield",
        "anemo_turb",
        "pyro_blast",
        "hydro_bribe",
        "geo_wall",
        "pyro_erosion"
    }
}

function PrepareView.Init(onStartMatchCallback)
    if not PrepareView.selectedIds or #PrepareView.selectedIds == 0 then
        PrepareView.selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }
    end
    PrepareView.maxBudget = BalanceConfig.MAX_BUDGET or 12
    PrepareView.maxCards = 4
    if onStartMatchCallback then
        PrepareView.onStartMatch = onStartMatchCallback
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
            return true, "unequipped", cardId
        end
    end

    -- 尝试添加装配
    if #PrepareView.selectedIds >= PrepareView.maxCards then
        return false, string.format("最多仅能装配 %d 张战术符印！请先点击卸下已选符印。", PrepareView.maxCards)
    end

    local card = CardRegistry.GetCardById(cardId)
    if not card then return false, "未知符印类型！" end

    local currentUsed = PrepareView.GetUsedBudget()
    if (currentUsed + card.cost) > PrepareView.maxBudget then
        return false, string.format("权能预算不足！当前已用 %d 点，该符印需 %d 点（上限 %d 点）。", currentUsed, card.cost, PrepareView.maxBudget)
    end

    table.insert(PrepareView.selectedIds, cardId)
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
            end
        end
    end

    local used = PrepareView.GetUsedBudget()
    local count = #PrepareView.selectedIds

    -- 5. 预算文字更新
    if budgetTextCtrl and budgetTextCtrl.alive then
        budgetTextCtrl.text = string.format("当前调配权能预算：%d / %d 点 （已装配 %d / %d 张）", used, PrepareView.maxBudget, count, PrepareView.maxCards)
    end

    -- 6. 卡组概要提示更新
    if hintTextCtrl and hintTextCtrl.alive then
        if count > 0 then
            local names = {}
            for _, id in ipairs(PrepareView.selectedIds) do
                local c = CardRegistry.GetCardById(id)
                if c then
                    table.insert(names, string.format("%s(%d点)", c.name, c.cost))
                end
            end
            hintTextCtrl.text = "已选符印：" .. table.concat(names, " + ")
        else
            hintTextCtrl.text = "尚未装配任何符印，请点击上方卡牌进行调配！"
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
