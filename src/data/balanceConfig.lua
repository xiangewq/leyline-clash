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

    -- 提瓦特官方音效资产 ID 映射表 (基于官方 1,997 音效库精选匹配)
    AUDIO_SLOTS = {
        UI_CLICK     = 50888,    -- 界面按钮点击 / 节点选中 (轻脆通用反馈音)
        ROUTE_LINK   = 40018,    -- 光轨连接建立 (能量脉冲流道激活)
        ROUTE_CUT    = 50912,    -- 光轨切断与结界切换 (能量断开清爽音)
        COMBAT_HIT   = 0,        -- 停用 70 秒长篇风声背景音(原10002)，交火采用纯净粒子光效与震颤
        SKILL_BLAST  = 40001,    -- 符印轰爆 / 灵穴共鸣爆发 (元素充能大招)
        MATCH_WIN    = 50961,    -- 全域大捷通关 (秘境挑战成功高昂号角)
        MATCH_LOSE   = 50962,    -- 灵脉耗竭败退 (挑战失利低沉音)
        NODE_CAPTURE = 40001,    -- 灵穴完全掌控 (核心充能爆发)
        NODE_DEFEND  = 20004,    -- 结界护盾吸收抵挡
        NODE_UPGRADE = 30005     -- 灵穴充能提升 / 强化清越音
    },

    activeAudioInstances = {}
}

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
