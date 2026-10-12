-- src/ui/modeSelectView.lua
-- 游戏模式选择主界面（剧情模式 vs 挑战模式·待完成）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local ModeSelectView = {
    onSelectStory = nil,
    onSelectChallenge = nil
}

function ModeSelectView.Init(onSelectStoryCb, onSelectChallengeCb)
    ModeSelectView.onSelectStory = onSelectStoryCb
    ModeSelectView.onSelectChallenge = onSelectChallengeCb
end

function ModeSelectView.Show(modalCtrl)
    Layout.SetVisible(modalCtrl, true)
end

function ModeSelectView.Hide(modalCtrl)
    Layout.SetVisible(modalCtrl, false)
end

return ModeSelectView
