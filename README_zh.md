# Labloop

[English →](README.md)

**Claude Code 自主实验循环技能。** 给它一个代码库和一个指标——它自动实验、评估、保留改进、丢弃退步，然后重复。永不停止。你睡觉，它做研究。

灵感来自 Karpathy 的 [autoresearch](https://github.com/karpathy/autoresearch)，但做了泛化：labloop 适用于**任何有可量化指标的优化问题**，不仅限于 LLM 训练。

## 工作原理

```
init  →  定义优化目标、评估指标、agent 可修改的文件
go    →  跑 baseline → 进入无限实验循环
          ┌─→ 分析历史记录
          │   提出假设
          │   修改代码
          │   git commit
          │   运行实验
          │   提取指标
          │   变好了？ → 保留（分支前进）
          │   没变好？ → 丢弃（git reset）
          └─→ 继续循环
```

Agent 永不停止、永不提问，直到你手动中断。

## 适用场景

| 领域 | 改什么 | 评估什么 |
|---|---|---|
| ML 训练 | 架构、超参、优化器 | val_loss, accuracy |
| 算法优化 | 实现代码 | 延迟、吞吐量 |
| Prompt 工程 | 提示词、few-shot 示例 | 准确率、评分 |
| 前端性能 | 组件、CSS、配置 | Lighthouse 分数 |
| 编译调优 | 编译参数、配置 | 二进制大小、benchmark |
| 任何优化问题 | 任何可编辑文件 | 任何单一数值指标 |

完整配置示例见 [`references/examples.md`](references/examples.md)。

## 安装

```bash
# 克隆仓库
git clone https://github.com/d-wwei/labloop.git

# 方式一：符号链接到 Claude Code skills 目录
ln -s "$(pwd)/labloop" ~/.claude/skills/labloop

# 方式二：直接复制
cp -r labloop ~/.claude/skills/labloop
```

Claude Code 下次启动时会自动识别该技能。

## 快速开始

```
/labloop init      # 交互式配置——生成 labloop.md
/labloop go        # 跑 baseline + 启动无限实验循环
/labloop status    # 查看进度：已跑实验数、最佳指标、最近结果
/labloop history   # 完整实验记录表
/labloop rewind    # 回退到历史最佳 commit
```

## 配置说明

`/labloop init` 会在项目根目录生成 `labloop.md`，其中定义：

- **研究目标** — 你要优化什么（一句话）
- **可修改文件** — agent 能改哪些文件（支持 glob 模式）
- **只读文件** — 评估逻辑、数据等（agent 不会动）
- **运行命令** — 执行一次实验的命令
- **指标** — 指标名、方向（`lower_is_better` / `higher_is_better`）、提取命令
- **超时时间** — 每次实验的最大秒数
- **约束条件** — agent 必须遵守的规则
- **研究方向提示** — 可选的领域知识，引导 agent 思路

## 设计原则

从 autoresearch 提炼并泛化：

1. **单一指标至上** — 每次实验由一个数字决定好坏
2. **固定预算** — 每次实验时间相同，公平比较
3. **保留或丢弃** — 二元决策，分支只往前走
4. **永不停止** — agent 无限运行直到人工中断
5. **简单优先** — 同等效果，更简单的方案 = 改进
6. **单变量原则** — 隔离变量，从历史中学习

## 文件结构

```
labloop/
├── SKILL.md                   # 技能定义（Claude Code 读取）
├── assets/
│   └── labloop-template.md    # 配置文件模板
├── references/
│   └── examples.md            # 5 个领域的配置示例
├── scripts/
│   ├── run-with-timeout.sh    # 带超时的实验运行器
│   └── extract-metric.sh      # 从日志中提取指标
└── evals/                     # 测试用例（规划中）
```

在你的项目中（由 `init` 生成）：

```
your-project/
├── labloop.md              # 实验配置（提交到 git）
├── labloop-run.log         # 最新运行日志（gitignored）
└── labloop-results.tsv     # 完整实验历史（gitignored）
```

## 依赖

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Git
- 项目本身的运行环境（Python、Node、Rust 等）

## 协议

MIT
