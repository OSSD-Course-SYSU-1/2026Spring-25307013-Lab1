```markdown
# AGENTS.md

本项目是 HarmonyOS / ArkTS / DevEco Studio 便签 App 课程项目。

## 工作原则

1. 每次只完成用户指定的小任务。
2. 不要全仓库扫描，除非用户明确要求。
3. 优先阅读：
   - `README_DEVLOG.md`
   - `analysis/project_overview.md`
   - 与本次任务直接相关的文件
4. 修改前只给简短计划，不写长篇分析。
5. 修改后只更新：
   - `analysis/change_log.md`
   - 必要时更新 `README_DEVLOG.md`
6. 不要重复生成已有文档。
7. 不要大规模重构。
8. 无法验证时明确写“未验证”。

## 常用验证

- 优先检查修改文件的语法和引用关系。
- 能运行时再执行 build。
- 不能运行 DevEco Studio 时，不要声称已通过真机/模拟器验证。

## 日志要求

每次任务结束后，在 `analysis/change_log.md` 追加：

- 任务目标
- 修改文件
- 修改原因
- 验证情况
如果涉及构建、运行、报错或验证，还必须追加更新 `analysis/solve_logs.md`。无法实际运行时要明确写“未验证，由用户在 DevEco Studio 中验证”。
- 后续建议xxxxxxxxxx ## YYYY-MM-DD HH:mm - 任务名称### 修改目标说明本次要解决什么问题。### 修改文件- `path/to/file.ets`：说明修改内容- `path/to/file.ts`：说明修改内容### 修改原因说明为什么这样改。### 验证方式说明是否执行了 build、preview、真机/模拟器运行。### 当前状态说明成功、部分成功或失败。### 后续建议说明下一步可以继续做什么。markdown
```
