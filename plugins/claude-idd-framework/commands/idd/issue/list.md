---
# Claude Code 必須要素
allowed-tools:
  Bash(
  ls:*, basename:*, sed:*, jq:*, echo:*, cat:*, stat:*,
  source:*, xargs:*, head:*, git:*
  ),
  Read(*),
  mcp__serena-mcp__*,
  mcp__lsmcp__*
argument-hint: (no arguments)
description: Issueドラフト一覧表示し、選択

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: idd-issue-list
version: 0.5.0
created: 2025-10-16
authors:
  - atsushifx
changes:
  - 2025-10-16: 初版作成 - Issue一覧表示とセッション準備機能を実装
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd-issue list

保存済み Issue ドラフトの一覧から対話的に Issue を選択するサブコマンドです。

## 概要

このコマンドは以下の処理を実行します:

1. Issue ドラフトディレクトリからファイル一覧を取得 (最新順)
2. `/_helpers:_select-from-list` を呼び出して対話的に Issue を選択
3. 選択した Issue を `.last.session` に保存
4. 選択結果を表示

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。
詳細は `.claude/commands/_helpers/README.md` を参照。

```bash
#!/bin/bash
# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/io-utils.lib.sh"
. "$LIBS_DIR/idd-env.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
_setup_repo_env
ISSUES_DIR=$(_get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
```

## メインブロック

```bash
#!/bin/bash
# Main execution flow
check_issues_exist || exit 0

files=$(get_issue_list)
current_issue=$(get_current_issue_from_session)
input_json=$(build_selection_json "$files" "$current_issue")

output=$(call_select-from-list "$input_json") || exit 0

selected=$(process_selection_result "$output") || exit 1
save_selected_issue "$selected"
display_selection_result "$selected"
```

## 依存関係

### ヘルパーライブラリ

- `io-utils.lib.sh`: エラー出力 (`error_print`)
- `idd-env.lib.sh`: リポジトリ環境設定 (`_setup_repo_env`, `_get_temp_dir`)
- `idd-session.lib.sh`: セッション管理 (`_load_session`)

### ヘルパーコマンド

- `/_helpers:_select-from-list`: 対話的リスト選択インターフェース

詳細は `.claude/commands/_helpers/README.md` を参照してください。

## 使用例

### 基本的な使用方法

```bash
# Issue 一覧から選択
/idd-issue list

# 対話的に選択:
# === Select an item ===
#
#  1. > 22-251016-150120-enhancement-idd-issue-rewrite
#  2.   21-251016-151030-enhancement-claude-mcp-integration
#
# Enter number (1-2), or 'q' to cancel: 1
#
# Selected: 22-251016-150120-enhancement-idd-issue-rewrite
# Title: [Enhancement]idd-issueコマンドの全面的な書き直し
```

### 選択後の操作

選択した Issue は `.last.session` に保存されます:

```bash
LAST_ISSUE_FILE="22-251016-150120-enhancement-idd-issue-rewrite"
```

選択後、以下のコマンドで操作できます:

```bash
/idd-issue view     # Issue 内容を表示
/idd-issue edit     # Issue を編集
/idd-issue push     # GitHub に Issue をプッシュ
/idd-issue branch   # Issue からブランチ名を提案
```

## 注意事項

### Issue が存在しない場合

Issue ドラフトが存在しない場合、以下のメッセージを表示して終了します:

```bash
No issues found. Run: /idd-issue new
```

### 選択のキャンセル

選択プロンプトで `q` を入力すると選択をキャンセルできます:

```bash
Enter number (1-2), or 'q' to cancel: q
Selection cancelled.
```

## Bash 関数ライブラリ

