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
                { id = 0, name = "西风前哨", x = 260, y = 450, radius = 42, faction = "player", particles = 20, control = 100, anomaly = "NORMAL", desc = "我方西风骑士前哨" },
                { id = 1, name = "清泉北陵", x = 520, y = 580, radius = 36, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "北侧灵泉高地 (侧翼拓展点)" },
                { id = 2, name = "泉水祭坛", x = 800, y = 620, radius = 38, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "清泉古祭坛" },
                { id = 3, name = "晨曦峡口", x = 1080, y = 580, radius = 36, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "近酒庄险隘" },
                { id = 4, name = "清泉主脉", x = 620, y = 450, radius = 38, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "清泉核心灵脉 (战略枢纽)" },
                { id = 5, name = "奔狼前驿", x = 980, y = 450, radius = 38, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "中路要冲 (战略枢纽)" },
                { id = 6, name = "清泉南溪", x = 520, y = 320, radius = 36, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "南侧支流草甸 (侧翼拓展点)" },
                { id = 7, name = "杜拉夫猎场", x = 800, y = 280, radius = 38, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "猎人歇脚营地" },
                { id = 8, name = "达达乌帕口", x = 1080, y = 320, radius = 36, faction = "neutral", particles = 7, control = 0, anomaly = "NORMAL", desc = "近部落前沿" },
                { id = 9, name = "愚人驻地", x = 1340, y = 450, radius = 42, faction = "enemy_red", particles = 20, control = 100, anomaly = "NORMAL", desc = "愚人众前线营地" }
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
                { id = 0, name = "风起营地", x = 220, y = 450, radius = 40, faction = "player", particles = 24, control = 100, anomaly = "NORMAL", desc = "蒙德西风阵地" },
                { id = 1, name = "低语树林", x = 440, y = 600, radius = 34, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路树影屏障" },
                { id = 2, name = "星落湖畔", x = 440, y = 300, radius = 34, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南路清澈湖滨" },
                { id = 3, name = "千风隘口", x = 700, y = 650, radius = 36, faction = "neutral", particles = 15, control = 0, anomaly = "WIND_FLOW", desc = "千风汇聚（输送翻倍）" },
                { id = 4, name = "石珀晶矿", x = 700, y = 250, radius = 36, faction = "neutral", particles = 14, control = 0, anomaly = "AMBER_MINE", desc = "石珀富矿（产能翻倍）" },
                { id = 5, name = "望风山地", x = 960, y = 650, radius = 34, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "俯瞰北境高崖" },
                { id = 6, name = "摘星崖底", x = 960, y = 250, radius = 34, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "悬崖南麓险隘" },
                { id = 7, name = "千风神殿", x = 700, y = 450, radius = 38, faction = "neutral", particles = 16, control = 0, anomaly = "NORMAL", desc = "远古神殿遗址" },
                { id = 8, name = "迷雾荒墟", x = 960, y = 450, radius = 34, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾衰减（产能减半）" },
                { id = 9, name = "急冻悬崖", x = 1180, y = 600, radius = 34, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北侧霜寒关卡" },
                { id = 10, name = "誓言岬哨", x = 1180, y = 300, radius = 34, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南侧海风前哨" },
                { id = 11, name = "千风绝壁", x = 1380, y = 450, radius = 40, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众千风要塞" }
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
                { id = 0, name = "西风先锋", x = 240, y = 240, radius = 38, faction = "player", particles = 24, control = 100, anomaly = "NORMAL", desc = "我方西南先锋大营" },
                { id = 1, name = "黑岩关隘", x = 640, y = 600, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路悬石关卡" },
                { id = 2, name = "天工峡口", x = 960, y = 600, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北路绝壁隘口" },
                { id = 3, name = "伏鳌谷地", x = 440, y = 380, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南峡谷要道" },
                { id = 4, name = "琉璃晶矿", x = 440, y = 180, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "琉璃晶砂浅坑" },
                { id = 5, name = "石珀富矿", x = 800, y = 490, radius = 36, faction = "neutral", particles = 15, control = 0, anomaly = "AMBER_MINE", desc = "石珀富矿（产能翻倍）" },
                { id = 6, name = "雷暴要塞", x = 800, y = 330, radius = 36, faction = "neutral", particles = 18, control = 0, anomaly = "DEFENSE_BASTION", desc = "雷暴灵障（战损减半）" },
                { id = 7, name = "层岩中继", x = 620, y = 380, radius = 32, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "西翼疾风流道" },
                { id = 8, name = "悬木吊桥", x = 980, y = 380, radius = 32, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "东翼古矿吊桥" },
                { id = 9, name = "无名遗迹", x = 800, y = 170, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "渊底远古废墟" },
                { id = 10, name = "巨渊之口", x = 1160, y = 380, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南盗宝前沿" },
                { id = 11, name = "丹砂矿脉", x = 1160, y = 180, radius = 32, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南丹砂坑洞" },
                { id = 12, name = "愚人巨垒", x = 800, y = 730, radius = 38, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众北山巨垒" },
                { id = 13, name = "盗宝匪巢", x = 1360, y = 240, radius = 38, faction = "enemy_purple", particles = 26, control = 100, anomaly = "NORMAL", desc = "渊影盗宝总寨" }
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
                { id = 0, name = "西风水港", x = 200, y = 450, radius = 36, faction = "player", particles = 28, control = 100, anomaly = "NORMAL", desc = "我方西港母基" },
                { id = 1, name = "枫丹前哨", x = 400, y = 570, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西北水下前沿" },
                { id = 2, name = "海露平原", x = 400, y = 330, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南海草平原" },
                { id = 3, name = "伊黎耶港", x = 620, y = 630, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北侧水闸港湾" },
                { id = 4, name = "白露隘口", x = 980, y = 630, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北水下窄谷" },
                { id = 5, name = "枫丹激流", x = 1200, y = 570, radius = 30, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "激流通道（输送翻倍）" },
                { id = 6, name = "苍晶矿脉", x = 1200, y = 330, radius = 30, faction = "neutral", particles = 14, control = 0, anomaly = "AMBER_MINE", desc = "苍晶富矿（产能翻倍）" },
                { id = 7, name = "纯水阳核", x = 700, y = 450, radius = 34, faction = "neutral", particles = 16, control = 0, anomaly = "PURE_WATER", desc = "中央纯水西枢纽" },
                { id = 8, name = "纯水阴核", x = 900, y = 450, radius = 34, faction = "neutral", particles = 16, control = 0, anomaly = "PURE_WATER", desc = "中央纯水东枢纽" },
                { id = 9, name = "沉玉古墟", x = 550, y = 450, radius = 30, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾残垣（产能减半）" },
                { id = 10, name = "水色要塞", x = 1050, y = 450, radius = 32, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "深水灵障（战损减半）" },
                { id = 11, name = "秋泉隐所", x = 620, y = 270, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "南侧暗流溶洞" },
                { id = 12, name = "柔灯要道", x = 980, y = 270, radius = 30, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南深水通道" },
                { id = 13, name = "愚人潜艇", x = 800, y = 740, radius = 36, faction = "enemy_red", particles = 24, control = 100, anomaly = "NORMAL", desc = "愚人众北境母舰" },
                { id = 14, name = "盗宝暗礁", x = 800, y = 160, radius = 36, faction = "enemy_purple", particles = 24, control = 100, anomaly = "NORMAL", desc = "盗宝团南礁老巢" },
                { id = 15, name = "机关工坊", x = 1400, y = 450, radius = 36, faction = "enemy_green", particles = 24, control = 100, anomaly = "NORMAL", desc = "遗迹机关核心中枢" }
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
                { id = 0, name = "西风终焉", x = 190, y = 220, radius = 35, faction = "player", particles = 28, control = 100, anomaly = "NORMAL", desc = "我方西南极境大营" },
                { id = 1, name = "忍冬废墟", x = 370, y = 680, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西北废墟要冲" },
                { id = 2, name = "覆雪咽喉", x = 370, y = 450, radius = 30, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "西翼要塞（战损减半）" },
                { id = 3, name = "眠龙前哨", x = 370, y = 220, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "西南峡谷前哨" },
                { id = 4, name = "寒天隘口", x = 650, y = 680, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "北境高寒关隘" },
                { id = 5, name = "苍白防线", x = 950, y = 680, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北绝壁关防" },
                { id = 6, name = "寒天激流", x = 650, y = 520, radius = 30, faction = "neutral", particles = 14, control = 0, anomaly = "WIND_FLOW", desc = "疾风通道（输送翻倍）" },
                { id = 7, name = "雪山要塞", x = 950, y = 520, radius = 30, faction = "neutral", particles = 16, control = 0, anomaly = "DEFENSE_BASTION", desc = "东北壁垒（战损减半）" },
                { id = 8, name = "熔核之北", x = 720, y = 410, radius = 32, faction = "neutral", particles = 15, control = 0, anomaly = "PLASMA", desc = "赤阳熔核（上限25粒，绞肉）" },
                { id = 9, name = "熔核之南", x = 880, y = 410, radius = 32, faction = "neutral", particles = 15, control = 0, anomaly = "PLASMA", desc = "赤阳熔核（上限25粒，绞肉）" },
                { id = 10, name = "覆雪迷雾", x = 650, y = 300, radius = 28, faction = "neutral", particles = 10, control = 0, anomaly = "MIST_RUINS", desc = "迷雾残迹（产能减半）" },
                { id = 11, name = "星银富矿", x = 950, y = 300, radius = 30, faction = "neutral", particles = 15, control = 0, anomaly = "AMBER_MINE", desc = "星银富矿（产能翻倍）" },
                { id = 12, name = "积雪小径", x = 1230, y = 220, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东南雪径要道" },
                { id = 13, name = "冰封哨卡", x = 1230, y = 450, radius = 30, faction = "neutral", particles = 16, control = 0, anomaly = "NORMAL", desc = "东翼防线枢纽" },
                { id = 14, name = "冰封棱堡", x = 1230, y = 680, radius = 28, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "东北棱堡哨站" },
                { id = 15, name = "愚人霜核", x = 190, y = 680, radius = 35, faction = "enemy_red", particles = 26, control = 100, anomaly = "NORMAL", desc = "愚人众西北霜核" },
                { id = 16, name = "盗宝残党", x = 1410, y = 220, radius = 35, faction = "enemy_purple", particles = 26, control = 100, anomaly = "NORMAL", desc = "盗宝团东南匪寨" },
                { id = 17, name = "遗迹主控", x = 1410, y = 680, radius = 35, faction = "enemy_green", particles = 26, control = 100, anomaly = "NORMAL", desc = "遗迹防卫主控主机" }
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


-- 提瓦特地脉标准调色板 (使用 0..255 整数)
Layout.PALETTE = {
    BG_DARK      = Layout.MakeColor(11, 17, 30, 255),
    PANEL_BG     = Layout.MakeColor(15, 23, 42, 235),
    PLAYER       = Layout.MakeColor(56, 189, 248, 255),   -- 提瓦特天青蓝 #38bdf8
    PLAYER_GLOW  = Layout.MakeColor(56, 189, 248, 102),
    ENEMY        = Layout.MakeColor(244, 63, 94, 255),    -- 侵蚀猩红 #f43f5e (敌方1/愚人众)
    ENEMY_GLOW   = Layout.MakeColor(244, 63, 94, 102),
    ENEMY_PURPLE = Layout.MakeColor(168, 85, 247, 255),   -- 深渊暗紫 #a855f7 (敌方2/盗宝团)
    ENEMY_PURPLE_GLOW = Layout.MakeColor(168, 85, 247, 102),
    ENEMY_GREEN  = Layout.MakeColor(16, 185, 129, 255),   -- 苍翠机体 #10b981 (敌方3/遗迹机关)
    ENEMY_GREEN_GLOW  = Layout.MakeColor(16, 185, 129, 102),
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

return Layout

end
_MODULES["core/layout"] = _MODULES["src/core/layout"]

_MODULES["src/core/runtime"] = function()
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
        control = def.control or 0,
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
        local n = allNodes[nId + 1]
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
    local effRatio = math.max(0.6, node.control / 100)
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

-- 占领共鸣度步进结算 (0.8s 周期)
function NodeEntity.TickCapture(node, elapsedTime, onCaptureCallback, onRevertNeutralCallback)
    if (node.protectedUntil or 0) > (elapsedTime or 0) then
        return -- 受千风庇护免疫侵蚀
    end

    if node.contenderFaction and node.contenderParticles > 0 then
        local excess = node.contenderParticles
        local baseGrowth = math.min(BalanceConfig.MAX_RESONANCE_GROWTH, math.max(1, math.floor(excess / 5 + 0.5)))

        if node.faction == "neutral" then
            -- 中立节点占领进度平衡：每轮 +14~20 共鸣度，需 5~6 轮 (约 4 秒) 完成掌控
            node.control = math.min(100, node.control + 14 + baseGrowth * 3)
            if node.control >= 100 then
                node.faction = node.contenderFaction
                -- 占领后初始守军：侵蚀微粒按 25% 比例转化，保底 2 粒，上限 5 粒 (防止瞬间获得满编大军继续碾压)
                node.particles = math.min(5, math.max(2, math.floor(node.contenderParticles * 0.25) + 2))
                node.contenderParticles = 0
                node.contenderFaction = nil
                node.isDefensive = true
                if onCaptureCallback then
                    onCaptureCallback(node)
                end
            end
        elseif node.faction ~= node.contenderFaction then
            -- 削减原主控方控制度：每轮削减 10 + baseGrowth * 3
            node.control = math.max(0, node.control - (10 + baseGrowth * 3))
            if node.control <= BalanceConfig.NEUTRAL_THRESHOLD then
                -- 沦为中立争夺态，控制度清零以便攻占方迅速掌控
                node.faction = "neutral"
                node.control = 0
                node.routeTo = nil
                node.isDefensive = false
                if onRevertNeutralCallback then
                    onRevertNeutralCallback(node)
                end
            end
        end

        node.contenderParticles = math.max(0, node.contenderParticles - 1)
    else
        -- 核心机制修复：已占领灵穴在无敌军侵蚀且防守稳固时，共鸣度自然逐步回满至 100%
        if node.faction ~= "neutral" and node.control < 100 then
            node.control = math.min(100, node.control + 10)
        end
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

    local fromNode = nodes[fromId + 1]
    local toNode = nodes[toId + 1]
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

    BalanceConfig.PlayAudioSafe("ROUTE_LINK")
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

-- 每帧更新：物流发射与微粒航行
function RouteManager.Update(dt, nodes, elapsedTime, onCombatHitCallback)
    -- 1. 物流发射
    for _, route in ipairs(RouteManager.routes) do
        local fromNode = nodes[route.fromId + 1]
        local toNode = nodes[route.toId + 1]

        if fromNode and toNode and fromNode.faction == route.faction then
            route.sendTimer = (route.sendTimer or 0) + dt
            local rate = BalanceConfig.BASE_TRANSPORT_RATE
            if fromNode.anomaly == "WIND_FLOW" or route.boostedUntil > elapsedTime then
                rate = BalanceConfig.BOOST_TRANSPORT_RATE
            end

            local interval = 1.0 / rate
            if route.sendTimer >= interval then
                route.sendTimer = 0
                -- 节点保留基础守备兵力 (默认 3 粒，防止基地永久定格在 1 且防守空虚)
                local safeFloor = BalanceConfig.SAFE_GARRISON or 3
                if fromNode.particles > safeFloor then
                    fromNode.particles = fromNode.particles - 1
                    local dx = toNode.x - fromNode.x
                    local dy = toNode.y - fromNode.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    table.insert(RouteManager.movingParticles, {
                        fromId = fromNode.id,
                        toId = toNode.id,
                        faction = route.faction,
                        progress = 0,
                        startX = fromNode.x,
                        startY = fromNode.y,
                        targetX = toNode.x,
                        targetY = toNode.y,
                        totalDist = dist
                    })
                end
            end
        end
    end

    -- 2. 飞行微粒位移更新
    for i = #RouteManager.movingParticles, 1, -1 do
        local p = RouteManager.movingParticles[i]
        local step = (BalanceConfig.PARTICLE_SPEED * dt) / p.totalDist
        p.progress = p.progress + step

        if p.progress >= 1.0 then
            -- 到达目标节点
            local targetNode = nodes[p.toId + 1]
            if targetNode then
                RouteManager.OnParticleArrive(p, targetNode, onCombatHitCallback)
            end
            table.remove(RouteManager.movingParticles, i)
        end
    end
end

-- 微粒到达目标节点结算
function RouteManager.OnParticleArrive(particle, node, onCombatHitCallback)
    if node.faction == particle.faction then
        -- 友军增援汇入
        local cap = (node.anomaly == "PLASMA") and BalanceConfig.PLASMA_CAP or BalanceConfig.MAX_NODE_CAP
        if node.particles < cap then
            node.particles = node.particles + 1
        end
    else
        -- 敌对交火与侵蚀 (固守减伤 30%，命中率 70%，兼顾防御阵地坚韧度与攻坚可行性)
        if node.particles > 0 then
            local defenseDamp = (node.isDefensive and 0.7 or 1.0)
            if math.random() <= defenseDamp then
                node.particles = node.particles - 1
            end
            BalanceConfig.PlayAudioSafe("COMBAT_HIT")
            if onCombatHitCallback then
                onCombatHitCallback(node)
            end
        else
            -- 节点防守空虚，微粒转化为侵蚀共鸣点
            node.contenderFaction = particle.faction
            node.contenderParticles = (node.contenderParticles or 0) + 1
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

    local targetNode = nodes[targetNodeId + 1]
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
-- 坎瑞亚遗迹推衍机（多阵营全员大乱斗 AI 智能调度与争端决策）

local StarMap = require("default_import_file/src/world/starMap") or require("src/world/starMap")

local FactionAI = {
    aiTimer = 0,
    AI_INTERVAL = 1.5 -- 1.5 秒决策一轮，反应敏捷
}

-- 辅助判定灵穴是否处于接敌前线 (拥有非己方邻居)
local function HasHostileNeighbor(node, allNodes, fac)
    local neighbors = StarMap.GetNeighbors(node.id)
    for _, nId in ipairs(neighbors) do
        local n = allNodes[nId + 1]
        if n and n.faction ~= fac then
            return true
        end
    end
    return false
end

function FactionAI.Update(dt, nodes, routeManager)
    FactionAI.aiTimer = FactionAI.aiTimer + dt
    if FactionAI.aiTimer < FactionAI.AI_INTERVAL then
        return
    end
    FactionAI.aiTimer = 0

    -- 遍历所有非玩家、非中立的敌对势力节点 (enemy_red / enemy_purple / enemy_green / enemy)
    for _, eNode in ipairs(nodes) do
        local fac = eNode.faction
        if fac ~= "player" and fac ~= "neutral" then

            -- 1. 活跃光轨动态监测与适时切断 (核心防死循环机制)
            if eNode.routeTo ~= nil then
                local targetNode = nodes[eNode.routeTo + 1]
                local shouldCut = false

                if targetNode then
                    if targetNode.faction == fac then
                        -- 目标为友军据点：
                        -- a) 目标守军充裕 (已达 14 粒) -> 增援任务圆满达成，立即切断，防止持续抽干源节点
                        -- b) 源节点自身兵力降至 8 粒 -> 保留自身驻防底线，停止无底洞抽血
                        -- c) 目标节点正向源节点反向输送 -> 严重对冲，立即切断
                        if targetNode.particles >= 14 or eNode.particles <= 8 or targetNode.routeTo == eNode.id then
                            shouldCut = true
                        end
                    else
                        -- 目标为敌方/中立据点：
                        -- a) 自身兵力消耗至危急水平 (< 5 粒) -> 进攻受挫，撤退固守
                        if eNode.particles < 5 then
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

            -- 2. 空闲节点决策与目标选择 (仅当 routeTo 为 nil 时执行)
            elseif eNode.particles >= 10 then
                local neighbors = StarMap.GetNeighbors(eNode.id)

                -- 2.1 战术互援判定 (严格前线受困条件，杜绝后方无意义对流)
                local needAlly = nil
                -- 只有当自身兵力充裕 (>= 16 粒) 且自身未面临直接受袭威胁时，才考虑增援邻近友军
                if eNode.particles >= 16 and not eNode.hasEnemyThreat then
                    for _, nId in ipairs(neighbors) do
                        local n = nodes[nId + 1]
                        if n and n.faction == fac and n.id ~= eNode.id then
                            -- 关键约束：
                            -- a) 友军不能已经在向我输送 (杜绝互援死锁)
                            -- b) 友军处于前线或面临敌情
                            -- c) 友军兵力确实不足 (< 8 粒)
                            if n.routeTo ~= eNode.id and n.particles < 8 and (n.hasEnemyThreat or HasHostileNeighbor(n, nodes, fac)) then
                                needAlly = n
                                break
                            end
                        end
                    end
                end

                if needAlly then
                    routeManager.SetRoute(eNode.id, needAlly.id, fac, nodes)
                else
                    -- 2.2 战线拓展与针对性进攻
                    local targets = {}
                    for _, nId in ipairs(neighbors) do
                        local n = nodes[nId + 1]
                        if n and n.faction ~= fac then
                            table.insert(targets, n)
                        end
                    end

                    if #targets > 0 then
                        -- 优先级：优先夺取中立薄弱灵穴，其次进攻弱势敌对/玩家据点
                        table.sort(targets, function(a, b)
                            if a.faction == "neutral" and b.faction ~= "neutral" then
                                return true
                            elseif a.faction ~= "neutral" and b.faction == "neutral" then
                                return false
                            else
                                return a.particles < b.particles
                            end
                        end)

                        local chosen = targets[1]
                        routeManager.SetRoute(eNode.id, chosen.id, fac, nodes)
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
-- 纯 Lua 几何视觉渲染器（光轨条带变换、共鸣环填充、固守结界与导引线绘制）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local VisualRenderer = {}

-- 动态绘制/变换单条线段条带控件 (使用 width = dist, height = thickness, pivot = (0, 0.5), rotationZ = angle)
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

-- 更新所有活跃光轨与拖拽连线
function VisualRenderer.UpdateRoutes(routeCtrls, routes, nodes, dragLineCtrl, inputState, elapsedTime)
    -- 1. 活跃光轨
    local activeCount = #routes
    local maxCtrls = #routeCtrls

    for i = 1, maxCtrls do
        local ctrl = routeCtrls[i]
        if ctrl and ctrl.alive then
            if i <= activeCount then
                local r = routes[i]
                local nA = nodes[r.fromId + 1]
                local nB = nodes[r.toId + 1]

                if nA and nB then
                    local col = Layout.GetFactionColor(r.faction)
                    local thickness = 4
                    -- 处于「疾风流道」(千风隘口) 或施加「千风湍流」符印：激活提瓦特千风翠绿粗流道特效 (10粒/秒高速流)
                    if nA.anomaly == "WIND_FLOW" or r.boostedUntil > elapsedTime then
                        col = Layout.PALETTE.ANEMO
                        thickness = 6
                    end
                    VisualRenderer.SetLineTransform(ctrl, nA.x, nA.y, nB.x, nB.y, thickness, col)
                else
                    Layout.SetVisible(ctrl, false)
                end
            else
                Layout.SetVisible(ctrl, false)
            end
        end
    end

    -- 2. 拖拽实时导引线
    if dragLineCtrl and dragLineCtrl.alive then
        if inputState.isDragging and inputState.dragSourceId ~= nil then
            local sourceNode = nodes[inputState.dragSourceId + 1]
            if sourceNode then
                VisualRenderer.SetLineTransform(
                    dragLineCtrl,
                    sourceNode.x, sourceNode.y,
                    inputState.dragCurrentX, inputState.dragCurrentY,
                    3,
                    Layout.PALETTE.GOLD
                )
            else
                Layout.SetVisible(dragLineCtrl, false)
            end
        else
            Layout.SetVisible(dragLineCtrl, false)
        end
    end
end

-- 更新地脉节点各层视觉呈现
function VisualRenderer.UpdateNodes(nodeUIList, nodes, elapsedTime)
    for i, node in ipairs(nodes) do
        local ui = nodeUIList[i]
        if ui then
            local factionColor = Layout.GetFactionColor(node.faction)

            -- 1. 固守结界环
            if ui.defenseRing and ui.defenseRing.alive then
                if node.isDefensive and node.routeTo == nil then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.GOLD_ALPHA
                elseif node.protectedUntil > elapsedTime then
                    Layout.SetVisible(ui.defenseRing, true)
                    ui.defenseRing.imageColor = Layout.PALETTE.ANEMO
                else
                    Layout.SetVisible(ui.defenseRing, false)
                end
            end

            -- 2. 节点主体共鸣外环 (使用 SetFillRadial360 或 fillAmount 呈现 0%~100% 进度)
            if ui.resonanceRing and ui.resonanceRing.alive then
                ui.resonanceRing.imageColor = factionColor
                local progress = Layout.Clamp(node.control / 100, 0.05, 1.0)
                if ui.resonanceRing.SetFillRadial360 then
                    pcall(function()
                        ui.resonanceRing:SetFillRadial360(Enum.ImageFillRadialType.Top, progress)
                    end)
                else
                    ui.resonanceRing.fillAmount = progress
                end
            end

            -- 3. 兵力数值显示 (双重保障：标题附加括号数值 + 兵力行独立高对比呈现)
            local currentParts = math.floor(node.particles or 0)
            if ui.titleText and ui.titleText.alive then
                ui.titleText.text = string.format("%s (%d)", node.name, currentParts)
                ui.titleText.fontColor = Layout.PALETTE.TEXT_LIGHT
                Layout.SetVisible(ui.titleText, true)
            end

            if ui.particleText and ui.particleText.alive then
                ui.particleText.text = string.format("兵力: %d", currentParts)
                ui.particleText.fontColor = factionColor
                Layout.SetVisible(ui.particleText, true)
            end

            -- 4. 异象标识文本
            if ui.anomalyText and ui.anomalyText.alive then
                if node.anomaly == "AMBER_MINE" then
                    ui.anomalyText.text = "【石珀晶矿】"
                    ui.anomalyText.fontColor = Layout.PALETTE.AMBER
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "WIND_FLOW" then
                    ui.anomalyText.text = "【疾风流道】"
                    ui.anomalyText.fontColor = Layout.PALETTE.ANEMO
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "MIST_RUINS" then
                    ui.anomalyText.text = "【迷雾荒墟】"
                    ui.anomalyText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "DEFENSE_BASTION" then
                    ui.anomalyText.text = "【雷暴要塞】"
                    ui.anomalyText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "PURE_WATER" then
                    ui.anomalyText.text = "【纯水枢纽】"
                    ui.anomalyText.fontColor = Layout.PALETTE.PLAYER
                    Layout.SetVisible(ui.anomalyText, true)
                elseif node.anomaly == "PLASMA" then
                    ui.anomalyText.text = "【赤阳熔核】"
                    ui.anomalyText.fontColor = Layout.PALETTE.ENEMY
                    Layout.SetVisible(ui.anomalyText, true)
                else
                    Layout.SetVisible(ui.anomalyText, false)
                end
            end

            -- 5. 占领进度与状态标签 (占领中/动摇中/输送中/固守中/休眠中)
            if ui.statusText and ui.statusText.alive then
                if node.faction == "neutral" and (node.control > 0 or (node.contenderParticles and node.contenderParticles > 0)) then
                    local fName = Layout.GetFactionName(node.contenderFaction)
                    local col = Layout.GetFactionColor(node.contenderFaction)
                    ui.statusText.text = string.format("[%s占领中 %d%%]", fName, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.faction ~= "neutral" and node.control < 100 then
                    local fName = Layout.GetFactionName(node.faction)
                    local col = Layout.GetFactionColor(node.faction)
                    ui.statusText.text = string.format("[%s动摇 %d%%]", fName, math.floor(node.control))
                    ui.statusText.fontColor = col
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isIdle then
                    ui.statusText.text = "[腹地休眠]"
                    ui.statusText.fontColor = Layout.PALETTE.TEXT_MUTED
                    Layout.SetVisible(ui.statusText, true)
                elseif node.isDefensive and node.routeTo == nil then
                    ui.statusText.text = "[驻阵固守]"
                    ui.statusText.fontColor = Layout.PALETTE.GOLD
                    Layout.SetVisible(ui.statusText, true)
                elseif node.routeTo ~= nil then
                    ui.statusText.text = "[输送中 ➔]"
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
    -- 1. 更新节点位置与可见性
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

    -- 2. 更新静态底轨连线
    if staticLinkCtrls and links then
        for i, linkCtrl in ipairs(staticLinkCtrls) do
            local link = links[i]
            if link and linkCtrl and linkCtrl.alive then
                local nA = nodes[link[1] + 1]
                local nB = nodes[link[2] + 1]
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
-- HUD 顶部掌控进度、倒计时、浮窗 Toast 播报与终局结算面板

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local HudView = {
    toastText = "",
    toastTimer = 0,
    isSettled = false,
    onRetry = nil
}

function HudView.Init(onRetryCallback)
    HudView.toastText = ""
    HudView.toastTimer = 0
    HudView.isSettled = false
    HudView.onRetry = onRetryCallback
end

function HudView.ShowToast(msg)
    HudView.toastText = msg or ""
    HudView.toastTimer = 2.5
end

function HudView.UpdateToast(dt, toastContainer, toastTextCtrl)
    if HudView.toastTimer > 0 then
        HudView.toastTimer = HudView.toastTimer - dt
        Layout.SetVisible(toastContainer, true)
        if toastTextCtrl and toastTextCtrl.alive then
            toastTextCtrl.text = HudView.toastText
        end
    else
        Layout.SetVisible(toastContainer, false)
    end
end

-- 更新顶部掌控条与计时
function HudView.UpdateTopBar(timeRemaining, nodes, playerPctCtrl, enemyPctCtrl, timerCtrl, barPlayerCtrl, barEnemyCtrl)
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
        playerPctCtrl.text = "我方掌控 " .. tostring(pPct) .. "%"
    end
    if enemyPctCtrl and enemyPctCtrl.alive then
        enemyPctCtrl.text = "敌方压制 " .. tostring(ePct) .. "%"
    end

    if barPlayerCtrl and barPlayerCtrl.alive then
        barPlayerCtrl.sizeDeltaX = math.max(10, math.floor(320 * (pPct / 100)))
    end
    if barEnemyCtrl and barEnemyCtrl.alive then
        barEnemyCtrl.sizeDeltaX = math.max(10, math.floor(320 * (ePct / 100)))
    end

    if timerCtrl and timerCtrl.alive then
        local t = math.max(0, math.floor(timeRemaining))
        local m = math.floor(t / 60)
        local s = t % 60
        timerCtrl.text = string.format("%02d:%02d", m, s)
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
        if isWin then
            titleCtrl.text = "【推衍大捷·全域共鸣】"
            titleCtrl.fontColor = Layout.PALETTE.PLAYER
        else
            titleCtrl.text = "【推衍中止·灵脉耗竭】"
            titleCtrl.fontColor = Layout.PALETTE.ENEMY
        end
    end

    if descCtrl and descCtrl.alive then
        if isWin then
            descCtrl.text = "星盘之理尽在掌控，地脉灵流归于统御。全域敌对势力已被彻底肃清！"
        else
            descCtrl.text = "地脉紊乱，推衍消散。我方灵穴已全部失守，请重新注灵推演。"
        end
    end

    if statsCtrl and statsCtrl.alive then
        statsCtrl.text = string.format("占领灵穴：%d/%d  |  存活兵力：%d  |  耗时：%s", pCount, #nodes, pParts, timeStr)
    end
end

-- 关卡特殊灵穴效果说明映射表
local ANOMALY_DESC_MAP = {
    WIND_FLOW = "● 疾风流道：地脉输送流速翻倍 (双倍流速)",
    AMBER_MINE = "● 石珀富矿：石珀滋养，微粒孕育速度翻倍",
    MIST_RUINS = "● 迷雾荒墟：迷雾遮蔽，微粒孕育速度减半",
    DEFENSE_BASTION = "● 雷暴要塞：雷暴灵障固守，战损减半",
    PURE_WATER = "● 纯水枢纽：纯水激荡，微粒孕育速度提升54%",
    PLASMA = "● 赤阳熔核：上限强制限25粒，极速绞肉战场"
}

-- 更新左上角关卡特殊灵穴说明与右上角战术操作说明
function HudView.UpdateStageInfo(chap, anomalyTitleCtrl, anomalyDescCtrl, guideTitleCtrl, guideDescCtrl)
    if guideTitleCtrl and guideTitleCtrl.alive then
        guideTitleCtrl.text = "【战术操作指引】"
    end
    if guideDescCtrl and guideDescCtrl.alive then
        guideDescCtrl.text = "● 连线：拖拽己方灵穴至相邻据点建立输送\n● 固守：轻点己方灵穴展开/收拢固守结界\n● 符印：点击下方符印后点击目标灵穴释放"
    end

    if anomalyTitleCtrl and anomalyTitleCtrl.alive then
        local stageTag = (chap and chap.title) and string.match(chap.title, "第 %d 关") or "战场"
        anomalyTitleCtrl.text = string.format("【%s · 地脉情报】", stageTag)
    end

    if anomalyDescCtrl and anomalyDescCtrl.alive then
        local lines = {}
        local seen = {}
        if chap and chap.nodes then
            for _, n in ipairs(chap.nodes) do
                if n.anomaly and n.anomaly ~= "NORMAL" and not seen[n.anomaly] then
                    seen[n.anomaly] = true
                    local desc = ANOMALY_DESC_MAP[n.anomaly]
                    if desc then
                        table.insert(lines, desc)
                    end
                end
            end
        end

        if #lines == 0 then
            anomalyDescCtrl.text = "● 标准地脉：常规孕育与输送，前线激战，后方休整\n● 固守结界：驻防灵穴战损削减30%"
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
        if countdownTextCtrl and countdownTextCtrl.alive then
            local countNum = math.ceil(timer)
            if countNum > 3 then countNum = 3 end
            countdownTextCtrl.text = tostring(countNum)
            countdownTextCtrl.fontColor = Layout.PALETTE.GOLD
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            if timer > 2.0 then
                countdownSubCtrl.text = "全域地脉连接调配完成..."
            elseif timer > 1.0 then
                countdownSubCtrl.text = "星轨推衍回路展开中..."
            else
                countdownSubCtrl.text = "元素微粒正在凝聚！"
            end
        end
    elseif timer > -0.6 then
        Layout.SetVisible(countdownModal, true)
        if countdownTextCtrl and countdownTextCtrl.alive then
            countdownTextCtrl.text = "开始！"
            countdownTextCtrl.fontColor = Layout.PALETTE.PLAYER
        end
        if countdownSubCtrl and countdownSubCtrl.alive then
            countdownSubCtrl.text = "执掌星轨，克敌制胜！"
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
    onStartStage = nil,
    onBack = nil
}

function ChapterSelectView.Init(onStartStageCb, onBackCb)
    ChapterSelectView.onStartStage = onStartStageCb
    ChapterSelectView.onBack = onBackCb
end

function ChapterSelectView.UnlockNextStage(completedStage)
    if completedStage and completedStage >= ChapterSelectView.unlockedStage then
        ChapterSelectView.unlockedStage = math.min(5, completedStage + 1)
    end
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

-- UI 控件绑定容器
local UI = {
    root           = nil,
    cursorArea     = nil,
    dragLine       = nil,
    routeCtrls     = {},
    staticLinkCtrls= {},
    particleCtrls  = {},
    nodeUIList     = {},
    cardSlots      = {},

    -- 模式选择弹窗
    modeSelectModal  = nil,
    modeStoryBtn     = nil,
    modeChallengeBtn = nil,

    -- 章节选择弹窗
    chapterSelectModal = nil,
    chapterCards       = {},
    chapDesc           = nil,
    chapTitle          = nil,
    chapStartBtn       = nil,
    chapStartTxt       = nil,
    chapBackBtn        = nil,

    -- 顶部 HUD
    playerPctText  = nil,
    enemyPctText   = nil,
    timerText      = nil,
    barPlayer      = nil,
    barEnemy       = nil,
    toastContainer = nil,
    toastText      = nil,

    -- 战前3秒倒计时
    countdownModal = nil,
    countdownText  = nil,
    countdownSub   = nil,

    -- 左上角特殊灵穴说明与右上角操作说明
    hudAnomalyBox  = nil,
    hudAnomalyTitle= nil,
    hudAnomalyDesc = nil,
    hudGuideBox    = nil,
    hudGuideTitle  = nil,
    hudGuideDesc   = nil,

    -- 剧情弹窗
    dialogueModal  = nil,
    dlgSpeaker     = nil,
    dlgContent     = nil,
    dlgSkipBtn     = nil,
    dlgNextBtn     = nil,

    -- 战前构筑弹窗
    prepareModal   = nil,
    prepBudgetText = nil,
    prepHint       = nil,
    prepTitle      = nil,
    prepStartBtn   = nil,
    prepCards      = {},

    -- 结算弹窗
    settleModal    = nil,
    settleTitle    = nil,
    settleDesc     = nil,
    settleStats    = nil,
    settleNextBtn  = nil,
    settleRetryBtn = nil,
    settleChapBtn  = nil
}

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
        BalanceConfig.PlayAudioSafe("MATCH_WIN")
        HudView.ShowSettlement(true, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    elseif pNodes == 0 and inFlightPlayer == 0 then
        -- 玩家兵力全军覆没
        gameState.isGameOver = true
        gameState.currentState = STATE_SETTLEMENT
        VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
        Runtime.HideAllParticles()
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
        if isWin then
            ChapterSelectView.UnlockNextStage(StarMap.currentStage)
            BalanceConfig.PlayAudioSafe("MATCH_WIN")
        else
            BalanceConfig.PlayAudioSafe("MATCH_LOSE")
        end
        HudView.ShowSettlement(isWin, gameState.nodes, gameState.elapsedTime, UI.settleModal, UI.settleTitle, UI.settleDesc, UI.settleStats, UI.settleNextBtn)
    end
end

-- 深度递归查找指定名称的子控件
local function FindDeepChild(parent, name)
    if not parent or not parent.alive then return nil end
    local direct = parent:FindChild(name)
    if direct then return direct end
    local children = parent:GetChildren()
    if children then
        for _, child in ipairs(children) do
            local found = FindDeepChild(child, name)
            if found then return found end
        end
    end
    return nil
end

-- 缓存控件树引用
local function CacheUIControls()
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
    UI.root = root

    -- 全局检测层与拖拽导引线
    UI.cursorArea = FindDeepChild(root, "GlobalCursorArea")
    UI.dragLine   = FindDeepChild(root, "DragLine")

    -- 模式选择弹窗
    UI.modeSelectModal  = FindDeepChild(root, "ModeSelectModal")
    if UI.modeSelectModal then
        UI.modeStoryBtn     = FindDeepChild(UI.modeSelectModal, "ModeStoryBtn")
        UI.modeChallengeBtn = FindDeepChild(UI.modeSelectModal, "ModeChallengeBtn")
    end

    -- 关卡章节选择弹窗
    UI.chapterSelectModal = FindDeepChild(root, "ChapterSelectModal")
    UI.chapterCards = {}
    if UI.chapterSelectModal then
        UI.chapDesc     = FindDeepChild(UI.chapterSelectModal, "ChapterDesc")
        UI.chapTitle    = FindDeepChild(UI.chapterSelectModal, "ChapterTitle")
        UI.chapStartBtn = FindDeepChild(UI.chapterSelectModal, "ChapterStartBtn")
        if UI.chapStartBtn then
            UI.chapStartTxt = FindDeepChild(UI.chapStartBtn, "Text")
        end
        UI.chapBackBtn  = FindDeepChild(UI.chapterSelectModal, "ChapterBackBtn")

        for idx = 1, 5 do
            local cardBtn = FindDeepChild(UI.chapterSelectModal, "ChapterCard_" .. idx)
            if cardBtn then
                table.insert(UI.chapterCards, {
                    button     = cardBtn,
                    tagCtrl    = FindDeepChild(cardBtn, "TagText"),
                    infoCtrl   = FindDeepChild(cardBtn, "InfoText"),
                    budgetCtrl = FindDeepChild(cardBtn, "BudgetText"),
                    titleCtrl  = FindDeepChild(cardBtn, "TitleText"),
                    bgCtrl     = FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 光轨条带池与静态连线池
    UI.routeCtrls = {}
    UI.staticLinkCtrls = {}
    UI.linksLayer = FindDeepChild(root, "LinksLayer")
    if UI.linksLayer then
        for i = 1, 25 do
            local line = FindDeepChild(UI.linksLayer, "RouteLine_" .. i)
            if line then table.insert(UI.routeCtrls, line) end
        end
        for i = 0, 44 do
            local sLine = FindDeepChild(UI.linksLayer, "StaticLink_" .. i)
            if sLine then table.insert(UI.staticLinkCtrls, sLine) end
        end
    end

    -- 微粒对象池 (120个)
    UI.particleCtrls = {}
    UI.particlesLayer = FindDeepChild(root, "ParticlesLayer")
    if UI.particlesLayer then
        for i = 1, 120 do
            local p = FindDeepChild(UI.particlesLayer, "P_" .. i)
            if p then table.insert(UI.particleCtrls, p) end
        end
    end
    Runtime.InitParticlePool(UI.particleCtrls)

    -- 18 座地脉灵穴 UI 组
    UI.nodeUIList = {}
    UI.nodesLayer = FindDeepChild(root, "NodesLayer")
    if UI.nodesLayer then
        for i = 0, 17 do
            local grp = FindDeepChild(UI.nodesLayer, "NodeGroup_" .. i)
            if grp then
                table.insert(UI.nodeUIList, {
                    group        = grp,
                    defenseRing  = FindDeepChild(grp, "DefenseRing"),
                    baseDisc     = FindDeepChild(grp, "BaseDisc"),
                    resonanceRing= FindDeepChild(grp, "ResonanceRing"),
                    titleText    = FindDeepChild(grp, "TitleText"),
                    particleText = FindDeepChild(grp, "ParticleText"),
                    anomalyText  = FindDeepChild(grp, "AnomalyText"),
                    statusText   = FindDeepChild(grp, "StatusText")
                })
            end
        end
    end

    -- 顶部 HUD
    UI.hudLayer = FindDeepChild(root, "HudLayer")
    local hud = UI.hudLayer
    if hud then
        UI.playerPctText  = FindDeepChild(hud, "HudPlayerPct")
        UI.enemyPctText   = FindDeepChild(hud, "HudEnemyPct")
        UI.timerText      = FindDeepChild(hud, "HudTimer")
        UI.barPlayer      = FindDeepChild(hud, "BarPlayer")
        UI.barEnemy       = FindDeepChild(hud, "BarEnemy")
        UI.toastContainer = FindDeepChild(root, "ToastContainer")
        if UI.toastContainer then
            UI.toastText  = FindDeepChild(UI.toastContainer, "ToastText")
        end

        -- 战前3秒倒计时弹窗
        UI.countdownModal = FindDeepChild(root, "CountdownModal")
        if UI.countdownModal then
            UI.countdownText = FindDeepChild(UI.countdownModal, "CountdownText")
            UI.countdownSub  = FindDeepChild(UI.countdownModal, "CountdownSub")
        end

        -- 左上角特殊灵穴说明与右上角操作指引
        UI.hudAnomalyBox   = FindDeepChild(hud, "HudAnomalyBox")
        if UI.hudAnomalyBox then
            UI.hudAnomalyTitle = FindDeepChild(UI.hudAnomalyBox, "AnomalyTitle")
            UI.hudAnomalyDesc  = FindDeepChild(UI.hudAnomalyBox, "AnomalyDesc")
        end
        UI.hudGuideBox     = FindDeepChild(hud, "HudGuideBox")
        if UI.hudGuideBox then
            UI.hudGuideTitle   = FindDeepChild(UI.hudGuideBox, "GuideTitle")
            UI.hudGuideDesc    = FindDeepChild(UI.hudGuideBox, "GuideDesc")
        end

        UI.cardSlots = {}
        for j = 1, 4 do
            local slotGrp = FindDeepChild(hud, "CardSlot_" .. j)
            if slotGrp then
                table.insert(UI.cardSlots, {
                    container  = slotGrp,
                    borderCtrl = FindDeepChild(slotGrp, "Border"),
                    nameCtrl   = FindDeepChild(slotGrp, "NameText"),
                    costCtrl   = FindDeepChild(slotGrp, "CostText"),
                    maskCtrl   = FindDeepChild(slotGrp, "CdMask"),
                    cdTextCtrl = FindDeepChild(slotGrp, "CdText")
                })
            end
        end
    end

    -- 剧情弹窗
    UI.dialogueModal = FindDeepChild(root, "DialogueModal")
    if UI.dialogueModal then
        UI.dlgSpeaker = FindDeepChild(UI.dialogueModal, "DlgSpeaker")
        UI.dlgContent = FindDeepChild(UI.dialogueModal, "DlgContent")
        UI.dlgSkipBtn = FindDeepChild(UI.dialogueModal, "DlgSkipBtn")
        UI.dlgNextBtn = FindDeepChild(UI.dialogueModal, "DlgNextBtn")
    end

    -- 战前调配弹窗
    UI.prepareModal = FindDeepChild(root, "PrepareModal")
    UI.prepCards = {}
    if UI.prepareModal then
        UI.prepBudgetText = FindDeepChild(UI.prepareModal, "PrepBudgetText")
        UI.prepHint       = FindDeepChild(UI.prepareModal, "PrepHint")
        UI.prepTitle      = FindDeepChild(UI.prepareModal, "PrepTitle")
        UI.prepStartBtn   = FindDeepChild(UI.prepareModal, "PrepStartBtn")
        for k = 1, 6 do
            local cardBtn = FindDeepChild(UI.prepareModal, "PrepCard_" .. k)
            if cardBtn then
                table.insert(UI.prepCards, {
                    button     = cardBtn,
                    checkCtrl  = FindDeepChild(cardBtn, "CheckTag"),
                    costCtrl   = FindDeepChild(cardBtn, "CostText"),
                    descCtrl   = FindDeepChild(cardBtn, "DescText"),
                    nameCtrl   = FindDeepChild(cardBtn, "NameText"),
                    bgCtrl     = FindDeepChild(cardBtn, "CardBg"),
                    borderCtrl = FindDeepChild(cardBtn, "CardBorder")
                })
            end
        end
    end

    -- 结算弹窗
    UI.settleModal = FindDeepChild(root, "SettleModal")
    if UI.settleModal then
        UI.settleTitle    = FindDeepChild(UI.settleModal, "SettleTitle")
        UI.settleDesc     = FindDeepChild(UI.settleModal, "SettleDesc")
        UI.settleStats    = FindDeepChild(UI.settleModal, "SettleStats")
        UI.settleNextBtn  = FindDeepChild(UI.settleModal, "SettleNextBtn")
        UI.settleRetryBtn = FindDeepChild(UI.settleModal, "SettleRetryBtn")
        UI.settleChapBtn  = FindDeepChild(UI.settleModal, "SettleChapterBtn")
    end
end

-- 控制战斗核心层（灵穴、光轨、微粒、HUD）的可见性
local function SetGameplayLayersVisible(visible)
    Layout.SetVisible(UI.nodesLayer, visible)
    Layout.SetVisible(UI.linksLayer, visible)
    Layout.SetVisible(UI.particlesLayer, visible)
    Layout.SetVisible(UI.hudLayer, visible)
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

    -- 隐藏其他面板，进入战前剧情
    Layout.SetVisible(UI.modeSelectModal, false)
    Layout.SetVisible(UI.chapterSelectModal, false)
    Layout.SetVisible(UI.settleModal, false)
    Layout.SetVisible(UI.prepareModal, false)
    Layout.SetVisible(UI.countdownModal, false)

    -- 1. 剧情演播
    DialoguePlayer.Init(chap.dialogues, function()
        print("[Starlink] 章节剧情完毕，进入战前符印调配...")
        Layout.SetVisible(UI.dialogueModal, false)
        Layout.SetVisible(UI.prepareModal, true)
        gameState.currentState = STATE_PREPARE

        -- 2. 调配面板初始化 (动态预算)
        PrepareView.Init(chap.budget, function(selectedDeck)
            print("[Starlink] 战前符印装配完成，进入战前 3 秒倒计时...")
            AbilitySystem.InitDeck(selectedDeck)
            Layout.SetVisible(UI.prepareModal, false)
            SetGameplayLayersVisible(true)

            -- 刷新左上角特殊灵穴说明与右上角战术操作指引
            HudView.UpdateStageInfo(chap, UI.hudAnomalyTitle, UI.hudAnomalyDesc, UI.hudGuideTitle, UI.hudGuideDesc)

            -- 启动 3 秒倒计时 (3、2、1、开始)
            gameState.countdownTimer = 3.6
            gameState.currentState = STATE_COUNTDOWN
            Layout.SetVisible(UI.countdownModal, true)
            BalanceConfig.PlayAudioSafe("UI_CLICK")
        end)
        PrepareView.Render(UI.prepCards, UI.prepBudgetText, UI.prepHint)
    end)

    gameState.currentState = STATE_DIALOGUE
    Layout.SetVisible(UI.dialogueModal, true)
end

-- 注册全屏与各面板交互监听
local function SetupEventHandlers()
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
        UI.modeChallengeBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            print("[Starlink] 玩家点击【挑战模式】（筹备中提示）...")
            HudView.ShowToast("【挑战模式】正在筹备中，敬请期待！")
        end)
    end

    -- 4. 章节选择按钮监听
    for idx, cardUI in ipairs(UI.chapterCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
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
        UI.chapStartBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            StartStage(ChapterSelectView.selectedStage)
        end)
    end

    if UI.chapBackBtn and UI.chapBackBtn.AddCursorEventListener then
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
        UI.dlgNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Next()
        end)
    end
    if UI.dlgSkipBtn and UI.dlgSkipBtn.AddCursorEventListener then
        UI.dlgSkipBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            DialoguePlayer.Skip()
        end)
    end

    -- 6. 战前调配卡牌点击选择
    for idx, cardUI in ipairs(UI.prepCards) do
        if cardUI.button and cardUI.button.AddCursorEventListener then
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

    -- 8. 结算弹窗按钮
    -- 进军下一关
    if UI.settleNextBtn and UI.settleNextBtn.AddCursorEventListener then
        UI.settleNextBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
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
        UI.settleRetryBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            print(string.format("[Starlink] 重新演练当前关卡: 第 %d 关...", StarMap.currentStage))
            StartStage(StarMap.currentStage)
        end)
    end

    -- 返回章节选择
    if UI.settleChapBtn and UI.settleChapBtn.AddCursorEventListener then
        UI.settleChapBtn:AddCursorEventListener(Enum.CursorEventType.CursorClick, function()
            BalanceConfig.PlayAudioSafe("UI_CLICK")
            VisualRenderer.HideAllRoutes(UI.routeCtrls, UI.dragLine)
            Runtime.HideAllParticles()
            Layout.SetVisible(UI.settleModal, false)
            Layout.SetVisible(UI.chapterSelectModal, true)
            SetGameplayLayersVisible(false)
            gameState.currentState = STATE_CHAPTER_SELECT
            ChapterSelectView.Render(UI.chapterCards, UI.chapDesc, UI.chapStartTxt)
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
            BalanceConfig.PlayAudioSafe("MATCH_WIN")
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
                        CheckMatchEnd()
                    end,
                    function(lostNode)
                        HudView.ShowToast(string.format("【%s】统治动摇，已沦为中立争夺！", lostNode.name))
                    end
                )
            end
        end

        -- 3. 物流发射与微粒流动
        RouteManager.Update(dt, gameState.nodes, gameState.elapsedTime, function(hitNode)
            CombatResolver.AddSpark(hitNode.x, hitNode.y)
        end)

        -- 4. 战火与威胁判定
        CombatResolver.Update(dt, gameState.nodes, RouteManager.movingParticles)

        -- 5. 敌方 AI 推进 (多阵营全员大乱斗)
        FactionAI.Update(dt, gameState.nodes, RouteManager)

        -- 6. 符印冷却计时
        AbilitySystem.UpdateCooldowns(dt)

        -- 7. 纯代码视觉渲染刷新
        Runtime.UpdateParticles(RouteManager.movingParticles, Layout.GetFactionColor)
        VisualRenderer.UpdateRoutes(UI.routeCtrls, RouteManager.routes, gameState.nodes, UI.dragLine, Input, gameState.elapsedTime)
        VisualRenderer.UpdateNodes(UI.nodeUIList, gameState.nodes, gameState.elapsedTime)
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

