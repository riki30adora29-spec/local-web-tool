---
name: local-web-tool
description: Build local single-page web tools with Node.js backend — Express + static HTML, API proxy pattern, WSL2 networking fixes, Windows launcher scripts.
---

# Local Web Tool Pattern

Use this skill when the user asks you to build a **local, single-purpose web tool** — a tool they open in their own browser, backed by a minimal Node.js server that proxies API calls (to DeepSeek, OpenAI, etc.).

## When to use

Triggers: "build a local web tool", "local single-page app", "proxy API on localhost", "simple web UI for...", or any PLAN.md that specifies Express + single HTML + API proxy.

## Environment detection

**If the user's environment is native Windows** (Node.js on Windows, no WSL), load `references/windows-native.md` for the simplified equivalents — no `0.0.0.0` binding, no CIFS latency, `taskkill` instead of `pkill`, direct `node server.js` in launchers.

**Otherwise, default to WSL** — this document's pitfalls and patterns assume WSL2. The Windows-native reference only overrides the OS-specific parts; all architecture, API, and visual patterns remain identical.

## Visual style — always ask, never assume

**If the user has NOT specified a visual style, ASK before writing any HTML/CSS.** Do not default to any particular aesthetic. Use `clarify()` with choices like:

- "Same visual style as your other projects (dark aurora + frosted glass)?"
- "A different theme — describe what you want"
- "Clean minimal — just functional, no decoration"
- "I'll give you a design reference HTML file"

Available visual references you can suggest (only if they match what the user describes):

| Reference | What it provides |
|---|---|
| `aurora-video-background.md` | Looping MP4 video background + dark overlay |
| `glass-morphism.md` | Two-tier backdrop-filter blur (clear panels + frosted inputs) |
| `typography.md` | MiSans + Inter font pairing for CN+EN tools |
| `sidebar-layout.md` | Sticky left sidebar with sliding indicator |
| `grain-noise.md` | SVG feTurbulence noise overlay for gradient backgrounds |
| `svg-fog-background.md` | Multi-layer SVG fog background with drifting orbs |
| `tab-spa-accordion.md` | Classic top-bar tabs + accordion for multi-module SPAs |
| `filterable-library.md` | Filter pills + sort + group-by toggle + inline edit |
| `theme-migration.md` | Apply a standalone design-reference HTML onto a project |

**The user may describe a completely new visual style.** In that case, build it from scratch — do not force any reference onto it. Use the references only as implementation guides when the user's description matches what a reference covers.

**If the user says "same visual style as my other projects,"** check memory for their established conventions (theme colors, fonts, glass settings, background approach) and apply them consistently.

## Architecture

```
project/
├── .env              ← API keys (never in code)
├── .gitignore        ← env + node_modules
├── package.json      ← express + dotenv
├── server.js         ← static hosting + POST/GET API proxy
├── start.bat         ← Windows one-click launcher (WSL)
├── stop.bat          ← Windows shutdown helper
└── public/
    └── index.html    ← single page, inline JS/CSS
```

## Server skeleton (server.js)

```js
const path = require("path");
const express = require("express");
require("dotenv").config({ path: path.join(__dirname, ".env") });

const app = express();
app.use(express.json({ limit: "100kb" }));
app.use(express.static(path.join(__dirname, "public")));

app.post("/api-endpoint", async (req, res) => {
  // validate, call external API, parse, return
});

// CRITICAL: bind to "0.0.0.0" for WSL → Windows access
app.listen(3000, "0.0.0.0", () => {
  console.log("Ready → http://localhost:3000");
});
```

## Pitfalls

### WSL2: server unreachable from Windows browser

**Symptom:** curl works inside WSL, but Windows browser shows "connection refused" or "无法连接".

**First, determine networking mode** — check `%USERPROFILE%\.wslconfig` for `networkingMode`:
- **Mirrored mode** (`networkingMode=mirrored`, WSL2 ≥ 2.0.0): WSL shares Windows IP. Use `localhost` or `127.0.0.1` — hardcoded IPs like `192.168.x.x` **will not work** (Windows Firewall blocks non-loopback on public profiles). `netsh portproxy` is not needed.
- **NAT mode** (default/older): WSL has its own IP. `localhost` forwarding may break. Fall back to `http://<wsl-ip>:3000`.

