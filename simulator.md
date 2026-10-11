# 千星沙箱 2D+Lua 模拟器操作指南

你拥有千星沙箱模拟器（qxqy\_simulator）mcp工具集，用于脱机开发、调试千星沙箱 2D UI 控件与客户端 Lua 脚本。请严格遵守以下 SOP 进行操作：

## 1\. 核心闭环工作流

在开发或修改游戏时，你必须按以下时序闭环执行：

1. **打开工程**：
调用 `qxqy\_project\_open({ path: "game.save.json" })`，获取操作句柄 `handle`（如 `"project-1"`）。
2. **获取当前状态**：
调用 `qxqy\_studio\_get({ handle: "project-1" })`，获取控件树、Lua 脚本列表及当前版本号 `revision`。
3. **原子修改（带版本锁）**：
调用 `qxqy\_studio\_patch({ handle: "project-1", op: { op: "set", ..., expectedRevision: N } })`。

   * ⚠️ 必须传入上一步读取的 `expectedRevision`，若发生 revision 冲突需重新 get。
4. **运行沙箱仿真**：

   * 启动：`qxqy\_studio\_play({ handle: "project-1", action: "start" })`
   * 时钟步进：`qxqy\_studio\_play({ handle: "project-1", action: "step", args: { dt: 1 } })`
   * 模拟点击测试：`qxqy\_studio\_play({ handle: "project-1", action: "pointer", args: { type: "click", x: 800, y: 450 } })`
5. **多模态视觉验收（最关键）**：

   * 运行画面截图：调用 `qxqy\_studio\_play\_screenshot({ handle: "project-1" })`
   * UI 编辑态截图：调用 `qxqy\_studio\_ui\_screenshot({ handle: "project-1" })`
   * ⚠️ **根据返回的真实 PNG 截图进行视觉检查**：确认文本无溢出、按钮未重叠、布局在所选分辨率下美观。
6. **保存工程**：
验证无误后调用 `qxqy\_project\_save({ handle: "project-1", path: "game.save.json" })` 存盘。

## 2\. 与知识库（Miliastra-toolbox）配合规则

* 遇到不清楚的千星客户端 Lua API（如 `game.GetClientUIControl`、`GetUICanvasSize`）或控件属性时，**先通过知识库 HTTP API 查阅文档**：
`POST http://10.100.200.19:8000/api/v1/skills/miliastra-knowledge/tools/get\_client\_document`
* 查阅确认语法后，再通过模拟器进行实装与验证，严禁凭空捏造不存在的 Lua API。

