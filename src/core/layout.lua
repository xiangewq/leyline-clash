-- src/core/layout.lua
-- 坐标计算、几何变换与提瓦特纯代码调色板

local Layout = {}

-- 几何与数学工具
function Layout.Distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Layout.AngleDeg(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local rad = math.atan(dy, dx)
    return math.deg(rad)
end

function Layout.Clamp(val, minVal, maxVal)
    if val < minVal then return minVal end
    if val > maxVal then return maxVal end
    return val
end

-- 安全设置控件可见性 (支持真机与模拟器 SetVisible 方法)
function Layout.SetVisible(ctrl, isVisible)
    if not ctrl or not ctrl.alive then return end
    if ctrl.SetVisible then
        ctrl:SetVisible(isVisible)
    else
        pcall(function() ctrl.visible = isVisible end)
    end
end

-- 颜色构造工具 (适配千星沙箱 Color 构造函数与 packed uint32 整数)
function Layout.MakeColor(r, g, b, a)
    local R = (r <= 1 and r > 0) and math.floor(r * 255) or math.floor(r or 0)
    local G = (g <= 1 and g > 0) and math.floor(g * 255) or math.floor(g or 0)
    local B = (b <= 1 and b > 0) and math.floor(b * 255) or math.floor(b or 0)
    local rawA = a == nil and 255 or a
    local A = (rawA <= 1 and rawA > 0) and math.floor(rawA * 255) or math.floor(rawA)

    if Color then
        if Color.FromRGBA then
            local ok, col = pcall(function() return Color.FromRGBA(R, G, B, A) end)
            if ok and col and type(col) == "number" then return math.tointeger(col) or math.floor(col) end
        end
        local ok, col = pcall(function() return Color(R, G, B, A) end)
        if ok and col and type(col) == "number" then return math.tointeger(col) or math.floor(col) end
    end
    -- 回退：计算 AARRGGBB 打包数值 (标准 32 位无符号整数)
    local val = A * 16777216 + R * 65536 + G * 256 + B
    return math.tointeger(val) or math.floor(val)
end

-- 安全转换任何颜色输入（table/number/nil）为合法的整数 ColorValue
function Layout.ToColorInt(val)
    if type(val) == "number" then
        return math.tointeger(val) or math.floor(val)
    elseif type(val) == "table" then
        return Layout.MakeColor(val.r or 1, val.g or 1, val.b or 1, val.a or 1)
    end
    return 0xFFFFFFFF
end


-- 从整数色彩中解包 RGBA (0..255)
function Layout.UnpackColor(colInt)
    if type(colInt) ~= "number" then return 255, 255, 255, 255 end
    local val = math.tointeger(colInt) or math.floor(colInt)
    local a = math.floor(val / 16777216) % 256
    local r = math.floor(val / 65536) % 256
    local g = math.floor(val / 256) % 256
    local b = val % 256
    return r, g, b, a
end

-- 调整指定颜色的 Alpha 透明度通道 (0..255)
function Layout.WithAlpha(colInt, newAlpha)
    local r, g, b, _ = Layout.UnpackColor(colInt)
    return Layout.MakeColor(r, g, b, newAlpha)
end

-- 提瓦特星图标准调色板 (高辨识度深邃星图与元素光晕)
Layout.PALETTE = {
    BG_DARK           = Layout.MakeColor(11, 17, 30, 255),
    PANEL_BG          = Layout.MakeColor(15, 23, 42, 235),
    -- 玩家地脉：清澈天青冰川蓝
    PLAYER            = Layout.MakeColor(56, 189, 248, 255),   -- #38bdf8
    PLAYER_GLOW       = Layout.MakeColor(125, 211, 252, 160),  -- 柔和发光环
    -- 敌方深渊势力：绛红暗晶
    ENEMY             = Layout.MakeColor(244, 63, 94, 255),    -- #f43f5e (愚人众/赤红)
    ENEMY_GLOW        = Layout.MakeColor(251, 113, 133, 160),
    ENEMY_PURPLE      = Layout.MakeColor(168, 85, 247, 255),   -- 深渊暗紫 (盗宝团)
    ENEMY_PURPLE_GLOW = Layout.MakeColor(192, 132, 252, 160),
    ENEMY_GREEN       = Layout.MakeColor(16, 185, 129, 255),   -- 苍翠机体 (遗迹机关)
    ENEMY_GREEN_GLOW  = Layout.MakeColor(52, 211, 153, 160),
    -- 中立据点：低饱和星尘冷灰蓝 (不喧宾夺主抢视觉)
    NEUTRAL           = Layout.MakeColor(148, 163, 184, 180),  -- #94a3b8 半透明星尘
    NEUTRAL_BORDER    = Layout.MakeColor(100, 116, 139, 140),
    -- 元素与高光
    GOLD              = Layout.MakeColor(251, 191, 36, 255),   -- 固守金岩 #fbbf24
    GOLD_ALPHA        = Layout.MakeColor(251, 191, 36, 191),
    ANEMO             = Layout.MakeColor(52, 211, 153, 255),   -- 千风翠碧 #34d399
    AMBER             = Layout.MakeColor(245, 158, 11, 255),   -- 石珀金橙 #f59e0b
    TEXT_LIGHT        = Layout.MakeColor(248, 250, 252, 255),
    TEXT_MUTED        = Layout.MakeColor(100, 116, 139, 255),
    -- 静态底线拓扑：暗星轨
    LINK_INACTIVE     = Layout.MakeColor(100, 116, 139, 75),
    LINK_HIGHLIGHT    = Layout.MakeColor(226, 232, 240, 200)   -- 拖拽直连高亮
}

function Layout.GetFactionColor(faction)
    if faction == "player" then
        return Layout.PALETTE.PLAYER
    elseif faction == "enemy" or faction == "enemy_red" then
        return Layout.PALETTE.ENEMY
    elseif faction == "enemy_purple" then
        return Layout.PALETTE.ENEMY_PURPLE
    elseif faction == "enemy_green" then
        return Layout.PALETTE.ENEMY_GREEN
    else
        return Layout.PALETTE.NEUTRAL
    end
end

function Layout.GetFactionName(faction)
    if faction == "player" then
        return "西风骑士"
    elseif faction == "enemy" or faction == "enemy_red" then
        return "愚人众"
    elseif faction == "enemy_purple" then
        return "盗宝团"
    elseif faction == "enemy_green" then
        return "遗迹机关"
    else
        return "中立"
    end
end

-- 线性插值工具
function Layout.Lerp(a, b, t)
    return a + (b - a) * Layout.Clamp(t, 0, 1)
end

-- 根据阵营获取带指定透明度的光晕色
function Layout.GetFactionGlowColor(faction, alpha)
    local a = Layout.Clamp(math.floor(alpha or 120), 0, 255)
    if faction == "player" then
        return Layout.MakeColor(56, 189, 248, a)
    elseif faction == "enemy" or faction == "enemy_red" then
        return Layout.MakeColor(244, 63, 94, a)
    elseif faction == "enemy_purple" then
        return Layout.MakeColor(168, 85, 247, a)
    elseif faction == "enemy_green" then
        return Layout.MakeColor(16, 185, 129, a)
    else
        return Layout.MakeColor(148, 163, 184, a)
    end
end

-- 统一配置文本框的美术样式（开启深色描边、字号、字色与富文本）
function Layout.ApplyTextStyle(textCtrl, fontSize, fontColor, outlineColor)
    if not textCtrl or not textCtrl.alive then return end
    if fontSize then
        pcall(function() textCtrl.fontSize = fontSize end)
    end
    if fontColor then
        pcall(function() textCtrl.fontColor = fontColor end)
    end
    pcall(function()
        textCtrl.enableOutline = true
        textCtrl.outlineColor = outlineColor or Layout.PALETTE.BG_DARK
        textCtrl.richText = true
    end)
end

return Layout