```bash
# ============================================================
# Issue存在チェック関数
# ============================================================

# Issue ディレクトリの存在と Issue ファイルの有無をチェック
# 戻り値: 0=Issues存在, 1=Issues不在 (メッセージ表示)
check_issues_exist() {
  if [ ! -d "$ISSUES_DIR" ] || \
     [ -z "$(ls -A "$ISSUES_DIR"/*.md 2>/dev/null)" ]; then
    echo "No issues found. Run: /idd-issue new"
    return 1
  fi
  return 0
}

# ============================================================
# Issue一覧取得関数
# ============================================================

# Issue ファイル一覧を取得 (最新順)
# 戻り値: 標準出力にファイル名リスト (拡張子なし)
get_issue_list() {
  mapfile -t files < <(
    ls -t "$ISSUES_DIR"/*.md 2>/dev/null | \
    xargs -n1 basename | \
    sed 's/\.md$//'
  )
  printf '%s\n' "${files[@]}"
}

# ============================================================
# セッション管理関数
# ============================================================

# セッションファイルから現在選択中の Issue を取得
# 戻り値: 標準出力に Issue ファイル名、なければ空文字列
get_current_issue_from_session() {
  local current_issue=""
  if _load_session "$SESSION_FILE" && [ -n "$LAST_ISSUE_FILE" ]; then
    current_issue="$LAST_ISSUE_FILE"
  fi
  echo "$current_issue"
}

# 選択した Issue をセッションファイルに保存
# 引数: $1 - 選択された Issue ファイル名
save_selected_issue() {
  local selected="$1"
  echo "LAST_ISSUE_FILE=\"$selected\"" > "$SESSION_FILE"
}

# ============================================================
# JSON構築関数
# ============================================================

# /_helpers:_select-from-list 用の JSON 入力を構築
# 引数: $1 - ファイルリスト (改行区切り), $2 - 現在選択中のファイル名 (オプション)
# 戻り値: 標準出力に JSON 文字列
build_selection_json() {
  local files="$1"
  local current_issue="$2"

  # Convert files to JSON array
  local items_json=$(echo "$files" | jq -R . | jq -s .)

  if [ -n "$current_issue" ]; then
    jq -n \
      --argjson items "$items_json" \
      --arg current "$current_issue" \
      '{items: $items, current: $current}'
  else
    jq -n \
      --argjson items "$items_json" \
      '{items: $items}'
  fi
}

# ============================================================
# ヘルパーコマンド呼び出し関数
# ============================================================

# /_helpers:_select-from-list を呼び出して Issue を選択
# 引数: $1 - JSON 入力文字列
# 戻り値: 標準出力に選択結果 JSON、キャンセル時は exit 1
call_select-from-list() {
  local input_json="$1"

  # Call _select-from-list as subprocess
  # Note: This requires claude CLI to be available in PATH
  local output=$(echo "$input_json" | claude run --no-prompt /_helpers:_select-from-list)

  echo "$output"
}

# ============================================================
# 選択結果処理関数
# ============================================================

# 選択結果 JSON を処理・検証
# 引数: $1 - 選択結果 JSON
# 戻り値: 標準出力に選択された Issue ファイル名、エラー時は exit 1
process_selection_result() {
  local output="$1"

  # Check if selection was cancelled
  if echo "$output" | jq -e '.cancel' >/dev/null 2>&1; then
    echo "Selection cancelled."
    return 1
  fi

  # Extract selected issue
  local selected=$(echo "$output" | jq -r '.selected')

  if [ -z "$selected" ] || [ "$selected" = "null" ]; then
    error_print "Failed to get selection"
    return 1
  fi

  echo "$selected"
  return 0
}

# ============================================================
# 表示関数
# ============================================================

# 選択結果を表示 (ファイル名とタイトル)
# 引数: $1 - 選択された Issue ファイル名
display_selection_result() {
  local selected="$1"
  local issue_file="$ISSUES_DIR/${selected}.md"

  # Extract title from first line (remove leading "# ")
  local title=$(head -1 "$issue_file" | sed 's/^# //')

  echo ""
  echo "Selected: $selected"
  echo "Title: $title"
}
```

## See Also

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
