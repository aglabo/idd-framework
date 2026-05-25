---
# Claude Code 必須要素
allowed-tools: Bash(git:*), Bash(gh:*), Read(*), Task(*)
argument-hint: [subcommand] [--output=file]
description: Pull Request自動生成コマンド - pr-generatorエージェントによるPRドラフト作成

# 設定変数
config:
  temp_dir: temp/idd/pr
  draft_file: pr_current_draft.md
  default_editor: ${EDITOR:-code}
  default_pager: ${PAGER:-less}
  base_branch: main

# サブコマンド定義
subcommands:
  new: "pr-generatorエージェントでPRドラフト生成"
  view: "現在のPRドラフト表示"
  edit: "PRドラフト編集"
  review: "PRドラフト詳細分析"
  push: "GitHub にPR作成"

# ag-logger プロジェクト要素
title: idd-pr
version: 0.6.0
created: 2025-09-30
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-02: Bash版に簡略化、pr-generatorエージェント連携
  - 2025-09-30: 初版作成
---

## Quick Reference

### Usage

```bash
# Main command (generate draft)
/idd-pr [options]

# Subcommands
/idd-pr <subcommand> [options]
```

### Main Options

- `--output=<filename>`: カスタムファイル名 (default: pr_current_draft.md)

### Subcommands

- `new`: pr-generator エージェントで PR ドラフト生成 (デフォルト)
- `view`: 現在の PR ドラフト表示
- `edit`: PR ドラフト編集
- `review`: PR ドラフト詳細分析
- `push`: GitHub に PR 作成

### Examples

```bash
# PRドラフト生成（tempファイルに自動保存）
/idd-pr
/idd-pr new

# カスタムファイル名で生成
/idd-pr new --output=feature-123.md

# サブコマンドで詳細操作
/idd-pr view      # ドラフト確認
/idd-pr edit      # ドラフト編集
/idd-pr review    # 詳細分析
/idd-pr push      # GitHub にPR作成
```

<!-- markdownlint-disable no-duplicate-heading -->

## Implementation

このコマンドでは、Claude が以下の処理を実行:

1. **設定読み込み**: メタデータの `config` セクションから設定を取得
2. **パス構築**: `{git_root}/{temp_dir}/{draft_file}` でドラフトファイルパスを構築
3. **サブコマンド実行**: 以下のいずれかを実行

### Subcommand: new (デフォルト)

```bash
#!/bin/bash
# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"
. "$LIBS_DIR/idd-session.lib.sh"

# Setup
REPO_ROOT=$(git rev-parse --show-toplevel)
PR_DIR="$REPO_ROOT/temp/idd/pr"
OUTPUT_FILE="${1:-pr_current_draft.md}"  # --output=XXX から解析
DRAFT_PATH="$PR_DIR/$OUTPUT_FILE"
mkdir -p "$PR_DIR"

# Parse --output option if provided
for arg in "$@"; do
  if [[ "$arg" =~ ^--output=(.+)$ ]]; then
    OUTPUT_FILE="${BASH_REMATCH[1]}"
    DRAFT_PATH="$PR_DIR/$OUTPUT_FILE"
  fi
done

# Save the output filename for later use
_save_last_file "$PR_DIR" "$OUTPUT_FILE"

echo "🚀 Launching pr-generator agent..."
echo "📝 Output file: $DRAFT_PATH"
echo ""
echo "📊 Agent will analyze:"
echo "  - Current branch commits"
echo "  - File changes"
echo "  - Related issues"
echo "  - PR template structure"
echo ""
echo "⏳ Please wait for pr-generator agent to complete..."

# Note: Claude will invoke pr-generator agent via Task tool
# Agent prompt: "Generate PR draft and save to: $DRAFT_PATH"
```

### Subcommand: view

```bash
#!/bin/bash
# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"
. "$LIBS_DIR/idd-session.lib.sh"

REPO_ROOT=$(git rev-parse --show-toplevel)
PR_DIR="$REPO_ROOT/temp/idd/pr"
OUTPUT_FILE=$(_load_last_file "$PR_DIR" "pr_current_draft.md")

DRAFT_FILE="$PR_DIR/$OUTPUT_FILE"
PAGER="${PAGER:-less}"

if [[ -f "$DRAFT_FILE" ]]; then
  echo "📄 Current PR Draft:"
  echo "=================================================="
  $PAGER "$DRAFT_FILE"
else
  echo "❌ No current PR draft found."
  echo "💡 Run '/idd-pr new' to generate one."
fi
```

### Subcommand: edit

```bash
#!/bin/bash
# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"
. "$LIBS_DIR/idd-session.lib.sh"

REPO_ROOT=$(git rev-parse --show-toplevel)
PR_DIR="$REPO_ROOT/temp/idd/pr"
OUTPUT_FILE=$(_load_last_file "$PR_DIR" "pr_current_draft.md")

DRAFT_FILE="$PR_DIR/$OUTPUT_FILE"
EDITOR="${EDITOR:-code}"

if [[ -f "$DRAFT_FILE" ]]; then
  echo "📝 Opening in editor: $EDITOR"
  $EDITOR "$DRAFT_FILE"
  echo "✅ Draft opened in editor"
else
  echo "❌ No current PR draft found."
  echo "💡 Run '/idd-pr new' to generate one."
fi
```

### Subcommand: push

