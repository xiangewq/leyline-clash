-- src/world/starMap.lua
-- 提瓦特五灵穴沙盘拓扑、连通性矩阵与几何规格

local StarMap = {
    -- 基础 5 节点规格
    NODES_DEF = {
        {
            id = 0,
            name = "西风枢纽",
            x = 320,
            y = 450,
            radius = 54,
            faction = "player",
            particles = 25,
            control = 100,
            anomaly = "NORMAL",
            desc = "蒙德前哨枢纽"
        },
        {
            id = 1,
            name = "石珀晶矿",
            x = 650,
            y = 280,
            radius = 46,
            faction = "neutral",
            particles = 10,
            control = 0,
            anomaly = "AMBER_MINE",
            desc = "石珀富矿（产能翻倍）"
        },
        {
            id = 2,
            name = "千风隘口",
            x = 800,
            y = 520,
            radius = 48,
            faction = "neutral",
            particles = 15,
            control = 0,
            anomaly = "WIND_FLOW",
            desc = "千风汇聚（输送翻倍）"
        },
        {
            id = 3,
            name = "迷雾荒墟",
            x = 950,
            y = 300,
            radius = 44,
            faction = "neutral",
            particles = 8,
            control = 0,
            anomaly = "MIST_RUINS",
            desc = "迷雾缓冲（产能减半）"
        },
        {
            id = 4,
            name = "愚人坚垒",
            x = 1280,
            y = 450,
            radius = 54,
            faction = "enemy",
            particles = 25,
            control = 100,
            anomaly = "NORMAL",
            desc = "敌对推衍要塞"
        }
    },

    -- 拓扑连线 (无交叉网络)
    LINKS = {
        { 0, 1 },
        { 0, 2 },
        { 1, 2 },
        { 1, 3 },
        { 2, 3 },
        { 2, 4 },
        { 3, 4 }
    }
}

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

return StarMap