**Root cause:** When Express listens on default hostname (localhost / 127.0.0.1), it binds to WSL's loopback interface only. Windows can't reach it.

**Fix:** Bind to `"0.0.0.0"` in `app.listen()`:

```js
app.listen(PORT, "0.0.0.0", () => { ... });
```

**Always use `localhost` in .bat launchers** — never hardcode the WSL IP. It changes on reboot in NAT mode and doesn't work at all in mirrored mode.

See `references/wsl2-networking.md` for full debugging checklist, mirrored mode detection, and firewall implications.

### WSL bash -c: node not found → "connection refused"

**Symptom:** User double-clicks `start.bat`, browser opens, but shows "localhost 拒绝连接" or "connection refused". The server never started — `node` was not found in the WSL non-interactive shell.

**Root cause:** `start.bat` uses `wsl -d <distro> -- bash -c "node server.js"`. But `bash -c` starts a **non-interactive, non-login** shell that does NOT source `~/.bashrc` or `~/.profile`. If node is installed in `~/.local/bin/` (common with nvm or manual install), the `node` binary won't be on PATH.

**Detect:** Inside WSL, run `which node`. If the output is under `~/.local/bin/`, this pitfall applies.

**Fix — use full path:** Replace `node` with the full path in start.bat:
```
wsl -d Ubuntu -- bash -c "cd /mnt/d/work/project && /home/user/.local/bin/node server.js"
```

**Alternative — login shell:** Use `bash -lc` (login shell that sources profile):
```
wsl -d Ubuntu -- bash -lc "cd /mnt/d/work/project && node server.js"
```
Note: `-lc` can be fragile across distributions; full path is more reliable.

**Always verify** after creating/updating a start.bat: check that the server actually responds on its port before telling the user "done".

### User accidentally associates .bat with a browser → launcher breaks

**Symptom:** User says "点了start文件选了始终用Chrome打开" or "选了始终以后就不能选择跳转到Edge了". Double-clicking `start.bat` now opens it as a text file in the browser instead of executing it. The server never starts.

**Root cause:** Windows File Explorer's "Open with → Always use this app" dialog applies to the **file type** (`.bat`), not just that one file. Once set to Chrome/Edge, ALL `.bat` files open as text in that browser.

**Fix — reset .bat association from WSL via PowerShell:**
```powershell
powershell.exe -NoProfile -Command "Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.bat\UserChoice' -Force -ErrorAction SilentlyContinue"
```
This deletes the per-user override from the registry. After running it, `.bat` files execute normally again — no reboot needed.

**Prevention — browser-specific fallback launcher:**
Create an `open-edge.bat` (or `open-chrome.bat`) that uses `start msedge http://localhost:3000` (or `start chrome http://localhost:3000`). This gives the user a browser-specific way to open the tool regardless of their default browser or file association state:
```bat
@echo off
start msedge http://localhost:3000
pause
```

### Double-click opens file://, not http://

**Symptom:** User double-clicks `index.html` in File Explorer. Page renders but API calls fail with "网络错误" because `fetch("/generate")` resolves to `file:///generate`.

**Fix:** Never tell the user to open the HTML file directly. Always provide a Windows `.bat` launcher (see `templates/start.bat`) that opens the browser to `http://localhost:3000`. If the user reports this error, create the launcher immediately — they're trying to use the tool the natural Windows way.

### .env not read after moving files

**Symptom:** Server returns "DEEPSEEK_API_KEY not configured" even though the key is in `.env`.

**Root cause:** Server process was started before the file move. `dotenv` reads `.env` once at startup.

**Fix:** Kill and restart the server. If the error persists, verify the key exists with:
```bash
node -e "require('dotenv').config(); console.log(process.env.DEEPSEEK_API_KEY ? 'OK' : 'MISSING')"
```

### Node.js startup is EXCRUCIATINGLY slow on /mnt/ drives (CIFS mount)

**Symptom:** `node server.js` appears to hang — no output for 30+ seconds, `curl` fails with "connection refused", `timeout 5 node server.js` always times out. You assume the server is broken and start debugging.

