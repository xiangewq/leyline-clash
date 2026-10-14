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
            desc = "加持己方星枢，20秒内免疫任何敌方侵蚀，本土共鸣恢复翻倍。",
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
            desc = "炽火灼烧敌脉，瞬间消灭目标敌方星枢上 40% 的驻留微粒并切断输出！",
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
            desc = "激发生发之风，30秒内从该星枢出发的光轨流速翻倍至10粒/秒。",
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
            desc = "引动燃素轰爆，瞬间消灭目标敌方星枢上 80% 的驻留微粒！",
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
            desc = "水之契约与摩拉通神：中立星枢直接秒占100%；敌方星枢削减65%共鸣。",
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
