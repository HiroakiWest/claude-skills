#!/usr/bin/env bash
# addyosmani/agent-skills から、superpowers・Claude Code 組み込みコマンド・
# context7・ponytail と機能が重ならない部分だけを plugins/agent-skills/ に取り込む。
#
# 使い方: scripts/sync-agent-skills.sh [ref]   (ref の既定は main)
# 取り込み後に git diff で差分を確認してからコミットする。
set -euo pipefail

REF="${1:-main}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/plugins/agent-skills"

# 取り込むもの
SKILLS=(
  accessibility-engineering
  api-and-interface-design
  ci-cd-and-automation
  constraint-driven-development
  context-engineering
  deprecation-and-migration
  documentation-and-adrs
  frontend-ui-engineering
  observability-and-instrumentation
  performance-optimization
  security-and-hardening
  shipping-and-launch
)
AGENTS=(accessibility-auditor web-performance-auditor)
COMMANDS=(a11y webperf constraints)

# 重複のため取り込まないもの(理由は README.md の表を参照)
SKIPPED=(
  spec-driven-development idea-refine interview-me
  planning-and-task-breakdown incremental-implementation
  test-driven-development debugging-and-error-recovery
  code-review-and-quality doubt-driven-development code-simplification
  git-workflow-and-versioning source-driven-development
  browser-testing-with-devtools using-agent-skills
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone -q --filter=blob:none https://github.com/addyosmani/agent-skills.git "$TMP/src"
git -C "$TMP/src" checkout -q "$REF"
SHA="$(git -C "$TMP/src" rev-parse HEAD)"
VER="$(jq -r '.version // "unknown"' "$TMP/src/.claude-plugin/plugin.json")"

rm -rf "$DEST/skills" "$DEST/agents" "$DEST/commands" "$DEST/references"
mkdir -p "$DEST/skills" "$DEST/agents" "$DEST/commands"
for s in "${SKILLS[@]}";   do cp -r "$TMP/src/skills/$s" "$DEST/skills/"; done
for a in "${AGENTS[@]}";   do cp "$TMP/src/agents/$a.md" "$DEST/agents/"; done
for c in "${COMMANDS[@]}"; do cp "$TMP/src/.claude/commands/$c.md" "$DEST/commands/"; done
cp -r "$TMP/src/references" "$DEST/references"
cp "$TMP/src/LICENSE" "$DEST/LICENSE"
printf 'repo=addyosmani/agent-skills\nref=%s\ncommit=%s\nversion=%s\n' \
  "$REF" "$SHA" "$VER" > "$DEST/UPSTREAM"

# upstream に新しく増えたスキルは、取り込むか除外するかを決めて上の一覧に足す
known=" ${SKILLS[*]} ${SKIPPED[*]} "
for d in "$TMP/src/skills"/*/; do
  n="$(basename "$d")"
  case "$known" in *" $n "*) ;; *) echo "未分類の新しいスキル: $n" >&2 ;; esac
done

echo "取り込み完了: $SHA (upstream v$VER)"
git -C "$ROOT" status --short -- plugins/agent-skills
