-- src/core/runtime.lua
-- 对象池管理、清理栈与沙箱安全调用边界

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local Runtime = {}

-- 微粒图元对象池 (120个控件全量池化复用，杜绝单帧高频创建/销毁)
local ParticlePool = {
    controls = {},
    capacity = 120,
    activeCount = 0
}

function Runtime.InitParticlePool(controlList)
    ParticlePool.controls = controlList or {}
    ParticlePool.capacity = #ParticlePool.controls > 0 and #ParticlePool.controls or 120
    ParticlePool.activeCount = 0
    -- 默认隐藏所有池内微粒控件并初始化基础尺寸与中轴点
    for _, ctrl in ipairs(ParticlePool.controls) do
        Layout.SetVisible(ctrl, false)
        if ctrl and ctrl.alive then
            ctrl.sizeDeltaX = 8
            ctrl.sizeDeltaY = 8
        end
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
                local prog = Layout.Clamp(p.progress or 0, 0, 1.0)

                -- 1. 基础线性插值坐标
                local baseX = p.startX + (p.targetX - p.startX) * prog
                local baseY = p.startY + (p.targetY - p.startY) * prog

                -- 2. 蜿蜒法向正弦微摆 (S-Curve Flow)：两端归零，中途宛如流质星芒汇入
                local waveFactor = math.sin(prog * math.pi)
                local sinWave = math.sin(prog * math.pi * 4.0 + (p.seed or 0)) * 5.0 * waveFactor
                local curX = baseX + (p.nx or 0) * sinWave
                local curY = baseY + (p.ny or 0) * sinWave

                ctrl.anchoredPositionX = curX
                ctrl.anchoredPositionY = curY

                -- 3. 方向对齐与流光拉伸 (Motion Stretch)
                ctrl.localRotationZ = p.angle or 0
                local isBoosted = p.isBoosted or false
                local isMerged = (p.payload and p.payload > 1)

                -- 聚合微粒或加速流道更加修长明亮
                local scaleX = isBoosted and 2.4 or 1.8
                local scaleY = isBoosted and 0.8 or 0.65
                if isMerged then
                    scaleX = scaleX * 1.3
                    scaleY = scaleY * 1.35
                end
                ctrl.localScaleX = scaleX
                ctrl.localScaleY = scaleY

                if factionColorGetter and p.faction then
                    local baseCol = factionColorGetter(p.faction)
                    -- 高能量或加速微粒提升亮度
                    if isBoosted or isMerged then
                        ctrl.imageColor = Layout.WithAlpha(baseCol, 255)
                    else
                        ctrl.imageColor = Layout.WithAlpha(baseCol, 225)
                    end
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
