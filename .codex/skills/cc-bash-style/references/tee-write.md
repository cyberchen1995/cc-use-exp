# tee 写入

- 需要写文件又想保留可见输出时，优先 `tee`。
- 需要权限提升时，优先 `sudo tee`，避免 `sudo echo > file` 这类误用。
- 重写和追加要明确区分：`tee` vs `tee -a`。