```bash
#!/bin/bash
# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"
. "$LIBS_DIR/idd-session.lib.sh"

REPO_ROOT=$(git rev-parse --show-toplevel)
PR_DIR="$REPO_ROOT/temp/idd/pr"
OUTPUT_FILE=$(_load_last_file "$PR_DIR" "pr_current_draft.md")

DRAFT_FILE="$PR_DIR/$OUTPUT_FILE"

if [[ ! -f "$DRAFT_FILE" ]]; then
  echo "❌ No current PR draft found."
  echo "💡 Run '/idd-pr new' to generate one."
  exit 1
fi

# Extract title from first line (H1 heading)
TITLE=$(head -n 1 "$DRAFT_FILE" | sed 's/^# *//')

if [[ -z "$TITLE" ]]; then
  echo "❌ Could not extract title from draft"
  echo "💡 First line should be an H1 heading (# Title)"
  exit 1
fi

# Determine base branch (parent branch of current branch)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
BASE_BRANCH="main"

# Find parent branch by checking merge-base with all branches
BEST_DISTANCE=999999
CANDIDATES=()

for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/origin/ | grep -v "$CURRENT_BRANCH" | grep -v "^origin$"); do
  # Skip remote tracking branches if local exists
  if [[ "$branch" =~ ^origin/ ]]; then
    LOCAL_NAME="${branch#origin/}"
    if git show-ref --verify --quiet "refs/heads/$LOCAL_NAME"; then
      continue
    fi
  fi

  # Calculate merge-base and distance
  MERGE_BASE=$(git merge-base "$CURRENT_BRANCH" "$branch" 2>/dev/null || echo "")
  if [[ -n "$MERGE_BASE" ]]; then
    DISTANCE=$(git rev-list --count "$MERGE_BASE..$CURRENT_BRANCH")
    if [[ $DISTANCE -gt 0 ]]; then
      if [[ $DISTANCE -lt $BEST_DISTANCE ]]; then
        BEST_DISTANCE=$DISTANCE
        CANDIDATES=("$branch")
      elif [[ $DISTANCE -eq $BEST_DISTANCE ]]; then
        CANDIDATES+=("$branch")
      fi
    fi
  fi
done

# If multiple candidates with same distance, prioritize main/master
FOUND_MAIN=false
for candidate in "${CANDIDATES[@]}"; do
  CLEAN_NAME="${candidate#origin/}"
  if [[ "$CLEAN_NAME" == "main" ]] || [[ "$CLEAN_NAME" == "master" ]]; then
    BASE_BRANCH="$CLEAN_NAME"
    FOUND_MAIN=true
    break
  fi
done

# If no main/master found, use first candidate
if [[ "$FOUND_MAIN" == false ]] && [[ ${#CANDIDATES[@]} -gt 0 ]]; then
  BASE_BRANCH="${CANDIDATES[0]#origin/}"
fi

echo "🚀 Creating PR: $TITLE"
echo "📌 Base branch: $BASE_BRANCH (detected parent)"

# Extract body (skip H1 title and empty line)
BODY_FILE="$PR_DIR/pr_body.txt"
tail -n +3 "$DRAFT_FILE" > "$BODY_FILE"

# Create PR using GitHub CLI with auto-detected base branch
if gh pr create --base "$BASE_BRANCH" --title "$TITLE" --body-file "$BODY_FILE"; then
  echo "🎉 PR successfully created!"

  # Clean up draft and temporary files
  rm -f "$DRAFT_FILE"
  rm -f "$LAST_DRAFT"
  rm -f "$BODY_FILE"
  echo "🗑️ Draft file cleaned up"
else
  echo "❌ GitHub CLI error"
  echo "💡 Tip: Make sure you have push permissions and gh CLI is authenticated"
  rm -f "$BODY_FILE"
  exit 1
fi
```

## アーキテクチャの特徴

- エージェント連携: PR 生成の複雑なロジックを pr-generator エージェントに委譲
- GitHub CLI 統合: `gh pr create` による PR 作成
- Bash シンプル実装: 各サブコマンドは 10-40行の軽量 Bash スクリプト
- 明確な責務分離: 生成 (agent)、作成 (gh CLI)、ユーティリティ (local scripts) を分離
- 設定の一元管理: フロントマターで設定・サブコマンド定義を集約
- 保守しやすい設計: 特定機能の修正時に該当セクションのみ変更すればよい。
- 拡張しやすい設計: 新サブコマンドは新セクション追加のみで実現可能。

## pr-generatorエージェントとの連携

`/idd-pr new` コマンドは以下の流れで動作:

1. **コマンド実行**: ユーザーが `/idd-pr new [--output=file]` を実行
2. **パラメータ解析**: 出力ファイル名を決定 (デフォルト: `pr_current_draft.md`)
3. **エージェント起動**: Claude が Task tool で pr-generator エージェントを起動
4. **エージェント処理**:
   - Git 情報収集 (commits, file changes, issues)
   - `.github/PULL_REQUEST_TEMPLATE.md` 読み込み
   - Conventional Commit 形式のタイトル生成
   - PR ドラフト生成 (1行目: H1 タイトル、3行目以降: テンプレート構造)
   - `temp/idd/pr/{output_file}` に保存
5. **完了報告**: エージェントが生成結果を報告

`/idd-pr push` コマンドは以下の流れで動作:

1. **ドラフト読み込み**: `temp/idd/pr/` から最後に生成されたドラフトを読み込み
2. **タイトル抽出**: 1行目の H1 見出しからタイトルを取得
3. **本文抽出**: 3行目以降 (H1 と空行をスキップ) を PR 本文として抽出
4. **PR 作成**: `gh pr create` を使用して GitHub に PR を作成
5. **クリーンアップ**: 成功後にドラフトファイルと一時ファイルを削除

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
