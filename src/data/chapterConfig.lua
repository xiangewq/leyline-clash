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
                { id = 0, name = "西风前哨", x = 260, y = 450, radius = 42, faction = "player", particles = 22, control = 100, anomaly = "NORMAL", desc = "我方西风骑士前哨" },
                { id = 1, name = "清泉北陵", x = 520, y = 580, radius = 36, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "北侧灵泉高地" },
                { id = 2, name = "泉水祭坛", x = 800, y = 620, radius = 38, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "清泉古祭坛" },
                { id = 3, name = "晨曦峡口", x = 1080, y = 580, radius = 36, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "近酒庄险隘" },
                { id = 4, name = "清泉主脉", x = 620, y = 450, radius = 38, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "清泉核心灵脉" },
                { id = 5, name = "奔狼前驿", x = 980, y = 450, radius = 38, faction = "neutral", particles = 14, control = 0, anomaly = "NORMAL", desc = "中路枢纽要道" },
                { id = 6, name = "清泉南溪", x = 520, y = 320, radius = 36, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "南侧支流草甸" },
                { id = 7, name = "杜拉夫猎场", x = 800, y = 280, radius = 38, faction = "neutral", particles = 12, control = 0, anomaly = "NORMAL", desc = "猎人歇脚营地" },
                { id = 8, name = "达达乌帕口", x = 1080, y = 320, radius = 36, faction = "neutral", particles = 10, control = 0, anomaly = "NORMAL", desc = "近部落前沿" },
                { id = 9, name = "愚人驻地", x = 1340, y = 450, radius = 42, faction = "enemy_red", particles = 22, control = 100, anomaly = "NORMAL", desc = "愚人众前线营地" }
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
                { id = 0, name = "西风水港", x = 200, y = 450, radius = 36, faction = "player", particles = 24, control = 100, anomaly = "NORMAL", desc = "我方西港母基" },
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
                { id = 0, name = "西风终焉", x = 190, y = 220, radius = 35, faction = "player", particles = 26, control = 100, anomaly = "NORMAL", desc = "我方西南极境大营" },
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
