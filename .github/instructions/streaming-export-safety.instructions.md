---
applyTo: "**"
---

# 流式导出 / 大对象内存安全

> 完整规范见 `.claude/skills/streaming-export-safety/`，本文件是 Copilot 仓库级精简版。

数据量超过 1 万行 / 10 MB 时必须切换为流式 API，否则 OOM、Full GC、HTTP 超时、临时文件残留。

## 决策

| 数据量 | 模式 |
|--------|------|
| ≤ 1 万行 / ≤ 5 MB | 内存构建 OK |
| 1 万 ~ 10 万行 | 强烈建议流式 |
| > 10 万行 / > 50 MB | 必须流式 + 异步 |
| 未知量 | 必须流式 + 上限保护 |

## 5 类必须流式的场景

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| Excel | `new XSSFWorkbook()` 全量循环 | POI `SXSSFWorkbook(100)` + `dispose()` / EasyExcel / openpyxl `write_only` / excelize `StreamWriter` + `Flush()` / ExcelJS `stream.xlsx.WorkbookWriter` |
| CSV | `Files.readAllLines` / `StringBuilder` 全量拼 | OpenCSV `CSVWriter` 逐行 / Python `csv.writer` 迭代器 / Go `csv.NewWriter` 必须 `Flush` |
| JSON | `objectMapper.writeValueAsString(list)` | Jackson `JsonGenerator` 流式 / orjson + JSONL 行分隔 / Go `json.NewEncoder` |
| PDF | 全 Page 加内存后 `save` | iText 每 100 行 `flush` / ReportLab `Canvas.showPage` / PDFKit `pipe(stream)` |
| 同步阻塞 | Controller 直返 `byte[]` | 任务化 + 任务 ID + 轮询 + 文件上传 OSS |

## 必检清单

- [ ] 预估 > 1 万行的导出是否用流式 API
- [ ] 临时文件清理在 `try-finally` / `defer` / `with`（SXSSF 必须 `dispose()`）
- [ ] 流式 API 限制告知调用方（不能回写 / 不支持公式 / 必须 flush）
- [ ] 导出 > 30s 必须异步化（见 `async-task-pattern`）
- [ ] 数据量上限保护（防 `pageSize=999999`）

## 嗅探信号

代码评审看到以下立即怀疑：

- `new XSSFWorkbook()` + 循环 `createRow` > 1 万次
- `EasyExcel.write(...).doWrite(list)` 且 `list.size() > 10000`
- `openpyxl.Workbook()`（未带 `write_only=True`）+ 循环 `append`
- `excelize.NewFile()` + 大量 `SetCellValue`
- Controller 同步生成大文件 + `return ResponseEntity.ok().body(bytes)`
