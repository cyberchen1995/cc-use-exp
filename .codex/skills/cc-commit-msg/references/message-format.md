# Message Format

默认检查顺序：

1. `git diff --cached --stat`
2. `git diff --cached`
3. 用户明确要求 `all` 时，再看 `git diff --stat` 和 `git diff`

输出结构：

```markdown
## 建议的 Commit Message

<type>: <subject>

- 变更点 1
- 变更点 2

## 变更文件

| 文件 | 说明 |
|------|------|
| path/to/file | 核心改动 |
```

约束：

- `subject` 保持单一主题
- `body` 只写用户真正关心的行为变化
- 如果 staged 为空且用户也没要求 `all`，先明确说明输入为空
