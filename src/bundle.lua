-- src/bundle.lua: Consolidated standalone bundle for Miliastra UGC
local _MODULES = {}
local _LOADED = {}
local _orig_require = require

local function local_require(name)
    local clean = tostring(name):gsub("^default_import_file/", ""):gsub("%.lua$", "")
    if _LOADED[clean] ~= nil then return _LOADED[clean] end
    if _MODULES[clean] ~= nil then
        _LOADED[clean] = _MODULES[clean]()
        return _LOADED[clean]
    end
    if _orig_require then
        local ok, res = pcall(_orig_require, name)
        if ok and res ~= nil then return res end
    end
    error("Module not found: " .. tostring(name))
end
local require = local_require

_MODULES["src/data/balanceConfig"] = function()
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

end
_MODULES["data/balanceConfig"] = _MODULES["src/data/balanceConfig"]

_MODULES["src/data/cardRegistry"] = function()
-- src/data/cardRegistry.lua
-- 《星轨交错：地脉争锋》17种提瓦特七大元素战术符印注册表

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local CardRegistry = {
    CARDS = {
        {
            id = "anemo_shield",
            name = "千风庇护",
            element = "anemo",
            cost = 2,
            cd = 30,
            duration = 20,
            targetType = "player_node",
            desc = "加持己方灵穴，20秒内免疫任何敌方侵蚀，本土共鸣恢复翻倍。",
            badgeColor = Layout.MakeColor(52, 211, 153, 255)
        },
        {
            id = "pyro_erosion",
            name = "烈焰侵蚀",
            element = "pyro",
            cost = 2,
            cd = 30,
            duration = 20,
            targetType = "enemy_node",
            desc = "炽火灼烧敌脉，瞬间消灭目标敌方灵穴上 40% 的驻留微粒并切断输出！",
            badgeColor = Layout.MakeColor(244, 63, 94, 255)
        },
        {
            id = "anemo_turb",
            name = "千风湍流",
            element = "anemo",
            cost = 3,
            cd = 20,
            duration = 30,
            targetType = "player_route_node",
            desc = "激发生发之风，30秒内从该灵穴出发的光轨流速翻倍至10粒/秒。",
            badgeColor = Layout.MakeColor(52, 211, 153, 255)
        },
        {
            id = "pyro_blast",
            name = "轰轰烈焰",
            element = "pyro",
            cost = 4,
            cd = 25,
            duration = 0,
            targetType = "enemy_node",
            desc = "引动燃素轰爆，瞬间消灭目标敌方灵穴上 80% 的驻留微粒！",
            badgeColor = Layout.MakeColor(244, 63, 94, 255)
        },
        {
            id = "geo_wall",
            name = "坚岩重嶂",
            element = "geo",
            cost = 4,
            cd = 30,
            duration = 20,
            targetType = "player_node",
            desc = "凝结磐岩坚盾，20秒内己方战损减半，敌方承受双倍反震战损。",
            badgeColor = Layout.MakeColor(251, 191, 36, 255)
        },
        {
            id = "hydro_bribe",
            name = "摩拉律法",
            element = "hydro",
            cost = 5,
            cd = 35,
            duration = 0,
            targetType = "any_node",
            desc = "水之契约与摩拉通神：中立灵穴直接秒占100%；敌方灵穴削减65%共鸣。",
            badgeColor = Layout.MakeColor(56, 189, 248, 255)
        }
    }
}

function CardRegistry.GetCardById(cardId)
    for _, card in ipairs(CardRegistry.CARDS) do
        if card.id == cardId then
            return card
        end
    end
    return nil
end

function CardRegistry.GetDefaultDeck()
    -- 按消耗权能升序推荐：千风庇护(2) + 烈焰侵蚀(2) + 千风湍流(3) + 轰轰烈焰(4) = 11点
    return { "anemo_shield", "pyro_erosion", "anemo_turb", "pyro_blast" }
end

return CardRegistry

end
_MODULES["data/cardRegistry"] = _MODULES["src/data/cardRegistry"]

_MODULES["src/data/chapterConfig"] = function()
-- src/data/chapterConfig.lua
-- 《星轨交错：地脉争锋》全 5 大战役章节参数、星盘拓扑、地脉异象与剧情简报配置

