-- src/ui/dialoguePlayer.lua
-- 开场逐字剧情演示播报 (UTF-8 安全逐字打印、原神剧场级对话框、呼吸光标提示)

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local DialoguePlayer = {
    DIALOGUES = {
        {
            speaker = "派蒙",
            title   = "最好的伙伴",
            color   = Layout.PALETTE.GOLD,
            content = "哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！"
        },
        {
            speaker = "阿贝多",
            title   = "白垩之子",
            color   = Layout.PALETTE.PLAYER,
            content = "呵呵，派蒙，这可不能吃。这是我和教令院学者共同复原的\n古代战争推衍法器——「地脉星图棋盘」。"
        },
        {
            speaker = "阿贝多",
            title   = "白垩之子",
            color   = Layout.PALETTE.PLAYER,
            content = "盘面上每一个光点都象征着一处地脉星枢，而流动的光尘则是纯净元素微粒。\n拖拽己方星枢铺设光轨，轻点星枢即可收拢固守。"
        },
        {
            speaker = "派蒙",
            title   = "最好的伙伴",
            color   = Layout.PALETTE.GOLD,
            content = "听起来很有意思！旅行者，快调配你的战术符印，\n让我们一起执掌星盘赢得推衍吧！"
        }
    },
    currentIndex = 1,
    charIndex = 0,
    charTimer = 0,
    elapsed = 0,
    isComplete = false,
    isStyleApplied = false,
    onFinished = nil
}

-- UTF-8 安全步进函数：从当前字节位置向前推进 count 个完整 UTF-8 字符，避免切断 3 字节中文产生乱码
local function StepUTF8ByteIndex(str, currentByteIdx, charStepCount)
    local len = #str
    local idx = currentByteIdx or 0
    for _ = 1, (charStepCount or 1) do
        if idx >= len then return len end
        local nextPos = idx + 1
        local b = string.byte(str, nextPos)
        if not b then return len end
        local charBytes = 1
        if b >= 240 then
            charBytes = 4
        elseif b >= 224 then
            charBytes = 3
        elseif b >= 192 then
            charBytes = 2
        end
        idx = math.min(len, idx + charBytes)
    end
    return idx
end

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
    DialoguePlayer.elapsed = 0
    DialoguePlayer.isComplete = false
    DialoguePlayer.isStyleApplied = false
end

function DialoguePlayer.GetCurrentLine()
    local list = DialoguePlayer.currentList or DialoguePlayer.DIALOGUES
    return list[DialoguePlayer.currentIndex]
end

function DialoguePlayer.Update(dt, speakerTextCtrl, contentTextCtrl)
    if DialoguePlayer.isComplete then return end

    DialoguePlayer.elapsed = (DialoguePlayer.elapsed or 0) + dt

    if not DialoguePlayer.isStyleApplied then
        DialoguePlayer.isStyleApplied = true
        Layout.ApplyTextStyle(speakerTextCtrl, 20, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
        Layout.ApplyTextStyle(contentTextCtrl, 17, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
        pcall(function() contentTextCtrl.lineSpacing = 1.25 end)
    end

    local cur = DialoguePlayer.GetCurrentLine()
    if not cur then
        DialoguePlayer.Finish()
        return
    end

    if speakerTextCtrl and speakerTextCtrl.alive then
        local titleSuffix = cur.title and (" · 「" .. cur.title .. "」") or ""
        speakerTextCtrl.text = "✦ " .. tostring(cur.speaker or "") .. titleSuffix
        speakerTextCtrl.fontColor = cur.color or Layout.PALETTE.GOLD
    end

    local fullText = cur.content or ""
    local totalBytes = #fullText

    if DialoguePlayer.charIndex < totalBytes then
        DialoguePlayer.charTimer = DialoguePlayer.charTimer + dt
        if DialoguePlayer.charTimer >= 0.028 then
            DialoguePlayer.charTimer = 0
            DialoguePlayer.charIndex = StepUTF8ByteIndex(fullText, DialoguePlayer.charIndex, 1)
        end
    end

    if contentTextCtrl and contentTextCtrl.alive then
        local subStr = string.sub(fullText, 1, DialoguePlayer.charIndex)
        -- 整句打字完毕后，在句末追加呼吸闪烁的光标；打字中展示推进星芒
        if DialoguePlayer.charIndex >= totalBytes then
            local cursor = (math.floor(DialoguePlayer.elapsed * 3) % 2 == 0) and "  ▾" or "  ▿"
            contentTextCtrl.text = subStr .. cursor
        else
            contentTextCtrl.text = subStr .. " ✦"
        end
    end
end

function DialoguePlayer.Next()
    local cur = DialoguePlayer.GetCurrentLine()
    if not cur then return end
    local fullText = cur.content or ""

    if DialoguePlayer.charIndex < #fullText then
        -- 点击快速完成当前句打字
        DialoguePlayer.charIndex = #fullText
    else
        DialoguePlayer.currentIndex = DialoguePlayer.currentIndex + 1
        DialoguePlayer.charIndex = 0
        DialoguePlayer.charTimer = 0
        local list = DialoguePlayer.currentList or DialoguePlayer.DIALOGUES
        if DialoguePlayer.currentIndex > #list then
            DialoguePlayer.Finish()
        end
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
