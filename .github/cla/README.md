# CLA Gate Process

本目录用于维护 `CLA` 执行层配置。

## 文件说明

- `allowlist.txt`
  已完成 `CLA.md` 签署且可长期放行的 GitHub 账号白名单

## 默认门槛

对于 `pull_request_target` 触发的 PR：

- 如果 PR 作者在 `allowlist.txt` 中，`CLA Gate` 直接通过
- 如果 PR 作者不在白名单中，则必须由维护者在确认已收到并归档签署版 `CLA.md` 后，为该 PR 手动添加 `cla-signed` 标签
- 如果两者都不满足，工作流失败，PR 不应合并

## 推荐维护流程

1. 收到外部非琐碎贡献
2. 让贡献者签署并回传 [CLA.md](../../CLA.md)
3. 将签署版归档到维护者控制的仓外位置
4. 选择一种放行方式：
   - 长期合作贡献者：加入 `allowlist.txt`
   - 一次性贡献者：仅给当前 PR 打 `cla-signed` 标签

## 注意

- `allowlist.txt` 只应写 GitHub login，不要写邮箱或姓名
- 不要在仓库内提交贡献者签署版 `CLA`
- 如果账号发生变更，应重新核验并更新记录
