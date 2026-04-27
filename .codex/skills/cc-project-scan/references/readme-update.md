# README Update

`project-scan` 负责生成或刷新项目级 `README.md`。处理时按以下顺序执行：

1. 读取现有 `README.md`、`AGENTS.md`、`.claude/CLAUDE.md` 和技术栈信号文件。
2. 区分扫描事实与推断；无法确认的启动方式、端口、部署方式、许可证和项目描述必须标注“待确认”。
3. 若 `README.md` 不存在，生成最小可用 README，包含项目概述、技术栈、目录结构、快速开始、配置说明和许可证。
4. 若 `README.md` 已存在且包含 `<!-- AUTO:* -->` 区块，只更新自动区块，保留手写内容。
5. 若 `README.md` 已存在但没有自动区块，先让用户选择：追加自动区块、首次全量重建或跳过。
6. 不为追求完整而编造命令；无法从仓库确认时写“待确认”。

推荐自动区块：

- `<!-- AUTO:tech-stack -->`：技术栈表格
- `<!-- AUTO:directory -->`：主要目录结构
- `<!-- AUTO:quick-start -->`：启动与访问方式
- `<!-- AUTO:docker -->`：Docker 部署方式（仅仓库已有 Docker 相关文件时生成）

最小 README 结构：

~~~markdown
# [项目名称]

作者：wwj

## 项目概述

[项目描述；无法确认时写“待确认”]

<!-- AUTO:tech-stack -->
## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 后端 | 待确认 | 待确认 |
<!-- /AUTO:tech-stack -->

<!-- AUTO:directory -->
## 目录结构

```text
[项目名]/
└── ...
```
<!-- /AUTO:directory -->

<!-- AUTO:quick-start -->
## 快速开始

- 启动方式：待确认
- 访问地址：待确认
<!-- /AUTO:quick-start -->

## 许可证

待确认
~~~
