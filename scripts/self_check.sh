#!/usr/bin/env bash
# plugin publish-repo self-check。
# 输出契约：每行一个组件一条 "OK"/"MISSING"/"PARSE-FAIL"，非零退出仅当有任一失败。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE="$PLUGIN_DIR/.claude-plugin/marketplace.json"
MCP_CONFIG="$PLUGIN_DIR/mcp/wiki-server.json"
PUBLISH_SCRIPT="$PLUGIN_DIR/scripts/publish_marketplace.py"

fail_count=0
say() { printf '%s\n' "$*"; }

if [ -f "$MANIFEST" ]; then
  if NAME_VER="$(/usr/bin/python3 -c 'import json,sys
m=json.load(open(sys.argv[1]))
print(m["name"]+" v"+m["version"])' "$MANIFEST" 2>/dev/null)"; then
    say "manifest: OK ($NAME_VER)"
  else
    say "manifest: PARSE-FAIL"
    fail_count=$((fail_count+1))
  fi
else
  say "manifest: MISSING"
  fail_count=$((fail_count+1))
fi

if [ -f "$MARKETPLACE" ]; then
  say "marketplace: OK"
else
  say "marketplace: MISSING"
  fail_count=$((fail_count+1))
fi

for s in insights-share insights-share-server; do
  if [ -f "$PLUGIN_DIR/skills/$s/SKILL.md" ]; then
    say "skill $s: OK"
  else
    say "skill $s: MISSING"
    fail_count=$((fail_count+1))
  fi
done

if [ -x "$PLUGIN_DIR/hooks/user-prompt-submit.sh" ]; then
  say "hook UserPromptSubmit: OK"
else
  say "hook UserPromptSubmit: MISSING"
  fail_count=$((fail_count+1))
fi

if [ -x "$PLUGIN_DIR/statusline/insights_share_statusline.sh" ]; then
  say "plugin statusline: OK"
else
  say "plugin statusline: MISSING"
  fail_count=$((fail_count+1))
fi

for c in share-install share-search share-publish share-review share-diff; do
  if [ -f "$PLUGIN_DIR/commands/$c.md" ]; then
    say "command /$c: OK"
  else
    say "command /$c: MISSING"
    fail_count=$((fail_count+1))
  fi
done

for a in share-curator share-validator; do
  if [ -f "$PLUGIN_DIR/agents/$a.md" ]; then
    say "agent $a: OK"
  else
    say "agent $a: MISSING"
    fail_count=$((fail_count+1))
  fi
done

if [ -f "$MCP_CONFIG" ]; then
  if NAME_TOOLS="$(/usr/bin/python3 -c 'import json,sys
cfg=json.load(open(sys.argv[1]))
print(cfg["name"]+" tools="+str(len(cfg.get("tools", []))))' "$MCP_CONFIG" 2>/dev/null)"; then
    say "mcp wiki-server: OK ($NAME_TOOLS)"
  else
    say "mcp wiki-server: PARSE-FAIL"
    fail_count=$((fail_count+1))
  fi
else
  say "mcp wiki-server: MISSING"
  fail_count=$((fail_count+1))
fi

if [ -f "$PUBLISH_SCRIPT" ]; then
  if /usr/bin/python3 "$PUBLISH_SCRIPT" --check >/dev/null 2>&1; then
    say "marketplace publish script: OK"
  else
    say "marketplace publish script: FAIL"
    fail_count=$((fail_count+1))
  fi
else
  say "marketplace publish script: MISSING"
  fail_count=$((fail_count+1))
fi

if [ -f "$MANIFEST" ]; then
  if /usr/bin/python3 - "$MANIFEST" "$MCP_CONFIG" "$MARKETPLACE" <<'PY' >/dev/null 2>&1
import json, sys
m = json.load(open(sys.argv[1]))
cfg = json.load(open(sys.argv[2]))
market = json.load(open(sys.argv[3]))
assert m["name"] == "insights-share", "name"
assert m["version"] == "0.6.0-m7", "version"
assert m["milestones"]["current"] == "M7_LATENCY_DEEP", "milestone current"
assert "M5_RENAME" in m["milestones"].get("completed", []), "m5 completed"
assert "M7_LATENCY_DEEP" in m["milestones"].get("partial", []), "m7 partial"
assert len(m["entry"].get("agents", [])) == 2, "agents count"
assert len(m["entry"].get("commands", [])) == 5, "commands count"
assert all(c.startswith("commands/share-") for c in m["entry"]["commands"]), "commands prefix"
assert all(a.startswith("agents/share-") for a in m["entry"]["agents"]), "agents prefix"
assert m["entry"]["statusline"] == "statusline/insights_share_statusline.sh", "statusline path"
assert m["entry"]["skills"] == [
    "skills/insights-share/SKILL.md",
    "skills/insights-share-server/SKILL.md",
], "skills paths"
assert m["requires"]["daemon"]["insightsd"] == "http://192.168.22.42:7821", "daemon url"
assert market["name"] == "insights-share-plugin", "marketplace name"
assert market["plugins"][0]["source"] == "./", "marketplace source"
assert market["plugins"][0]["version"] == m["version"], "marketplace version"
assert len(cfg.get("tools", [])) >= 7, "mcp tools"
assert cfg.get("capabilities", {}).get("signed_cards") is True, "signed cards"
PY
  then
    say "manifest M7 publish contract (name=insights-share, ver=0.6.0-m7, source=./, daemon=192.168.22.42, share-* cmds/agents, mcp>=7, signed_cards): OK"
  else
    say "manifest M7 publish contract: FAIL"
    fail_count=$((fail_count+1))
  fi
fi

if [ "$fail_count" -gt 0 ]; then
  say "plugin self-check: FAIL ($fail_count)"
  exit 1
fi
say "plugin self-check: ALL GREEN"
exit 0
