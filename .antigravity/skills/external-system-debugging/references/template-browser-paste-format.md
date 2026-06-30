# Template: 浏览器粘贴行为差异(占位框架)

> 这是一个**模板文件**(template),不是已发生的案例(case)。踩到具体坑后请按下方结构填入,并改名为 `case-{system}-{symptom}.md`。

---

## 何时启用本模板

调试涉及**浏览器粘贴行为**的 bug 时,先用本模板的「数据采集模板」抓数据,再决定填什么内容到「待补充章节」。

---

## 待观察方向

| 方向 | 典型差异点 |
|------|---------|
| Chrome vs Safari vs Firefox 的 Clipboard API | `navigator.clipboard.read()` 支持的 mime type 不同 |
| 富文本编辑器对 HTML mime 的处理 | 有的优先 text/plain,有的优先 text/html |
| 移动端浏览器 webview 行为 | iOS WKWebView 对粘贴的 HTML sanitize 行为 |
| `paste` 事件的 ClipboardData 与 Clipboard API 差异 | 异步 vs 同步,可访问的内容类型不同 |
| 操作系统级剪贴板 mime 优先级 | macOS `pbpaste -Prefer html` vs Linux `xclip -selection clipboard -t text/html` |

---

## 数据采集模板(预填,可直接给用户复制)

调试粘贴问题时,**第一步**让用户在目标浏览器 Console 执行:

```javascript
const items = await navigator.clipboard.read();
for (const item of items) {
  console.log('mime types:', item.types);
  for (const type of item.types) {
    const blob = await item.getType(type);
    const text = await blob.text();
    console.log(`[${type}]\n`, text);
  }
}
```

或者在 paste 事件里:

```javascript
element.addEventListener('paste', (e) => {
  for (const type of e.clipboardData.types) {
    console.log(`[${type}]`, e.clipboardData.getData(type));
  }
});
```

---

## 待补充章节(踩坑后填写,完成后改名为 case-*)

- 现象
- 黑盒类型
- 错误调试路径(轮次表)
- 真实根因
- 修复方案
- 教训

参考 `case-csdn-paste-list.md` 的完整结构。

---

## 相关 skill

- [SKILL.md](../SKILL.md) — 总方法论
