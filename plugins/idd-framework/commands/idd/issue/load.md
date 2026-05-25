---
# Claude Code 必須要素
allowed-tools:
  - Bash(gh:*, jq:*, mkdir:*, basename:*, date:*, git:*, source:*)
  - SlashCommand(/_helpers:_get-issue-types)
  - Write(temp/idd/issues/**)
argument-hint: <issue_number>
description: GitHub IssueをロードしてMarkdown形式で保存

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: /idd:issue:load
version: 0.6.0
created: 2025-10-20
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-20: v1.0.0 - 初版作成 - GitHub Issue読み込み、種別判定、Markdown保存機能を実装
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:load - GitHub Issueをロード

GitHub APIを使用してIssue本文を取得し、種別判定を行ってMarkdown形式で保存します。

## 概要

このコマンドは以下の処理を実行します:

1. **Issue番号検証**: 引数で指定されたIssue番号の妥当性を確認
2. **GitHub API呼び出し**: `gh api` コマンドでIssue情報(title, body)を取得
3. **動的種別判定**: `/_helpers:_get-issue-types` でtitle + bodyから種別を判定
4. **ファイル名生成**: `{issue_number}-{timestamp}-{type}-{slug}.md` 形式で生成
5. **Markdown保存**: Issue内容をMarkdown形式で `temp/idd/issues/` に保存
6. **セッション保存**: `.last.session` と `.last_draft` に情報を記録

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。
詳細は `.claude/commands/_helpers/README.md` を参照。

```bash
#!/bin/bash
set -euo pipefail

# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/io-utils.lib.sh"
. "$LIBS_DIR/idd-env.lib.sh"
. "$LIBS_DIR/filename-utils.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
setup_repo_env
ISSUES_DIR=$(get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
```

## 実装指示

### Step 1: Issue番号検証

引数で渡されたIssue番号を検証します。

```bash
# 引数チェック
issue_number="${1:-}"

if [ -z "$issue_number" ]; then
  error_print <<EOF
❌ Error: Issue number required

Usage: /idd:issue:load <issue_number>
Example: /idd:issue:load 34
EOF
  exit 1
fi

# 数値チェック
if ! [[ "$issue_number" =~ ^[0-9]+$ ]]; then
  error_print <<EOF
❌ Error: Invalid issue number: $issue_number

Issue number must be a positive integer.
EOF
  exit 1
fi
```

### Step 2: GitHub API呼び出し

`gh api` コマンドを使用してIssue情報を取得します。

```bash
echo "Loading Issue #$issue_number from GitHub..."

# GitHub API呼び出し
if ! issue_json=$(gh api repos/:owner/:repo/issues/$issue_number 2>&1); then
  error_print <<EOF
❌ Error: Failed to fetch Issue #$issue_number

GitHub CLI error:
$issue_json

Please ensure:
1. 'gh' CLI is installed and authenticated (run: gh auth login)
2. Issue #$issue_number exists in this repository
3. You have access to this repository
EOF
  exit 1
fi

# Pull Request判定
if echo "$issue_json" | jq -e '.pull_request' > /dev/null 2>&1; then
  error_print <<EOF
❌ Error: #$issue_number is a Pull Request, not an Issue

This command only works with GitHub Issues.
Pull Requests cannot be loaded as Issue drafts.

To view this Pull Request:
  gh pr view $issue_number

To list available Issues:
  gh issue list
EOF
  exit 1
fi

# タイトルと本文を抽出
title=$(echo "$issue_json" | jq -r '.title // "Untitled"')
body=$(echo "$issue_json" | jq -r '.body // ""')

if [ -z "$title" ] || [ "$title" = "Untitled" ]; then
  error_print "❌ Error: Could not extract issue title"
  exit 1
fi

echo "✓ Issue retrieved"
echo "  Title: $title"
echo ""
```

### Step 3: 動的種別判定

`/_helpers:_get-issue-types` を呼び出してIssue種別を判定します。

```bash
echo "[Step 3] Determining issue type..."

# _get-issue-types を呼び出し (Claude が SlashCommand ツールで実行)
types_json=$(/_helpers:_get-issue-types "$title" "$body")

# エラー判定
if echo "$types_json" | jq -e '.result == "error"' > /dev/null 2>&1; then
  reason=$(echo "$types_json" | jq -r '.reason')
  error_print "❌ Error: Type determination failed ($reason)"
  exit 1
fi

# 種別を抽出
commit_type=$(echo "$types_json" | jq -r '.commit_type')
issue_type=$(echo "$types_json" | jq -r '.issue_type')
branch_type=$(echo "$types_json" | jq -r '.branch_type')
reasoning=$(echo "$types_json" | jq -r '.reasoning')

echo "✓ Type determined"
echo "  Commit type: $commit_type"
echo "  Issue type: $issue_type"
echo "  Branch type: $branch_type"
echo "  Reasoning: $reasoning"
echo ""
```

### Step 4: ファイル名生成

命名規則に従ってファイル名を生成します。

```bash
echo "[Step 4] Generating filename..."

# ファイルパス生成 (filename-utils.lib.sh の generate_issue_filepath を使用)
filepath=$(generate_issue_filepath "$title" "$issue_type" "$issue_number" "$ISSUES_DIR")
filename=$(basename "$filepath")

echo "✓ Filename generated"
echo "  File: $filename"
echo ""
```

### Step 5: Markdown保存

Issue内容をMarkdown形式で保存します。

```bash
echo "[Step 5] Saving to Markdown..."

# ディレクトリ作成
mkdir -p "$ISSUES_DIR"

# Markdown形式で保存 (Claude が Write ツールで実行)
# フォーマット:
# # $title
#
# $body

cat > "$filepath" <<EOF
# $title

$body
EOF

echo "✓ Saved to: $filepath"
echo ""
```

### Step 6: セッション保存

セッション情報を保存します。

```bash
echo "[Step 6] Updating session..."

# ファイル名 (拡張子なし)
filename_no_ext=$(basename "$filename" .md)

# セッション保存
_save_session "$SESSION_FILE" \
  filename "$filename_no_ext" \
  title "$title" \
  issue_type "$issue_type" \
  commit_type "$commit_type" \
  branch_type "$branch_type" \
  issue_number "$issue_number" \
  command "load"

# 最終ファイル名保存
_save_last_file "$ISSUES_DIR" "$filename"

echo "✓ Session updated"
echo ""
```

### Step 7: 完了メッセージ

ユーザーに結果を表示します。

```bash
echo "═══════════════════════════════════════"
echo "✅ Issue #$issue_number loaded successfully"
echo "═══════════════════════════════════════"
echo ""
echo "File: $filename"
echo "Location: temp/idd/issues/"
echo ""
echo "Next steps:"
echo "  /idd:issue:edit $issue_number  - Edit the issue draft"
echo "  /idd:issue:view $issue_number  - View the issue content"
echo "  /idd:issue:branch $issue_number - Generate branch name"
echo ""
```

## 使用例

### 基本的な使用方法

```bash
# Issue #34 をロード
/idd:issue:load 34

# 出力例:
# Loading Issue #34 from GitHub...
# ✓ Issue retrieved
#   Title: [Feature] /idd:issue:loadコマンドの実装
#
# [Step 3] Determining issue type...
# ✓ Type determined
#   Commit type: feat
#   Issue type: feature
#   Branch type: feat
#   Reasoning: 新機能追加のためfeat/feature/featを選択
#
# [Step 4] Generating filename...
# ✓ Filename generated
#   File: 34-20251020-185530-feature-idd-issue-load.md
#
# [Step 5] Saving to Markdown...
# ✓ Saved to: temp/idd/issues/34-20251020-185530-feature-idd-issue-load.md
#
# [Step 6] Updating session...
# ✓ Session updated
#
# ═══════════════════════════════════════
# ✅ Issue #34 loaded successfully
# ═══════════════════════════════════════
#
# File: 34-20251020-185530-feature-idd-issue-load.md
# Location: temp/idd/issues/
#
# Next steps:
#   /idd:issue:edit 34  - Edit the issue draft
#   /idd:issue:view 34  - View the issue content
#   /idd:issue:branch 34 - Generate branch name
```

### エラーケース

**Issue番号未指定**:
```bash
/idd:issue:load

# 出力:
# ❌ Error: Issue number required
#
# Usage: /idd:issue:load <issue_number>
# Example: /idd:issue:load 34
```

**無効なIssue番号**:
```bash
/idd:issue:load abc

# 出力:
# ❌ Error: Invalid issue number: abc
#
# Issue number must be a positive integer.
```

**存在しないIssue**:
```bash
/idd:issue:load 99999

# 出力:
# Loading Issue #99999 from GitHub...
# ❌ Error: Failed to fetch Issue #99999
#
# GitHub CLI error:
# {
#   "message": "Not Found",
#   "documentation_url": "https://docs.github.com/..."
# }
#
# Please ensure:
# 1. 'gh' CLI is installed and authenticated (run: gh auth login)
# 2. Issue #99999 exists in this repository
# 3. You have access to this repository
```

## 依存関係

### GitHub CLI

このコマンドは `gh` CLI を使用します:

```bash
# インストール確認
gh --version

# 認証
gh auth login

# 動作確認
gh api repos/:owner/:repo/issues/1
```

### ヘルパーライブラリ

- `io-utils.lib.sh`: エラー出力 (`error_print`)
- `idd-env.lib.sh`: 環境設定 (`setup_repo_env`, `get_temp_dir`)
- `filename-utils.lib.sh`: ファイル名生成 (`generate_slug`)
- `idd-session.lib.sh`: セッション管理 (`_save_session`, `_save_last_file`)

### ヘルパーコマンド

- `/_helpers:_get-issue-types`: Issue種別判定

## 注意事項

### GitHub APIレート制限

GitHub APIには1時間あたり60リクエスト(未認証)または5000リクエスト(認証済み)の制限があります。
`gh` CLIで認証することを推奨します。

### Issue番号の一意性

同じIssue番号で複数回ロードすると、異なるタイムスタンプで別ファイルが作成されます。
古いファイルは自動削除されないため、必要に応じて手動で削除してください。

### セッション管理

最後にロードしたIssueが `.last.session` と `.last_draft` に記録されます。
他のサブコマンド(`edit`, `view`, `branch`)で引数を省略すると、このIssueが使用されます。

## See Also

- `/idd:issue:new`: 新しいIssueを作成
- `/idd:issue:list`: Issue一覧を表示・選択
- `/idd:issue:edit`: Issueを編集
- `/idd:issue:view`: Issue内容を表示
- `/idd:issue:branch`: ブランチ名を生成
- `/_helpers:_get-issue-types`: commit/issue/branch種別のAI判定ヘルパー
- `.claude/commands/_libs/filename-utils.lib.sh`: ファイル名生成ユーティリティ
- `.claude/commands/_libs/idd-session.lib.sh`: セッション管理ライブラリ

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
