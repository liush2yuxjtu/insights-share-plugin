# insights-share plugin

`insights-share-plugin` 是 `insights-share` 的轻量 **publish 仓**。完整开发、
proposal、demo daemon、validation 与历史记录位于 dev 仓
`liush2yuxjtu/demo_insights_share`。当前发布版本：`0.6.0-m7`。

权威设计文档：

- <https://github.com/liush2yuxjtu/demo_insights_share/blob/main/proposal/proposal_plugin_design.md>
- <https://github.com/liush2yuxjtu/demo_insights_share/blob/main/proposal/proposal_rename_to_insights_share.md>

## 双仓说明

| 仓 | GitHub 仓库 | 用途 |
|----|-------------|------|
| dev 仓 | `liush2yuxjtu/demo_insights_share` | 开发、设计、proposal、demo_codes、validation、历史 |
| plugin / publish 仓 | `liush2yuxjtu/insights-share-plugin` | 轻量分发，只保留 plugin 运行时需要的文件 |

含义：

- 日常开发、修代码、跑 `start.demo.sh`、改 proposal 都在 dev 仓
- `claude plugin marketplace add` / `claude plugin install` 推荐走这个 publish 仓
- publish 仓更新不是自动发生的，需要从 dev 仓显式同步

## 目录结构

```text
./
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── agents/
├── commands/
├── hooks/
├── mcp/
├── scripts/
├── skills/
├── statusline/
└── README.md
```

## 当前能力

- 两个 skill：`insights-share`、`insights-share-server`
- 两个 agent：`share-curator`、`share-validator`
- 五条命令：`/share-install`、`/share-search`、`/share-publish`、`/share-review`、`/share-diff`
- 一个 MCP 契约：`mcp/wiki-server.json`
- 一个 statusline badge：`[share ✓ N/today] / [share ⚠ stale] / [share 🔒 sig-fail]`
- 一套 ed25519 卡片签名链路：daemon 写入时签名，读取时验签
- 一个 publish contract 校验脚本：`scripts/publish_marketplace.py --check`

默认 daemon 入口当前硬编码为 `http://192.168.22.42:7821`。运行时仍可用
`INSIGHTS_SHARE_URL`、`INSIGHTS_DAEMON_URL` 或本地安装配置覆盖。

## 安装

推荐安装：

```bash
claude plugin marketplace add liush2yuxjtu/insights-share-plugin
claude plugin install insights-share@insights-share-plugin
```

从旧名升级：

```bash
claude plugin uninstall insights-wiki
claude plugin install insights-share@insights-share-plugin
```

如需完整开发/演示环境：

```bash
git clone git@github.com:liush2yuxjtu/demo_insights_share.git
cd demo_insights_share
bash start.demo.sh
```

## 验证

| 验证项 | 命令 | 通过标准 |
|--------|------|---------|
| manifest 合法 | `python -c 'import json; json.load(open(".claude-plugin/plugin.json"))'` | 无异常 |
| marketplace 合法 | `python -c 'import json; json.load(open(".claude-plugin/marketplace.json"))'` | 无异常 |
| skill 完整 | `ls skills/*/SKILL.md` | 两个 SKILL.md |
| hook 可执行 | `test -x hooks/user-prompt-submit.sh && bash -n hooks/user-prompt-submit.sh` | `SYNTAX OK` |
| statusline 可执行 | `SHARE_STATUSLINE_NO_COLOR=1 bash statusline/insights_share_statusline.sh` | 输出 `[share …]` / `[share ✓ N/today]` / `[share ⚠ stale]` / `[share 🔒 sig-fail]` |
| MCP 契约可解析 | `python -c 'import json; json.load(open("mcp/wiki-server.json"))'` | 无异常 |
| 合同自检 | `bash scripts/self_check.sh` | 输出 `plugin self-check: ALL GREEN` |
| 发布摘要校验 | `python scripts/publish_marketplace.py --check` | 输出 `marketplace publish contract: OK` |

## 说明

- publish 仓是 plugin root，因此 `marketplace.json` 使用 `source: "./"`
- dev 仓中的 `plugins/insights-share/` 是开发源；publish 仓是同步产物
- 本仓不包含 `demo_codes/`、`proposal/`、`validation/`，这些都留在 dev 仓
