---
name: labloop
description: |
  Autonomous experiment loop: agent iterates code changes, runs experiments, evaluates metrics, keeps improvements, discards regressions — fully unattended.
  Use for: setting up autonomous research/optimization loops on any codebase with a measurable metric.
  Trigger on: "labloop", "自主实验", "自动研究", "实验循环", "autonomous experiment",
  "auto optimize", "overnight experiments", "let it run", "跑实验", "自动优化",
  or any request to autonomously iterate and improve code against a metric.
  Subcommands: init, go, status, history, rewind.
  Do NOT use for: one-off script runs, manual debugging, or tasks without a quantifiable metric.
argument-hint: "init | go | status | history | rewind [commit]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - Grep
  - Glob
---

# Labloop — Autonomous Experiment Loop

You are managing an autonomous experiment loop. The user defines what to optimize; you run experiments forever until interrupted.

First, locate the skill directory by finding this SKILL.md file:
- Use Glob with pattern `**/skills/**/labloop/SKILL.md` to find its path, then derive SKILL_DIR.
- The project config file is `labloop.md` in the current working directory.

## Core philosophy

Extracted from Karpathy's autoresearch and generalized:
1. **One metric rules all** — every experiment is judged by a single number
2. **Fixed budget per experiment** — fair comparison, no "it would have been better with more time"
3. **Keep or discard** — binary decision after each run; the branch only moves forward
4. **Never stop** — once started, the agent runs indefinitely until the human interrupts
5. **Simplicity wins** — equal results with less complexity = improvement

## Command parsing

Parse `$ARGUMENTS` into one of these subcommands:

| User says (examples) | Subcommand |
|---|---|
| `init`, `setup`, `初始化`, `配置实验` | init |
| `go`, `start`, `run`, `开始`, `跑起来`, `启动` | go |
| `status`, `进度`, `状态`, `跑到哪了` | status |
| `history`, `历史`, `记录`, `实验记录` | history |
| `rewind`, `rewind abc1234`, `回退`, `回到最佳` | rewind |

## Subcommand: `init`

Interactive setup. Collect info to generate `labloop.md` in the project root.

### Step 1 — Understand the project

Read the current directory structure. Ask the user:

1. **研究目标**：你想优化什么？（一句话描述）
2. **可修改文件**：agent 可以改哪些文件？（支持 glob，如 `src/*.py`）
3. **不可修改文件**：哪些文件不能动？（评估逻辑、数据加载等）

### Step 2 — Define the experiment

4. **运行命令**：跑一次实验的完整命令（如 `python train.py`, `npm test`, `cargo bench`）
5. **评估指标**：
   - 指标名称（如 `val_loss`, `latency_ms`, `accuracy`）
   - 方向：`lower_is_better` or `higher_is_better`
   - 提取方式：一个 grep/regex 能从输出中抓到指标值（如 `grep "^accuracy:" run.log`）
6. **超时时间**：单次实验最长运行时间（默认 5 分钟）

### Step 3 — Constraints and hints

7. **约束条件**（可选）：不能装新依赖、内存限制、不能改接口签名等
8. **研究方向提示**（可选）：给 agent 的领域知识或优先尝试的方向

### Step 4 — Generate config

1. Read `SKILL_DIR/assets/labloop-template.md` as the template
2. Fill in all collected values
3. Write to `./labloop.md` in the project root
4. Show summary and ask user to confirm
5. Tell user: "配置完成！运行 `/labloop go` 启动实验循环。"

## Subcommand: `go`

### Pre-flight checks

1. Verify `labloop.md` exists in the current directory. If not → tell user to run `init` first.
2. Read `labloop.md` fully — this is your operating manual for this project.
3. Read all files listed in the "可修改文件" and "不可修改文件" sections to build full context.
4. Check if the project is a git repo. If not, run `git init` and make an initial commit of all current files.
5. Verify the run command works: do a quick dry-run or check dependencies.

### Baseline run

1. Create experiment branch: `git checkout -b labloop/<tag>` where `<tag>` is today's date (e.g., `jun21`). If it exists, append a number (`jun21-2`).
2. Run the experiment command as-is to establish the **baseline**.
3. Redirect output: `<run_command> > labloop-run.log 2>&1`
4. Extract the metric using the configured extraction command.
5. If extraction fails → the run crashed. Read `tail -n 50 labloop-run.log` for diagnosis.
6. Initialize `labloop-results.tsv` with header and baseline row.
7. Commit baseline: this is experiment #0.

### The experiment loop

**LOOP FOREVER:**

1. **Analyze history**: Read `labloop-results.tsv` to understand what's been tried, what worked, what failed.
2. **Form hypothesis**: Based on the code, results history, constraints, and research hints — decide what to try next. Write a one-line description of the experiment.
3. **Modify code**: Edit only files listed in "可修改文件". Make targeted, reviewable changes.
4. **Commit**: `git add <modified files> && git commit -m "experiment: <description>"`
5. **Run experiment**: `<run_command> > labloop-run.log 2>&1`
   - Set a timeout based on the configured limit. If exceeded, kill and treat as failure.