local ChapterConfig = {
    -- 章节列表 (1 ~ 5)
    CHAPTERS = {
        -- =====================================================================
        -- 第 1 关：启蒙·清泉流响 (2方混战，10灵穴，预算4点，180s)
        -- =====================================================================
        {
            id = 1,
            title = "第 1 关·启蒙·清泉流响",
            subtitle = "单线对冲 · 基础地脉流动新手演练",
            factions = { "player", "enemy_red" },
            budget = 4,
            duration = 180,
            bgm = 10035,
            desc = "清泉镇下汇聚着温和的地脉微粒。在此熟悉光轨铺设与驻阵固守，击溃愚人众前哨。",
            dialogues = {
                {
                    speaker = "派蒙",
                    content = "哇！阿贝多，这个泛着蓝光的大圆盘是什么呀？\n上面亮晶晶的小圆点，看起来好像……会发光的甜甜花糖豆！"
                },
                {
                    speaker = "阿贝多",
                    content = "呵呵，派蒙，这是古代战争推衍法器——「地脉星图棋盘」。\n每一个光点象征一处灵穴，流动的光尘则是纯净元素微粒。"
                },
                {
                    speaker = "阿贝多",
                    content = "第一关在清泉之畔。拖拽己方灵穴铺设光轨占领中立据点，\n轻点灵穴收拢防御。击溃前方的愚人众阵营即可过关。"
                },
                {
                    speaker = "派蒙",
                    content = "听起来很有意思！旅行者，4点权能调配已经准备好，\n我们一起执掌星盘赢得推衍吧！"
                }
            },
            nodes = {
                { id = 0, name = "西风前哨", x = 240, y = 490, radius = 26, faction = "player", particles = 20, control = 100, anomaly = "NORMAL", desc = "我方西风骑士前哨" },
                { id = 1, name = "清泉北陵", x = 480, y = 650, radius = 26, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "北侧灵泉高地 (侧翼拓展点)" },
                { id = 2, name = "泉水祭坛", x = 760, y = 590, radius = 26, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "清泉古祭坛" },
                { id = 3, name = "晨曦峡口", x = 1120, y = 620, radius = 26, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "近酒庄险隘" },
                { id = 4, name = "清泉主脉", x = 580, y = 430, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "清泉核心灵脉 (战略枢纽)" },
                { id = 5, name = "奔狼前驿", x = 950, y = 390, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "中路要冲 (战略枢纽)" },
                { id = 6, name = "清泉南溪", x = 490, y = 250, radius = 26, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "南侧支流草甸 (侧翼拓展点)" },
                { id = 7, name = "杜拉夫猎场", x = 790, y = 210, radius = 26, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "猎人歇脚营地" },
                { id = 8, name = "达达乌帕口", x = 1110, y = 270, radius = 26, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "近部落前沿" },
                { id = 9, name = "愚人驻地", x = 1360, y = 430, radius = 26, faction = "enemy_red", particles = 20, control = 100, anomaly = "NORMAL", desc = "愚人众前线营地" }
            },
            links = {
                { 0, 1 }, { 0, 4 }, { 0, 6 },
                { 1, 2 }, { 1, 4 },
                { 6, 7 }, { 6, 4 },
                { 4, 2 }, { 4, 5 }, { 4, 7 },
                { 2, 3 }, { 2, 5 },
                { 7, 8 }, { 7, 5 },
                { 5, 3 }, { 5, 8 }, { 5, 9 },
                { 3, 9 }, { 8, 9 }
            }
        },

        -- =====================================================================
        -- 第 2 关：风起·千风之壁 (2方混战，12灵穴，预算6点，240s)
        -- =====================================================================
        {
            id = 2,
            title = "第 2 关·风起·千风之壁",
            subtitle = "双路推进 · 疾风流道与迷雾荒墟的博弈",
            factions = { "player", "enemy_red" },
            budget = 6,
            duration = 240,
            bgm = 10068,
            desc = "千风神殿周边狂风肆虐。抢占千风隘口激活双倍流速，避开迷雾荒墟的产速衰减。",
            dialogues = {
                {
                    speaker = "阿贝多",
                    content = "清泉镇推衍完成得很出色。现在我们将沙盘推展至「千风神殿」。\n在这里，你将见识到真正的地脉异象。"
                },
                {
                    speaker = "派蒙",
                    content = "看！上方那座灵穴泛着青绿风旋，中间那座却被雾气笼罩！\n它们有什么不同吗？"
                },
                {
                    speaker = "阿贝多",
                    content = "青色的是「疾风流道」，兵力输送速率翻倍；雾气则是「迷雾荒墟」，产速减半且易失守。\n权能预算已提升至 6 点，妥善利用地脉之利吧！"
                }
            },
            nodes = {
                { id = 0, name = "风起营地", x = 200, y = 420, radius = 26, faction = "player", particles = 24, control = 100, anomaly = "NORMAL", desc = "蒙德西风阵地" },
                { id = 1, name = "低语树林", x = 430, y = 640, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路树影屏障" },
                { id = 2, name = "星落湖畔", x = 420, y = 230, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南路清澈湖滨" },
                { id = 3, name = "千风隘口", x = 730, y = 690, radius = 26, faction = "neutral", particles = 15, control = 0, anomaly = "WIND_FLOW", desc = "千风汇聚（输送翻倍）" },
                { id = 4, name = "石珀晶矿", x = 710, y = 200, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "AMBER_MINE", desc = "石珀富矿（产能翻倍）" },
                { id = 5, name = "望风山地", x = 990, y = 660, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "俯瞰北境高崖" },
                { id = 6, name = "摘星崖底", x = 980, y = 180, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "悬崖南麓险隘" },
                { id = 7, name = "千风神殿", x = 680, y = 470, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "NORMAL", desc = "远古神殿遗址" },
                { id = 8, name = "迷雾荒墟", x = 950, y = 380, radius = 26, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾衰减（产能减半）" },
                { id = 9, name = "急冻悬崖", x = 1210, y = 580, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北侧霜寒关卡" },
                { id = 10, name = "誓言岬哨", x = 1200, y = 260, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南侧海风前哨" },
                { id = 11, name = "千风绝壁", x = 1400, y = 460, radius = 26, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众千风要塞" }
            },
            links = {
                { 0, 1 }, { 0, 7 }, { 0, 2 },
                { 1, 3 }, { 1, 7 },
                { 2, 4 }, { 2, 7 },
                { 3, 5 }, { 3, 7 },
                { 4, 6 }, { 4, 7 },
                { 7, 8 },
                { 5, 8 }, { 5, 9 },
                { 6, 8 }, { 6, 10 },
                { 8, 9 }, { 8, 10 }, { 8, 11 },
                { 9, 11 }, { 10, 11 }
            }
        },

        -- =====================================================================
        -- 第 3 关：激斗·千岩巨渊 (3方混战，14灵穴，预算8点，300s)
        -- =====================================================================
        {
            id = 3,
            title = "第 3 关·激斗·千岩巨渊",
            subtitle = "三角对峙 · 盗宝团介入与层岩雷暴要塞",
            factions = { "player", "enemy_red", "enemy_purple" },
            budget = 8,
            duration = 300,
            bgm = 10099,
            desc = "璃月层岩巨渊深处，不仅有愚人众驻军，更有盘踞多时的渊影盗宝团。三方势力互相争夺！",
            dialogues = {
                {
                    speaker = "派蒙",
                    content = "哇哇哇！怎么地图上有三种颜色的光芒呀？\n除了红色，还有紫色！"
                },
                {
                    speaker = "阿贝多",
                    content = "这是三方混战演练。红方为愚人众，紫方为盗宝团。\n各方势力不仅会攻击我们，彼此之间也会抢夺灵穴。"
                },
                {
                    speaker = "阿贝多",
                    content = "中央的「雷暴要塞」战损减半，下方的「石珀富矿」产能翻倍。\n权能预算提升至 8 点，可带上「坚岩重嶂」等高阶符印稳固战线。"
                },
                {
                    speaker = "派蒙",
                    content = "让他们先两败俱伤，我们再坐收渔翁之利！嘿嘿，出发！"
                }
            },
            nodes = {
                { id = 0, name = "西风先锋", x = 220, y = 250, radius = 26, faction = "player", particles = 24, control = 100, anomaly = "NORMAL", desc = "我方西南先锋大营" },
                { id = 1, name = "黑岩关隘", x = 580, y = 630, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路悬石关卡" },
                { id = 2, name = "天工峡口", x = 990, y = 650, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路绝壁隘口" },
                { id = 3, name = "伏鳌谷地", x = 390, y = 410, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南峡谷要道" },
                { id = 4, name = "琉璃晶矿", x = 440, y = 170, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "琉璃晶砂浅坑" },
                { id = 5, name = "石珀富矿", x = 790, y = 530, radius = 26, faction = "neutral", particles = 15, control = 0, anomaly = "AMBER_MINE", desc = "石珀富矿（产能翻倍）" },
                { id = 6, name = "雷暴要塞", x = 840, y = 320, radius = 26, faction = "neutral", particles = 18, control = 0, anomaly = "DEFENSE_BASTION", desc = "雷暴灵障（战损减半）" },
                { id = 7, name = "层岩中继", x = 610, y = 370, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "西翼疾风流道" },
                { id = 8, name = "悬木吊桥", x = 1020, y = 420, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "东翼古矿吊桥" },
                { id = 9, name = "无名遗迹", x = 740, y = 150, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "渊底远古废墟" },
                { id = 10, name = "巨渊之口", x = 1210, y = 440, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南盗宝前沿" },
                { id = 11, name = "丹砂矿脉", x = 1170, y = 190, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南丹砂坑洞" },
                { id = 12, name = "愚人巨垒", x = 770, y = 740, radius = 26, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众北山巨垒" },
                { id = 13, name = "盗宝匪巢", x = 1380, y = 280, radius = 26, faction = "enemy_purple", particles = 26, control = 100, anomaly = "NORMAL", desc = "渊影盗宝总寨" }
            },
            links = {
                { 0, 3 }, { 0, 4 }, { 3, 4 },
                { 3, 7 }, { 4, 7 }, { 4, 9 },
                { 12, 1 }, { 12, 2 }, { 1, 2 },
                { 1, 7 }, { 1, 5 }, { 2, 5 }, { 2, 8 },
                { 7, 5 }, { 5, 8 },
                { 7, 6 }, { 8, 6 }, { 5, 6 },
                { 7, 9 }, { 8, 9 }, { 6, 9 },
                { 10, 8 }, { 10, 13 }, { 10, 11 },
                { 11, 13 }, { 11, 8 }, { 11, 9 }
            }
        },

        -- =====================================================================
        -- 第 4 关：诡计·纯水暗流 (4方混战，16灵穴，预算10点，360s)
        -- =====================================================================
        {
            id = 4,
            title = "第 4 关·诡计·纯水暗流",
            subtitle = "四方争霸 · 中央双生纯水枢纽多线穿插",
            factions = { "player", "enemy_red", "enemy_purple", "enemy_green" },
            budget = 10,
            duration = 360,
            bgm = 10113,
            desc = "枫丹水下暗流涌动。红方愚人众、紫方盗宝团与苍翠遗迹机关全境交战，争夺中央双生纯水枢纽！",
            dialogues = {
                {
                    speaker = "派蒙",
                    content = "天哪！绿色的光芒也出现了！整整四种颜色混在一起，\n简直就像彩虹大乱炖！"
                },
                {
                    speaker = "阿贝多",
                    content = "绿方代表坎瑞亚古代遗迹防卫机关。四大阵营将在枫丹水盘展开全面战争。\n中央是「纯水双生枢纽」，占领后具有极高的战略中继价值。"
                },
                {
                    speaker = "阿贝多",
                    content = "本关权能预算大幅提升至 10 点，可以使用强力的「摩拉律法」快速强占，\n或以「轰轰烈焰」压制四方突围。"
                },
                {
                    speaker = "派蒙",
                    content = "四方大乱斗！旅行者，保持冷静，我们逐个击破！"
                }
            },
            nodes = {
                { id = 0, name = "西风水港", x = 180, y = 410, radius = 26, faction = "player", particles = 28, control = 100, anomaly = "NORMAL", desc = "我方西港母基" },
                { id = 1, name = "枫丹前哨", x = 380, y = 590, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西北水下前沿" },
                { id = 2, name = "海露平原", x = 370, y = 250, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南海草平原" },
                { id = 3, name = "伊黎耶港", x = 620, y = 670, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北侧水闸港湾" },
                { id = 4, name = "白露隘口", x = 1030, y = 660, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北水下窄谷" },
                { id = 5, name = "枫丹激流", x = 1240, y = 620, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "激流通道（输送翻倍）" },
                { id = 6, name = "苍晶矿脉", x = 1250, y = 280, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "AMBER_MINE", desc = "苍晶富矿（产能翻倍）" },
                { id = 7, name = "纯水阳核", x = 720, y = 480, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "PURE_WATER", desc = "中央纯水西枢纽" },
                { id = 8, name = "纯水阴核", x = 930, y = 390, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "PURE_WATER", desc = "中央纯水东枢纽" },
                { id = 9, name = "沉玉古墟", x = 540, y = 420, radius = 26, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾残垣（产能减半）" },
                { id = 10, name = "水色要塞", x = 1090, y = 470, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "深水灵障（战损减半）" },
                { id = 11, name = "秋泉隐所", x = 590, y = 220, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南侧暗流溶洞" },
                { id = 12, name = "柔灯要道", x = 1010, y = 210, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南深水通道" },
                { id = 13, name = "愚人潜艇", x = 830, y = 750, radius = 26, faction = "enemy_red", particles = 24, control = 100, anomaly = "NORMAL", desc = "愚人众北境母舰" },
                { id = 14, name = "盗宝暗礁", x = 790, y = 140, radius = 26, faction = "enemy_purple", particles = 24, control = 100, anomaly = "NORMAL", desc = "盗宝团南礁老巢" },
                { id = 15, name = "机关工坊", x = 1420, y = 460, radius = 26, faction = "enemy_green", particles = 24, control = 100, anomaly = "NORMAL", desc = "遗迹机关核心中枢" }
            },
            links = {
                { 0, 1 }, { 0, 2 }, { 1, 2 },
                { 1, 9 }, { 2, 9 }, { 1, 3 }, { 2, 11 },
                { 13, 3 }, { 13, 4 }, { 3, 4 },
                { 3, 9 }, { 3, 7 }, { 4, 8 }, { 4, 5 },
                { 14, 11 }, { 14, 12 }, { 11, 12 },
                { 11, 9 }, { 11, 7 }, { 12, 8 }, { 12, 6 },
                { 15, 5 }, { 15, 6 }, { 5, 6 },
                { 5, 10 }, { 6, 10 },
                { 9, 7 }, { 7, 8 }, { 8, 10 },
                { 7, 3 }, { 7, 11 }, { 8, 4 }, { 8, 12 }
            }
        },

        -- =====================================================================
        -- 第 5 关：终章·极寒凛冬 (4方混战，18灵穴，满额预算12点，360s)
        -- =====================================================================
        {
            id = 5,
            title = "第 5 关·终章·极寒凛冬",
            subtitle = "全网状决战 · 赤阳熔核绞肉与满额神技对决",
            factions = { "player", "enemy_red", "enemy_purple", "enemy_green" },
            budget = 12,
            duration = 360,
            bgm = 10184,
            desc = "龙脊雪山之巅，远古推衍机全功率觉醒！18 座灵穴交织成网，双核赤阳熔核限制25微粒极速绞杀。",
            dialogues = {
                {
                    speaker = "阿贝多",
                    content = "这是推衍沙盘的终极篇章——「极寒凛冬」。\n盘面扩展至 18 座灵穴，地脉网络极为密集复杂。"
                },
                {
                    speaker = "派蒙",
                    content = "哇，中间那两座灵穴像太阳一样散发着强光！感觉一靠近就会融化！"
                },
                {
                    speaker = "阿贝多",
                    content = "那是「赤阳熔核」，微粒上限被强行限制在 25 粒，战损极高，是名副其实的绞肉战场。\n你的权能预算已达 12 点满额！尽情调配全套高阶战术符印吧！"
                },
                {
                    speaker = "派蒙",
                    content = "旅行者，调集全部星轨，成为这片星海的无上主宰吧！"
                }
            },
            nodes = {
                { id = 0, name = "西风终焉", x = 180, y = 210, radius = 26, faction = "player", particles = 28, control = 100, anomaly = "NORMAL", desc = "我方西南极境大营" },
                { id = 1, name = "忍冬废墟", x = 350, y = 680, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西北废墟要冲" },
                { id = 2, name = "覆雪咽喉", x = 390, y = 470, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "西翼要塞（战损减半）" },
                { id = 3, name = "眠龙前哨", x = 360, y = 250, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南峡谷前哨" },
                { id = 4, name = "寒天隘口", x = 680, y = 720, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北境高寒关隘" },
                { id = 5, name = "苍白防线", x = 970, y = 720, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北绝壁关防" },
                { id = 6, name = "寒天激流", x = 610, y = 530, radius = 26, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "疾风通道（输送翻倍）" },
                { id = 7, name = "雪山要塞", x = 980, y = 570, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "东北壁垒（战损减半）" },
                { id = 8, name = "熔核之北", x = 730, y = 440, radius = 26, faction = "neutral", particles = 15, control = 0, anomaly = "PLASMA", desc = "赤阳熔核（上限25粒，绞肉）" },
                { id = 9, name = "熔核之南", x = 900, y = 380, radius = 26, faction = "neutral", particles = 15, control = 0, anomaly = "PLASMA", desc = "赤阳熔核（上限25粒，绞肉）" },
                { id = 10, name = "覆雪迷雾", x = 620, y = 250, radius = 26, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾残迹（产能减半）" },
                { id = 11, name = "星银富矿", x = 970, y = 230, radius = 26, faction = "neutral", particles = 15, control = 0, anomaly = "AMBER_MINE", desc = "星银富矿（产能翻倍）" },
                { id = 12, name = "积雪小径", x = 1220, y = 240, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南雪径要道" },
                { id = 13, name = "冰封哨卡", x = 1240, y = 470, radius = 26, faction = "neutral", particles = 16, control = 0, anomaly = "NORMAL", desc = "东翼防线枢纽" },
                { id = 14, name = "冰封棱堡", x = 1210, y = 690, radius = 26, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北棱堡哨站" },
                { id = 15, name = "愚人霜核", x = 180, y = 700, radius = 26, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众西北霜核" },
                { id = 16, name = "盗宝残党", x = 1420, y = 210, radius = 26, faction = "enemy_purple", particles = 26, control = 100, anomaly = "NORMAL", desc = "盗宝团东南匪寨" },
                { id = 17, name = "遗迹主控", x = 1420, y = 700, radius = 26, faction = "enemy_green", particles = 26, control = 100, anomaly = "NORMAL", desc = "遗迹防卫主控主机" }
            },
            links = {
                { 15, 1 }, { 1, 2 }, { 1, 4 },
                { 0, 3 }, { 3, 2 }, { 3, 10 },
                { 2, 6 }, { 2, 10 },
                { 4, 1 }, { 4, 5 }, { 4, 6 },
                { 5, 14 }, { 5, 7 },
                { 6, 7 }, { 6, 8 }, { 6, 4 },
                { 7, 9 }, { 7, 14 }, { 7, 13 },
                { 8, 9 }, { 8, 10 },
                { 9, 11 }, { 9, 13 },
                { 10, 11 }, { 10, 3 },
                { 11, 12 }, { 11, 13 },
                { 14, 17 }, { 14, 13 },
                { 13, 17 }, { 13, 16 }, { 13, 12 },
                { 12, 16 }, { 12, 11 }
            }
        }
    }
}

-- 获取指定章节配置 (默认返回第 1 关)
function ChapterConfig.GetChapter(id)
    local idx = tonumber(id) or 1
    if idx < 1 then idx = 1 end
    if idx > #ChapterConfig.CHAPTERS then idx = #ChapterConfig.CHAPTERS end
    return ChapterConfig.CHAPTERS[idx]
end

return ChapterConfig

end
_MODULES["data/chapterConfig"] = _MODULES["src/data/chapterConfig"]

_MODULES["src/core/layout"] = function()
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

end
_MODULES["core/layout"] = _MODULES["src/core/layout"]

_MODULES["src/core/runtime"] = function()
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

end
_MODULES["core/runtime"] = _MODULES["src/core/runtime"]

_MODULES["src/core/input"] = function()
-- src/core/input.lua
-- 全局全屏输入适配器与光标事件分发

local Input = {
    isDragging = false,
    dragSourceId = nil,
    dragCurrentX = 0,
    dragCurrentY = 0,
    pressStartX = 0,
    pressStartY = 0,
    selectedCardIndex = nil,

    -- 回调事件注册
    onNodeClicked = nil,      -- fun(nodeId)
    onRouteCreated = nil,     -- fun(fromId, toId)
    onCardCast = nil          -- fun(cardIndex, targetNodeId)
}

local DRAG_THRESHOLD = 15 -- 像素防抖阈值

function Input.SetSelectedCard(index)
    Input.selectedCardIndex = index
end

function Input.GetSelectedCard()
    return Input.selectedCardIndex
end

function Input.ClearSelectedCard()
    Input.selectedCardIndex = nil
end

function Input.FindNodeAtPos(x, y, nodes)
    for _, node in ipairs(nodes) do
        local dx = node.x - x
        local dy = node.y - y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= (node.radius + 18) then
            return node
        end
    end
    return nil
end

function Input.OnCursorDown(x, y, nodes)
    Input.pressStartX = x
    Input.pressStartY = y
    Input.dragCurrentX = x
    Input.dragCurrentY = y

    local clickedNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Down at (%.1f, %.1f), hit = %s", x, y, clickedNode and clickedNode.name or "none"))

    -- 若当前已选中卡牌，直接作为技能目标拾取
    if Input.selectedCardIndex then
        local slotIdx = Input.selectedCardIndex
        if clickedNode then
            if Input.onCardCast then
                Input.onCardCast(slotIdx, clickedNode.id)
            end
            Input.selectedCardIndex = nil
        else
            if Input.onCardCancelled then
                Input.onCardCancelled(slotIdx)
            end
            Input.selectedCardIndex = nil
        end
        return
    end

    -- 若点击己方灵穴，启动拖拽连线准备
    if clickedNode and clickedNode.faction == "player" then
        Input.isDragging = true
        Input.dragSourceId = clickedNode.id
    else
        Input.isDragging = false
        Input.dragSourceId = nil
    end
end

function Input.OnCursorDrag(x, y)
    if Input.isDragging then
        Input.dragCurrentX = x
        Input.dragCurrentY = y
    end
end

function Input.OnCursorUp(x, y, nodes)
    if not Input.isDragging and not Input.dragSourceId then
        return
    end

    local sourceId = Input.dragSourceId
    local targetNode = Input.FindNodeAtPos(x, y, nodes)
    print(string.format("[Starlink Input] Up at (%.1f, %.1f), target = %s", x, y, targetNode and targetNode.name or "none"))

    local movedDist = math.sqrt((x - Input.pressStartX) ^ 2 + (y - Input.pressStartY) ^ 2)

    if targetNode and targetNode.id ~= sourceId then
        -- 成功拖至不同节点：建立航线
        if Input.onRouteCreated then
            Input.onRouteCreated(sourceId, targetNode.id)
        end
    elseif movedDist < DRAG_THRESHOLD or (targetNode and targetNode.id == sourceId) then
        -- 原地轻点或微小位移：激活固守 / 切断光轨
        if Input.onNodeClicked and sourceId then
            Input.onNodeClicked(sourceId)
        end
    end

    Input.isDragging = false
    Input.dragSourceId = nil
end

return Input

end
_MODULES["core/input"] = _MODULES["src/core/input"]

_MODULES["src/world/starMap"] = function()
-- src/world/starMap.lua
-- 提瓦特多章节沙盘拓扑、连通性矩阵、邻居查询与动态关卡加载器

local ChapterConfig = require("default_import_file/src/data/chapterConfig") or require("src/data/chapterConfig")

local StarMap = {
    currentStage = 1,
    currentChapterDef = nil,
    NODES_DEF = {},
    LINKS = {}
}

-- 动态加载关卡数据
function StarMap.LoadStage(stageIndex)
    local chap = ChapterConfig.GetChapter(stageIndex)
    StarMap.currentStage = chap.id
    StarMap.currentChapterDef = chap
    StarMap.NODES_DEF = chap.nodes
    StarMap.LINKS = chap.links
    return chap
end

-- 安全获取节点（统一收敛 0-Based 与 1-Based 下标混用隐患）
function StarMap.GetNode(nodes, nodeId)
    if not nodes or nodeId == nil then return nil end
    return nodes[nodeId + 1]
end

-- 获取两节点构成的无向边唯一键 (min_max)
function StarMap.GetEdgeKey(idA, idB)
    if idA < idB then
        return idA .. "_" .. idB
    else
        return idB .. "_" .. idA
    end
end

-- 判定两节点间是否存在地脉直通流道
function StarMap.AreNodesLinked(idA, idB)
    for _, link in ipairs(StarMap.LINKS) do
        if (link[1] == idA and link[2] == idB) or (link[1] == idB and link[2] == idA) then
            return true
        end
    end
    return false
end

-- 获取指定节点的所有物理相邻邻居列表
function StarMap.GetNeighbors(nodeId)
    local list = {}
    for _, link in ipairs(StarMap.LINKS) do
        if link[1] == nodeId then
            table.insert(list, link[2])
        elseif link[2] == nodeId then
            table.insert(list, link[1])
        end
    end
    return list
end

-- 初始默认载入第 1 关
StarMap.LoadStage(1)

return StarMap

end
_MODULES["world/starMap"] = _MODULES["src/world/starMap"]

_MODULES["src/world/nodeEntity"] = function()
-- src/world/nodeEntity.lua
-- 地脉灵穴实体生命周期、内陆休眠、共鸣度渐进与固守状态

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local NodeEntity = {}

-- 实体构造函数
function NodeEntity.Create(def)
    return {
        id = def.id,
        name = def.name,
        x = def.x,
        y = def.y,
        radius = def.radius,
        faction = def.faction,
        particles = def.particles or 0,
        control = def.control or (def.faction == "neutral" and 0 or 100),
        anomaly = def.anomaly or "NORMAL",

        -- 状态标签
        routeTo = nil,          -- 当前对外输出的目标节点ID (nil 为无输出)
        isDefensive = (def.faction ~= "neutral"), -- 默认初始若无输出则固守
        isIdle = false,         -- 内陆腹地休眠标记
        protectedUntil = 0,     -- 千风庇护失效时间戳
        boostedUntil = 0,       -- 生产/流速加速时间戳

        -- 生产与占领内部计时器
        spawnTimer = 0,
        contenderFaction = nil,
        contenderParticles = 0
    }
end

-- 判定是否为腹地节点：所有物理相邻灵穴均为同阵营领地
function NodeEntity.CheckIsInland(node, allNodes)
    if node.faction == "neutral" then
        return false
    end
    local neighbors = StarMap.GetNeighbors(node.id)
    if #neighbors == 0 then return false end
    for _, nId in ipairs(neighbors) do
        local n = StarMap.GetNode(allNodes, nId)
        if not n or n.faction ~= node.faction then
            return false
        end
    end
    return true
end

-- 判定腹地休眠与状态维护
function NodeEntity.CheckInlandDormant(node, allNodes)
    local isInland = NodeEntity.CheckIsInland(node, allNodes)
    if not isInland then
        node.isIdle = false
        return false
    end

    -- 核心理性机制：若灵穴处于安全腹地且未向外输送，储备达到 15 粒时自动休眠停止造兵
    if node.routeTo == nil and node.particles >= 15 then
        node.isIdle = true
        return true
    end

    node.isIdle = false
    return false
end

-- 帧更新生产逻辑
function NodeEntity.TickSpawn(node, dt, allNodes, elapsedTime)
    if node.faction == "neutral" then return end

    -- 判定内陆休眠 (未外调且储备充足则完全停产)
    if NodeEntity.CheckInlandDormant(node, allNodes) then
        return
    end

    local isInland = NodeEntity.CheckIsInland(node, allNodes)

    -- 生产周期换算
    local baseInterval = BalanceConfig.SPAWN_INTERVAL
    if isInland then
        -- 核心理性机制：腹地远离前线战火，地脉平息，产能衰减为前线的 40% (周期延长 2.5 倍)
        -- 避免后方节点无限造兵串联成超级水泵碾压前线
        baseInterval = baseInterval * 2.5
    end

    if node.anomaly == "AMBER_MINE" then
        baseInterval = baseInterval * 0.5
    elseif node.anomaly == "MIST_RUINS" then
        baseInterval = baseInterval * 1.25 -- 迷雾轻度减产
    elseif node.anomaly == "PURE_WATER" then
        baseInterval = baseInterval * 0.65 -- 纯水激荡：产速提升约 54%
    end

    -- 共鸣度衰减曲线（底线提高至 0.6，防止受创灵穴产兵完全停摆）
    local effRatio = math.max(0.6, (node.control or 100) / 100)
    local actualInterval = baseInterval / effRatio

    node.spawnTimer = node.spawnTimer + dt
    if node.spawnTimer >= actualInterval then
        node.spawnTimer = 0
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
    end
end

-- 微粒到达时对灵穴归属与占领度的拔河对消结算 (Tug-of-War / Influence Pool)
function NodeEntity.ApplyArrival(node, particleFaction, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    if node.faction == particleFaction then
        -- 1. 友军微粒汇入
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
        -- 若据点此前受创但未失守，友军微粒同时修复防守共鸣度
        if (node.control or 100) < 100 then
            node.control = math.min(100, (node.control or 100) + 5)
        end
        if node.particles > 0 then
            node.contenderFaction = nil
        end
        return
    end

    -- 2. 敌对微粒进攻结算
    -- 核心防御保障：检查目标灵穴是否处于【千风庇护/守护】神圣保护期间
    if (node.protectedUntil or 0) > (elapsedTime or 0) then
        -- 千风结界绝对阻挡与湮灭一切敌方微粒！
        -- 守备兵力不扣减、控制度不扣减、绝不沦陷为中立态！
        BalanceConfig.PlayAudioSafe("NODE_DEFEND")
        if type(onCombatHitCallback) == "function" then
            onCombatHitCallback(node)
        end
        return
    end

    if node.particles > 0 then
        -- 仍有驻军守备：交火决算
        local defenseDamp = (node.isDefensive and 0.7 or 1.0)
        if math.random() <= defenseDamp then
            node.particles = node.particles - 1
            -- COMBAT_HIT 保持静音，依靠视觉闪烁
        else
            BalanceConfig.PlayAudioSafe("NODE_DEFEND")
        end
        if onCombatHitCallback then
            onCombatHitCallback(node)
        end
        return
    end

    -- 3. 守军已清零，进入侵蚀与占领结算 (防守空虚)
    if node.faction ~= "neutral" then
        -- 3.1 敌对微粒侵蚀现有掌控者 (动摇沦陷阶段)
        -- 每颗微粒削减 10% 控制度
        node.control = math.max(0, (node.control or 100) - 10)
        node.contenderFaction = particleFaction
        if node.control <= (BalanceConfig.NEUTRAL_THRESHOLD or 20) then
            -- 彻底沦为中立争夺态！
            node.faction = "neutral"
            node.control = 0
            node.routeTo = nil
            node.isDefensive = false
            node.contenderFaction = particleFaction -- 攻破者确立为中立争夺先锋
            if onRevertNeutralCallback then
                onRevertNeutralCallback(node)
            end
        end
        if onCombatHitCallback then
            onCombatHitCallback(node)
        end
        return
    end

    -- 3.2 中立争夺态：多阵营拔河对消模型 (Tug-of-War)
    -- node.control 统一表示当前主导方 (node.contenderFaction) 的占领进度 (0 ~ 100)
    if node.contenderFaction == nil or (node.control or 0) <= 0 then
        -- 当前无主导方：该阵营微粒直接确立为主导方
        node.contenderFaction = particleFaction
        node.control = 10
    elseif node.contenderFaction == particleFaction then
        -- 同阵营微粒：推进占领进度
        node.control = math.min(100, (node.control or 0) + 10)
        if node.control >= 100 then
            -- 占领成功！成为正式据点
            node.faction = particleFaction
            node.control = 100
            node.particles = 2 -- 初始赠予 2 粒守军
            node.contenderFaction = nil
            node.isDefensive = true
            if onCaptureCallback then
                onCaptureCallback(node)
            end
            if particleFaction == "player" then
                BalanceConfig.PlayAudioSafe("NODE_CAPTURE")
            end
        end
    else
        -- 异阵营微粒：拔河对消！反向削减当前主导方的占领度
        node.control = (node.control or 0) - 10
        if node.control < 0 then
            -- 彻底击穿原主导方！新阵营确立并继承穿透进度
            node.contenderFaction = particleFaction
            node.control = math.abs(node.control)
        elseif node.control == 0 then
            -- 正好完全抵消归零，阵地重归中立争夺态
            node.contenderFaction = nil
            node.control = 0
        end
    end

    if onCombatHitCallback then
        onCombatHitCallback(node)
    end
end

-- 占领共鸣度周期自然维稳 (0.8s 周期)
function NodeEntity.TickCapture(node, elapsedTime, onCaptureCallback, onRevertNeutralCallback)
    local isProtected = (node.protectedUntil or 0) > (elapsedTime or 0)

    -- 若已有主据点守军充裕且无敌情侵蚀，受损控制度逐步平稳回满
    -- 若处于【千风庇护】守护期，即使兵力空虚也受神圣结界庇护并享受双倍共鸣恢复 (每次恢复 20%)
    if node.faction ~= "neutral" and (node.control or 0) < 100 and ((node.particles or 0) > 0 or isProtected) then
        local healRate = isProtected and 20 or 10
        node.control = math.min(100, (node.control or 0) + healRate)
    end
end

return NodeEntity

end
_MODULES["world/nodeEntity"] = _MODULES["src/world/nodeEntity"]

_MODULES["src/world/routeManager"] = function()
-- src/world/routeManager.lua
-- 地脉光轨物流管网、微粒发射批次与航线生命周期管理

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")
local NodeEntity = require("default_import_file/src/world/nodeEntity") or require("src/world/nodeEntity")

local RouteManager = {
    routes = {},           -- 活跃光轨列表: { fromId, toId, faction, sendTimer, boostedUntil }
    movingParticles = {}   -- 飞行中微粒: { fromId, toId, faction, progress, startX, startY, targetX, targetY, totalDist }
}

function RouteManager.Init()
    RouteManager.routes = {}
    RouteManager.movingParticles = {}
end

-- 建立单向光轨
function RouteManager.SetRoute(fromId, toId, faction, nodes)
    if not StarMap.AreNodesLinked(fromId, toId) then
        return false, "两灵穴间不存在直通地脉流道！"
    end

    local fromNode = StarMap.GetNode(nodes, fromId)
    local toNode = StarMap.GetNode(nodes, toId)
    if not fromNode or not toNode then return false end

    -- 单节点同一时间仅允许存在 1 条对外输出光轨
    RouteManager.RemoveRouteFrom(fromId, nodes)

    -- 仅限【同阵营内部调兵】防止死锁回环：若同阵营目标据点已在向源据点输送，切断原同向光轨
    -- 敌对阵营之间完全允许互相进攻交火，绝不打断敌方的进攻光轨！
    local revRoute = RouteManager.GetRouteFrom(toId)
    if revRoute and revRoute.toId == fromId and revRoute.faction == faction then
        RouteManager.RemoveRouteFrom(toId, nodes)
    end

    fromNode.routeTo = toId
    fromNode.isDefensive = false -- 开启输出自动解除纯驻阵固守

    table.insert(RouteManager.routes, {
        fromId = fromId,
        toId = toId,
        faction = faction,
        sendTimer = 0,
        boostedUntil = 0
    })

    if faction == "player" then
        BalanceConfig.PlayAudioSafe("ROUTE_LINK")
    end
    return true
end

-- 切断指定节点的对外光轨
function RouteManager.RemoveRouteFrom(fromId, nodes)
    for i = #RouteManager.routes, 1, -1 do
        local r = RouteManager.routes[i]
        if r.fromId == fromId then
            table.remove(RouteManager.routes, i)
            local node = nodes[fromId + 1]
            if node then
                node.routeTo = nil
            end
            return true
        end
    end
    return false
end

function RouteManager.GetRouteFrom(fromId)
    for _, r in ipairs(RouteManager.routes) do
        if r.fromId == fromId then return r end
    end
    return nil
end

-- 每帧更新：物流发射、中途相向空间分桶碰撞决算与微粒航行
function RouteManager.Update(dt, nodes, elapsedTime, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback)
    -- 1. 物流发射（含高负荷自动数据包聚合 Packet Merging 机制）
    local activeParticleCount = #RouteManager.movingParticles
    local isHighLoad = (activeParticleCount >= 96) -- 超过 120 容积的 80% 触发聚合

    for _, route in ipairs(RouteManager.routes) do
        local fromNode = StarMap.GetNode(nodes, route.fromId)
        local toNode = StarMap.GetNode(nodes, route.toId)

        if fromNode and toNode and fromNode.faction == route.faction then
            route.sendTimer = (route.sendTimer or 0) + dt
            local isBoosted = (fromNode.anomaly == "WIND_FLOW" or (route.boostedUntil and route.boostedUntil > elapsedTime))
            local rate = isBoosted and BalanceConfig.BOOST_TRANSPORT_RATE or BalanceConfig.BASE_TRANSPORT_RATE

            local interval = 1.0 / rate
            if route.sendTimer >= interval then
                route.sendTimer = 0
                -- 节点保留基础守备兵力 (默认 3 粒，防止基地永久定格在 1 且防守空虚)
                local safeFloor = BalanceConfig.SAFE_GARRISON or 3
                local available = fromNode.particles - safeFloor
                if available > 0 then
                    -- 数据包聚合计算：高负载时单次发射 2~3 粒
                    local payload = 1
                    if isHighLoad and available >= 2 then
                        payload = math.min(3, available)
                    end
                    fromNode.particles = fromNode.particles - payload

                    local dx = toNode.x - fromNode.x
                    local dy = toNode.y - fromNode.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist <= 0.001 then dist = 1 end

                    local nx = -dy / dist
                    local ny = dx / dist
                    local rad = math.atan(dy, dx)
                    local angle = math.deg(rad)

                    table.insert(RouteManager.movingParticles, {
                        fromId = fromNode.id,
                        toId = toNode.id,
                        edgeKey = StarMap.GetEdgeKey(fromNode.id, toNode.id),
                        faction = route.faction,
                        payload = payload,
                        progress = 0,
                        startX = fromNode.x,
                        startY = fromNode.y,
                        targetX = toNode.x,
                        targetY = toNode.y,
                        totalDist = dist,
                        nx = nx,
                        ny = ny,
                        angle = angle,
                        seed = (fromNode.id * 17 + toNode.id * 31) % 100,
                        isBoosted = isBoosted
                    })
                end
            end
        end
    end

    -- 2. 飞行微粒位移更新
    for _, p in ipairs(RouteManager.movingParticles) do
        local step = (BalanceConfig.PARTICLE_SPEED * dt) / p.totalDist
        p.progress = p.progress + step
    end

    -- 3. O(N) 空间边分桶中途碰撞决算 (同一条边相向而行的大对撞)
    local edgeBuckets = {}
    for i, p in ipairs(RouteManager.movingParticles) do
        if p.progress < 1.0 and (p.payload or 1) > 0 then
            local k = p.edgeKey
            if not edgeBuckets[k] then
                edgeBuckets[k] = { i }
            else
                table.insert(edgeBuckets[k], i)
            end
        end
    end

    for _, indices in pairs(edgeBuckets) do
        if #indices >= 2 then
            for idxA = 1, #indices do
                local i = indices[idxA]
                local pA = RouteManager.movingParticles[i]
                if pA and (pA.payload or 1) > 0 then
                    for idxB = idxA + 1, #indices do
                        local j = indices[idxB]
                        local pB = RouteManager.movingParticles[j]
                        -- 仅在相向对流且不同阵营时发生交汇湮灭
                        if pB and (pB.payload or 1) > 0 and pA.faction ~= pB.faction and pA.fromId == pB.toId and pA.toId == pB.fromId then
                            -- 一维交汇比对：两相向质点进度之和 >= 1.0 即说明在航道中途相撞！
                            if (pA.progress + pB.progress) >= 1.0 then
                                local colX = pA.startX + (pA.targetX - pA.startX) * pA.progress
                                local colY = pA.startY + (pA.targetY - pA.startY) * pA.progress
                                if onCombatHitCallback then
                                    onCombatHitCallback({ x = colX, y = colY })
                                end
                                BalanceConfig.PlayAudioSafe("NODE_DEFEND")

                                local payA = pA.payload or 1
                                local payB = pB.payload or 1
                                if payA == payB then
                                    pA.payload = 0
                                    pB.payload = 0
                                elseif payA > payB then
                                    pA.payload = payA - payB
                                    pB.payload = 0
                                else
                                    pB.payload = payB - payA
                                    pA.payload = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 4. 到达目标节点或中途湮灭结算
    for i = #RouteManager.movingParticles, 1, -1 do
        local p = RouteManager.movingParticles[i]
        local payload = p.payload or 1

        if payload <= 0 then
            -- 中途碰撞完全消散
            table.remove(RouteManager.movingParticles, i)
        elseif p.progress >= 1.0 then
            -- 成功抵达目标据点
            local targetNode = StarMap.GetNode(nodes, p.toId)
            if targetNode then
                for _ = 1, payload do
                    RouteManager.OnParticleArrive(p, targetNode, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
                end
            end
            table.remove(RouteManager.movingParticles, i)
        end
    end
end

-- 微粒到达目标节点结算 (委托至 NodeEntity.ApplyArrival 拔河对消决算)
function RouteManager.OnParticleArrive(particle, node, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    if NodeEntity and NodeEntity.ApplyArrival then
        NodeEntity.ApplyArrival(node, particle.faction, onCombatHitCallback, onCaptureCallback, onRevertNeutralCallback, elapsedTime)
    else
        -- 兜底逻辑
        if node.faction == particle.faction then
            node.particles = node.particles + 1
        elseif (node.protectedUntil or 0) > (elapsedTime or 0) then
            -- 受千风庇护免疫
            BalanceConfig.PlayAudioSafe("NODE_DEFEND")
            if onCombatHitCallback then onCombatHitCallback(node) end
        elseif node.particles > 0 then
            node.particles = node.particles - 1
            if onCombatHitCallback then onCombatHitCallback(node) end
        end
    end
end

return RouteManager

end
_MODULES["world/routeManager"] = _MODULES["src/world/routeManager"]

_MODULES["src/world/combatResolver"] = function()
-- src/world/combatResolver.lua
-- 轨道交火决算、威胁态判定与战火特效数据维护

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")

local CombatResolver = {
    sparks = {} -- { x, y, life, maxLife, color }
}

function CombatResolver.Init()
    CombatResolver.sparks = {}
end

function CombatResolver.AddSpark(x, y, color)
    table.insert(CombatResolver.sparks, {
        x = x + (math.random() - 0.5) * 24,
        y = y + (math.random() - 0.5) * 24,
        life = 0.35,
        maxLife = 0.35,
        color = color or 0xFFF43F5E
    })
end

function CombatResolver.Update(dt, nodes, movingParticles)
    -- 1. 更新火花生命周期
    for i = #CombatResolver.sparks, 1, -1 do
        local sp = CombatResolver.sparks[i]
        sp.life = sp.life - dt
        if sp.life <= 0 then
            table.remove(CombatResolver.sparks, i)
        end
    end

    -- 2. 威胁判定与防空提示
    for _, node in ipairs(nodes) do
        node.hasEnemyThreat = false
        if node.faction ~= "neutral" then
            for _, p in ipairs(movingParticles) do
                if p.toId == node.id and p.faction ~= node.faction then
                    node.hasEnemyThreat = true
                    break
                end
            end
        end
    end
end

return CombatResolver

end
_MODULES["world/combatResolver"] = _MODULES["src/world/combatResolver"]

_MODULES["src/world/abilitySystem"] = function()
-- src/world/abilitySystem.lua
-- 战术符印权能执行器、法术冷却计时与战场逆转效果驱动

local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local AbilitySystem = {
    deck = {},             -- 当前装配的4张卡片元数据
    cooldowns = { 0, 0, 0, 0 }
}

-- 判定是否为敌对势力据点（支持多阵营敌方 enemy_red / enemy_purple / enemy_green / enemy）
local function IsEnemyFaction(faction)
    if not faction then return false end
    if faction == "player" or faction == "neutral" then return false end
    return true
end

function AbilitySystem.InitDeck(cardIdList)
    AbilitySystem.deck = {}
    AbilitySystem.cooldowns = { 0, 0, 0, 0 }
    for i, id in ipairs(cardIdList) do
        if i <= 4 then
            local card = CardRegistry.GetCardById(id)
            if card then
                table.insert(AbilitySystem.deck, card)
            end
        end
    end
    -- 确保局内符印栏按消耗权能升序排列 (低费在前，高费在后)
    table.sort(AbilitySystem.deck, function(a, b)
        return a.cost < b.cost
    end)
end

function AbilitySystem.UpdateCooldowns(dt)
    for i = 1, #AbilitySystem.cooldowns do
        if AbilitySystem.cooldowns[i] > 0 then
            AbilitySystem.cooldowns[i] = math.max(0, AbilitySystem.cooldowns[i] - dt)
        end
    end
end

-- 施放指定符印
function AbilitySystem.CastAbility(slotIndex, targetNodeId, nodes, routeManager, elapsedTime, onSparkCallback)
    local card = AbilitySystem.deck[slotIndex]
    if not card then return false, "未找到该符印" end

    if AbilitySystem.cooldowns[slotIndex] > 0 then
        return false, "符印权能仍在凝聚冷却中！"
    end

    local targetNode = StarMap.GetNode(nodes, targetNodeId)
    if not targetNode then return false, "未选中合法灵穴" end

    if card.id == "anemo_shield" then
        -- 千风庇护：仅己方节点
        if targetNode.faction ~= "player" then
            return false, "【千风庇护】只能施加于我方灵穴！"
        end
        targetNode.protectedUntil = elapsedTime + card.duration
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        return true, "【千风庇护】生效！20秒内免疫侵蚀！"

    elseif card.id == "anemo_turb" then
        -- 千风湍流：需正在向外输送的己方节点
        if targetNode.faction ~= "player" or targetNode.routeTo == nil then
            return false, "【千风湍流】需要施加在正在向外输送的己方灵穴上！"
        end
        local route = routeManager.GetRouteFrom(targetNode.id)
        if route then
            route.boostedUntil = elapsedTime + card.duration
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【千风湍流】激发！地脉输送流速翻倍！"
        end
        return false, "未检测到活跃输出光轨"

    elseif card.id == "pyro_blast" then
        -- 轰轰烈焰：轰炸敌方据点
        if not IsEnemyFaction(targetNode.faction) then
            return false, "【轰轰烈焰】只能轰击敌对势力据点！"
        end
        local eliminated = math.floor(targetNode.particles * 0.8)
        targetNode.particles = targetNode.particles - eliminated

        if onSparkCallback then
            for _ = 1, 10 do
                onSparkCallback(targetNode.x, targetNode.y, 0xFFFF3F20)
            end
        end

        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("SKILL_BLAST")
        return true, "【轰轰烈焰】轰爆了 " .. tostring(eliminated) .. " 粒敌对微粒！"

    elseif card.id == "hydro_bribe" then
        -- 摩拉律法：中立秒占，敌方削弱
        if targetNode.faction == "neutral" then
            targetNode.faction = "player"
            targetNode.control = 100
            targetNode.particles = 15
            targetNode.isDefensive = true
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【摩拉律法】生效！已直接同化掌管中立灵穴！"
        elseif IsEnemyFaction(targetNode.faction) then
            targetNode.control = math.max(0, targetNode.control - 65)
            AbilitySystem.cooldowns[slotIndex] = card.cd
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            return true, "【摩拉律法】生效！瓦解敌方 65% 共鸣！"
        else
            return false, "不可对己方灵穴使用摩拉律法"
        end

    elseif card.id == "geo_wall" then
        -- 坚岩重嶂：己方据点坚盾加持，增加10微粒并固守20秒
        if targetNode.faction ~= "player" then
            return false, "【坚岩重嶂】只能施加于我方灵穴！"
        end
        targetNode.isDefensive = true
        targetNode.protectedUntil = elapsedTime + card.duration
        targetNode.particles = targetNode.particles + 10
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        return true, "【坚岩重嶂】磐岩升起！增生10微粒并展开20秒坚盾！"

    elseif card.id == "pyro_erosion" then
        -- 烈焰侵蚀：重创敌对据点并切断其输出航线
        if not IsEnemyFaction(targetNode.faction) then
            return false, "【烈焰侵蚀】只能施加于敌方灵穴！"
        end
        local cut = math.max(8, math.floor(targetNode.particles * 0.4))
        targetNode.particles = math.max(0, targetNode.particles - cut)
        if routeManager and routeManager.RemoveRouteFrom then
            routeManager.RemoveRouteFrom(targetNode.id, nodes)
        end
        if onSparkCallback then
            for _ = 1, 8 do
                onSparkCallback(targetNode.x, targetNode.y, 0xFFFF3F20)
            end
        end
        AbilitySystem.cooldowns[slotIndex] = card.cd
        BalanceConfig.PlayAudioSafe("SKILL_BLAST")
        return true, "【烈焰侵蚀】灼烧敌穴！削减 " .. cut .. " 微粒并截断其输出！"
    end

    return false, "未知符印效果"
end

-- 智能索敌推荐目标（针对玩家快捷双击或自动施法）
function AbilitySystem.GetSmartTarget(cardId, nodes, routeManager)
    if cardId == "anemo_shield" or cardId == "geo_wall" then
        -- 优先选受到敌袭动摇或兵力最少的己方节点
        local best = nil
        for _, n in ipairs(nodes) do
            if n.faction == "player" then
                if not best or (n.particles < best.particles) then
                    best = n
                end
            end
        end
        return best and best.id or nil

    elseif cardId == "anemo_turb" then
        -- 优先选正在向外输出光轨的己方灵穴
        for _, n in ipairs(nodes) do
            if n.faction == "player" and n.routeTo ~= nil then
                return n.id
            end
        end
        -- 次选任意己方灵穴
        for _, n in ipairs(nodes) do
            if n.faction == "player" then return n.id end
        end
        return nil

    elseif cardId == "pyro_blast" or cardId == "pyro_erosion" then
        -- 优先选兵力最多的敌方灵穴
        local best = nil
        for _, n in ipairs(nodes) do
            if IsEnemyFaction(n.faction) then
                if not best or (n.particles > best.particles) then
                    best = n
                end
            end
        end
        return best and best.id or nil

    elseif cardId == "hydro_bribe" then
        -- 优先选中立灵穴，其次选敌方灵穴
        for _, n in ipairs(nodes) do
            if n.faction == "neutral" then return n.id end
        end
        for _, n in ipairs(nodes) do
            if IsEnemyFaction(n.faction) then return n.id end
        end
        return nil
    end
    return nil
end

return AbilitySystem

end
_MODULES["world/abilitySystem"] = _MODULES["src/world/abilitySystem"]

_MODULES["src/world/factionAI"] = function()
-- src/world/factionAI.lua
-- 坎瑞亚遗迹推衍机（多阵营全员大乱斗 AI 智能调度与梯次争端决策）

local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local FactionAI = {
    aiTimer = 0,
    AI_INTERVAL = 1.2 -- 1.2 秒决策一轮，反应敏捷高效
}

-- 辅助：广度优先遍历计算每个节点到最近非己方节点的最短跳数 (战线梯度)
local function ComputeFrontierDistances(allNodes, fac)
    local distMap = {}
    local queue = {}

    -- 1. 所有非己方节点作为距离源点 (距离为 0)
    for _, node in ipairs(allNodes) do
        if node.faction ~= fac then
            distMap[node.id] = 0
            table.insert(queue, node.id)
        end
    end

    -- 2. BFS 向内陆扩散标记跳数
    local head = 1
    while head <= #queue do
        local currId = queue[head]
        head = head + 1
        local currDist = distMap[currId]

        local neighbors = StarMap.GetNeighbors(currId)
        for _, nId in ipairs(neighbors) do
            if distMap[nId] == nil then
                distMap[nId] = currDist + 1
                table.insert(queue, nId)
            end
        end
    end

    return distMap
end

function FactionAI.Update(dt, nodes, routeManager)
    FactionAI.aiTimer = FactionAI.aiTimer + dt
    if FactionAI.aiTimer < FactionAI.AI_INTERVAL then
        return
    end
    FactionAI.aiTimer = 0

    -- 1. 收集当前场上所有活跃的 AI 势力阵营
    local activeFactions = {}
    for _, node in ipairs(nodes) do
        local fac = node.faction
        if fac ~= "player" and fac ~= "neutral" and not activeFactions[fac] then
            activeFactions[fac] = true
        end
    end

    -- 2. 针对每个 AI 阵营独立推衍战局
    for fac, _ in pairs(activeFactions) do
        local distMap = ComputeFrontierDistances(nodes, fac)

        for _, eNode in ipairs(nodes) do
            if eNode.faction == fac then
                local nodeDist = distMap[eNode.id] or 99

                -- ========================================================
                -- 阶段 1：活跃光轨动态监测与适时切断 (防止死循环抽干)
                -- ========================================================
                if eNode.routeTo ~= nil then
                    local targetNode = nodes[eNode.routeTo + 1]
                    local shouldCut = false

                    if targetNode then
                        if targetNode.faction == fac then
                            -- 目标为友军据点：
                            -- a) 目标守军已极大饱和 (>= 22 粒) -> 增援圆满达成
                            -- b) 源节点兵力降至防守底线 (<= 4 粒) -> 停止抽血
                            -- c) 目标节点正向源节点反向输送 -> 严重对冲死锁
                            if targetNode.particles >= 22 or eNode.particles <= 4 or targetNode.routeTo == eNode.id then
                                shouldCut = true
                            end
                        else
                            -- 目标为敌方/中立据点：
                            -- a) 自身兵力消耗至危急水平 (< 3 粒) -> 进攻受挫，撤退固守
                            if eNode.particles < 3 then
                                shouldCut = true
                            end
                        end
                    else
                        shouldCut = true
                    end

                    if shouldCut then
                        routeManager.RemoveRouteFrom(eNode.id, nodes)
                        eNode.isDefensive = true
                    end

                -- ========================================================
                -- 阶段 2：空闲节点决策与目标选择 (当 routeTo 为 nil 时执行)
                -- ========================================================
                else
                    local neighbors = StarMap.GetNeighbors(eNode.id)

                    if nodeDist > 1 then
                        -- ----------------------------------------------------
                        -- 分支 A：后方腹地节点 (战线跳数 > 1，远离前线)
                        -- 核心策略：梯次推进输送带 (Conveyor Belt)
                        -- 只要兵力充足 (>= 12 粒)，向更靠近前线的友军邻居调兵！
                        -- ----------------------------------------------------
                        if eNode.particles >= 12 then
                            local bestForwardAlly = nil
                            local minAllyParts = 999

                            for _, nId in ipairs(neighbors) do
                                local n = StarMap.GetNode(nodes, nId)
                                local nDist = distMap[nId] or 99
                                -- 必须是同阵营友军，且距离前线更近 (nDist < nodeDist)
                                if n and n.faction == fac and nDist < nodeDist then
                                    if n.routeTo ~= eNode.id and n.particles < 22 then
                                        if n.particles < minAllyParts then
                                            minAllyParts = n.particles
                                            bestForwardAlly = n
                                        end
                                    end
                                end
                            end

                            if bestForwardAlly then
                                routeManager.SetRoute(eNode.id, bestForwardAlly.id, fac, nodes)
                            end
                        end

                    else
                        -- ----------------------------------------------------
                        -- 分支 B：前线接触据点 (nodeDist == 1，直接毗邻敌方/中立)
                        -- 核心策略：动态斩首突击与战线拓展
                        -- ----------------------------------------------------
                        local hostileTargets = {}
                        for _, nId in ipairs(neighbors) do
                            local n = StarMap.GetNode(nodes, nId)
                            if n and n.faction ~= fac then
                                table.insert(hostileTargets, n)
                            end
                        end

                        local chosenTarget = nil
                        if #hostileTargets > 0 and eNode.particles >= 4 then
                            -- 优先夺取中立据点
                            local neutralTargets = {}
                            local enemyTargets = {}
                            for _, t in ipairs(hostileTargets) do
                                if t.faction == "neutral" then
                                    table.insert(neutralTargets, t)
                                else
                                    table.insert(enemyTargets, t)
                                end
                            end

                            if #neutralTargets > 0 then
                                -- 抢占中立：优先兵力较少的
                                table.sort(neutralTargets, function(a, b) return a.particles < b.particles end)
                                chosenTarget = neutralTargets[1]
                            elseif #enemyTargets > 0 then
                                table.sort(enemyTargets, function(a, b) return a.particles < b.particles end)
                                local weakestEnemy = enemyTargets[1]

                                -- 动态门槛斩首判定：
                                -- 1) 敌方据点极为空虚 (<= 3 粒，甚至 0 粒无防守)：只要我方 >= 4 粒且多于敌方，果断斩首！
                                -- 2) 敌方据点防守充裕 (> 3 粒)：我方集结达到 8 粒以上且占优，发起总攻！
                                if weakestEnemy.particles <= 3 then
                                    if eNode.particles >= 4 and eNode.particles > weakestEnemy.particles then
                                        chosenTarget = weakestEnemy
                                    end
                                else
                                    if eNode.particles >= 8 and eNode.particles >= weakestEnemy.particles then
                                        chosenTarget = weakestEnemy
                                    end
                                end
                            end
                        end

                        if chosenTarget then
                            routeManager.SetRoute(eNode.id, chosenTarget.id, fac, nodes)
                        elseif eNode.particles >= 14 then
                            -- 前线防守充沛但无合适进攻机会时，协助相邻受困的前线友军
                            for _, nId in ipairs(neighbors) do
                                local n = nodes[nId + 1]
                                if n and n.faction == fac and n.particles < 8 and n.routeTo ~= eNode.id then
                                    routeManager.SetRoute(eNode.id, n.id, fac, nodes)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return FactionAI

end
_MODULES["world/factionAI"] = _MODULES["src/world/factionAI"]

_MODULES["src/ui/visualRenderer"] = function()
-- src/ui/visualRenderer.lua
-- 提瓦特星象仪级几何视觉渲染器
-- 包含：三层文字分离黄金分割排版、三层差速星环与易主动态弹性波、柔边羽化光轨、正弦呼吸脉冲与拓扑交互指引

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")
local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local VisualRenderer = {
    isLayoutInitialized = false,
    hasRadialApiChecked = false,
    hasRadialApi = false
}

-- 异象视觉风格表
local ANOMALY_STYLE = {
    AMBER_MINE      = { label = "✦ 石珀晶矿", colorKey = "AMBER" },
    WIND_FLOW       = { label = "❖ 疾风流道", colorKey = "ANEMO" },
    MIST_RUINS      = { label = "◈ 迷雾荒墟", colorKey = "TEXT_MUTED" },
    DEFENSE_BASTION = { label = "❖ 雷暴要塞", colorKey = "GOLD" },
    PURE_WATER      = { label = "✦ 纯水枢纽", colorKey = "PLAYER" },
    PLASMA          = { label = "✴ 赤阳熔核", colorKey = "ENEMY" }
}

-- 初始化连线柔边羽化 (消除矩形生硬折角，构建星轨能量束)
function VisualRenderer.InitLineSoftEdge(routeCtrls, staticLinkCtrls)
    if routeCtrls then
        for _, lineCtrl in ipairs(routeCtrls) do
            if lineCtrl and lineCtrl.alive then
                pcall(function()
                    lineCtrl.enableSoftEdge = true
                    if lineCtrl.SetSoftEdgeWidth then
                        lineCtrl:SetSoftEdgeWidth(2, 4)
                    end
                end)
            end
        end
    end
    if staticLinkCtrls then
        for _, sCtrl in ipairs(staticLinkCtrls) do
            if sCtrl and sCtrl.alive then
                pcall(function()
                    sCtrl.enableSoftEdge = true
                    if sCtrl.SetSoftEdgeWidth then
                        sCtrl:SetSoftEdgeWidth(1, 2)
                    end
                end)
            end
        end
    end
end

-- 一次性初始化所有灵穴节点的三层文字排版锚点与深色描边样式 (避免每帧重复调用造成额外开销)
local function EnsureNodeLayoutInitialized(nodeUIList)
    if VisualRenderer.isLayoutInitialized then return end
    VisualRenderer.isLayoutInitialized = true

    if not nodeUIList then return end
    for _, ui in ipairs(nodeUIList) do
        -- 1. 核心兵力大字 (居中锚定于圆盘正中央)
        if ui.particleText and ui.particleText.alive then
            Layout.ApplyTextStyle(ui.particleText, 20, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.particleText.anchoredPositionX = 0
                ui.particleText.anchoredPositionY = 0
            end)
        end
        -- 2. 底部灵穴名称 (下移至圆盘正下方外侧，不遮挡核心兵力)
        if ui.titleText and ui.titleText.alive then
            Layout.ApplyTextStyle(ui.titleText, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.titleText.anchoredPositionX = 0
                ui.titleText.anchoredPositionY = -34
            end)
        end
        -- 3. 顶部异象标识 (上移至圆盘外侧上方)
        if ui.anomalyText and ui.anomalyText.alive then
            Layout.ApplyTextStyle(ui.anomalyText, 11, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.anomalyText.anchoredPositionX = 0
                ui.anomalyText.anchoredPositionY = 34
            end)
        end
        -- 4. 顶部战术状态提示 (置于异象上方或交替呈现)
        if ui.statusText and ui.statusText.alive then
            Layout.ApplyTextStyle(ui.statusText, 11, Layout.PALETTE.ANEMO, Layout.PALETTE.BG_DARK)
            pcall(function()
                ui.statusText.anchoredPositionX = 0
                ui.statusText.anchoredPositionY = 48
            end)
        end
    end
end

-- 动态绘制/变换单条线段条带控件
function VisualRenderer.SetLineTransform(lineCtrl, x1, y1, x2, y2, thickness, color)
    if not lineCtrl or not lineCtrl.alive then return end

    local dist = Layout.Distance(x1, y1, x2, y2)
    local angle = Layout.AngleDeg(x1, y1, x2, y2)

    lineCtrl.anchoredPositionX = x1
    lineCtrl.anchoredPositionY = y1
    lineCtrl.sizeDeltaX = dist
    lineCtrl.sizeDeltaY = thickness or 4
    lineCtrl.localRotationZ = angle

    if color then
        lineCtrl.imageColor = color
    end

    Layout.SetVisible(lineCtrl, true)
end

-- 更新所有活跃光轨与拖拽连线（支持正弦能量呼吸脉冲与拖拽导引）
function VisualRenderer.UpdateRoutes(routeCtrls, routes, nodes, dragLineCtrl, inputState, elapsedTime)
    local activeCount = #routes
    local maxCtrls = #routeCtrls

    for i = 1, maxCtrls do
        local ctrl = routeCtrls[i]
        if ctrl and ctrl.alive then
            if i <= activeCount then
                local r = routes[i]
                local nA = StarMap.GetNode(nodes, r.fromId)
                local nB = StarMap.GetNode(nodes, r.toId)

                if nA and nB then
                    local baseCol = Layout.GetFactionColor(r.faction)
                    local isBoosted = (nA.anomaly == "WIND_FLOW" or (r.boostedUntil and r.boostedUntil > elapsedTime))

                    if isBoosted then
                        baseCol = Layout.PALETTE.ANEMO
                    end

                    -- 正弦能量脉冲：粗细 5.5px~8.5px 呼吸，透明度 170~250 流转
                    local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 5.0 + (r.fromId or 0))
                    local baseThickness = isBoosted and 7.5 or 5.0
                    local thickness = baseThickness + pulse * 2.2
                    local alpha = math.floor(170 + pulse * 80)
                    local pulseCol = Layout.WithAlpha(baseCol, alpha)

                    VisualRenderer.SetLineTransform(ctrl, nA.x, nA.y, nB.x, nB.y, thickness, pulseCol)
                else
                    Layout.SetVisible(ctrl, false)
                end
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end

    -- 拖拽实时导引线 (曜金星轨引导)
    if dragLineCtrl and dragLineCtrl.alive then
        if inputState.isDragging and inputState.dragSourceId ~= nil then
            local sourceNode = StarMap.GetNode(nodes, inputState.dragSourceId)
            if sourceNode then
                local pulse = 0.5 + 0.5 * math.sin(elapsedTime * 8.0)
                local dragThickness = 3.2 + pulse * 1.5
                local dragColor = Layout.WithAlpha(Layout.PALETTE.GOLD, math.floor(160 + pulse * 95))
                VisualRenderer.SetLineTransform(
                    dragLineCtrl,
                    sourceNode.x, sourceNode.y,
                    inputState.dragCurrentX, inputState.dragCurrentY,
                    dragThickness,
                    dragColor
                )
            else
                Layout.SetVisible(dragLineCtrl, false)
            end
        else
            Layout.SetVisible(dragLineCtrl, false)
        end
    end
end

-- 更新地脉节点视觉呈现 (三层文字黄金分割排版、差速旋转、易主/受击弹性波、拓扑连通高亮)
function VisualRenderer.UpdateNodes(nodeUIList, nodes, elapsedTime, inputState)
    EnsureNodeLayoutInitialized(nodeUIList)

    local isDragging = inputState and inputState.isDragging and inputState.dragSourceId ~= nil
    local dragSourceId = isDragging and inputState.dragSourceId or nil
    local validNeighborsMap = {}

    if isDragging and dragSourceId ~= nil then
        local nList = StarMap.GetNeighbors(dragSourceId)
        for _, nId in ipairs(nList) do
            validNeighborsMap[nId] = true
        end
    end

    for i, node in ipairs(nodes) do
        local ui = nodeUIList[i]
        if ui then
            local factionColor = Layout.GetFactionColor(node.faction)
            local currentParts = math.floor(node.particles or 0)
            local isSource = (isDragging and node.id == dragSourceId)
            local isValidNeighbor = (isDragging and validNeighborsMap[node.id])
            local phase = (node.id or i) * 1.5

            -- 1. 监测易主与兵力跳变，驱动动效弹性缩放冲击波 (Scale Pop)
            if ui.lastFaction ~= nil and ui.lastFaction ~= node.faction then
                ui.capturePulse = 1.0 -- 易主爆发强烈冲击波
            end
            if ui.lastParticles ~= nil and ui.lastParticles ~= currentParts then
                ui.numberPulse = math.min(1.0, (ui.numberPulse or 0) + 0.45)
            end
            ui.lastFaction = node.faction
            ui.lastParticles = currentParts
            ui.capturePulse = math.max(0, (ui.capturePulse or 0) - 0.05)
            ui.numberPulse  = math.max(0, (ui.numberPulse or 0) - 0.08)

            -- 2. 节点整体缩放与明暗处理 (拖拽连线时合法邻居高亮并放大，非邻居半透明压暗)
            if ui.group and ui.group.alive then
                if isDragging then
                    if isSource then
                        ui.group.localScaleX = 1.18
                        ui.group.localScaleY = 1.18
                    elseif isValidNeighbor then
                        local neighPulse = 1.12 + 0.05 * math.sin(elapsedTime * 6.0 + phase)
                        ui.group.localScaleX = neighPulse
                        ui.group.localScaleY = neighPulse
                    else
                        ui.group.localScaleX = 0.94
                        ui.group.localScaleY = 0.94
                    end
                else
                    -- 平时底盘自呼吸脉冲
                    local baseScale = node.isIdle and 0.88 or (1.0 + 0.03 * math.sin(elapsedTime * 3.0 + phase))
                    ui.group.localScaleX = baseScale
                    ui.group.localScaleY = baseScale
                end
            end

            -- 3. 固守防御环 (第一层：顺时针差速自转 + 庇护/固守状态展示)
            if ui.defenseRing and ui.defenseRing.alive then
                local isShielded = (node.protectedUntil and node.protectedUntil > elapsedTime)
                local isFortified = (node.isDefensive and node.routeTo == nil and node.faction ~= "neutral")

                if isShielded or isFortified or isValidNeighbor then
                    Layout.SetVisible(ui.defenseRing, true)
                    local rotSpeed = isShielded and 80 or 20
                    ui.defenseRing.localRotationZ = (elapsedTime * rotSpeed + phase * 20) % 360
                    local ringScale = 1.04 + 0.05 * math.sin(elapsedTime * 4.5 + phase)
                    pcall(function()
                        ui.defenseRing.localScaleX = ringScale
                        ui.defenseRing.localScaleY = ringScale
                    end)

                    if isShielded then
                        local pulseA = 170 + 80 * (0.5 + 0.5 * math.sin(elapsedTime * 7.0))
                        ui.defenseRing.imageColor = Layout.WithAlpha(Layout.PALETTE.ANEMO, pulseA)
                    elseif isFortified then
                        ui.defenseRing.imageColor = Layout.PALETTE.GOLD_ALPHA
                    elseif isValidNeighbor then
                        ui.defenseRing.imageColor = Layout.PALETTE.GOLD
                    end
                else
                    Layout.SetVisible(ui.defenseRing, false)
                end
            end

            -- 4. 灵穴核心底盘 (BaseDisc)：阵营暗底染色 + 内陆休眠微缩 / 易主回弹
            if ui.baseDisc and ui.baseDisc.alive then
                local breathe = node.isIdle and -0.06 or (0.03 * math.sin(elapsedTime * 3.0 + phase))
                local discScale = 1.0 + breathe + (ui.capturePulse * 0.32)
                local discAlpha = node.isIdle and 140 or 225
                ui.baseDisc.imageColor = Layout.GetFactionGlowColor(node.faction, discAlpha)
                pcall(function()
                    ui.baseDisc.localScaleX = discScale
                    ui.baseDisc.localScaleY = discScale
                end)
            end

            -- 5. 灵穴主体共鸣外环 (第二层：逆时针微转 + Lerp 阻尼平滑进度)
            if ui.resonanceRing and ui.resonanceRing.alive then
                ui.resonanceRing.localRotationZ = -(elapsedTime * 14 + phase * 15) % 360

                if isDragging and not isSource and not isValidNeighbor then
                    ui.resonanceRing.imageColor = Layout.WithAlpha(factionColor, 90)
                else
                    ui.resonanceRing.imageColor = factionColor
                end

                local targetProgress = Layout.Clamp((node.control or 100) / 100, 0.06, 1.0)
                ui.smoothProgress = Layout.Lerp(ui.smoothProgress or targetProgress, targetProgress, 0.2)

                local ringPop = 1.0 + (ui.capturePulse * 0.25)
                pcall(function()
                    ui.resonanceRing.localScaleX = ringPop
                    ui.resonanceRing.localScaleY = ringPop
                end)

                if not VisualRenderer.hasRadialApiChecked then
                    VisualRenderer.hasRadialApiChecked = true
                    VisualRenderer.hasRadialApi = (ui.resonanceRing.SetFillRadial360 ~= nil and Enum and Enum.ImageFillRadialType ~= nil)
                end

                if VisualRenderer.hasRadialApi then
                    ui.resonanceRing:SetFillRadial360(Enum.ImageFillRadialType.Top, ui.smoothProgress)
                else
                    ui.resonanceRing.fillAmount = ui.smoothProgress
                end
            end

            -- 6. 核心兵力数字与底部灵穴名称分离渲染 (黄金分割排版)
            if ui.particleText and ui.particleText.alive then
                Layout.SetVisible(ui.particleText, true)
                ui.particleText.text = tostring(currentParts)
                local dynamicFontSize = math.floor(Layout.Clamp(17 + currentParts * 0.12 + ui.numberPulse * 3, 17, 25))
                pcall(function()
                    ui.particleText.fontSize = dynamicFontSize
                    local numScale = 1.0 + ui.numberPulse * 0.16
                    ui.particleText.localScaleX = numScale
                    ui.particleText.localScaleY = numScale
                end)
                ui.particleText.fontColor = (currentParts >= 40) and Layout.PALETTE.GOLD or Layout.PALETTE.TEXT_LIGHT
            end

            if ui.titleText and ui.titleText.alive then
                Layout.SetVisible(ui.titleText, true)
                ui.titleText.text = "「" .. tostring(node.name or "灵穴") .. "」"
                if isDragging and not isSource and not isValidNeighbor then
                    ui.titleText.fontColor = Layout.WithAlpha(Layout.PALETTE.TEXT_LIGHT, 110)
                else
                    ui.titleText.fontColor = (node.faction == "neutral") and Layout.PALETTE.NEUTRAL or Layout.PALETTE.TEXT_LIGHT
                end
            end

            -- 7. 顶部异象标签 (提瓦特星象符号与专属配色)
            local hasAnomaly = false
            if ui.anomalyText and ui.anomalyText.alive then
                local style = node.anomaly and ANOMALY_STYLE[node.anomaly]
                if style then
                    hasAnomaly = true
                    ui.anomalyText.text = style.label
                    ui.anomalyText.fontColor = Layout.PALETTE[style.colorKey] or Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.anomalyText, true)
                else
                    Layout.SetVisible(ui.anomalyText, false)
                end
            end

            -- 8. 顶部实时战术状态小字 (护盾倒计时、固守、掌控动摇、内陆休眠)
            if ui.statusText and ui.statusText.alive then
                pcall(function()
                    ui.statusText.anchoredPositionY = hasAnomaly and 50 or 34
                end)

                if node.protectedUntil and node.protectedUntil > elapsedTime then
                    local remain = math.max(0.1, node.protectedUntil - elapsedTime)
                    ui.statusText.text = string.format("❖ 庇护 %.1fs", remain)
                    ui.statusText.fontColor = Layout.PALETTE.ANEMO
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction == "neutral" and (node.control or 0) > 0 and node.contenderFaction then
                    local fName = Layout.GetFactionName(node.contenderFaction)
                    local col = Layout.GetFactionColor(node.contenderFaction)
                    ui.statusText.text = string.format("[%s掌控 %d%%]", fName, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction ~= "neutral" and (node.control or 100) < 100 then
                    local fName = Layout.GetFactionName(node.faction)
                    local col = Layout.GetFactionColor(node.faction)
                    ui.statusText.text = string.format("[%s动摇 %d%%]", fName, math.floor(node.control or 100))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isIdle then
                    ui.statusText.text = "◈ 腹地休眠"
                    ui.statusText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isDefensive and node.routeTo == nil and node.faction ~= "neutral" then
                    ui.statusText.text = "✦ 固守结界"
                    ui.statusText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.statusText, true)
                elseif node.routeTo ~= nil then
                    ui.statusText.text = "➔ 输送中"
                    ui.statusText.fontColor = factionColor
                    Layout.SetVisible(ui.statusText, true)
                else
                    Layout.SetVisible(ui.statusText, false)
                end
            end
        end
    end
end

-- 关卡拓扑几何重布局 (按当前章节的节点坐标与连线刷新沙盘)
function VisualRenderer.ApplyStageLayout(nodeUIList, nodes, staticLinkCtrls, links)
    for i, ui in ipairs(nodeUIList) do
        local node = nodes[i]
        if node and ui.group and ui.group.alive then
            ui.group.anchoredPositionX = node.x
            ui.group.anchoredPositionY = node.y
            Layout.SetVisible(ui.group, true)
        elseif ui.group and ui.group.alive then
            Layout.SetVisible(ui.group, false)
        end
    end

    if staticLinkCtrls and links then
        for i, linkCtrl in ipairs(staticLinkCtrls) do
            local link = links[i]
            if link and linkCtrl and linkCtrl.alive then
                local nA = StarMap.GetNode(nodes, link[1])
                local nB = StarMap.GetNode(nodes, link[2])
                if nA and nB then
                    VisualRenderer.SetLineTransform(linkCtrl, nA.x, nA.y, nB.x, nB.y, 2, Layout.PALETTE.LINK_INACTIVE)
                else
                    Layout.SetVisible(linkCtrl, false)
                end
            elseif linkCtrl and linkCtrl.alive then
                Layout.SetVisible(linkCtrl, false)
            end
        end
    end
end

-- 彻底清除并隐藏所有光轨连线与导引线
function VisualRenderer.HideAllRoutes(routeCtrls, dragLineCtrl)
    if routeCtrls then
        for _, ctrl in ipairs(routeCtrls) do
            if ctrl and ctrl.alive then
                Layout.SetVisible(ctrl, false)
            end
        end
    end
    if dragLineCtrl and dragLineCtrl.alive then
        Layout.SetVisible(dragLineCtrl, false)
    end
end

return VisualRenderer

end
_MODULES["ui/visualRenderer"] = _MODULES["src/ui/visualRenderer"]

_MODULES["src/ui/dialoguePlayer"] = function()
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
            content = "盘面上每一个光点都象征着一处地脉灵穴，而流动的光尘则是纯净元素微粒。\n拖拽己方灵穴铺设光轨，轻点灵穴即可收拢固守。"
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

end
_MODULES["ui/dialoguePlayer"] = _MODULES["src/ui/dialoguePlayer"]

_MODULES["src/ui/prepareView"] = function()
-- src/ui/prepareView.lua
-- 战前符印调配界面（12点权能预算、自选卡组装配、视觉差分效果与确认开启）

local CardRegistry = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local PrepareView = {
    selectedIds = { "anemo_shield", "pyro_erosion" }, -- 初始预选低耗核心
    maxBudget = 12,
    maxCards = 4,
    onStartMatch = nil,
    lastWarning = nil,
    warningTimer = 0,

    -- 战术符印按权能消耗升序排列 (2点 -> 2点 -> 3点 -> 4点 -> 4点 -> 5点)
    POOL_ORDER = {
        "anemo_shield",  -- 2点
        "pyro_erosion",  -- 2点
        "anemo_turb",    -- 3点
        "pyro_blast",    -- 4点
        "geo_wall",      -- 4点
        "hydro_bribe"    -- 5点
    }
}

function PrepareView.Init(budgetOrCb, onStartMatchCallback)
    local budget = 12
    local cb = nil
    if type(budgetOrCb) == "number" then
        budget = budgetOrCb
        cb = onStartMatchCallback
    else
        cb = budgetOrCb
        budget = BalanceConfig.MAX_BUDGET or 12
    end
    PrepareView.maxBudget = budget
    PrepareView.maxCards = 4
    PrepareView.lastWarning = nil
    PrepareView.warningTimer = 0
    if cb then
        PrepareView.onStartMatch = cb
    end

    if not PrepareView.selectedIds or #PrepareView.selectedIds == 0 then
        PrepareView.selectedIds = { "anemo_shield" }
    end

    -- 自动校验修剪超限符印
    while #PrepareView.selectedIds > 0 and PrepareView.GetUsedBudget() > PrepareView.maxBudget do
        table.remove(PrepareView.selectedIds)
    end
    if #PrepareView.selectedIds == 0 then
        for _, cKey in ipairs(PrepareView.POOL_ORDER) do
            local c = CardRegistry.GetCardById(cKey)
            if c and c.cost <= PrepareView.maxBudget then
                table.insert(PrepareView.selectedIds, cKey)
                break
            end
        end
    end

    -- 确保装配卡片默认按消耗权能升序排列
    table.sort(PrepareView.selectedIds, function(a, b)
        local cA = CardRegistry.GetCardById(a)
        local cB = CardRegistry.GetCardById(b)
        if cA and cB and cA.cost ~= cB.cost then
            return cA.cost < cB.cost
        end
        return false
    end)
end

function PrepareView.Update(dt)
    if PrepareView.warningTimer and PrepareView.warningTimer > 0 then
        PrepareView.warningTimer = PrepareView.warningTimer - dt
        if PrepareView.warningTimer <= 0 then
            PrepareView.lastWarning = nil
        end
    end
end

function PrepareView.GetUsedBudget()
    local sum = 0
    for _, id in ipairs(PrepareView.selectedIds) do
        local card = CardRegistry.GetCardById(id)
        if card then sum = sum + card.cost end
    end
    return sum
end

function PrepareView.IsCardSelected(cardId)
    for _, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then return true end
    end
    return false
end

function PrepareView.ToggleCard(cardId)
    -- 若已选，则反选移除
    for idx, id in ipairs(PrepareView.selectedIds) do
        if id == cardId then
            table.remove(PrepareView.selectedIds, idx)
            PrepareView.lastWarning = nil
            PrepareView.warningTimer = 0
            return true, "unequipped", cardId
        end
    end

    -- 尝试添加装配
    if #PrepareView.selectedIds >= PrepareView.maxCards then
        local warnMsg = string.format("符印槽位已满！最多仅能装配 %d 张符印", PrepareView.maxCards)
        PrepareView.lastWarning = warnMsg
        PrepareView.warningTimer = 3.0
        return false, string.format("最多仅能装配 %d 张战术符印！请先点击卸下已选符印。", PrepareView.maxCards)
    end

    local card = CardRegistry.GetCardById(cardId)
    if not card then return false, "未知符印类型！" end

    local currentUsed = PrepareView.GetUsedBudget()
    if (currentUsed + card.cost) > PrepareView.maxBudget then
        local warnMsg = string.format("权能预算不足！超限 %d 点（已用 %d/%d，该符印需 %d 点）", (currentUsed + card.cost) - PrepareView.maxBudget, currentUsed, PrepareView.maxBudget, card.cost)
        PrepareView.lastWarning = warnMsg
        PrepareView.warningTimer = 3.0
        return false, string.format("【预算不足】当前已用 %d 点，该符印需 %d 点（上限 %d 点）！", currentUsed, card.cost, PrepareView.maxBudget)
    end

    PrepareView.lastWarning = nil
    PrepareView.warningTimer = 0
    table.insert(PrepareView.selectedIds, cardId)

    -- 保持装配卡牌按权能消耗升序排列
    table.sort(PrepareView.selectedIds, function(a, b)
        local cA = CardRegistry.GetCardById(a)
        local cB = CardRegistry.GetCardById(b)
        if cA and cB and cA.cost ~= cB.cost then
            return cA.cost < cB.cost
        end
        return false
    end)

    return true, "equipped", cardId
end

-- 刷新调配界面差分视觉表现（边框高亮、背景深浅、角标切换与预算提示）
function PrepareView.Render(cardUIList, budgetTextCtrl, hintTextCtrl)
    if cardUIList then
        for idx, cardKey in ipairs(PrepareView.POOL_ORDER) do
            local ui = cardUIList[idx]
            local card = CardRegistry.GetCardById(cardKey)
            if ui and card then
                local isSel = PrepareView.IsCardSelected(cardKey)

                -- 1. 边框高光差分
                if ui.borderCtrl and ui.borderCtrl.alive then
                    ui.borderCtrl.imageColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(71, 85, 105, 255)
                end

                -- 2. 背景明暗差分
                if ui.bgCtrl and ui.bgCtrl.alive then
                    ui.bgCtrl.imageColor = isSel and Layout.MakeColor(30, 58, 95, 255) or Layout.MakeColor(15, 23, 42, 255)
                end

                -- 3. 名称文本差分 (选中附带醒目 [✓] 标识)
                if ui.nameCtrl and ui.nameCtrl.alive then
                    ui.nameCtrl.text = isSel and ("[✓] " .. card.name) or card.name
                    ui.nameCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.PALETTE.TEXT_MUTED
                end

                -- 4. 选中状态角标
                if ui.checkCtrl and ui.checkCtrl.alive then
                    ui.checkCtrl.text = isSel and "【★ 已装配】" or "【点击装配】"
                    ui.checkCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(100, 116, 139, 255)
                end

                -- 5. 消耗与 CD 明确标注 (要求2: 符印CD写在配置界面)
                if ui.costCtrl and ui.costCtrl.alive then
                    ui.costCtrl.text = string.format("消耗: %d 权能  |  CD: %d秒", card.cost, card.cd)
                    ui.costCtrl.fontColor = isSel and Layout.PALETTE.GOLD or Layout.MakeColor(251, 191, 36, 255)
                end

                -- 6. 描述文本
                if ui.descCtrl and ui.descCtrl.alive then
                    ui.descCtrl.text = card.desc
                end
            end
        end
    end

    local used = PrepareView.GetUsedBudget()
    local count = #PrepareView.selectedIds
    local isWarning = (PrepareView.warningTimer and PrepareView.warningTimer > 0 and PrepareView.lastWarning ~= nil)

    -- 5. 预算文字更新 (若预算超限，文字变红高亮警示)
    if budgetTextCtrl and budgetTextCtrl.alive then
        budgetTextCtrl.text = string.format("当前调配权能预算：%d / %d 点 （已装配 %d / %d 张）", used, PrepareView.maxBudget, count, PrepareView.maxCards)
        if isWarning then
            budgetTextCtrl.fontColor = Layout.MakeColor(244, 63, 94, 255) -- 警示玫瑰红
        else
            budgetTextCtrl.fontColor = Layout.MakeColor(56, 189, 248, 255) -- 正常青蓝
        end
    end

    -- 6. 卡组概要/超限告警更新 (要求3: 界面内显眼大字提示预算不足)
    if hintTextCtrl and hintTextCtrl.alive then
        if isWarning then
            hintTextCtrl.text = "⚠️ " .. PrepareView.lastWarning
            hintTextCtrl.fontColor = Layout.MakeColor(244, 63, 94, 255) -- 醒目赤红预警
        elseif count > 0 then
            local names = {}
            for _, id in ipairs(PrepareView.selectedIds) do
                local c = CardRegistry.GetCardById(id)
                if c then
                    table.insert(names, string.format("%s(%d点·CD%ds)", c.name, c.cost, c.cd))
                end
            end
            hintTextCtrl.text = "已选符印：" .. table.concat(names, " + ")
            hintTextCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
        else
            hintTextCtrl.text = "尚未装配任何符印，请点击上方卡牌进行调配！"
            hintTextCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
        end
    end
end

function PrepareView.ConfirmAndStart()
    if #PrepareView.selectedIds == 0 then
        return false, "请至少装配 1 张战术符印后再启阵出征！"
    end
    if PrepareView.onStartMatch then
        PrepareView.onStartMatch(PrepareView.selectedIds)
    end
    return true
end

return PrepareView

end
_MODULES["ui/prepareView"] = _MODULES["src/ui/prepareView"]

_MODULES["src/ui/hudView"] = function()
-- src/ui/hudView.lua
-- HUD 顶部掌控进度、倒计时、提瓦特敕令风 Toast 浮窗与终局结算面板

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local HudView = {
    toastText = "",
    toastTimer = 0,
    toastDuration = 2.4,
    toastRGB = { r = 251, g = 191, b = 36 },
    isSettled = false,
    isStyleInitialized = false,
    onRetry = nil
}

function HudView.Init(onRetryCallback)
    HudView.toastText = ""
    HudView.toastTimer = 0
    HudView.toastDuration = 2.4
    HudView.toastRGB = { r = 251, g = 191, b = 36 }
    HudView.isSettled = false
    HudView.isStyleInitialized = false
    HudView.onRetry = onRetryCallback
end

-- 根据提示文本内容自动推断视觉语义与提瓦特配色
local function ResolveToastStyle(msg, explicitType)
    local t = explicitType
    if not t then
        if string.find(msg, "不足") or string.find(msg, "无法") or string.find(msg, "冷却") or string.find(msg, "警告") or string.find(msg, "失守") or string.find(msg, "未连通") then
            t = "warn"
        elseif string.find(msg, "符印") or string.find(msg, "施加") or string.find(msg, "激活") or string.find(msg, "守护") then
            t = "spell"
        else
            t = "info"
        end
    end

    if t == "warn" then
        return "❖ ──  " .. msg .. "  ── ❖", { r = 244, g = 63, b = 94 }   -- 绯红警示
    elseif t == "spell" then
        return "✦ ──  " .. msg .. "  ── ✦", { r = 52, g = 211, b = 153 }  -- 千风翠碧敕令
    else
        return "✦ ──  " .. msg .. "  ── ✦", { r = 251, g = 191, b = 36 }  -- 曜金星轨播报
    end
end

function HudView.ShowToast(msg, toastType)
    local rawMsg = msg or ""
    local styledText, rgb = ResolveToastStyle(rawMsg, toastType)
    HudView.toastText = styledText
    HudView.toastRGB = rgb
    HudView.toastDuration = 2.4
    HudView.toastTimer = HudView.toastDuration
end

function HudView.UpdateToast(dt, toastContainer, toastTextCtrl)
    if HudView.toastTimer > 0 then
        HudView.toastTimer = HudView.toastTimer - dt
        Layout.SetVisible(toastContainer, true)

        -- 计算弹出回弹缩放 (Pop-in) 与尾部淡出 (Fade-out)
        local elapsed = HudView.toastDuration - HudView.toastTimer
        local scale = 1.0
        if elapsed < 0.18 then
            -- 0 ~ 0.18s: 从 0.84 快速弹至 1.05
            scale = Layout.Lerp(0.84, 1.05, elapsed / 0.18)
        elseif elapsed < 0.30 then
            -- 0.18 ~ 0.30s: 从 1.05 回落至 1.0
            scale = Layout.Lerp(1.05, 1.0, (elapsed - 0.18) / 0.12)
        end

        local alpha = 255
        if HudView.toastTimer < 0.45 then
            alpha = math.floor(Layout.Clamp(HudView.toastTimer / 0.45, 0, 1) * 255)
        end

        if toastContainer and toastContainer.alive then
            pcall(function()
                toastContainer.localScaleX = scale
                toastContainer.localScaleY = scale
            end)
        end

        if toastTextCtrl and toastTextCtrl.alive then
            Layout.ApplyTextStyle(toastTextCtrl, 18, nil, Layout.PALETTE.BG_DARK)
            toastTextCtrl.text = HudView.toastText
            local c = HudView.toastRGB
            toastTextCtrl.fontColor = Layout.MakeColor(c.r, c.g, c.b, alpha)
        end
    else
        Layout.SetVisible(toastContainer, false)
    end
end

-- 更新顶部掌控条与计时
function HudView.UpdateTopBar(timeRemaining, nodes, playerPctCtrl, enemyPctCtrl, timerCtrl, barPlayerCtrl, barEnemyCtrl)
    if not HudView.isStyleInitialized then
        HudView.isStyleInitialized = true
        Layout.ApplyTextStyle(playerPctCtrl, 15, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
        Layout.ApplyTextStyle(enemyPctCtrl, 15, Layout.PALETTE.ENEMY, Layout.PALETTE.BG_DARK)
        Layout.ApplyTextStyle(timerCtrl, 20, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
    end

    local pNodes, eNodes = 0, 0
    local pParticles, eParticles = 0, 0

    for _, n in ipairs(nodes) do
        if n.faction == "player" then
            pNodes = pNodes + 1
            pParticles = pParticles + n.particles
        elseif n.faction ~= "neutral" then
            eNodes = eNodes + 1
            eParticles = eParticles + n.particles
        end
    end

    local pScore = pNodes * 100 + pParticles
    local eScore = eNodes * 100 + eParticles
    local total = pScore + eScore
    if total <= 0 then total = 1 end

    local pPct = math.floor(pScore / total * 100)
    local ePct = 100 - pPct

    if playerPctCtrl and playerPctCtrl.alive then
        playerPctCtrl.text = string.format("✦ 我方星轨 %d%% (%d穴)", pPct, pNodes)
    end
    if enemyPctCtrl and enemyPctCtrl.alive then
        enemyPctCtrl.text = string.format("敌方侵蚀 %d%% (%d穴) ❖", ePct, eNodes)
    end

    if barPlayerCtrl and barPlayerCtrl.alive then
        local targetW = math.max(10, math.floor(320 * (pPct / 100)))
        barPlayerCtrl.sizeDeltaX = math.floor(Layout.Lerp(barPlayerCtrl.sizeDeltaX or targetW, targetW, 0.2))
    end
    if barEnemyCtrl and barEnemyCtrl.alive then
        local targetW = math.max(10, math.floor(320 * (ePct / 100)))
        barEnemyCtrl.sizeDeltaX = math.floor(Layout.Lerp(barEnemyCtrl.sizeDeltaX or targetW, targetW, 0.2))
    end

    if timerCtrl and timerCtrl.alive then
        local t = math.max(0, math.floor(timeRemaining))
        local m = math.floor(t / 60)
        local s = t % 60
        timerCtrl.text = string.format("%02d : %02d", m, s)
        -- 剩余不足 30 秒时切换为曜金/猩红闪烁警示
        if t <= 30 then
            local blink = (math.floor(timeRemaining * 4) % 2 == 0)
            timerCtrl.fontColor = blink and Layout.PALETTE.ENEMY or Layout.PALETTE.GOLD
        else
            timerCtrl.fontColor = Layout.PALETTE.TEXT_LIGHT
        end
    end
end

-- 显示终局结算
function HudView.ShowSettlement(isWin, nodes, elapsedTime, modalCtrl, titleCtrl, descCtrl, statsCtrl, nextBtnCtrl)
    HudView.isSettled = true
    Layout.SetVisible(modalCtrl, true)

    if nextBtnCtrl and nextBtnCtrl.alive then
        Layout.SetVisible(nextBtnCtrl, isWin)
    end

    local pCount = 0
    local pParts = 0
    for _, n in ipairs(nodes) do
        if n.faction == "player" then
            pCount = pCount + 1
            pParts = pParts + n.particles
        end
    end

    local t = math.floor(elapsedTime)
    local timeStr = string.format("%02d:%02d", math.floor(t / 60), t % 60)

    if titleCtrl and titleCtrl.alive then
        Layout.ApplyTextStyle(titleCtrl, 24, nil, Layout.PALETTE.BG_DARK)
        if isWin then
            titleCtrl.text = "✦ ──  地 脉 推 衍 · 大 捷  ── ✦"
            titleCtrl.fontColor = Layout.PALETTE.GOLD
        else
            titleCtrl.text = "❖ ──  星 轨 崩 碎 · 惜 败  ── ❖"
            titleCtrl.fontColor = Layout.PALETTE.ENEMY
        end
    end

    if descCtrl and descCtrl.alive then
        Layout.ApplyTextStyle(descCtrl, 15, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
        if isWin then
            descCtrl.text = "星盘之理尽在掌控，地脉灵流归于统御。全域敌对据点已被彻底肃清！"
        else
            descCtrl.text = "地脉紊乱，推衍消散。我方地脉源枢失守，不妨重新调配战术符印后再战。"
        end
    end

    if statsCtrl and statsCtrl.alive then
        Layout.ApplyTextStyle(statsCtrl, 14, Layout.PALETTE.AMBER, Layout.PALETTE.BG_DARK)
        statsCtrl.text = string.format("占领灵穴：%d/%d  |  存活兵力：%d  |  耗时：%s", pCount, #nodes, pParts, timeStr)
    end
end

-- 关卡特殊灵穴效果说明映射表与重要度排序
local ANOMALY_DESC_MAP = {
    PLASMA          = "【赤阳熔核】上限强制限25粒，极速绞肉战场",
    DEFENSE_BASTION = "【雷暴要塞】雷暴灵障固守，战损减半",
    PURE_WATER      = "【纯水枢纽】纯水核心与微粒快速回流 (+54%)",
    WIND_FLOW       = "【疾风流道】地脉输送流速翻倍 (双倍极速)",
    AMBER_MINE      = "【石珀晶矿】灵穴能量产出速率翻倍 (+100%)",
    MIST_RUINS      = "【迷雾荒墟】据点驻防加成，微粒孕育减半"
}

local ANOMALY_PRIORITY = {
    PLASMA          = 1,
    DEFENSE_BASTION = 2,
    PURE_WATER      = 3,
    WIND_FLOW       = 4,
    AMBER_MINE      = 5,
    MIST_RUINS      = 6
}

-- 更新左上角关卡特殊灵穴说明与右上角战术操作说明 (支持去重与 ×N 统计数量)
function HudView.UpdateStageInfo(chap, anomalyTitleCtrl, anomalyDescCtrl, guideTitleCtrl, guideDescCtrl)
    if guideTitleCtrl and guideTitleCtrl.alive then
        Layout.ApplyTextStyle(guideTitleCtrl, 14, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
        guideTitleCtrl.text = "✦ 【战术操作指引】"
    end
    if guideDescCtrl and guideDescCtrl.alive then
        Layout.ApplyTextStyle(guideDescCtrl, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)
        guideDescCtrl.text = "● 连线：拖拽己方灵穴至相邻据点建立输送\n● 固守：轻点己方灵穴展开/收拢固守结界\n● 符印：点击下方符印后点击目标灵穴释放"
    end

    if anomalyTitleCtrl and anomalyTitleCtrl.alive then
        Layout.ApplyTextStyle(anomalyTitleCtrl, 14, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
        local stageTag = "战场"
        if chap and chap.title then
            local m = string.match(chap.title, "第 %d+ 关")
            if m then
                stageTag = m
            elseif chap.id then
                stageTag = string.format("第 %d 关", chap.id)
            end
        elseif chap and chap.id then
            stageTag = string.format("第 %d 关", chap.id)
        end
        anomalyTitleCtrl.text = string.format("✦ 【%s · 地脉情报】", stageTag)
    end

    if anomalyDescCtrl and anomalyDescCtrl.alive then
        Layout.ApplyTextStyle(anomalyDescCtrl, 12, Layout.PALETTE.TEXT_LIGHT, Layout.PALETTE.BG_DARK)

        -- 对战场异象进行去重与数量统计，避免同类型异象刷屏
        local counts = {}
        if chap and chap.nodes then
            for _, n in ipairs(chap.nodes) do
                if n.anomaly and n.anomaly ~= "NORMAL" and ANOMALY_DESC_MAP[n.anomaly] then
                    counts[n.anomaly] = (counts[n.anomaly] or 0) + 1
                end
            end
        end

        local anomalyKeys = {}
        for k, _ in pairs(counts) do
            table.insert(anomalyKeys, k)
        end
        table.sort(anomalyKeys, function(a, b)
            return (ANOMALY_PRIORITY[a] or 99) < (ANOMALY_PRIORITY[b] or 99)
        end)

        local lines = {}
        for _, k in ipairs(anomalyKeys) do
            local desc = ANOMALY_DESC_MAP[k]
            local cnt = counts[k]
            if desc and cnt then
                local suffix = (cnt > 1) and string.format(" ×%d", cnt) or ""
                table.insert(lines, "  ◆ " .. desc .. suffix)
            end
        end

        if #lines == 0 then
            anomalyDescCtrl.text = "● 标准地脉：常规孕育与输送，前线激战\n● 固守结界：驻防灵穴战损削减30%"
        else
            anomalyDescCtrl.text = table.concat(lines, "\n")
        end
    end
end

-- 战前 3 秒倒计时更新 (3、2、1、开始)
function HudView.UpdateCountdown(timer, countdownModal, countdownTextCtrl, countdownSubCtrl)
    if not countdownModal or not countdownModal.alive then return end

    if timer > 0 then
        Layout.SetVisible(countdownModal, true)
        local countNum = math.ceil(timer)
        if countNum > 3 then countNum = 3 end
        if countNum < 1 then countNum = 1 end

        if countdownTextCtrl and countdownTextCtrl.alive then
            Layout.ApplyTextStyle(countdownTextCtrl, 52, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            countdownTextCtrl.text = tostring(countNum)
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            Layout.ApplyTextStyle(countdownSubCtrl, 18, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
            if countNum == 3 then
                countdownSubCtrl.text = "【3 秒】全域地脉连接调配完成..."
            elseif countNum == 2 then
                countdownSubCtrl.text = "【2 秒】星轨推衍回路展开中..."
            else
                countdownSubCtrl.text = "【1 秒】元素微粒正在凝聚！"
            end
        end
    elseif timer > -0.6 then
        Layout.SetVisible(countdownModal, true)
        if countdownTextCtrl and countdownTextCtrl.alive then
            Layout.ApplyTextStyle(countdownTextCtrl, 44, Layout.PALETTE.PLAYER, Layout.PALETTE.BG_DARK)
            countdownTextCtrl.text = "开 始 ！"
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            Layout.ApplyTextStyle(countdownSubCtrl, 18, Layout.PALETTE.GOLD, Layout.PALETTE.BG_DARK)
            countdownSubCtrl.text = "【开战】执掌星轨，克敌制胜！"
        end
    else
        Layout.SetVisible(countdownModal, false)
    end
end

return HudView

end
_MODULES["ui/hudView"] = _MODULES["src/ui/hudView"]

_MODULES["src/ui/cardBar"] = function()
-- src/ui/cardBar.lua
-- 底部战术符印栏渲染（卡牌名称、权能能耗、冷却遮罩与选中态）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local CardBar = {}

function CardBar.Update(cardSlots, deck, cooldowns, selectedSlotIndex)
    for i = 1, 4 do
        local slot = cardSlots[i]
        local card = deck[i]
        local cd = cooldowns[i] or 0

        if slot and slot.container and slot.container.alive then
            if card then
                Layout.SetVisible(slot.container, true)

                if slot.nameCtrl and slot.nameCtrl.alive then
                    if selectedSlotIndex == i then
                        slot.nameCtrl.text = "★ " .. card.name
                        slot.nameCtrl.fontColor = Layout.PALETTE.GOLD
                    else
                        slot.nameCtrl.text = card.name
                        slot.nameCtrl.fontColor = Layout.PALETTE.TEXT_LIGHT
                    end
                end

                if slot.costCtrl and slot.costCtrl.alive then
                    slot.costCtrl.text = string.format("%d点 · CD %ds", card.cost, card.cd)
                    slot.costCtrl.fontColor = (selectedSlotIndex == i) and Layout.PALETTE.GOLD or Layout.MakeColor(251, 191, 36, 255)
                end

                if slot.borderCtrl and slot.borderCtrl.alive then
                    if selectedSlotIndex == i then
                        slot.borderCtrl.imageColor = Layout.PALETTE.GOLD
                    else
                        slot.borderCtrl.imageColor = card.badgeColor or Layout.PALETTE.TEXT_MUTED
                    end
                end

                -- 选定符印进入施法等待态：卡槽微抬升与高亮，提示玩家选取目标灵穴
                if slot.container.anchoredPositionY ~= nil then
                    local targetY = (selectedSlotIndex == i) and 14 or 0
                    slot.container.anchoredPositionY = targetY
                end

                -- 冷却遮罩
                if cd > 0 then
                    Layout.SetVisible(slot.maskCtrl, true)
                    if slot.cdTextCtrl and slot.cdTextCtrl.alive then
                        Layout.SetVisible(slot.cdTextCtrl, true)
                        slot.cdTextCtrl.text = string.format("%ds", math.ceil(cd))
                    end
                else
                    Layout.SetVisible(slot.maskCtrl, false)
                    Layout.SetVisible(slot.cdTextCtrl, false)
                end
            else
                Layout.SetVisible(slot.container, false)
            end
        end
    end
end

return CardBar

end
_MODULES["ui/cardBar"] = _MODULES["src/ui/cardBar"]

_MODULES["src/ui/modeSelectView"] = function()
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

end
_MODULES["ui/modeSelectView"] = _MODULES["src/ui/modeSelectView"]

_MODULES["src/ui/chapterSelectView"] = function()
-- src/ui/chapterSelectView.lua
-- 战役章节选择面板（5 大关卡展示、解锁进度判定、选关差分表现与出征确认）

local ChapterConfig = require("default_import_file/src/data/chapterConfig") or require("src/data/chapterConfig")
local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")
local BalanceConfig = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")

local ChapterSelectView = {
    unlockedStage = 1,
    selectedStage = 1,
    clearedStages = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false
    },
    onStartStage = nil,
    onBack = nil
}

function ChapterSelectView.Init(onStartStageCb, onBackCb)
    ChapterSelectView.onStartStage = onStartStageCb
    ChapterSelectView.onBack = onBackCb
end

function ChapterSelectView.UnlockNextStage(completedStage)
    if completedStage then
        ChapterSelectView.clearedStages[completedStage] = true
        if completedStage >= ChapterSelectView.unlockedStage then
            ChapterSelectView.unlockedStage = math.min(5, completedStage + 1)
        end
    end
end

-- 判定是否已完成剧情模式前4关
function ChapterSelectView.HasCompletedFirst4Stages()
    if (ChapterSelectView.unlockedStage or 1) >= 5 then
        return true
    end
    local cleared = ChapterSelectView.clearedStages
    if cleared and cleared[1] and cleared[2] and cleared[3] and cleared[4] then
        return true
    end
    return false
end

-- 获取已通关章节总数
function ChapterSelectView.GetClearedCount()
    local cnt = 0
    for i = 1, 5 do
        if ChapterSelectView.clearedStages and ChapterSelectView.clearedStages[i] then
            cnt = cnt + 1
        end
    end
    return cnt
end

function ChapterSelectView.SelectStage(stageId)
    if stageId > ChapterSelectView.unlockedStage then
        return false, "该关卡尚未解锁，请先通关前序章节！"
    end
    ChapterSelectView.selectedStage = stageId
    return true
end

-- 渲染章节卡片与信息展示
function ChapterSelectView.Render(chapterCards, descTextCtrl, startBtnTxtCtrl)
    local selectedChap = ChapterConfig.GetChapter(ChapterSelectView.selectedStage)

    if chapterCards then
        for i = 1, 5 do
            local cardUI = chapterCards[i]
            local chap = ChapterConfig.GetChapter(i)
            if cardUI and chap then
                local isUnlocked = (i <= ChapterSelectView.unlockedStage)
                local isSelected = (i == ChapterSelectView.selectedStage)

                -- 1. 边框发光
                if cardUI.borderCtrl and cardUI.borderCtrl.alive then
                    if isSelected then
                        cardUI.borderCtrl.imageColor = Layout.PALETTE.GOLD
                    elseif isUnlocked then
                        cardUI.borderCtrl.imageColor = Layout.PALETTE.PLAYER
                    else
                        cardUI.borderCtrl.imageColor = Layout.MakeColor(51, 65, 85, 255)
                    end
                end

                -- 2. 背景明暗
                if cardUI.bgCtrl and cardUI.bgCtrl.alive then
                    if isSelected then
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(30, 58, 95, 255)
                    elseif isUnlocked then
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(15, 23, 42, 255)
                    else
                        cardUI.bgCtrl.imageColor = Layout.MakeColor(10, 15, 26, 255)
                    end
                end

                -- 3. 标题
                if cardUI.titleCtrl and cardUI.titleCtrl.alive then
                    cardUI.titleCtrl.text = chap.title
                    cardUI.titleCtrl.fontColor = isSelected and Layout.PALETTE.GOLD or (isUnlocked and Layout.PALETTE.TEXT_LIGHT or Layout.PALETTE.TEXT_MUTED)
                end

                -- 4. 概要 (灵穴数 / 阵营数 / 权能)
                if cardUI.infoCtrl and cardUI.infoCtrl.alive then
                    local fCount = #chap.factions
                    local nCount = #chap.nodes
                    cardUI.infoCtrl.text = string.format("%d方混战 | %d灵穴 | %d权能", fCount, nCount, chap.budget)
                    cardUI.infoCtrl.fontColor = isUnlocked and Layout.PALETTE.AMBER or Layout.PALETTE.TEXT_MUTED
                end

                -- 5. 状态角标
                if cardUI.tagCtrl and cardUI.tagCtrl.alive then
                    if isSelected then
                        cardUI.tagCtrl.text = "【★ 当前选择】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.GOLD
                    elseif isUnlocked then
                        cardUI.tagCtrl.text = "【已解锁】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.PLAYER
                    else
                        cardUI.tagCtrl.text = "【锁定中】"
                        cardUI.tagCtrl.fontColor = Layout.PALETTE.TEXT_MUTED
                    end
                end
            end
        end
    end

    -- 6. 描述文本
    if descTextCtrl and descTextCtrl.alive and selectedChap then
        descTextCtrl.text = string.format("【%s】\n%s\n%s", selectedChap.title, selectedChap.subtitle, selectedChap.desc)
    end

    -- 7. 出征按钮文本
    if startBtnTxtCtrl and startBtnTxtCtrl.alive and selectedChap then
        startBtnTxtCtrl.text = string.format("【启程出征 · 第 %d 关】", selectedChap.id)
    end
end

return ChapterSelectView

end
_MODULES["ui/chapterSelectView"] = _MODULES["src/ui/chapterSelectView"]

_MODULES["src/ui/uiBinder"] = function()
-- src/ui/uiBinder.lua
-- 控件树深度检索、各层图元容器集中缓存与生命周期辅助管理

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local UIBinder = {}

-- 深度递归查找指定名称的子控件
function UIBinder.FindDeepChild(parent, name)
    if not parent or not parent.alive then return nil end
    local direct = parent:FindChild(name)
    if direct then return direct end
    local children = parent:GetChildren()
    if children then
        for _, child in ipairs(children) do
            local found = UIBinder.FindDeepChild(child, name)
            if found then return found end
        end
    end
    return nil
end

-- 辅助：静音原生按钮 clickAudioId，避免引擎底层默认点击音效与脚本 PlayAudioSafe 重叠双响
function UIBinder.SilenceButton(btn)
    if btn and btn.alive then
        pcall(function() btn.clickAudioId = 0 end)
    end
end

-- 集中缓存全量 UI 控件树结构
function UIBinder.BindControls(script, game)
    local root = nil
    if script and script.GetParam then
        local pId = script:GetParam("RootCanvasID")
        if pId and type(pId) == "number" and game and game.GetClientUIControl then
            root = game.GetClientUIControl(pId)
        end
    end
    if not root and script and script.object then
        root = script.object
    end
    if not root and game and game.FindClientUIRoot then
        root = game.FindClientUIRoot("StarlinkCanvas") or game.FindClientUIRoot("GameRoot")
    end
    if not root and game and game.GetClientUIRoots then
        local roots = game.GetClientUIRoots()
        if roots and #roots > 0 then root = roots[1] end
    end

    local UI = {
        root = root
    }

    -- 1. 全局输入检测层与拖拽导引线
    UI.cursorArea = UIBinder.FindDeepChild(root, "GlobalCursorArea")
    UI.dragLine   = UIBinder.FindDeepChild(root, "DragLine")

    -- 2. 模式选择弹窗
    UI.modeSelectModal = UIBinder.FindDeepChild(root, "ModeSelectModal")
    if UI.modeSelectModal then
        UI.modeStoryBtn     = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeStoryBtn")
        UI.modeChallengeBtn = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeChallengeBtn")
        UI.modeQuitBtn      = UIBinder.FindDeepChild(UI.modeSelectModal, "ModeQuitBtn")
    end

    -- 3. 关卡章节选择弹窗
    UI.chapterSelectModal = UIBinder.FindDeepChild(root, "ChapterSelectModal")
    UI.chapterCards = {}
    if UI.chapterSelectModal then
        UI.chapDesc     = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterDesc")
        UI.chapTitle    = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterTitle")
        UI.chapStartBtn = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterStartBtn")
        if UI.chapStartBtn then
            UI.chapStartTxt = UIBinder.FindDeepChild(UI.chapStartBtn, "Text")
        end
        UI.chapBackBtn  = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterBackBtn")

        for idx = 1, 5 do
            local cardBtn = UIBinder.FindDeepChild(UI.chapterSelectModal, "ChapterCard_" .. idx)
            if cardBtn then
                table.insert(UI.chapterCards, {
                    button     = cardBtn,
                    tagCtrl    = UIBinder.FindDeepChild(cardBtn, "TagText"),
                    infoCtrl   = UIBinder.FindDeepChild(cardBtn, "InfoText"),
                    budgetCtrl = UIBinder.FindDeepChild(cardBtn, "BudgetText"),
                    titleCtrl  = UIBinder.FindDeepChild(cardBtn, "TitleText"),
                    bgCtrl     = UIBinder.FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = UIBinder.FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 4. 光轨条带池与静态连线池 (20 条动态光轨 + 30 条静态底轨)
    UI.routeCtrls = {}
    UI.staticLinkCtrls = {}
    UI.linksLayer = UIBinder.FindDeepChild(root, "LinksLayer")
    if UI.linksLayer then
        for i = 1, 20 do
            local line = UIBinder.FindDeepChild(UI.linksLayer, "RouteLine_" .. i)
            if line then table.insert(UI.routeCtrls, line) end
        end
        for i = 0, 29 do
            local sLine = UIBinder.FindDeepChild(UI.linksLayer, "StaticLink_" .. i)
            if sLine then table.insert(UI.staticLinkCtrls, sLine) end
        end
    end

    -- 5. 微粒对象池 (120个全量池化)
    UI.particleCtrls = {}
    UI.particlesLayer = UIBinder.FindDeepChild(root, "ParticlesLayer")
    if UI.particlesLayer then
        for i = 1, 120 do
            local p = UIBinder.FindDeepChild(UI.particlesLayer, "P_" .. i)
            if p then table.insert(UI.particleCtrls, p) end
        end
    end

    -- 6. 22 座地脉灵穴 UI 组
    UI.nodeUIList = {}
    UI.nodesLayer = UIBinder.FindDeepChild(root, "NodesLayer")
    if UI.nodesLayer then
        for i = 0, 21 do
            local grp = UIBinder.FindDeepChild(UI.nodesLayer, "NodeGroup_" .. i)
            if grp then
                table.insert(UI.nodeUIList, {
                    group        = grp,
                    defenseRing  = UIBinder.FindDeepChild(grp, "DefenseRing"),
                    baseDisc     = UIBinder.FindDeepChild(grp, "BaseDisc"),
                    resonanceRing= UIBinder.FindDeepChild(grp, "ResonanceRing"),
                    titleText    = UIBinder.FindDeepChild(grp, "TitleText"),
                    particleText = UIBinder.FindDeepChild(grp, "ParticleText"),
                    anomalyText  = UIBinder.FindDeepChild(grp, "AnomalyText"),
                    statusText   = UIBinder.FindDeepChild(grp, "StatusText")
                })
            end
        end
    end

    -- 7. 顶部 HUD 与战术情报
    UI.hudLayer = UIBinder.FindDeepChild(root, "HudLayer")
    local hud = UI.hudLayer
    if hud then
        UI.playerPctText  = UIBinder.FindDeepChild(hud, "HudPlayerPct")
        UI.enemyPctText   = UIBinder.FindDeepChild(hud, "HudEnemyPct")
        UI.timerText      = UIBinder.FindDeepChild(hud, "HudTimer")
        UI.barPlayer      = UIBinder.FindDeepChild(hud, "BarPlayer")
        UI.barEnemy       = UIBinder.FindDeepChild(hud, "BarEnemy")
        UI.toastContainer = UIBinder.FindDeepChild(root, "ToastContainer")
        if UI.toastContainer then
            UI.toastText  = UIBinder.FindDeepChild(UI.toastContainer, "ToastText")
        end

        -- 战前3秒倒计时
        UI.countdownModal = UIBinder.FindDeepChild(root, "CountdownModal")
        if UI.countdownModal then
            UI.countdownText = UIBinder.FindDeepChild(UI.countdownModal, "CountdownText")
            UI.countdownSub  = UIBinder.FindDeepChild(UI.countdownModal, "CountdownSub")
        end

        -- 左上角地脉说明与右上角指引
        UI.hudAnomalyBox   = UIBinder.FindDeepChild(hud, "HudAnomalyBox")
        if UI.hudAnomalyBox then
            UI.hudAnomalyTitle = UIBinder.FindDeepChild(UI.hudAnomalyBox, "AnomalyTitle")
            UI.hudAnomalyDesc  = UIBinder.FindDeepChild(UI.hudAnomalyBox, "AnomalyDesc")
        end
        UI.hudGuideBox     = UIBinder.FindDeepChild(hud, "HudGuideBox")
        if UI.hudGuideBox then
            UI.hudGuideTitle   = UIBinder.FindDeepChild(UI.hudGuideBox, "GuideTitle")
            UI.hudGuideDesc    = UIBinder.FindDeepChild(UI.hudGuideBox, "GuideDesc")
        end

        UI.cardSlots = {}
        for j = 1, 4 do
            local slotGrp = UIBinder.FindDeepChild(hud, "CardSlot_" .. j)
            if slotGrp then
                table.insert(UI.cardSlots, {
                    container  = slotGrp,
                    borderCtrl = UIBinder.FindDeepChild(slotGrp, "Border"),
                    nameCtrl   = UIBinder.FindDeepChild(slotGrp, "NameText"),
                    costCtrl   = UIBinder.FindDeepChild(slotGrp, "CostText"),
                    maskCtrl   = UIBinder.FindDeepChild(slotGrp, "CdMask"),
                    cdTextCtrl = UIBinder.FindDeepChild(slotGrp, "CdText")
                })
            end
        end
    end

    -- 8. 剧情演播弹窗
    UI.dialogueModal = UIBinder.FindDeepChild(root, "DialogueModal")
    if UI.dialogueModal then
        UI.dlgSpeaker = UIBinder.FindDeepChild(UI.dialogueModal, "DlgSpeaker")
        UI.dlgContent = UIBinder.FindDeepChild(UI.dialogueModal, "DlgContent")
        UI.dlgSkipBtn = UIBinder.FindDeepChild(UI.dialogueModal, "DlgSkipBtn")
        UI.dlgNextBtn = UIBinder.FindDeepChild(UI.dialogueModal, "DlgNextBtn")
    end

    -- 9. 战前调配弹窗
    UI.prepareModal = UIBinder.FindDeepChild(root, "PrepareModal")
    UI.prepCards = {}
    if UI.prepareModal then
        UI.prepBudgetText = UIBinder.FindDeepChild(UI.prepareModal, "PrepBudgetText")
        UI.prepHint       = UIBinder.FindDeepChild(UI.prepareModal, "PrepHint")
        UI.prepTitle      = UIBinder.FindDeepChild(UI.prepareModal, "PrepTitle")
        UI.prepStartBtn   = UIBinder.FindDeepChild(UI.prepareModal, "PrepStartBtn")
        for k = 1, 6 do
            local cardBtn = UIBinder.FindDeepChild(UI.prepareModal, "PrepCard_" .. k)
            if cardBtn then
                table.insert(UI.prepCards, {
                    button     = cardBtn,
                    checkCtrl  = UIBinder.FindDeepChild(cardBtn, "CheckTag"),
                    costCtrl   = UIBinder.FindDeepChild(cardBtn, "CostText"),
                    descCtrl   = UIBinder.FindDeepChild(cardBtn, "DescText"),
                    nameCtrl   = UIBinder.FindDeepChild(cardBtn, "NameText"),
                    bgCtrl     = UIBinder.FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = UIBinder.FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 10. 常驻侧边导航栏 (除剧情演播外常驻于左上角)
    UI.quickNavLayer = UIBinder.FindDeepChild(root, "QuickNavLayer")
    if UI.quickNavLayer then
        UI.sideRestartBtn = UIBinder.FindDeepChild(UI.quickNavLayer, "SideRestartBtn")
        UI.sideSettleBtn  = UIBinder.FindDeepChild(UI.quickNavLayer, "SideSettleBtn")
    end

    -- 11. 退出挑战 / 游玩结算二次确认弹窗
    UI.settleConfirmModal = UIBinder.FindDeepChild(root, "SettleConfirmModal")
    if UI.settleConfirmModal then
        UI.confirmResumeBtn  = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmResumeBtn")
        UI.confirmRestartBtn = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmRestartBtn")
        UI.confirmQuitBtn    = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmQuitBtn")
        UI.confirmDesc       = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmDesc")
        UI.confirmTitle      = UIBinder.FindDeepChild(UI.settleConfirmModal, "ConfirmTitle")
    end

    -- 12. 终局结算演出弹窗
    UI.settleModal = UIBinder.FindDeepChild(root, "SettleModal")
    if UI.settleModal then
        UI.settleTitle      = UIBinder.FindDeepChild(UI.settleModal, "SettleTitle")
        UI.settleDesc       = UIBinder.FindDeepChild(UI.settleModal, "SettleDesc")
        UI.settleStats      = UIBinder.FindDeepChild(UI.settleModal, "SettleStats")
        UI.settleNextBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleNextBtn")
        UI.settleRetryBtn   = UIBinder.FindDeepChild(UI.settleModal, "SettleRetryBtn")
        UI.settleChapBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleChapterBtn")
        UI.settleRestartBtn = UIBinder.FindDeepChild(UI.settleModal, "SettleRestartBtn")
        UI.settleQuitBtn    = UIBinder.FindDeepChild(UI.settleModal, "SettleQuitBtn")
    end

    return UI
end

-- 控制战斗核心沙盘层（灵穴、光轨、微粒、HUD）可见性
function UIBinder.SetGameplayLayersVisible(UI, visible)
    if not UI then return end
    Layout.SetVisible(UI.nodesLayer, visible)
    Layout.SetVisible(UI.linksLayer, visible)
    Layout.SetVisible(UI.particlesLayer, visible)
    Layout.SetVisible(UI.hudLayer, visible)
end

return UIBinder

end
_MODULES["ui/uiBinder"] = _MODULES["src/ui/uiBinder"]


-- ========== MAIN ENTRYPOINT ==========
-- src/main.lua
-- 《星轨交错：地脉争锋》千星奇域 2D 俯视角即时战略游戏主控脚本
-- 支持模式选择（剧情模式/挑战模式）、5大关卡章节推衍、2~4方大乱斗与动态权能预算阶梯

local BalanceConfig   = require("default_import_file/src/data/balanceConfig") or require("src/data/balanceConfig")
local CardRegistry    = require("default_import_file/src/data/cardRegistry") or require("src/data/cardRegistry")
local ChapterConfig   = require("default_import_file/src/data/chapterConfig") or require("src/data/chapterConfig")
local Layout          = require("default_import_file/src/core/layout") or require("src/core/layout")
local Runtime         = require("default_import_file/src/core/runtime") or require("src/core/runtime")
local Input           = require("default_import_file/src/core/input") or require("src/core/input")

local StarMap         = require("default_import_file/src/world/starMap") or require("src/world/starMap")
local NodeEntity      = require("default_import_file/src/world/nodeEntity") or require("src/world/nodeEntity")
local RouteManager    = require("default_import_file/src/world/routeManager") or require("src/world/routeManager")
local CombatResolver  = require("default_import_file/src/world/combatResolver") or require("src/world/combatResolver")
local AbilitySystem   = require("default_import_file/src/world/abilitySystem") or require("src/world/abilitySystem")
local FactionAI       = require("default_import_file/src/world/factionAI") or require("src/world/factionAI")

local VisualRenderer  = require("default_import_file/src/ui/visualRenderer") or require("src/ui/visualRenderer")
local DialoguePlayer  = require("default_import_file/src/ui/dialoguePlayer") or require("src/ui/dialoguePlayer")
local PrepareView     = require("default_import_file/src/ui/prepareView") or require("src/ui/prepareView")
local HudView         = require("default_import_file/src/ui/hudView") or require("src/ui/hudView")
local CardBar         = require("default_import_file/src/ui/cardBar") or require("src/ui/cardBar")
local ModeSelectView  = require("default_import_file/src/ui/modeSelectView") or require("src/ui/modeSelectView")
local ChapterSelectView = require("default_import_file/src/ui/chapterSelectView") or require("src/ui/chapterSelectView")
local UIBinder        = require("default_import_file/src/ui/uiBinder") or require("src/ui/uiBinder")

-- 全局游戏状态机枚举
local STATE_MODE_SELECT    = "STATE_MODE_SELECT"
local STATE_CHAPTER_SELECT = "STATE_CHAPTER_SELECT"
local STATE_DIALOGUE       = "STATE_DIALOGUE"
local STATE_PREPARE        = "STATE_PREPARE"
local STATE_COUNTDOWN      = "STATE_COUNTDOWN"   -- 战前3秒倒计时 (3、2、1、开始)
local STATE_PLAYING        = "STATE_PLAYING"
local STATE_SETTLEMENT     = "STATE_SETTLEMENT"

local gameState = {
    currentState   = STATE_MODE_SELECT,
    elapsedTime    = 0,
    timeRemaining  = BalanceConfig.MATCH_DURATION,
    captureTimer   = 0,
    countdownTimer = 0,
    isGameOver     = false,
    nodes          = {}
}

-- UI 控件绑定容器 (由 UIBinder.BindControls 统筹填充)
local UI = {}

-- 初始化沙盘所有灵穴实体
local function InitNodes()
    gameState.nodes = {}
    for _, def in ipairs(StarMap.NODES_DEF) do
        table.insert(gameState.nodes, NodeEntity.Create(def))
    end
end

-- 胜负判定 (支持 2~4 方多阵营混战)
local function CheckMatchEnd(isTimeout)
    if gameState.isGameOver then return end

    local pNodes, pParts = 0, 0
    local enemyFactionScores = {}

    for _, n in ipairs(gameState.nodes) do
        if n.faction == "player" then
            pNodes = pNodes + 1
            pParts = pParts + n.particles
        elseif n.faction ~= "neutral" then
            local fac = n.faction
            if not enemyFactionScores[fac] then
                enemyFactionScores[fac] = { nodes = 0, parts = 0 }
            end
            enemyFactionScores[fac].nodes = enemyFactionScores[fac].nodes + 1
            enemyFactionScores[fac].parts = enemyFactionScores[fac].parts + n.particles
        end
    end

    local inFlightPlayer = 0
    local inFlightEnemy = {}
    for _, p in ipairs(RouteManager.movingParticles) do
        if p.faction == "player" then
            inFlightPlayer = inFlightPlayer + 1
        elseif p.faction ~= "neutral" then
            inFlightEnemy[p.faction] = (inFlightEnemy[p.faction] or 0) + 1
        end
    end

    -- 判定所有敌对势力是否已全部被歼灭
    local allEnemiesDefeated = true
    for fac, data in pairs(enemyFactionScores) do
        local flying = inFlightEnemy[fac] or 0
        if data.nodes > 0 or flying > 0 then
            allEnemiesDefeated = false
            break
        end
    end
    for fac, cnt in pairs(inFlightEnemy) do
        if cnt > 0 then
            allEnemiesDefeated = false
            break
        end
    end

    if allEnemiesDefeated then
        -- 玩家大获全胜！
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        ChapterSelectView.UnlockNextStage(StarMap.currentStage)
        BalanceConfig.StopAllAudios()
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowSettlement(true, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    elseif pNodes == 0 and inFlightPlayer == 0 then
        -- 玩家兵力全军覆没
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        BalanceConfig.StopAllAudios()
        BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        HudView.ShowSettlement(false, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    elseif isTimeout then
        -- 倒计时归零压哨决胜
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
        local pScore = pNodes * 1000 + pParts * 10
        local isWin = true
        for _, data in pairs(enemyFactionScores) do
            local eScore = data.nodes * 1000 + data.parts * 10
            if eScore >= pScore then
                isWin = false
                break
            end
        end
        BalanceConfig.StopAllAudios()
        if isWin then
            ChapterSelectView.UnlockNextStage(StarMap.currentStage)
            BalanceConfig.PlayAudioSafe("MATCH_WIN")
        else
            BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        end
        HudView.ShowSettlement(isWin, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    end
end

-- 缓存控件树引用 (统一由 UIBinder.BindControls 处理)
local function CacheUIControls()
    UI = UIBinder.BindControls(script, game)
    Runtime.InitParticlePool(UI.particleCtrls)
    -- 初始化连线柔边羽化 (光束能量脉冲质感)
    VisualRenderer.InitLineSoftEdge(UI.routeCtrls, UI.staticLinkCtrls)
end

-- 控制战斗核心层（灵穴、光轨、微粒、HUD）的可见性
local function SetGameplayLayersVisible(visible)
    UIBinder.SetGameplayLayersVisible(UI, visible)
end

-- 提取光标事件位置助手
local function GetEventPos(data)
    if not data then return 0, 0 end
    if data.GetUIPos then
        local ok, pos, maybeY = pcall(function() return data:GetUIPos() end)
        if ok then
            if type(pos) == "table" then
                return pos[1] or pos.x or 0, pos[2] or pos.y or 0
            elseif type(pos) == "number" then
                return pos, maybeY or 0
            end
        end
    end
    if type(data.x) == "number" and type(data.y) == "number" then
        return data.x, data.y
    end
    if type(data.positionX) == "number" and type(data.positionY) == "number" then
        return data.positionX, data.positionY
    end
    return 0, 0
end

-- 载入并启动指定章节
local function StartStage(stageId)
    local chap = StarMap.LoadStage(stageId)
    print(string.format("[Starlink] 加载章节: 第 %d 关【%s】(节点数: %d, 权能预算: %d, 时限: %ds)", chap.id, chap.title, #chap.nodes, chap.budget, chap.duration))

    InitNodes()
    RouteManager.Init()
    CombatResolver.Init()
    AbilitySystem.cooldowns = { 0, 0, 0, 0 }

    -- 彻底清除旧关卡残留连线、微粒与拖拽线
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    gameState.elapsedTime   = 0
    gameState.timeRemaining = chap.duration or BalanceConfig.MATCH_DURATION
    gameState.isGameOver    = false

    -- 呈现战场沙盘层
    SetGameplayLayersVisible(true)

    -- 刷新沙盘节点与静态连线几何布局
    VisualRenderer.ApplyStageLayout(UI.nodeUIList, gameState.nodes, UI.staticLinkCtrls, StarMap.LINKS)
    VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()

    -- 立即刷新左上角地脉情报与右上角操作指引
    HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

    -- 隐藏其他面板，进入战前剧情
    Layout.SetVisible(UI.modeSelectModal, false)
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.countdownModal, false)
    CloseSettleConfirmModal()

    -- 剧情演播阶段隐藏侧边常驻导航按钮，剧情结束后重新显示
    Layout.SetVisible(UI.quickNavLayer, false)

    -- 1. 剧情演播
    DialoguePlayer.Init(chap.dialogues, function()
        print("[Starlink] 章节剧情完毕，进入战前符印调配...")
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.prepareModal, true)
        Layout.SetVisible(UI.quickNavLayer, true)
        gameState.currentState = STATE_PREPARE

        -- 2. 调配面板初始化 (动态预算)
        PrepareView.Init(chap.budget, function(selectedDeck)
            print("[Starlink] 战前符印装配完成，进入战前 3 秒倒计时...")
            AbilitySystem.InitDeck(selectedDeck)
            Layout.SetVisible(UI.prepareModal, false)
            Layout.SetVisible(UI.quickNavLayer, true)
            SetGameplayLayersVisible(true)

            -- 刷新左上角特殊灵穴说明与右上角战术操作指引
            HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

            -- 启动 3 秒倒计时 (3、2、1、开始)
            gameState.countdownTimer = 3.6
            gameState.currentState = STATE_COUNTDOWN
            Layout.SetVisible(UI.countdownModal, true)
            HudView.UpdateCountdown(gameState.countdownTimer, UI.countdownModal, UI.countdownText, UI.countdownSub)
            BalanceConfig.PlayAudioSafe("UI_CLICK")
        end)
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
    end)

    gameState.currentState = STATE_DIALOGUE
    Layout.SetVisible(UI.dialogueModal, true)
end

-- 关闭千星奇域退出挑战 / 游玩结算二次确认弹窗
local function CloseSettleConfirmModal()
    if UI.settleConfirmModal then
        Layout.SetVisible(UI.settleConfirmModal, false)
    end
end

-- 打开千星奇域退出挑战 / 游玩结算二次确认弹窗（动态提示当前进度与成功/失败判定预测）
local function OpenSettleConfirmModal()
    BalanceConfig.PlayAudioSafe("UI_CLICK")
    local completed4 = ChapterSelectView.HasCompletedFirst4Stages()
    local clearedCount = ChapterSelectView.GetClearedCount and ChapterSelectView.GetClearedCount() or 0
    if UI.confirmDesc and UI.confirmDesc.alive then
        if completed4 then
            UI.confirmDesc.text = string.format("已通关 %d/4 关 · 当前中断将判定为【大捷成功】", clearedCount)
            UI.confirmDesc.fontColor = Layout.PALETTE.GOLD
        else
            UI.confirmDesc.text = string.format("已通关 %d/4 关 · 未达成前4关，中断将判定为【失败】", clearedCount)
            UI.confirmDesc.fontColor = Layout.PALETTE.ENEMY
        end
    end
    if UI.settleConfirmModal then
        Layout.SetVisible(UI.settleConfirmModal, true)
    end
end

-- 触发千星奇域原生系统个人结算 (按规则判定成功/失败)
local function TriggerNativePersonalSettlement()
    CloseSettleConfirmModal()
    local completed4 = ChapterSelectView.HasCompletedFirst4Stages()
    local isSuccess = completed4
    local clearedCount = ChapterSelectView.GetClearedCount and ChapterSelectView.GetClearedCount() or (isSuccess and 4 or 0)
    print(string.format("[Starlink] 触发原生系统个人结算: completedFirst4Stages=%s (已通关%d关) => 结算状态: %s",
        tostring(completed4), clearedCount, isSuccess and "成功" or "失败"))

    gameState.isGameOver = true
    gameState.currentState = STATE_SETTLEMENT

    BalanceConfig.StopAllAudios()
    if isSuccess then
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowToast("【推衍圆满·结算成功】已达成前4关推衍，正在结算并退出...")
    else
        BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        HudView.ShowToast("【推衍未成·结算失败】未达成前4关推衍，已中断挑战...")
    end

    -- 停止战场动态
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    -- 展现终局全屏游玩结算演出（参考原神/千星奇域关卡结算弹窗大捷/未成界面）
    if UI.settleModal then
        Layout.SetVisible(UI.modeSelectModal, false)
        Layout.SetVisible(UI.chapterSelectModal, false)
        Layout.SetVisible(UI.prepareModal, false)
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.countdownModal, false)
        SetGameplayLayersVisible(false)
        HudView.ShowSettlement(isSuccess, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
        if UI.settleNextBtn then
            -- 如果是退出挑战结算，下一关按钮改为不可用或直接隐藏，保留重开模式与重新挑战
            Layout.SetVisible(UI.settleNextBtn, false)
        end
    end

    -- 上报千星奇域原生系统结算 (个人结算)
    if game then
        pcall(function()
            if game.ServerSignal then
                game.ServerSignal("SettlePersonalGame", {
                    isSuccess = isSuccess,
                    result = isSuccess and 1 or 0,
                    clearedCount = clearedCount,
                    currentStage = StarMap.currentStage
                })
                game.ServerSignal("QuitGame", {
                    isSuccess = isSuccess,
                    result = isSuccess and 1 or 0
                })
            end
        end)
        pcall(function()
            if game.SettleGame then
                game.SettleGame(isSuccess)
            end
        end)
        pcall(function()
            if game.QuitGame then
                game.QuitGame()
            end
        end)
    end
end

-- 重开模式：回退到模式选择界面，保留剧情模式关卡解锁与通关进度
local function HandleRestartToModeSelect()
    CloseSettleConfirmModal()
    print("[Starlink] 重开模式：回退到模式选择界面（保留剧情模式关卡进度: 已解锁第 " .. tostring(ChapterSelectView.unlockedStage) .. " 关）")
    BalanceConfig.PlayAudioSafe("UI_CLICK")
    BalanceConfig.StopAllAudios()
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Input.isDragging = false
    Input.dragSourceId = nil
    Input.ClearSelectedCard()

    -- 隐藏所有战斗与演播面板
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.dialogueModal, false)
    Layout.SetVisible(UI.countdownModal, false)
    SetGameplayLayersVisible(false)

    -- 打开模式选择主面板并显示常驻快捷栏
    Layout.SetVisible(UI.modeSelectModal, true)
    Layout.SetVisible(UI.quickNavLayer, true)
    gameState.currentState = STATE_MODE_SELECT
    HudView.ShowToast("已返回模式选择界面，关卡进度已保留。")
end

-- 注册全屏与各面板交互监听
local function SetupEventHandlers()
    -- 辅助：静音原生按钮 clickAudioId，避免引擎底层默认点击音效与脚本 PlayAudioSafe 重叠双响
    local function SilenceButton(btn)
        if btn and btn.alive then
            pcall(function() btn.clickAudioId = 0 end)
        end
    end

    -- 1. 全屏光标事件 (连线与轻点)
    if UI.cursorArea and UI.cursorArea.AddCursorEventListener then
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDown, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
            local x, y = GetEventPos(data)
            Input.OnCursorDown(x, y, gameState.nodes)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorDrag, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
            local x, y = GetEventPos(data)
            Input.OnCursorDrag(x, y)
        end)
        UI.cursorArea:AddCursorEventListener(Enum.CursorEventType.CursorUp, function(data)
            if gameState.currentState ~= STATE_PLAYING then return end
            local x, y = GetEventPos(data)
            Input.OnCursorUp(x, y, gameState.nodes)
        end)
    end

    -- 2. 输入事件回调分发
    Input.onNodeClicked = function(nodeId)
        local node = gameState.nodes[nodeId + 1]
        if node and node.faction == "player" then
            if node.routeTo ~= nil then
                RouteManager.RemoveRouteFrom(node.id, gameState.nodes)
                node.isDefensive = true
                BalanceConfig.PlayAudioSafe("ROUTE_CUT")
                HudView.ShowToast("【固守结界已展开】" .. node.name .. " 损耗削减 50%！")
            else
                node.isDefensive = not node.isDefensive
                if node.isDefensive then
                    HudView.ShowToast("【固守结界已展开】" .. node.name .. " 损伤削减 50%！")
                else
                    HudView.ShowToast("【解除驻防】" .. node.name .. " 待命准备输送。")
                end
            end
        end
    end

    Input.onRouteCreated = function(fromId, toId)
        local ok, msg = RouteManager.SetRoute(fromId, toId, "player", gameState.nodes)
        if ok then
            local nA = gameState.nodes[fromId + 1]
            local nB = gameState.nodes[toId + 1]
            HudView.ShowToast("灵流通道已建立：" .. nA.name .. " ➔ " .. nB.name)
        elseif msg then
            HudView.ShowToast(msg)
        end
    end

    Input.onCardCast = function(slotIndex, targetNodeId)
        local ok, msg = AbilitySystem.CastAbility(
            slotIndex,
            targetNodeId,
            gameState.nodes,
            RouteManager,
            gameState.elapsedTime,
            function(x, y, col) CombatResolver.AddSpark(x, y, col) end
        )
        if ok then
            BalanceConfig.PlayAudioSafe("SKILL_BLAST")
            if msg then HudView.ShowToast(msg) end
        else
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            if msg then HudView.ShowToast("【释放失败】" .. msg) end
        end
        Input.ClearSelectedCard()
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    end

    Input.onCardCancelled = function(slotIndex)
        local card = AbilitySystem.deck[slotIndex]
        BalanceConfig.PlayAudioSafe("UI_CLICK")
        HudView.ShowToast(string.format("【取消施法】%s", card and card.name or ""))
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    end

    -- 3. 模式选择按钮监听
    if UI.modeStoryBtn and UI.modeStoryBtn.AddCursorEventListener then
        SilenceButton(UI.modeStoryBtn)
        UI.modeStoryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            print("[Starlink] 玩家选择【剧情模式】，打开战役章节选择面板...")
            Layout.SetVisible(UI.modeSelectModal, false)
            Layout.SetVisible(UI.chapterSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_CHAPTER_SELECT
            ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
        end)
    end

    if UI.modeChallengeBtn and UI.modeChallengeBtn.AddCursorEventListener then
        SilenceButton(UI.modeChallengeBtn)
        UI.modeChallengeBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            print("[Starlink] 玩家点击【挑战模式】（筹备中提示）...")
            HudView.ShowToast("【挑战模式】正在筹备中，敬请期待！")
        end)
    end

    if UI.modeQuitBtn and UI.modeQuitBtn.AddCursorEventListener then
        SilenceButton(UI.modeQuitBtn)
        UI.modeQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            TriggerNativePersonalSettlement()
        end)
    end

    -- 4. 章节选择按钮监听
    for idx, cardUI in ipairs(UI.chapterCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
            SilenceButton(cardUI.button)
            cardUI.button:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                BalanceConfig.PlayAudioSafe("UI_CLICK")
                local ok, err = ChapterSelectView.SelectStage(idx)
                if not ok then
                    HudView.ShowToast(err or "该关卡尚未解锁！")
                else
                    ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
                end
            end)
        end
    end

    if UI.chapStartBtn and UI.chapStartBtn.AddCursorEventListener then
        SilenceButton(UI.chapStartBtn)
        UI.chapStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            StartStage(ChapterSelectView.selectedStage)
        end)
    end

    if UI.chapBackBtn and UI.chapBackBtn.AddCursorEventListener then
        SilenceButton(UI.chapBackBtn)
        UI.chapBackBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            Layout.SetVisible(UI.chapterSelectModal, false)
            Layout.SetVisible(UI.modeSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_MODE_SELECT
        end)
    end

    -- 5. 剧情按钮监听
    if UI.dlgNextBtn and UI.dlgNextBtn.AddCursorEventListener then
        SilenceButton(UI.dlgNextBtn)
        UI.dlgNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Next()
        end)
    end
    if UI.dlgSkipBtn and UI.dlgSkipBtn.AddCursorEventListener then
        SilenceButton(UI.dlgSkipBtn)
        UI.dlgSkipBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Skip()
        end)
    end

    -- 6. 战前调配卡牌点击选择
    for idx, cardUI in ipairs(UI.prepCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
            SilenceButton(cardUI.button)
            local cardKey = PrepareView.POOL_ORDER[idx]
            cardUI.button:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                local ok, action, cardId = PrepareView.ToggleCard(cardKey)
                local card = CardRegistry.GetCardById(cardKey)
                BalanceConfig.PlayAudioSafe("UI_CLICK")
                if not ok then
                    HudView.ShowToast(action or "调配失败")
                else
                    local used = PrepareView.GetUsedBudget()
                    local count = #PrepareView.selectedIds
                    if action == "equipped" then
                        HudView.ShowToast(string.format("【已装配】%s (耗能%d·CD%ds) | 预算 %d/%d，已选 %d/4 张", card and card.name or "符印", card and card.cost or 0, card and card.cd or 0, used, PrepareView.maxBudget, count))
                    elseif action == "unequipped" then
                        HudView.ShowToast(string.format("【已卸下】%s (归还%d) | 预算 %d/%d，已选 %d/4 张", card and card.name or "符印", card and card.cost or 0, used, PrepareView.maxBudget, count))
                    end
                end
                PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
            end)
        end
    end

    if UI.prepStartBtn and UI.prepStartBtn.AddCursorEventListener then
        SilenceButton(UI.prepStartBtn)
        UI.prepStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            local ok, err = PrepareView.ConfirmAndStart()
            if not ok and err then
                HudView.ShowToast(err)
            end
        end)
    end

    -- 7. 符印槽位点击选择
    for idx, slot in ipairs(UI.cardSlots) do
        if slot.container and slot.container.AddCursorEventListener then
            SilenceButton(slot.container)
            slot.container:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
                if gameState.currentState == STATE_PLAYING then
                    local card = AbilitySystem.deck[idx]
                    if not card then return end

                    if AbilitySystem.cooldowns[idx] and AbilitySystem.cooldowns[idx] > 0 then
                        BalanceConfig.PlayAudioSafe("UI_CLICK")
                        HudView.ShowToast(string.format("【%s】仍在冷却中（还剩 %d 秒）", card.name, math.ceil(AbilitySystem.cooldowns[idx])))
                        return
                    end

                    -- 取消智能释放：如果当前已选中该卡牌，再次点击则直接取消选定
                    if Input.GetSelectedCard() == idx then
                        Input.ClearSelectedCard()
                        BalanceConfig.PlayAudioSafe("UI_CLICK")
                        HudView.ShowToast(string.format("【已取消选定】%s", card.name))
                        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
                        return
                    end

                    -- 选定符印，等待玩家点击目标灵穴
                    Input.SetSelectedCard(idx)
                    BalanceConfig.PlayAudioSafe("UI_CLICK")
                    local targetHint = ""
                    if card.targetType == "enemy_node" then
                        targetHint = "请轻点敌方灵穴释放"
                    elseif card.targetType == "player_node" then
                        targetHint = "请轻点我方灵穴加持"
                    elseif card.targetType == "player_route_node" then
                        targetHint = "请轻点正在输送中的我方灵穴提速"
                    else
                        targetHint = "请轻点目标灵穴释放"
                    end
                    HudView.ShowToast(string.format("【已选定】%s（%s，再点符印取消）", card.name, targetHint))
                    CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, idx)
                end
            end)
        end
    end

    -- 8. 常驻侧边导航栏按钮监听 (重开推衍 & 结算退出)
    if UI.sideRestartBtn and UI.sideRestartBtn.AddCursorEventListener then
        SilenceButton(UI.sideRestartBtn)
        UI.sideRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    if UI.sideSettleBtn and UI.sideSettleBtn.AddCursorEventListener then
        SilenceButton(UI.sideSettleBtn)
        UI.sideSettleBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            OpenSettleConfirmModal()
        end)
    end

    -- 9. 退出挑战 / 游玩结算二次确认弹窗按钮监听
    if UI.confirmResumeBtn and UI.confirmResumeBtn.AddCursorEventListener then
        SilenceButton(UI.confirmResumeBtn)
        UI.confirmResumeBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            CloseSettleConfirmModal()
        end)
    end

    if UI.confirmRestartBtn and UI.confirmRestartBtn.AddCursorEventListener then
        SilenceButton(UI.confirmRestartBtn)
        UI.confirmRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    if UI.confirmQuitBtn and UI.confirmQuitBtn.AddCursorEventListener then
        SilenceButton(UI.confirmQuitBtn)
        UI.confirmQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            TriggerNativePersonalSettlement()
        end)
    end

    -- 10. 结算弹窗按钮
    -- 进军下一关
    if UI.settleNextBtn and UI.settleNextBtn.AddCursorEventListener then
        SilenceButton(UI.settleNextBtn)
        UI.settleNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            local nextStageId = StarMap.currentStage + 1
            if nextStageId <= 5 then
                print(string.format("[Starlink] 进军下一关: 第 %d 关...", nextStageId))
                ChapterSelectView.selectedStage = nextStageId
                StartStage(nextStageId)
            else
                HudView.ShowToast("【恭喜】已通关全部 5 大战役章节！")
                Layout.SetVisible(UI.settleModal, false)
                Layout.SetVisible(UI.chapterSelectModal, true)
                SetGameplayLayersVisible(false)
                gameState.currentState = STATE_CHAPTER_SELECT
                ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
            end
        end)
    end

    -- 重新演练
    if UI.settleRetryBtn and UI.settleRetryBtn.AddCursorEventListener then
        SilenceButton(UI.settleRetryBtn)
        UI.settleRetryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            print(string.format("[Starlink] 重新演练当前关卡: 第 %d 关...", StarMap.currentStage))
            StartStage(StarMap.currentStage)
        end)
    end

    -- 返回章节选择
    if UI.settleChapBtn and UI.settleChapBtn.AddCursorEventListener then
        SilenceButton(UI.settleChapBtn)
        UI.settleChapBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            BalanceConfig.StopAllAudios()
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            Layout.SetVisible(UI.settleModal, false)
            Layout.SetVisible(UI.chapterSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_CHAPTER_SELECT
            ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
        end)
    end

    -- 重开模式 (回退到模式选择界面并保留关卡进度)
    if UI.settleRestartBtn and UI.settleRestartBtn.AddCursorEventListener then
        SilenceButton(UI.settleRestartBtn)
        UI.settleRestartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            HandleRestartToModeSelect()
        end)
    end

    -- 退出推衍 (原生系统个人结算)
    if UI.settleQuitBtn and UI.settleQuitBtn.AddCursorEventListener then
        SilenceButton(UI.settleQuitBtn)
        UI.settleQuitBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            OpenSettleConfirmModal()
        end)
    end
end

--------------------------------------------------------------------------------
-- 千星沙箱标准客户端脚本生命周期钩子
--------------------------------------------------------------------------------

function OnInit()
    print("[Starlink] OnInit: 装配 2D 纯代码关卡模式沙盘...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    CacheUIControls()
    StarMap.LoadStage(1)
    InitNodes()
    RouteManager.Init()
    CombatResolver.Init()
    HudView.Init()

    -- 初始应用第 1 关布局
    VisualRenderer.ApplyStageLayout(UI.nodeUIList, gameState.nodes, UI.staticLinkCtrls, StarMap.LINKS)
    VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
    CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
    HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)
    local chap = StarMap.currentChapterDef
    HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

    SetupEventHandlers()
    print("[Starlink] OnInit: 装配完成！准备就绪。")
end

function OnStart()
    print("[Starlink] OnStart: 启动模式选择主界面...")
    if script and script.EnableUpdate then
        script:EnableUpdate(true)
    end
    gameState.currentState = STATE_MODE_SELECT
    SetGameplayLayersVisible(false)
    VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
    Runtime.HideAllParticles()
    Layout.SetVisible(UI.modeSelectModal, true)
    Layout.SetVisible(UI.quickNavLayer, true)
    Layout.SetVisible(UI.settleConfirmModal, false)
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.dialogueModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.countdownModal, false)
end

function OnUpdate(dt)
    if gameState.currentState == STATE_MODE_SELECT then
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_CHAPTER_SELECT then
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_DIALOGUE then
        DialoguePlayer.Update(dt, UI.dlgSpeaker, UI.dlgContent)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_PREPARE then
        PrepareView.Update(dt)
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

    elseif gameState.currentState == STATE_COUNTDOWN then
        local prevSec = math.ceil(gameState.countdownTimer)
        gameState.countdownTimer = gameState.countdownTimer - dt
        local currSec = math.ceil(gameState.countdownTimer)
        if prevSec > 0 and currSec < prevSec and currSec >= 1 then
            BalanceConfig.PlayAudioSafe("UI_CLICK")
        end

        HudView.UpdateCountdown(gameState.countdownTimer, UI.countdownModal, UI.countdownText, UI.countdownSub)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)
        VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, 0)
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, nil)
        HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)

        if gameState.countdownTimer <= -0.6 then
            Layout.SetVisible(UI.countdownModal, false)
            gameState.currentState = STATE_PLAYING
            gameState.elapsedTime = 0
            BalanceConfig.PlayAudioSafe("ROUTE_LINK")
            local chap = StarMap.currentChapterDef
            HudView.ShowToast(string.format("【%s】推衍启阵！全速进军！", chap and chap.title or "开战"))
        end

    elseif gameState.currentState == STATE_PLAYING then
        gameState.elapsedTime = gameState.elapsedTime + dt
        gameState.timeRemaining = gameState.timeRemaining - dt

        if not gameState._lastHeartbeat or (gameState.elapsedTime - gameState._lastHeartbeat >= 2.0) then
            gameState._lastHeartbeat = gameState.elapsedTime
            local p0 = gameState.nodes[1]
            print(string.format("[Starlink Battle] Stage %d, t=%.1fs, routes=%d, flying=%d | p0 particles=%d",
                StarMap.currentStage, gameState.elapsedTime, #RouteManager.routes, #RouteManager.movingParticles,
                p0 and p0.particles or 0
            ))
        end

        -- 1. 灵穴微粒孕育
        for _, n in ipairs(gameState.nodes) do
            NodeEntity.TickSpawn(n, dt, gameState.nodes, gameState.elapsedTime)
        end

        -- 2. 共鸣度连续步进 (0.8s 周期)
        gameState.captureTimer = gameState.captureTimer + dt
        if gameState.captureTimer >= BalanceConfig.CAPTURE_INTERVAL then
            gameState.captureTimer = 0
            for _, n in ipairs(gameState.nodes) do
                NodeEntity.TickCapture(
                    n,
                    gameState.elapsedTime,
                    function(capturedNode)
                        local facName = Layout.GetFactionName(capturedNode.faction)
                        HudView.ShowToast(string.format("【%s】已被【%s】完全掌控！", capturedNode.name, facName))
                        BalanceConfig.PlayAudioSafe("NODE_CAPTURE")
                        CheckMatchEnd()
                    end,
                    function(lostNode)
                        HudView.ShowToast(string.format("【%s】统治动摇，已沦为中立争夺！", lostNode.name))
                    end
                )
            end
        end

        -- 3. 物流发射与微粒流动 (包含微粒到达即时拔河对消占领决算)
        RouteManager.Update(
            dt,
            gameState.nodes,
            gameState.elapsedTime,
            function(hitNode)
                CombatResolver.AddSpark(hitNode.x, hitNode.y)
            end,
            function(capturedNode)
                local facName = Layout.GetFactionName(capturedNode.faction)
                HudView.ShowToast(string.format("【%s】已被【%s】完全掌控！", capturedNode.name, facName))
                CheckMatchEnd()
            end,
            function(lostNode)
                HudView.ShowToast(string.format("【%s】统治动摇，已沦为中立争夺！", lostNode.name))
            end
        )

        -- 4. 战火与威胁判定
        CombatResolver.Update(dt, gameState.nodes, RouteManager.movingParticles)

        -- 5. 敌方 AI 推进 (多阵营全员大乱斗)
        FactionAI.Update(dt, gameState.nodes, RouteManager)

        -- 6. 符印冷却计时
        AbilitySystem.UpdateCooldowns(dt)

        -- 7. 纯代码视觉渲染刷新 (含拖拽拓扑高亮与运动形变)
        Runtime.UpdateParticles(RouteManager.movingParticles, Layout.GetFactionColor)
        VisualRenderer.UpdateRoutes(UI.routeCtrls, RouteManager.routes, gameState.nodes, UI.dragLine, Input, gameState.elapsedTime)
        VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, gameState.elapsedTime, Input)
        CardBar.Update(UI.cardSlots, AbilitySystem.deck, AbilitySystem.cooldowns, Input.GetSelectedCard())
        HudView.UpdateTopBar(gameState.timeRemaining, gameState.nodes, UI.playerPctText, UI.enemyPctText, UI.timerText, UI.barPlayer, UI.barEnemy)
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)

        -- 8. 胜负检定
        if gameState.timeRemaining <= 0 then
            CheckMatchEnd(true)
        else
            CheckMatchEnd(false)
        end

    elseif gameState.currentState == STATE_SETTLEMENT then
        HudView.UpdateToast(dt, UI.toastContainer, UI.toastText)
    end
end

