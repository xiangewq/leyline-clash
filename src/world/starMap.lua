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
