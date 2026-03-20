---
name: cc-java-dev
description: Java 与 Spring 开发规范，适用于异常处理、集合、并发、服务分层和测试；不负责 review、debug 或运维流程。
---

# CC Java Dev

在编辑或审查 Java、Spring 代码时使用本技能，重点处理分层、异常、集合、并发和测试。

不要用于：

- 正式 review 或 fix/debug 工作流
- 运维风险判断
- 语言无关的通用边界控制

## 核心规则

- 代码结构优先清晰、职责单一。
- 异常处理要保留业务语义和上下文。
- 集合和对象的可变性要明确。
- 并发代码要显式管理线程池和共享状态。
- 测试优先覆盖行为和边界分支。

## 按需展开

- 风格：`references/style.md`
- Spring：`references/spring.md`
- 异常：`references/exceptions.md`
- 集合：`references/collections.md`
- 并发：`references/concurrency.md`
- 测试：`references/testing.md`
