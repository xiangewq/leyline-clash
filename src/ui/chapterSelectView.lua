-- src/ui/chapterSelectView.lua
-- 战役章节选择面板（5 大关卡展示、解锁进度判定、选关差分表现与出征确认）

local ChapterConfig = require("default_import_file/src/data/chapterConfig") or require("src/data/chapterConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")

local ChapterSelectView = {
    unlockedStage = 1,
    selectedStage = 1,
    onStartStage = nil,
    onBack = nil
}

function ChapterSelectView.Init(onStartStageCb, onBackCb)
    ChapterSelectView.onStartStage = onStartStageCb
    ChapterSelectView.onBack = onBackCb
end

function ChapterSelectView.UnlockNextStage(completedStage)
    if completedStage and completedStage >= ChapterSelectView.unlockedStage then
        ChapterSelectView.unlockedStage = math.min(5, completedStage + 1)
    end
end

function ChapterSelectView.SelectStage(stageId)
    if stageId > ChapterSelectView.unlockedStage then
        return false, "该关卡尚未解锁，请先通关前序章节！"
    end
    ChapterSelectView.selectedStage = stageId
    return true
end

-- 渲染章节卡片与信息展示
function ChapterSelectView.Render(chapterCards, descTextCtrl, startBtnTxtCtrl)
    local selectedChap = ChapterConfig.GetChapter(ChapterSelectView.selectedStage)

    if chapterCards then
        for i = 1, 5 do
            local cardUI = chapterCards[i]
            local chap = ChapterConfig.GetChapter(i)
            if cardUI and chap then
                local isUnlocked = (i <= ChapterSelectView.unlockedStage)
                local isSelected = (i == ChapterSelectView.selectedStage)

                -- 1. 边框发光
                if cardUI.borderCtrl and cardUI.borderCtrl.alive then
                    if isSelected then
                        cardUI.borderCtrl.imageColor = Layout.PALETTE.GOLD
                    elseif isUnlocked then
                        cardUI.borderCtrl.imageColor = Layout.PALETTE.PLAYER
                    else
                        cardUI.borderCtrl.imageColor = Layout.MakeColor(51, 65, 85, 255)
                    end
                end

                -- 2. 背景明暗
                if cardUI.bgCtrl and cardUI.bgCtrl.alive then
                    if isSelected then
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(30, 58, 95, 255)
                    elseif isUnlocked then
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(15, 23, 42, 255)
                    else
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(10, 15, 26, 255)
                    end
                end

                -- 3. 标题
                if cardUI.titleCtrl and cardUI.titleCtrl.alive then
                    cardUI.titleCtrl.text = chap.title
                    cardUI.titleCtrl.fontColor = isSelected and Layout.PALETTE.GOLD or (isUnlocked and Layout.PALETTE.TEXT_LIGHT or Layout.PALETTE.TEXT_MUTED)
                end

                -- 4. 概要 (灵穴数 / 阵营数 / 权能)
                if cardUI.infoCtrl and cardUI.infoCtrl.alive then
                    local fCount = #chap.factions
                    local nCount = #chap.nodes
                    cardUI.infoCtrl.text = string.format("%d方混战 | %d灵穴 | %d权能", fCount, nCount, chap.budget)
                    cardUI.infoCtrl.fontColor = isUnlocked and Layout.PALETTE.AMBER or Layout.PALETTE.TEXT_MUTED
                end

                -- 5. 状态角标
                if cardUI.tagCtrl and cardUI.tagCtrl.alive then
                    if isSelected then
                        cardUI.tagCtrl.text = "【★ 当前选择】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.GOLD
                    elseif isUnlocked then
                        cardUI.tagCtrl.text = "【已解锁】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.PLAYER
                    else
                        cardUI.tagCtrl.text = "【锁定中】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
                    end
                end
            end
        end
    end

    -- 6. 描述文本
    if descTextCtrl and descTextCtrl.alive and selectedChap then
        descTextCtrl.text = string.format("【%s】\n%s\n%s", selectedChap.title, selectedChap.subtitle, selectedChap.desc)
    end

    -- 7. 出征按钮文本
    if startBtnTxtCtrl and startBtnTxtCtrl.alive and selectedChap then
        startBtnTxtCtrl.text = string.format("【启程出征 · 第 %d 关】", selectedChap.id)
    end
end

return ChapterSelectView
