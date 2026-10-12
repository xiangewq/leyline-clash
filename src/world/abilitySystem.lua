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
