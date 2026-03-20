# Go 并发

- 启动 goroutine 前先想清楚谁来等待、谁来取消。
- 优先使用 `context.Context` 控制生命周期。
- 涉及共享状态时，明确同步策略并考虑 `go test -race`。
