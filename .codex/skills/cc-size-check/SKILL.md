---
name: size-check
description: 代码简化与复杂度审查工作流，适用于显式简化代码、检查文件体量或识别过度抽象的场景；不负责安全审查或 bug 修复流程。
---

# Size Check

当用户明确要求简化代码、检查文件大小、识别复杂度或寻找重构候选时，使用本技能。

不要用于：

- 普通功能实现
- 正式安全审查
- bug 修复
- 语言细节规范

## 核心方式

1. 先看是否存在明显的重复、冗余或过度抽象。
2. 再看文件或模块体量是否已经影响可读性和维护性。
3. 输出问题、原因和建议，不把所有超阈值都机械转成必须重构。

## 按需展开

- 体量启发式：`references/size-heuristics.md`
- 简化信号：`references/simplification-signals.md`
- 可接受复杂度：`references/acceptable-complexity.md`
