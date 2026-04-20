---
applyTo: "**/*.java,**/pom.xml,**/build.gradle,**/build.gradle.kts"
---

Java 相关任务遵守以下约定：

- 包名全小写，类名大驼峰，方法名小驼峰。
- 优先保持现有分层与已有模式，避免无证据重构。
- DTO / VO / Request / Response 类优先复用项目现有 Lombok 模式。
- 新增 Java 文件，或按现有风格补齐文件头注释时，统一使用 `@author wwj`。
- 优先补齐真实边界处理、异常上下文和最小必要验证。
