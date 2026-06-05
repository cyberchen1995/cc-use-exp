# Case: CSDN paste 列表 bug — HTML→MD 转换丢 start 属性

> 来源:`wx-doc-public` 项目「AI 生成多平台文章」复制到 CSDN 后列表显示异常(2026-06)

---

## 现象

复制 AI 生成的多平台文章到 CSDN 后,「常见误区」小节的 4 个有序列表项:

- 每项独立成 `<ol>`,**全部显示 "1."**(而不是 1/2/3/4)
- 项之间**间距异常巨大**

微信、51cto 显示正常。

---

## 黑盒类型

**第三方编辑器** — CSDN 富文本编辑器底层是 Markdown 编辑器,粘贴 HTML 会触发 HTML→MD 转换。

---

## 错误调试路径(3 轮才定位根因)

| 轮次 | 假设 | 错在哪 |
|------|------|--------|
| 1 | 主题渲染输出 `<p>1. xxx</p>` 文本伪列表 → 写"合并 p 段落"函数 | 后端早已渲染为真 `<ol>`,函数完全 no-op |
| 2 | 后端为每个 paragraph 输出独立 ol → 写"合并相邻 ol"函数 | ol 之间隔着 `<p>` 解释段落,`nextElementSibling` 不命中,还是 no-op |
| 3 | **让用户在 Console 打印实际 HTML 结构** | 3 分钟定位:start 连续但被 p 隔开 → 正确修复 |

---

## 真实根因(第 3 轮数据揭示)

后端结构正常,但与 CSDN 编辑器特性不兼容:

1. AI 生成文章时,把"常见误区"的 4 个项作为 4 个独立 paragraph 输出
2. 后端 `theme_render_list.go` 把每个 paragraph 单独走 `processMarkdown`,渲染为:

```html
<ol><li>项1</li></ol>
<p>项1的解释</p>
<ol start="2"><li>项2</li></ol>
<p>项2的解释</p>
<ol start="3"><li>项3</li></ol>
<p>项3的解释</p>
<ol start="4"><li>项4</li></ol>
<p>项4的解释</p>
```

3. 4 个独立 ol,通过 `start` 属性接力编号
4. **微信**:保留 start 属性 → 4 个 ol 视觉上像连续编号 → 用户以为正常
5. **CSDN**:底层是 Markdown 编辑器,HTML→MD 转换时**丢弃 start 属性** → 4 个 ol 全回退 start=1 → 4 个 "1.",每个 ol 的默认 margin 累积 → 巨大间距

---

## 修复方案

`web/frontend/src/composables/result/useResultCopy.js` 的 `copyToClipboard` 在写入剪贴板前,加一步 `mergeAdjacentLists(doc)`:

- **ol 类型**:跳过中间的 `<p>` 段落,**start 数字必须连续才合并**(1→2→3→4 才合)
- 中间被跳过的 `<p>` 用 `appendChild` 移到前一个 `<li>` 内部,作为该项的详细说明
- **ul 类型**:严格相邻才合并(无 start 可验证,保守处理)
- 用 **DOM 节点搬移 + TreeWalker**,不用 `innerHTML`(避开 XSS 风险 + hook 告警)

合并后 CSDN 收到一个真正的 4 项 `<ol>`,不再被 start 丢失影响。

---

## 教训

1. **代码没说谎**:后端 ol 的 start 确实连续,前端 HTML 结构也对
2. **黑盒系统的行为不在代码里**:CSDN HTML→MD 转换的"丢 start 属性"是未文档化行为
3. **第 1 步就该抓数据**:第 3 轮才用 `el.outerHTML` 抓 DOM 结构,前 2 轮在凭推理写无效修复
4. **跨平台差异是强信号**:微信正常 vs CSDN 异常 → 第一反应应是"CSDN 处理流程必然不同",而不是"前端代码有 bug"
5. **数据采集模板**:浏览器粘贴/编辑器渲染 → 优先抓 outerHTML 对比

---

## 相关 skill

- [SKILL.md](../SKILL.md) — 总方法论
- 同类案例可参考 `case-browser-paste-format.md`
