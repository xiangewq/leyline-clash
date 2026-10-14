-- src/data/balanceConfig.lua
-- 《星轨交错：地脉争锋》核心数值平衡与音频配置

local BalanceConfig = {
    -- 基础对局时间 (秒)
    MATCH_DURATION = 360, -- 6 分钟紧凑快节奏

    -- 兵力孕育与生产
    SPAWN_INTERVAL = 0.8,  -- 基础孕育周期 (秒) - 前沿活跃灵穴每秒产 1.25 粒，节奏张弛有度
    MAX_NODE_CAP = 50,     -- 普通灵穴兵力上限
    PLASMA_CAP = 25,       -- 赤阳熔核灵穴兵力硬封顶
    SAFE_GARRISON = 3,     -- 光轨输出时源灵穴保留的最低护卫兵力 (防止基地永久定格在1)

    -- 物流与光轨
    PARTICLE_SPEED = 200,  -- 微粒基础航速 (像素/秒)
    BASE_TRANSPORT_RATE = 3.2, -- 标准输送率 (粒/秒) - 平滑连贯光流
    BOOST_TRANSPORT_RATE = 6.4, -- 疾风加速输送率 (粒/秒)

    -- 占领与共鸣度 (0% ~ 100%)
    CAPTURE_INTERVAL = 0.8, -- 占领共鸣判定步进周期 (秒)
    MAX_RESONANCE_GROWTH = 5, -- 核心防滚雪球封顶步进 (点/轮)
    NEUTRAL_THRESHOLD = 20, -- 跌破 20% 沦为中立争夺态

    -- 战火决算
    COMBAT_INTERVAL = 0.5, -- 交火结算周期 (秒)
    COMBAT_BASE_DAMAGE_MIN = 3,
    COMBAT_BASE_DAMAGE_MAX = 6,
    DEFENSIVE_DAMAGE_MIN = 2,
    DEFENSIVE_DAMAGE_MAX = 4,

    -- 战前构筑预算
    MAX_BUDGET = 12,

    -- 提瓦特官方音效资产 ID 映射表 (精选柔和自然、富有沙盘推演质感的音频)
    AUDIO_SLOTS = {
        UI_CLICK     = 50888,    -- 界面按钮点击 / 节点选中 (轻脆通用反馈音)
        ROUTE_LINK   = 50912,    -- 光轨连接建立 (温润清爽能量流道音，取代原40018尖利金属出剑音)
        ROUTE_CUT    = 50888,    -- 光轨切断与结界切换 (轻脆断开反馈)
        COMBAT_HIT   = 0,        -- 交火采用纯净粒子光爆与数字跳动，保持听感纯净
        SKILL_BLAST  = 40001,    -- 符印轰爆 / 星枢共鸣爆发 (元素充能大招)
        MATCH_WIN    = 50961,    -- 全域大捷通关 (秘境挑战成功高昂号角)
        MATCH_LOSE   = 50962,    -- 星轨耗竭败退 (挑战失利低沉音)
        NODE_CAPTURE = 40001,    -- 星枢完全掌控 (核心充能爆发)
        NODE_DEFEND  = 0,        -- 消除消灭守军的高频嗞嗞电流声(原20004)，交火依靠粒子爆破与生命数值跳动
        NODE_UPGRADE = 30005     -- 星枢充能提升 / 强化清越音
    },

    activeAudioInstances = {},
    lastAudioTimes = {}
}

-- 节流音频播放器 (同类高频音效施加时间防抖，杜绝重叠杂音)
function BalanceConfig.PlayAudioThrottled(audioSlotKey, interval)
    local minInterval = interval or 0.25
    local now = (os and os.clock) and os.clock() or 0
    if BalanceConfig.lastAudioTimes[audioSlotKey] and (now - BalanceConfig.lastAudioTimes[audioSlotKey]) < minInterval then
        return
    end
    BalanceConfig.lastAudioTimes[audioSlotKey] = now
    BalanceConfig.PlayAudioSafe(audioSlotKey)
end

-- 安全播放音效包装器 (若未配置或ID无效，安全静音运行并以视觉动效兜底)
function BalanceConfig.PlayAudioSafe(audioSlotKey)
    local audioId = BalanceConfig.AUDIO_SLOTS[audioSlotKey]
    if audioId and audioId > 0 and game and game.PlayAudio2D then
        pcall(function()
            local instId = game.PlayAudio2D(audioId)
            if instId and instId > 0 then
                table.insert(BalanceConfig.activeAudioInstances, instId)
                if #BalanceConfig.activeAudioInstances > 50 then
                    table.remove(BalanceConfig.activeAudioInstances, 1)
                end
            end
        end)
    end
end

-- 彻底停止所有正在播放的音效实例 (对局结束、切换关卡或退出战斗时调用)
function BalanceConfig.StopAllAudios()
    if game and game.StopAudio then
        pcall(function()
            for _, instId in ipairs(BalanceConfig.activeAudioInstances or {}) do
                if game.IsAudioAlive then
                    if game.IsAudioAlive(instId) then
                        game.StopAudio(instId)
                    end
                else
                    game.StopAudio(instId)
                end
            end
            BalanceConfig.activeAudioInstances = {}
        end)
    end
end

-- 背景音乐已移交关卡编辑器【背景音乐管理】与服务端节点图配置，客户端不再发送网络信号
function BalanceConfig.SetBGM(bgmId) end
function BalanceConfig.SetMenuBGM() end
function BalanceConfig.SetStageBGM(stageId) end

return BalanceConfig