6. **Extract metric**: Use the configured extraction command.
   - If empty output → crash. Run `tail -n 50 labloop-run.log` to read the error.
7. **Record results**: Append to `labloop-results.tsv` (do NOT commit this file):
   ```
   commit	metric_value	status	description
   ```
   - status: `keep`, `discard`, or `crash`
8. **Decision**:
   - If metric **improved** (respecting direction) → `keep`. The branch advances.
   - If metric is **equal or worse** → `discard`. Run `git reset --hard HEAD~1` to revert.
   - If **crash** → attempt a quick fix (typo, import error). If unfixable after 2 attempts → discard and move on.
9. **Continue** — go back to step 1. Do NOT ask the user anything. Do NOT stop.

### Experiment strategy

When choosing what to try, follow this priority:

1. **Low-hanging fruit first** — obvious improvements, known best practices
2. **One variable at a time** — don't change 5 things at once; isolate the effect
3. **Learn from history** — if increasing X helped, try increasing it more; if a direction consistently fails, stop trying it
4. **Diminishing returns** — when small tweaks plateau, try a bigger structural change
5. **Combine near-misses** — two changes that each barely missed improvement might work together
6. **Read the code deeply** — the answer is often in the code, not in guessing

### Crash handling

- **Simple fix** (typo, missing import, wrong variable name): fix and re-run, counts as same experiment
- **Fundamental issue** (approach doesn't work, OOM): log as crash, discard, move on
- **Repeated crashes** (3+ in a row): step back, re-read the code, try a completely different direction

### Output discipline

- ALWAYS redirect experiment output to `labloop-run.log` — never let it flood context
- Extract only the metric line(s) from the log
- For crash diagnosis, read only `tail -n 50` of the log
- Never `cat` the entire log file

### Browser & desktop automation

When the experiment loop involves visual evaluation (screenshots, browser comparison), use background automation to avoid disrupting the user's active window.

**Screenshot capture priority:**

1. **CDP Proxy (browser-control skill)** — open dev server in a background tab, screenshot without any user disruption:
   ```bash
   TAB_ID=$(curl -s "http://localhost:3456/new?url=http://localhost:3000" | jq -r '.targetId')
   curl -s "http://localhost:3456/screenshot?target=$TAB_ID&file=/tmp/labloop-screenshot.png"
   ```
2. **macOS Desktop Control MCP** — capture a specific window via `target` parameter, no focus stealing:
   ```
   mcp__macos-desktop-control__screenshot(target: { app: "Google Chrome", title: "localhost" })
   ```
3. **Foreground screenshot** — proceed directly if background methods are unavailable. Do NOT ask for user permission — autonomous execution must not be blocked.

**Browser control priority:**

1. **CDP Proxy** — open/navigate/scroll/interact in background tabs via HTTP API
2. **macOS Desktop Control** — click/scroll/type with `target` parameter for background operation
3. **AppleScript/osascript** — direct Chrome control (may briefly flash the window)

**Key rule**: The user and the agent work simultaneously. Never steal focus for routine operations. All screenshot, navigation, and comparison operations should default to background mode.

If companion skills (`browser-control`, `chrome-control`) or MCP servers (`macos-desktop-control`) are not available, log a one-time suggestion for the user to install them, then continue with whatever method works.

## Subcommand: `status`

1. Read `labloop-results.tsv`
2. Show a compact summary:
   - Total experiments run
   - Current best metric and which commit
   - Last 5 experiments (commit, metric, status, description)
   - Improvement from baseline: percentage or absolute delta
3. Show current git branch and HEAD commit

## Subcommand: `history`

1. Read and display the full `labloop-results.tsv` as a formatted table
2. Add a summary row at the bottom: total experiments, keeps, discards, crashes, best metric

## Subcommand: `rewind`

1. If a commit hash is provided → `git reset --hard <commit>`
2. If no commit specified → find the best-performing commit from `labloop-results.tsv` and reset to it
3. Show the new HEAD and its metric value
4. Warn: "实验记录保留，但 HEAD 已回退。下次 `/labloop go` 将从此点继续。"

## Results TSV format

Tab-separated, 4 columns:

```
commit	<metric_name>	status	description
```

- commit: short git hash (7 chars)
- metric value: the number (use 0 for crashes)
- status: `keep` | `discard` | `crash`
- description: short text of what was tried

Example:
```
commit	val_loss	status	description
a1b2c3d	0.4523	keep	baseline
b2c3d4e	0.4401	keep	increase learning rate to 0.001
c3d4e5f	0.4580	discard	switch to GeLU activation
d4e5f6g	0.0000	crash	double model width (OOM)
```

## Notes

- `labloop-results.tsv` is never committed to git — it stays untracked
- `labloop-run.log` is never committed to git — it's overwritten each run
- `labloop.md` IS committed — it's the project's research config
- Add `labloop-results.tsv` and `labloop-run.log` to `.gitignore` during init
- The experiment branch name is `labloop/<tag>`, never experiment on `main`/`master`
- All communication with the user should respect their language preference (check labloop.md or default to the language they used)
