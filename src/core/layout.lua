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


-- 提瓦特地脉标准调色板 (使用 0..255 整数)
Layout.PALETTE = {
    BG_DARK      = Layout.MakeColor(11, 17, 30, 255),
    PANEL_BG     = Layout.MakeColor(15, 23, 42, 235),
    PLAYER       = Layout.MakeColor(56, 189, 248, 255),   -- 提瓦特天青蓝 #38bdf8
    PLAYER_GLOW  = Layout.MakeColor(56, 189, 248, 102),
    ENEMY        = Layout.MakeColor(244, 63, 94, 255),    -- 侵蚀猩红 #f43f5e
    ENEMY_GLOW   = Layout.MakeColor(244, 63, 94, 102),
    NEUTRAL      = Layout.MakeColor(148, 163, 184, 255),  -- 远古银岩灰 #94a3b8
    GOLD         = Layout.MakeColor(251, 191, 36, 255),   -- 固守金岩 #fbbf24
    GOLD_ALPHA   = Layout.MakeColor(251, 191, 36, 191),
    ANEMO        = Layout.MakeColor(52, 211, 153, 255),   -- 千风翠碧 #34d399
    AMBER        = Layout.MakeColor(245, 158, 11, 255),   -- 石珀金橙 #f59e0b
    TEXT_LIGHT   = Layout.MakeColor(248, 250, 252, 255),
    TEXT_MUTED   = Layout.MakeColor(100, 116, 139, 255),
    LINK_INACTIVE= Layout.MakeColor(51, 65, 85, 115)
}

function Layout.GetFactionColor(faction)
    if faction == "player" then
        return Layout.PALETTE.PLAYER
    elseif faction == "enemy" then
        return Layout.PALETTE.ENEMY
    else
        return Layout.PALETTE.NEUTRAL
    end
end

return Layout
