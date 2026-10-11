-- src/core/runtime.lua
-- 对象池管理、清理栈与沙箱安全调用边界

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local Runtime = {}

-- 微粒图元对象池 (复用已挂载的 UI 控件，杜绝单帧高频创建/销毁)
local ParticlePool = {
    controls = {},
    capacity = 80,
    activeCount = 0
}

function Runtime.InitParticlePool(controlList)
    ParticlePool.controls = controlList or {}
    ParticlePool.capacity = #ParticlePool.controls
    ParticlePool.activeCount = 0
    -- 默认隐藏所有池内微粒控件
    for _, ctrl in ipairs(ParticlePool.controls) do
        Layout.SetVisible(ctrl, false)
    end
end

function Runtime.GetPoolCapacity()
    return ParticlePool.capacity
end

function Runtime.UpdateParticles(movingParticles, factionColorGetter)
    local count = #movingParticles
    local maxAvail = ParticlePool.capacity

    for i = 1, maxAvail do
        local ctrl = ParticlePool.controls[i]
        if ctrl and ctrl.alive then
            if i <= count then
                local p = movingParticles[i]
                -- 计算当前插值坐标
                local curX = p.startX + (p.targetX - p.startX) * p.progress
                local curY = p.startY + (p.targetY - p.startY) * p.progress

                ctrl.anchoredPositionX = curX
                ctrl.anchoredPositionY = curY

                if factionColorGetter and p.faction then
                    ctrl.imageColor = factionColorGetter(p.faction)
                end

                Layout.SetVisible(ctrl, true)
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end
end

function Runtime.HideAllParticles()
    for _, ctrl in ipairs(ParticlePool.controls) do
        Layout.SetVisible(ctrl, false)
    end
end

-- 安全执行函数
function Runtime.SafeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        if printerr then
            printerr("[Starlink Runtime Error]: " .. tostring(res))
        else
            print("[Starlink Runtime Error]: " .. tostring(res))
        end
        return nil, res
    end
    return res
end

return Runtime
