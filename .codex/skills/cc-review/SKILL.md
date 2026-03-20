---
name: cc-review
description: 结构化代码审查工作流，适用于显式 quick/full/security review；不负责普通实现或 bug 修复流程。
---

# CC Review

当用户明确要求 review、quick review 或 security review 时，使用本技能。

不要用于：

- 普通编码实现
- 直接 bug 修复
- 语言细节规范
- 环境级风险判断

## 审查模式

### Quick Review

面向当前 diff 或最可能的回归点，快速给出高价值反馈。

### Full Review

围绕受影响调用链、输入输出契约和回归面做更完整的审查。

### Security Review

重点检查认证授权、输入校验、命令执行、数据暴露和权限边界。

## 默认优先级

1. 错误行为和明显 bug
2. 回归风险
3. 缺失校验或错误处理
4. 安全问题
5. 缺失或薄弱测试
6. 可维护性问题

## 输出要求

- findings 优先，按严重度排序。
- 尽量带精确文件引用。
- 总结保持简短，放在 findings 之后。
- 若没有发现问题，要明确写出，并说明残余风险或验证盲区。

## 按需展开

- 审查优先级：`references/review-priority.md`
- Quick Review：`references/quick-review.md`
- Full Review：`references/full-review.md`
- Security Review：`references/security-review.md`
