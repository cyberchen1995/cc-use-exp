# Case: HTTP CDN/WAF 拦截 — body 空 + headers 极简

> 来源:从 `claude-code-defensive.md`「HTTP 错误诊断」段落迁移并扩展

---

## 现象

调用第三方 HTTP API,出现以下症状组合:

- 状态码 4xx/5xx,但 **response body 为空**
- response headers **极简**(缺少目标 API 应有的标准 headers,如 `X-Request-Id`、`X-RateLimit-*` 等)
- 状态码可能是 403 / 503 / 451 / 502,而非业务正常错误码

---

## 黑盒类型

**网络中间层** — CDN(Cloudflare/AWS CloudFront/阿里云 CDN)、WAF(ModSecurity/Cloudflare WAF/腾讯云 T-Sec)、反向代理(Nginx/Envoy)。

---

## 优先怀疑顺序

| 优先级 | 假设 | 验证方法 |
|------|------|--------|
| **1**(最优先) | CDN/WAF 拦截 | 看 `Server` / `Via` headers;空 body + 极简 headers 强信号 |
| 2 | HTTP 客户端兼容性(TLS/HTTP2/UA) | 换 `curl -v` 看是否同样异常;比对 UA |
| 3 | API 真实业务错误 | 当且仅当前两条排除后 |

❌ **不要先怀疑 API 本身的业务错误** — 业务错误一般会有 JSON body 和标准 headers。

---

## 关键诊断方法

### 1. 同一 API 比对 GET vs POST

如果 GET 请求正常返回(有 body、headers 完整),POST 同样路径异常 → **HTTP 客户端兼容性问题**(常见:Apache HttpClient 旧版与 HTTP/2 不兼容、某些 SDK 默认禁用 keep-alive 触发 WAF 速率限制等)。

### 2. 用 curl -v 复现

```bash
curl -v \
  -H "User-Agent: <你代码里实际的 UA>" \
  -X POST "https://api.example.com/endpoint" \
  -d '{"key":"value"}'
```

观察:
- TLS 握手是否成功
- 是否经过 Cloudflare / Akamai 等中间节点(看 `Server: cloudflare`、`Via:`)
- response headers 与你代码看到的是否一致

### 3. 查 Server / Via headers

| Header 值 | 含义 |
|---------|------|
| `Server: cloudflare` | Cloudflare CDN/WAF |
| `Server: AmazonS3` 或 `AmazonCloudFront` | AWS |
| `Via: 1.1 google` | Google Cloud Load Balancer |
| `X-Cache: HIT/MISS` | 经过 CDN |
| `cf-ray: ...` | Cloudflare 标识 |

如果存在以上任一,基本可确认请求被中间层处理过,**业务错误的概率很低**。

---

## 常见根因

1. **WAF 速率限制**:UA 缺失/异常被识别为爬虫
2. **WAF body 规则**:请求 body 含 SQL 注入特征字符被拦截
3. **HTTP/2 兼容性**:旧版 SDK 强制 HTTP/1.1 被 CDN 降级失败
4. **TLS 版本**:旧版 SDK 仅支持 TLS 1.0/1.1 被现代 CDN 拒绝
5. **地理位置封禁**:服务器 IP 段被 WAF GeoIP 黑名单

---

## 教训

1. **空 body + 极简 headers 是 CDN/WAF 拦截的指纹** — 不是 API 业务错误
2. **GET 正常 POST 异常** → HTTP 客户端兼容性
3. **优先看中间层**:`Server`、`Via`、`cf-ray` headers
4. **永远先用 curl -v 复现**,不要只在代码层猜

---

## 相关 skill

- [SKILL.md](../SKILL.md) — 总方法论
- `cc-api-design-safety` — 自己设计 API 时的 headers 规范(对比视角)
