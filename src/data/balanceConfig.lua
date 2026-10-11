-- src/data/balanceConfig.lua
-- 《星轨交错：地脉争锋》核心数值平衡与音频配置

local BalanceConfig = {
    -- 基础对局时间 (秒)
    MATCH_DURATION = 360, -- 6 分钟紧凑快节奏

    -- 兵力孕育与生产
    SPAWN_INTERVAL = 0.75, -- 基础孕育周期 (秒)
    MAX_NODE_CAP = 50,     -- 普通灵穴兵力上限
    PLASMA_CAP = 25,       -- 赤阳熔核灵穴兵力硬封顶

    -- 物流与光轨
    PARTICLE_SPEED = 200,  -- 微粒基础航速 (像素/秒)
    BASE_TRANSPORT_RATE = 5, -- 标准输送率 (粒/秒)
    BOOST_TRANSPORT_RATE = 10, -- 疾风加速输送率 (粒/秒)

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

    -- 提瓦特音频 GUID 槽位映射表 (创作者可在编辑器中填入实机音频 GUID)
    AUDIO_SLOTS = {
        UI_CLICK = 0,       -- 节点选定与按钮点击
        ROUTE_LINK = 0,     -- 光轨连接建立
        ROUTE_CUT = 0,      -- 光轨切断与结界激活
        COMBAT_HIT = 0,     -- 微粒交火火花
        SKILL_BLAST = 0,    -- 轰轰烈焰与神罚轰爆
        MATCH_WIN = 0,      -- 全域大捷
        MATCH_LOSE = 0      -- 灵脉耗竭
    }
}

-- 安全播放音效包装器 (若未配置或ID无效，安全静音运行并以视觉动效兜底)
function BalanceConfig.PlayAudioSafe(audioSlotKey)
    local audioId = BalanceConfig.AUDIO_SLOTS[audioSlotKey]
    if audioId and audioId > 0 and game and game.PlayAudio2D then
        pcall(function()
            game.PlayAudio2D(audioId)
        end)
    end
end

return BalanceConfig
