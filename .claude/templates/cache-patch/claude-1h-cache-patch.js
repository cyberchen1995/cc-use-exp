#!/usr/bin/env node
/**
 * Claude Code CLI — 1h Cache Patch Tool
 * 支持 Windows / macOS / Linux
 * 版本无关：通过语义锚点定位函数，不依赖混淆后的函数名
 *
 * 用法：
 *   node claude-1h-cache-patch.js          # 打补丁
 *   node claude-1h-cache-patch.js restore  # 还原备份
 *   node claude-1h-cache-patch.js status   # 查看当前状态
 */

const fs   = require('fs');
const path = require('path');
const os   = require('os');
const { execSync } = require('child_process');

const isTTY = process.stdout.isTTY;
const c = {
  red:    (s) => isTTY ? `\x1b[31m${s}\x1b[0m`  : s,
  green:  (s) => isTTY ? `\x1b[32m${s}\x1b[0m`  : s,
  yellow: (s) => isTTY ? `\x1b[33m${s}\x1b[0m`  : s,
  cyan:   (s) => isTTY ? `\x1b[36m${s}\x1b[0m`  : s,
  bold:   (s) => isTTY ? `\x1b[1m${s}\x1b[0m`   : s,
};
const log = {
  info:    (msg) => console.log(`  ${c.cyan('ℹ')}  ${msg}`),
  ok:      (msg) => console.log(`  ${c.green('✔')}  ${msg}`),
  warn:    (msg) => console.log(`  ${c.yellow('⚠')}  ${msg}`),
  error:   (msg) => console.error(`  ${c.red('✘')}  ${msg}`),
  section: (msg) => console.log(`\n${c.bold(c.cyan(msg))}`),
};

const ANCHOR_KEY    = 'tengu_prompt_cache_1h_config';
const PATCH_COMMENT = '/*__1h_cache_patched__*/';

function findCacheFunction(content) {
  const keyIdx = content.indexOf(ANCHOR_KEY);
  if (keyIdx === -1) return null;
  const searchStart = Math.max(0, keyIdx - 800);
  const before = content.slice(searchStart, keyIdx);
  const fnDeclRe = /function\s+(\w+)\s*\((\w*)\)\s*\{/g;
  let lastMatch = null, m;
  while ((m = fnDeclRe.exec(before)) !== null) lastMatch = m;
  if (!lastMatch) return null;
  const fnName  = lastMatch[1], fnParam = lastMatch[2] || 'A';
  const fnStart = searchStart + lastMatch.index;
  const bodyOpen = fnStart + lastMatch[0].length - 1;
  let depth = 0, pos = bodyOpen;
  while (pos < content.length) {
    if (content[pos] === '{') depth++;
    else if (content[pos] === '}') {
      depth--;
      if (depth === 0) return { name: fnName, param: fnParam, start: fnStart, end: pos + 1 };
    }
    pos++;
  }
  return null;
}

function detectState(content) {
  if (content.includes(PATCH_COMMENT)) return 'patched';
  if (content.includes(ANCHOR_KEY)) return 'original';
  return 'unknown';
}

function extractVersion(content) {
  const m = content.match(/"version"\s*:\s*"([\d.]+)"/);
  return m ? m[1] : '未知';
}

function findCliJs() {
  const candidates = [];
  try {
    const npmRoot = execSync('npm root -g', { encoding: 'utf8', stdio: ['pipe','pipe','pipe'], shell: true }).trim().split('\n')[0].trim();
    if (npmRoot) candidates.push(path.join(npmRoot, '@anthropic-ai', 'claude-code', 'cli.js'));
  } catch (_) {}
  if (os.platform() === 'win32') {
    const appdata = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming');
    candidates.push(path.join(appdata, 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js'));
  } else {
    candidates.push('/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js',
      '/usr/lib/node_modules/@anthropic-ai/claude-code/cli.js',
      path.join(os.homedir(), '.npm-global', 'lib', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js'));
    const nvmDir = process.env.NVM_DIR || path.join(os.homedir(), '.nvm');
    try { for (const v of fs.readdirSync(path.join(nvmDir, 'versions', 'node')))
      candidates.push(path.join(nvmDir, 'versions', 'node', v, 'lib', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js'));
    } catch (_) {}
    for (const root of [path.join(os.homedir(), '.fnm'), '/opt/homebrew/lib/node_modules']) {
      try { for (const sub of fs.readdirSync(root))
        candidates.push(path.join(root, sub, 'lib', 'node_modules', '@anthropic-ai', 'claude-code', 'cli.js'));
      } catch (_) {}
    }
  }
  for (const p of candidates) { if (fs.existsSync(p)) return p; }
  return null;
}

function main() {
  const cmd = process.argv[2] || 'patch';
  const cliPath = findCliJs();
  if (!cliPath) { log.error('未找到 Claude Code CLI。'); process.exit(1); }
  log.ok(`找到：${c.cyan(cliPath)}`);
  const bak = cliPath + '.1h-cache-bak';
  let content;
  try { content = fs.readFileSync(cliPath, 'utf8'); } catch (e) { log.error(`读取失败：${e.message}`); process.exit(1); }
  const state = detectState(content);
  log.info(`版本：${c.yellow(extractVersion(content))}`);
  log.info(`状态：${state === 'patched' ? c.green('已打补丁 ✔') : state === 'original' ? c.yellow('未打补丁') : c.red('未知')}`);
  if (cmd === 'status') process.exit(0);
  if (cmd === 'restore') {
    if (!fs.existsSync(bak)) { log.error('未找到备份文件'); process.exit(1); }
    fs.writeFileSync(cliPath, fs.readFileSync(bak, 'utf8'), 'utf8');
    log.ok('已还原。'); process.exit(0);
  }
  if (state === 'patched') { log.ok('已是补丁状态，无需操作。'); process.exit(0); }
  if (state === 'unknown') { log.error('未找到锚点，无法定位。'); process.exit(1); }
  const fn = findCacheFunction(content);
  if (!fn) { log.error('无法定位缓存判断函数。'); process.exit(1); }
  log.info(`定位：函数 ${c.yellow(fn.name)}，偏移 ${fn.start}–${fn.end}`);
  if (!fs.existsSync(bak)) { fs.copyFileSync(cliPath, bak); log.ok(`备份：${c.cyan(bak)}`); }
  const replacement = `${PATCH_COMMENT}function ${fn.name}(${fn.param}){return!0}`;
  fs.writeFileSync(cliPath, content.slice(0, fn.start) + replacement + content.slice(fn.end), 'utf8');
  if (!fs.readFileSync(cliPath, 'utf8').includes(PATCH_COMMENT)) { log.error('验证失败！'); fs.copyFileSync(bak, cliPath); process.exit(1); }
  log.ok(`补丁成功！重启 Claude Code 生效。`);
}

main();