**Reality:** The server is NOT broken. Node.js `require()` traverses the dependency tree on startup, performing thousands of stat/read syscalls. On a CIFS-mounted Windows drive (`/mnt/c/`, `/mnt/d/`), each syscall has ~10-50ms latency. A simple Express server (express → accepts → negotiator → mime-types → …) can take **30-120 seconds** to start.

**Detection:** `node --check server.js` returns instantly (no requires), but `node server.js` hangs. `node -e "require('express')"` also hangs. `node --version` is instant.

**Workarounds:**

1. **Be patient.** Set `timeout=120` or launch in background and poll. The server WILL start eventually. The user normally double-clicks a `.bat` launcher and never notices the delay because the browser opens after a fixed `timeout /t 3` — but by then the server may not be ready yet. After making code changes, wait 30+ seconds before running `curl` health checks.

2. **Check for the `.env` PORT.** Projects on /mnt/ drives often have a `.env` file with `PORT=3001` or similar. The server silently binds to that port, not the default 3000 in code. Test `PORT=3001` AND `PORT=3000` — don't assume which one the server used.

3. **Listen for the startup message.** The server prints "Ready → http://localhost:XXXX" to stdout when it's done loading. In background mode, poll `process(action='log')` until this appears.

4. **Cache node_modules on the Linux filesystem** (advanced): Copy `node_modules` to `~/.cache/npm-copy/<project-hash>/` and symlink. This eliminates CIFS latency entirely but requires maintenance when packages change.

## Windows launcher pattern

Always create a `start.bat` in the project root for WSL users. It should:
1. Start the WSL server (`wsl -d <distro> -- bash -c "cd <path> && node server.js"`)
2. Wait 2-3 seconds
3. Open the browser to `http://localhost:{{PORT}}`

**Never hardcode the WSL IP** in launcher scripts. The IP changes on reboot (NAT mode) and doesn't work at all in mirrored mode. Always use `localhost` — it works in both networking modes when the server binds to `0.0.0.0`.

See `templates/start.bat` for the template. Also create `stop.bat` that kills the server via `pkill`.

## API key management

- Never hardcode keys in server code or frontend
- Use `dotenv` to load from `.env` in project root
- Add `.env` to `.gitignore`
- Validate at startup: warn if key is missing
- In the `/generate`-style endpoint, return a clear 500 error if the key is absent — don't crash

## Prompt pattern (when tool generates text via LLM)

For tools that call an LLM to generate structured output:

1. **System prompt:** Numbered rules, each one constraint. Include output format requirement as the last rule.
2. **User prompt:** Structured with labeled sections (`【我的简历】`, `【职位JD】`, etc.).
3. **Output format:** Require JSON (`{"greetings": [...]}`) with explicit "no markdown wrapper" instruction.
4. **Parse defensively:** Strip ```json``` fences first, try `JSON.parse`, then fall back to paragraph splitting.
5. **Never fabricate:** Prompt should explicitly forbid inventing information not present in the input.

## PLAN-driven gap analysis (when updating an existing project)

When the user attaches a PLAN file for an existing project and says "对齐计划来修改" or similar, or provides a **standalone design-reference HTML** and says "apply this theme":

1. **Read the new PLAN fully** — it may have expanded scope (new modules, new APIs, new UI sections)
2. **Read all existing project files** (server.js, index.html, app.js, style.css, package.json, existing data files)
3. **Compare systematically** — what's in the new PLAN that's NOT in the existing code? Don't assume the old implementation matches the new spec.
4. **Create a todo list** with one item per logical change (backend APIs, HTML structure, CSS, JS logic, verification)
5. **Stop the running server** before modifying code — stale processes on wrong ports cause confusion
6. **Verify with curl after restarting** — test new endpoints, test old ones still work, test edge cases
7. **Clean up test data** — remove any artifacts you created during testing (unless kept as demo)

Common gaps to look for:
- Port number changes (e.g., 3001 → 3000)
- New API routes added to the spec
- New data directories or file formats
- New UI sections (tabs, panels, accordions) — see `references/tab-spa-accordion.md`
- New validation rules or field constraints
- Missing config files (.gitignore, .env.example)
- **Missing basic CRUD operations**: PLANs that say "不要添加任何未列出的功能" may still omit obvious operations like DELETE. If the user says "没做删除键" or similar, add it — basic data hygiene (delete) is expected even when not in the spec. Don't argue that "the PLAN didn't list it."

