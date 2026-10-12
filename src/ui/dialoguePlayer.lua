-- src/ui/dialoguePlayer.lua
-- 开场逐字剧情演播器（阿贝多与派蒙台词演出、跳过与推进）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local DialoguePlayer = {
    DIALOGUES = {
        {
            speaker = "派蒙",
            color = Layout.PALETTE.GOLD,
            content = "哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！"
        },
        {
            speaker = "阿贝多",
            color = Layout.PALETTE.PLAYER,
            content = "呵呵，派蒙，这可不能吃。这是我和教令院学者共同复原的\n古代战争推衍法器——「地脉星图棋盘」。"
        },
        {
            speaker = "阿贝多",
            color = Layout.PALETTE.PLAYER,
            content = "盘面上每一个光点都象征着一处地脉灵穴，而流动的光尘则是纯净元素微粒。\n拖拽己方灵穴铺设光轨，轻点灵穴收拢防御。"
        },
        {
            speaker = "派蒙",
            color = Layout.PALETTE.GOLD,
            content = "听起来很有意思！旅行者，快调配你的战术符印，\n我们一起执掌星盘赢得推衍吧！"
        }
    },
    currentIndex = 1,
    charIndex = 0,
    charTimer = 0,
    isComplete = false,
    onFinished = nil
}

function DialoguePlayer.Init(dialoguesOrCb, onFinishedCallback)
    if type(dialoguesOrCb) == "table" then
        DialoguePlayer.currentList = dialoguesOrCb
        DialoguePlayer.onFinished = onFinishedCallback
    else
        DialoguePlayer.currentList = DialoguePlayer.DIALOGUES
        DialoguePlayer.onFinished = dialoguesOrCb
    end
    DialoguePlayer.currentIndex = 1
    DialoguePlayer.charIndex = 0
    DialoguePlayer.charTimer = 0
    DialoguePlayer.isComplete = false
end

function DialoguePlayer.GetCurrentLine()
    local list = DialoguePlayer.currentList or DialoguePlayer.DIALOGUES
    return list[DialoguePlayer.currentIndex]
end

function DialoguePlayer.Update(dt, speakerTextCtrl, contentTextCtrl)
    if DialoguePlayer.isComplete then return end

    local line = DialoguePlayer.GetCurrentLine()
    if not line then
        DialoguePlayer.Finish()
        return
    end

    if speakerTextCtrl and speakerTextCtrl.alive then
        speakerTextCtrl.text = "【" .. line.speaker .. "】"
        local col = line.color
        if not col then
            if line.speaker == "阿贝多" then
                col = Layout.PALETTE.PLAYER
            elseif line.speaker == "派蒙" then
                col = Layout.PALETTE.GOLD
            else
                col = Layout.PALETTE.TEXT_LIGHT
            end
        end
        local colInt = type(col) == "number" and col or (Layout and Layout.ToColorInt and Layout.ToColorInt(col) or Layout.PALETTE.GOLD)
        pcall(function() speakerTextCtrl.fontColor = colInt end)
    end


    DialoguePlayer.charTimer = DialoguePlayer.charTimer + dt
    if DialoguePlayer.charTimer >= 0.03 then
        DialoguePlayer.charTimer = 0
        local totalLen = utf8 and utf8.len(line.content) or string.len(line.content)
        if DialoguePlayer.charIndex < totalLen then
            DialoguePlayer.charIndex = DialoguePlayer.charIndex + 1
        end
    end

    if contentTextCtrl and contentTextCtrl.alive then
        -- 简易截取或直接呈现全段文字
        contentTextCtrl.text = line.content
    end
end

function DialoguePlayer.Next()
    if DialoguePlayer.currentIndex < #DialoguePlayer.DIALOGUES then
        DialoguePlayer.currentIndex = DialoguePlayer.currentIndex + 1
        DialoguePlayer.charIndex = 0
    else
        DialoguePlayer.Finish()
    end
end

function DialoguePlayer.Skip()
    DialoguePlayer.Finish()
end

function DialoguePlayer.Finish()
    DialoguePlayer.isComplete = true
    if DialoguePlayer.onFinished then
        DialoguePlayer.onFinished()
    end
end

return DialoguePlayer
