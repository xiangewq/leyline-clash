-- src/ui/prepareView.lua
-- 战前符印调配界面（12点权能预算、自选卡组装配与确认开启）

local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")

local PrepareView = {
    selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }, -- 初始预选 9 点预算 (2+3+4)
    maxBudget = 12,
    onStartMatch = nil
}

function PrepareView.Init(onStartMatchCallback)
    PrepareView.selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }
    PrepareView.maxBudget = BalanceConfig.MAX_BUDGET
    PrepareView.onStartMatch = onStartMatchCallback
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
    for idx, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then
            table.remove(PrepareView.selectedIds, idx)
            return true
        end
    end

    -- 尝试添加
    if #PrepareView.selectedIds >= 4 then
        return false, "最多仅能携带 4 张战术符印！"
    end

    local card = CardRegistry.GetCardById(cardId)
    if not card then return false, "未知符印" end

    if (PrepareView.GetUsedBudget() + card.cost) > PrepareView.maxBudget then
        return false, "权能预算不足！当前上限 12 点。"
    end

    table.insert(PrepareView.selectedIds, cardId)
    return true
end

function PrepareView.ConfirmAndStart()
    if #PrepareView.selectedIds == 0 then
        -- 若未选则装配推荐卡
        PrepareView.selectedIds = { "anemo_shield", "anemo_turb", "pyro_blast" }
    end
    if PrepareView.onStartMatch then
        PrepareView.onStartMatch(PrepareView.selectedIds)
    end
end

return PrepareView