For **design-reference-driven updates** (user provides a standalone HTML visual reference instead of a PLAN), skip the diff approach above and use the full theme-migration workflow in `references/theme-migration.md`.

**Concise reporting after multi-change passes:** When the user provides several changes at once and says "一次性改完，改完简单告诉我你动了哪些文件和地方" or similar, execute all changes in a single pass and report with a compact table — one row per file, one sentence per change. No verbose prose, no recap of what was already shown. If the user also wants git versioning, commit after verification.

## Full verification testing workflow

See `references/testing-workflow.md` for the complete 6-layer verification sequence: reachability → CRUD cycle → boundary cases → export endpoints → DELETE operations → cleanup. Always run this before declaring a local web tool done.

## Support files

- `templates/start.bat` — Windows one-click launcher (WSL server + browser). Replace `{{PROJECT_NAME}}`, `{{WSL_DISTRO}}`, `{{PROJECT_PATH}}`, `{{PORT}}`.
- `templates/stop.bat` — Windows shutdown script (kills the WSL server process).
- `templates/open-edge.bat` — Browser-specific fallback launcher. Use when the user's default browser choice or `.bat` file association causes issues. Replace `{{PORT}}` and `{{WSL_IP}}`.
- `references/wsl2-networking.md` — Deep dive on WSL2 networking: why `0.0.0.0` is needed, debugging checklist, netsh fallback.
- `references/testing-workflow.md` — Full 6-layer verification sequence for local web tools.
- `references/tab-spa-accordion.md` — Reusable vanilla-JS tab + accordion pattern for multi-module SPAs. Two variants: classic top-bar tabs and left sidebar (see `references/sidebar-layout.md`).
- `references/sidebar-layout.md` — Sticky left sidebar with smooth-sliding indicator. CSS transition + JS position calculation for both vertical (desktop) and horizontal (mobile) modes.
- `references/theme-migration.md` — Workflow for applying a standalone design-reference HTML (visual theme) onto an existing project: class-name mapping, rewrite order, common pitfalls.
- `references/i18n-checklist.md` — 7-layer checklist for full internationalization of a local web tool (HTML, JS, server validation, API errors, AI prompts, CSS classes, data migration).
- `references/typography.md` — Font pairing for CN+EN tools: MiSans (body, jsDelivr CDN) + Inter (titles, Google Fonts). Dark-theme frosted glass text readability tweaks.
- `references/filterable-library.md` — Library/directory panel pattern: filter pills, sort dropdown, group-by toggle, per-item inline edit, collapsible group sections.
- `references/grain-noise.md` — SVG feTurbulence procedural noise overlay: reduce gradient banding on blurred backgrounds, tuning guide, pitfalls.
- `references/svg-fog-background.md` — Multi-layer SVG feTurbulence fog: fractalNoise at low baseFrequency (0.012–0.022), feColorMatrix cool-pale tinting, radial mask for irregular strength distribution, slow drift animation, stacking with faint coloured orbs behind. Note: fog is one of several background approaches; see also `references/aurora-video-background.md` for the video alternative.
- `references/aurora-video-background.md` — Looping MP4 video background with dark overlay for readability. HTML structure (video + still fallback + overlay), CSS (object-fit: cover, fixed positioning), prefers-reduced-motion still-image fallback, theme-color strategy.
- `references/glass-morphism.md` — Two-tier backdrop-filter blur system for video/gradient backgrounds: clear glass (8px for panels/cards/sidebar) vs frosted glass (18px for text inputs). CSS variable pattern, rationale, conversion order.
- `references/ai-inline-analysis.md` — Add LLM-powered analysis to individual items in an existing list/library. Two variants: toggle expand/collapse (default), and repeated calls with session counter (for creative/coaching use cases). Also covers persistence: append results to a `untangles` array on the item's JSON record for cross-session recall. Reuses existing AI env vars — no new keys or hardcoded models.
- `references/dual-panel-ai-annotate.md` — Detail-view dual-panel AI annotation: side-by-side editor + sticky annotations column. For writing-coach / structural-editor patterns where the user sees AI feedback alongside their text while editing. Covers adding a new page to an existing multi-screen SPA.
