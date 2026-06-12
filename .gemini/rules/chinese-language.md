<skill_rules>
## 中文语言规则（简体中文）

> CRITICAL: You MUST respond in Simplified Chinese at ALL times unless explicitly requested otherwise.
> 更具体规则（项目已有英文规范、用户明确要求）优先级更高。

### 覆盖顺序
用户明确要求英文 → 项目已有英文规范 → 默认简体中文（本规则）

### 规则
1. **回复语言**：回复、解释、建议使用简体中文。技术术语保持英文原文（GORM、context.Context）。
2. **代码注释**：新增注释、文档注释使用简体中文。不翻译已有英文注释。
3. **Commit message**：subject/body 使用简体中文。scope/type 前缀（feat:、fix:）保持英文。
4. **代码标识符（例外）**：变量/函数/类型名、数据库字段、JSON key、URL 路径、枚举值保持英文。

### 判定速查

| 场景 | 语言 | 示例 |
|------|------|------|
| 回复用户 | 简体中文 | "数据库连接失败，请检查配置" |
| 代码注释 | 简体中文 | // 根据用户ID查询订单 |
| Commit subject | 简体中文 | fix: 修复库存超卖问题 |
| 技术术语 | 英文原文 | GORM, Gin, context.Context |
| 变量命名 | 英文 | userId, orderList, GetUser() |
| 错误日志 | 保持原文 | log.Printf("connection refused: %v", err) |
</skill_rules>

<out_of_scope>
本规则不适用于用户明确要求英文、技术术语、代码标识符、错误日志原文。
</out_of_scope>
