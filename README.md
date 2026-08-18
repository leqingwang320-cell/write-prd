# Write PRD — Cursor / Codex Skill

将一句话需求或零散材料，整理成与信息成熟度匹配的产品需求文档（PRD）。

## 设计理念

**结构完整不能代替业务信息真实。** AI 可以补齐流程、规则和异常，但核心方向（用户、场景、目标、MVP）必须由产品经理确认。

这个 Skill 的核心不是"帮你写文档"，而是**在 AI 天然倾向于自信补全的背景下，强行让它承认自己不知道**。

## 安装

### Cursor

从本仓库安装（推荐）：

```bash
git clone https://github.com/leqingwang320-cell/write-prd.git
cd write-prd
chmod +x install.sh
./install.sh
```

如果你已经下载了 `write-prd.tar`：

```bash
chmod +x install.sh
./install.sh /Users/didi/Downloads/write-prd.tar
```

或手动解压到 Cursor 用户技能目录：

```bash
mkdir -p ~/.cursor/skills
tar -xf /Users/didi/Downloads/write-prd.tar -C ~/.cursor/skills
# 确认结果是 ~/.cursor/skills/write-prd/SKILL.md
```

安装后执行 **Developer: Reload Window**。之后在 Agent 对话里输入 `/write-prd`，或直接说「写一份 PRD」。

### Codex

在 Codex 中使用 `skill-installer` 安装：

```
安装 write-prd skill，仓库地址：https://github.com/leqingwang320-cell/write-prd
```

或手动放入 `~/.codex/skills/write-prd/`。`./install.sh` 也会同时写入该目录。

## 工作流程

```
一句话需求
    ↓
入口门槛（九项 G-01~G-09）—— 判断信息成熟度
    ↓
┌─ 继续澄清    → 逐项追问核心方向（B0 → B1 → B2 → B3）
├─ 假设草案    → 用户授权后，逐项标记待验证
└─ 正式 PRD    → 全部确认后，生成可评审/可研发交接的文档
    ↓
复杂度裁剪      → 简单/标准/复杂，章节按需展开
    ↓
质量自检        → P0 硬阻塞 → 跨章节一致性 → 修复后交付
```

### 核心机制

- **九项硬门槛：** 核心用户、场景、问题、目标、闭环、动线、MVP、AI 边界、风险边界——缺一项就不能出正式 PRD
- **阻塞分级（B0~B3）：** B0 方向性缺口逐项处理，B2/B3 独立缺口自动批处理
- **信息状态分类：** 已确认 / 有证据 / 待验证假设 / 开放问题 / 产品决策——AI 推荐永远不能伪装成确认结论
- **渐进追问：** 每次只问最高影响问题；说"一起问"则全量列出

## 文件结构

```
write-prd/
├── SKILL.md                         ← 工作流 + 路由指引（主文件）
├── install.sh                       ← Cursor / Codex / Claude 一键安装
├── .cursor-plugin/plugin.json       ← Cursor 本地插件清单
├── agents/openai.yaml               ← Codex 界面配置
├── evals/
│   └── PRD-SKILL-CASES.md          ← 18 条回归测试用例
└── references/
    ├── PRD-ENTRY-GATE.md            ← 九项门槛 + 判定算法
    ├── PRD-COMPLEXITY-RULES.md      ← 复杂度评分 + 章节裁剪
    ├── PRD-TEMPLATE.md              ← PRD 章节模板
    ├── PRD-QUALITY-CHECKLIST.md     ← 质量自检 + 独立评审
    └── PRD-WORKING-MEMORY-TEMPLATE.md ← 跨对话项目记忆模板
```

`SKILL.md` 是驾驶舱 checklist，每次执行都在上下文中。`references/` 下的文件按需加载，不会一股脑全读。

## 协议

MIT
