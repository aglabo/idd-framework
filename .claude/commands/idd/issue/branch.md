---
# Claude Code 必須要素
allowed-tools:
  - Bash(git:*, date:*, cat:*, grep:*)
  - Read(temp/idd/issues/**)
  - Write(temp/idd/issues/**)
  - SlashCommand(/_helpers:_get-issue-types)
  - SlashCommand(/_helpers:_select-from-list)
  - Task(commit-message-generator)
  - mcp__codex-mcp__codex
argument-hint: [subcommand (new|commit)] [options (--base <domain>)]
description: Issue選択からブランチ作成・コミットまでの統合ワークフロー

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  branch_session_file: temp/idd/issues/.branch.session

# ag-logger プロジェクト要素
title: /idd:issue:branch
version: 0.6.0
created: 2025-10-23
authors:
  - atsushifx
changes:
  - 2026-05-25: version 0.6.0 — marketplace release unification
  - 2025-10-27: T19実装完了 (使い方セクション・使用例セクション追加)
  - 2025-10-27: T18実装完了 (フロントマター完成: allowed-toolsの具体化)
  - 2025-10-26: ブランチ既存エラー処理実装 (T10-3: Branch already exists validation)
  - 2025-10-23: newサブコマンド統合完了 (T7: 完全な処理フロー, 9テスト全合格)
  - 2025-10-23: ドメイン検出機能実装 (T3: detect_domain)
  - 2025-10-23: サブコマンドルーティング実装 (T2)
  - 2025-10-23: 初版作成 (T1: 基本構造とセッション管理)
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:branch - Issue統合ワークフロー

選択されたIssueから、ブランチ提案、ブランチ作成、コミット統合までの一連のワークフローを管理します。

## 初期設定

コマンド実行の最初に、以下の初期設定を行います:

```bash
#!/bin/bash
set -euo pipefail

# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/filename-utils.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"
. "$LIBS_DIR/prereq-check.lib.sh"

# Issue-specific environment setup
setup_repo_env
ISSUES_DIR=$(get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
BRANCH_SESSION_FILE="$ISSUES_DIR/.branch.session"
```

この初期設定により:

- `set -euo pipefail`: エラー時の即座終了、未定義変数の検出、パイプラインエラーの伝播
- リポジトリルートを動的に取得し、ライブラリパスを構築
- 必要なライブラリを事前に読み込み、全ステップで利用可能に
- Issue管理用のディレクトリとセッションファイルのパスを設定
- ブランチ提案用の専用セッションファイルを設定

## セッション管理

### Issueセッション読み込み

```bash
# Load issue session
if ! _load_issue_session "$SESSION_FILE"; then
  exit 1
fi

# Available variables after loading:
# - filename: Issue draft filename (without extension)
# - issue_number: GitHub Issue number (empty if not pushed)
# - TITLE: Issue title
# - ISSUE_TYPE: Issue type (feature, bug, enhancement, task)
# - COMMIT_TYPE: Commit type (feat, fix, refactor, etc.)
# - BRANCH_TYPE: Branch type (feat, fix, refactor, etc.)
# - command: Last executed command
```

セッションロードが失敗した場合:

```
❌ No issue selected.
💡 Run '/idd:issue:list' to select an issue, or
   '/idd:issue:new' to create one.
```

## サブコマンドルーティング

### 引数解析とルーティング

```bash
# Parse subcommand and options using parse_subcommand_and_options()
# Function is defined in script library section below
# SUBCOMMAND and BRANCH_OPTIONS are set as global variables
parse_subcommand_and_options "$@" || exit 1

# Route to subcommand handler with parsed options
case "$SUBCOMMAND" in
  new)
    # Delegate to new subcommand implementation
    # Options are already parsed in BRANCH_OPTIONS associative array
    subcommand_new
    exit $?
    ;;
  commit)
    # Delegate to commit subcommand implementation
    # Options are already parsed in BRANCH_OPTIONS associative array
    subcommand_commit
    exit $?
    ;;
  help)
    # Show help message
    subcommand_help
    ;;
  *)
    echo "❌ Error: Unknown subcommand '$SUBCOMMAND'"
    echo ""
    echo "Available subcommands:"
    echo "  new      - Create branch proposal session (default)"
    echo "  commit   - Create branch and integrate commit"
    echo "  help     - Show help message"
    echo ""
    echo "Usage: /idd:issue:branch [new|commit|help] [options]"
    exit 1
    ;;
esac
```

このルーティングロジックにより:

- 引数なしの場合、デフォルトで `new` サブコマンドを実行
- `new` または `commit` を認識し、対応する関数に処理を委譲
- 不明なサブコマンドの場合、エラーメッセージと使用法を表示

## サブコマンド

### new - ブランチ提案セッション作成

`subcommand_new()` 関数が実装します。詳細は「## スクリプトライブラリ」セクションを参照してください。

(T3以降で実装)

### commit - ブランチ作成とコミット統合

`subcommand_commit()` 関数が実装します。詳細は「## スクリプトライブラリ」セクションを参照してください。

(T14以降で実装)

## 使い方

このコマンドは2段階のワークフローでブランチ作成を支援します:

### new サブコマンド (ブランチ提案)

1. **前提条件チェック** (`check_prerequisites` → `validate_git_full`)
   - `git` コマンドの存在確認 (Git 2.23以降)
   - Gitリポジトリ内であることを確認
   - ※ `.claude/commands/_libs/prereq-check.lib.sh` の関数を使用

2. **Issueセッション読み込み** (`_load_issue_session`)
   - `.last.session` からIssue情報を読み込み
   - TITLE, BRANCH_TYPE, issue_number などを取得

3. **ドメイン検出** (`detect_domain`)
   - タイトルから `[domain]` プレフィックスを抽出
   - `--domain` オプションで上書き可能
   - フォールバック: issue_typeに基づくデフォルト

4. **ブランチ名生成** (`generate_branch_name`)
   - 形式: `{branch_type}-{issue_number}/{domain}/{slug}`
   - スラッグは50文字以内に制限

5. **ベースブランチ決定** (`determine_base_branch`)
   - デフォルト: 現在のブランチ
   - `--base` オプションで上書き可能

6. **ブランチ提案セッション保存** (`save_branch_session`)
   - 提案内容を `.branch.session` に保存
   - タイムスタンプ付きで永続化

7. **提案表示とNext Steps**
   - 提案ブランチ名、ドメイン、ベースブランチを表示
   - `/idd:issue:branch commit` で実行するよう案内

### commit サブコマンド (ブランチ作成)

1. **ブランチ提案セッション読み込み** (`load_branch_session`)
   - `.branch.session` から提案内容を取得
   - セッションなしの場合はエラー

2. **Git状態検証** (`validate_git_state`)
   - 未コミット変更の検出
   - ※ 未追跡ファイルのみの場合は許可

3. **ブランチ存在チェック** (`check_branch_exists`)
   - 提案ブランチが既存でないことを確認

4. **ブランチ作成** (`create_branch`)
   - 必要に応じてベースブランチへ切り替え
   - `git switch -c` で新ブランチ作成

5. **Issueセッション更新** (`update_session_with_branch`)
   - `.last.session` に作成ブランチ名を追加
   - LAST_BRANCH_NAME フィールドを設定

6. **セッションクリーンアップ** (`cleanup_branch_session`)
   - `.branch.session` を削除
   - 一時データのクリーンアップ

## 使用例

### 基本的なワークフロー

Issue選択後、ブランチ提案から作成まで:

```bash
# 1. Issueを選択 (list または new コマンド経由)
/idd:issue:list
# または
/idd:issue:new "Add new feature"

# 2. ブランチ提案を作成 (デフォルト: 現在のブランチがベース)
/idd:issue:branch
# または明示的に new サブコマンド指定
/idd:issue:branch new

# 出力例:
# 📋 Current branch: main
# 🌿 Suggested branch: feat-27/feature/add-new-feature
# 📁 Domain: feature (detected from issue type)
# 🔀 Base branch: main
#
# 💡 Next steps:
#   - Review the suggestion
#   - Run '/idd:issue:branch commit' to create the branch
#   - Run '/idd:issue:branch new --domain <name>' to override domain
#   - Run '/idd:issue:branch new --base <branch>' to change base branch

# 3. ブランチを作成
/idd:issue:branch commit

# 出力例:
# ✅ Already on base branch 'main'
# ✅ Created and switched to branch: feat-27/feature/add-new-feature
# 💾 Updated issue session with branch name
# 🧹 Branch session cleaned up
```

### オプション使用例

#### --domain オプション

タイトルから自動検出されるドメインを上書き:

```bash
# タイトルが "Add logging functionality" の場合
# デフォルト: domain=feature (issue_typeベース)

# ドメインを明示的に指定
/idd:issue:branch new --domain scripts

# 出力:
# 🌿 Suggested branch: feat-27/scripts/add-logging-functionality
# 📁 Domain: scripts (overridden)
```

#### --base オプション

ベースブランチを現在のブランチ以外に指定:

```bash
# 現在 main ブランチだが、develop からブランチを切りたい場合
/idd:issue:branch new --base develop

# 出力:
# 📋 Current branch: main
# 🌿 Suggested branch: feat-27/feature/add-feature
# 🔀 Base branch: develop (will switch before creating)

# commit 時に自動的に develop へ切り替え
/idd:issue:branch commit

# 出力:
# 🔀 Switching to base branch: develop
# ✅ Switched to branch: develop
# ✅ Created and switched to branch: feat-27/feature/add-feature
```

#### 複数オプション併用

```bash
/idd:issue:branch new --domain scripts --base develop
```

### エラーケース例

#### Case 1: Issueセッションなし

```bash
/idd:issue:branch

# 出力:
# ❌ No issue selected.
# 💡 Run '/idd:issue:list' to select an issue, or
#    '/idd:issue:new' to create one.
```

#### Case 2: 未コミット変更あり

```bash
/idd:issue:branch commit

# 出力:
# ❌ Uncommitted changes detected. Please commit or stash them first.
#
# Modified files:
#   M  src/components/Button.tsx
#   M  src/styles/main.css
#
# 💡 Options:
#    - git status              # View changes
#    - git add . && git commit # Commit changes
#    - git stash               # Stash changes
```

#### Case 3: ブランチ既存エラー

```bash
/idd:issue:branch commit

# 出力 (ブランチが既に存在する場合):
# ❌ Error: Branch 'feat-27/feature/add-feature' already exists.
# 💡 Switch to it with: git switch feat-27/feature/add-feature
```

#### Case 4: ブランチ提案セッションなし

```bash
/idd:issue:branch commit
# (new サブコマンドを実行せずに commit した場合)

# 出力:
# ❌ No branch proposal found.
# 💡 Run '/idd:issue:branch' first to create a proposal.
```

#### Case 5: ベースブランチ不存在

```bash
/idd:issue:branch new --base nonexistent
/idd:issue:branch commit

# 出力:
# ❌ Error: Base branch 'nonexistent' does not exist.
```

## スクリプトライブラリ

サブコマンド:

```bash
##
# @brief Create branch proposal session
# @description Handles the 'new' subcommand to create a branch proposal
# @param $@ Command-line arguments (--base, --domain, etc.)
# @return 0 on success, 1 on failure
##
subcommand_new() {
  # Read options from associative array
  local domain_override="${BRANCH_OPTIONS["domain"]:-}"
  local base_override="${BRANCH_OPTIONS["base"]:-}"

  # 1. Get current branch
  local current_branch
  current_branch=$(git branch --show-current)

  # 2. Detect domain (uses TITLE, ISSUE_TYPE from session)
  local domain
  if [ -n "$domain_override" ]; then
    export DOMAIN="$domain_override"  # For detect_domain to prioritize
  fi
  domain=$(detect_domain "$TITLE" "${ISSUE_TYPE:-feature}")

  # 3. Determine base branch
  local base_branch
  base_branch=$(determine_base_branch "$current_branch" "$base_override")

  # 4. Generate branch name
  local suggested_branch
  suggested_branch=$(generate_branch_name "${BRANCH_TYPE:-feat}" "${issue_number:-new}" "$domain" "$TITLE")

  # 5. Save branch session
  save_branch_session "$ISSUES_DIR" "$suggested_branch" "$domain" "$base_branch" "${issue_number:-new}"

  # 6. Display proposal
  echo ""
  echo "📋 Branch Proposal"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Issue: ${TITLE}"
  echo "  Current branch: ${current_branch}"
  echo "  Suggested branch: ${suggested_branch}"
  if [ -n "$domain_override" ]; then
    echo "  Domain: ${domain} (overridden)"
  else
    echo "  Domain: ${domain}"
  fi
  if [ "$base_branch" != "$current_branch" ]; then
    echo "  Base branch: ${base_branch} (will switch before creating)"
  else
    echo "  Base branch: ${base_branch}"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "💡 Next steps:"
  echo "  - /idd:issue:branch commit  : Create the branch and switch to it"
  echo "  - /idd:issue:branch --domain <name>  : Override domain detection"
  echo "  - /idd:issue:branch --base <branch>  : Specify different base branch"
  echo ""

  return 0
}

##
# @brief Create branch and integrate commit
# @description Handles the 'commit' subcommand to create branch and commit
# @param $@ Command-line arguments
# @return 0 on success, 1 on failure
##
subcommand_commit() {
  # BDD Test: T14 - Complete commit subcommand workflow integration
  # Given: .branch.session exists
  # When: commitサブコマンド実行
  # Then: [正常] - ブランチ作成とセッション更新が完了

  # T8: Load branch session
  if ! load_branch_session "$ISSUES_DIR"; then
    error_print "❌ No branch proposal found."
    error_print "💡 Run '/idd:issue:branch' first to create a proposal."
    return 2
  fi

  # T9: Validate Git state (check for uncommitted changes)
  if ! validate_git_state; then
    return 3
  fi

  # T10: Check if suggested branch already exists
  if check_branch_exists "$SUGGESTED_BRANCH"; then
    error_print "❌ Branch already exists: $SUGGESTED_BRANCH"
    error_print "💡 Switch to it with: git switch $SUGGESTED_BRANCH"
    return 5
  fi

  # T11: Create branch (handles base branch switching internally)
  if ! create_branch "$SUGGESTED_BRANCH" "$BASE_BRANCH"; then
    # Error already printed by create_branch
    # T14-3: Preserve .branch.session on error (do not call cleanup)
    return 6
  fi

  echo ""
  echo "✅ Branch created: $SUGGESTED_BRANCH"
  echo ""

  # T12: Update Issue session with branch name
  if ! update_session_with_branch "$SESSION_FILE" "$SUGGESTED_BRANCH"; then
    error_print "⚠️ Warning: Failed to update Issue session"
    # Continue anyway - branch was created successfully
  fi

  # T13: Cleanup branch session (successful completion)
  cleanup_branch_session "$(dirname "$SESSION_FILE")/.branch.session"

  echo "💡 Next steps:"
  echo "  - Make your changes"
  echo "  - Commit with: git commit"
  echo "  - Push with: git push -u origin $SUGGESTED_BRANCH"
  echo ""

  return 0
}

##
# @brief Show help message for branch command
# @description Displays usage information and available subcommands using heredoc
# @return 0 on success
##
subcommand_help() {
  cat <<'EOF'

Usage: /idd:issue:branch [SUBCOMMAND] [OPTIONS]

Create and manage Git branches from issue sessions.

Subcommands:
  new      Create branch proposal from issue (default)
  commit   Create branch and switch to it
  help     Show this help message

Options (for 'new' and 'commit'):
  --domain <name>   Override automatic domain detection
                    (hyphens converted to underscores)
  --base <branch>   Specify base branch (default: current or main)

Examples:
  /idd:issue:branch              # Create branch proposal (default 'new')
  /idd:issue:branch new          # Same as above
  /idd:issue:branch new --domain claude_command
  /idd:issue:branch new --base develop
  /idd:issue:branch commit       # Create and switch to branch
  /idd:issue:branch help         # Show this help

EOF
  return 0
}
```

```bash
#!/bin/bash

##
# @brief Get domain from title and issue type using Codex-MCP
# @description Uses AI semantic inference to determine the appropriate domain
# @param $1 Title string (may contain [type] prefix for context)
# @param $2 Issue type (feature, bug, enhancement, task)
# @return 0 on success with output, 1 on failure (no output)
# @stdout Inferred domain string (empty if inference fails)
##
_get_domain_use_codex() {
  local title="$1"
  local issue_type="$2"

  local codex_prompt="Based on the issue title \"$title\" and issue type \"$issue_type\", infer the most appropriate domain name for a Git branch in ONE WORD.

Examples:
- Title: \"Add /idd-issue command\", Type: feature → claude-commands
- Title: \"[claude-commands] Add feature\", Type: feature → claude-commands
- Title: \"Fix xcp.sh bug\", Type: bug → scripts
- Title: \"[scripts] Add utility\", Type: feature → scripts
- Title: \"Update README\", Type: enhancement → docs
- Title: \"Implement feature\", Type: feature → feature
- Title: \"Fix validation error\", Type: bug → bugfix

Note: If title contains [type] prefix, treat it as the issue type/category, not domain.
Return ONLY the domain name, no explanation."

  # Call Codex-MCP for inference (early return on failure)
  local codex_result
  if ! codex_result=$(claude mcp__codex-mcp__codex --prompt "$codex_prompt" 2>/dev/null | tail -n 1 | tr -d '[:space:]'); then
    return 1
  fi

  # Early return if result is empty
  if [ -z "$codex_result" ]; then
    return 1
  fi

  # Success path
  echo "$codex_result"
  return 0
}

##
# @brief Get domain from issue type (fallback mapping)
# @description Provides default domain mapping when Codex is unavailable
# @param $1 Issue type (feature, bug, enhancement, task)
# @return 0 on success
# @stdout Mapped domain string
##
_get_domain_from_issue_type() {
  local issue_type="$1"

  case "$issue_type" in
    bug)
      echo "bugfix"
      ;;
    feature)
      echo "feature"
      ;;
    enhancement)
      echo "enhancement"
      ;;
    task)
      echo "task"
      ;;
    *)
      # Fallback to issue_type as-is
      echo "$issue_type"
      ;;
  esac

  return 0
}

##
# @brief Detect domain from issue title (coordinator function)
# @description Determines domain using priority-based strategy:
#   1. DOMAIN variable (--domain option, highest priority)
#   2. Codex-MCP inference (unless no_codex="no_codex")
#   3. Issue type mapping (fallback)
# @param $1 Title string
# @param $2 Issue type (default: "feature")
# @param $3 no_codex flag ("no_codex" to disable Codex, empty to enable)
# @return 0 on success
# @stdout Domain string
# @example
#   domain=$(detect_domain "Add /idd-issue command" "feature")
#   domain=$(detect_domain "Fix bug" "bug" "no_codex")
##
detect_domain() {
  local title="$1"
  local issue_type="${2:-feature}"
  local no_codex="${3:-}"

  # Priority 1: --domain option override
  if [ -n "${DOMAIN:-}" ]; then
    echo "$DOMAIN"
    return 0
  fi

  # Priority 2: Codex-MCP inference
  if [ "$no_codex" != "no_codex" ]; then
    local domain
    if domain=$(_get_domain_use_codex "$title" "$issue_type"); then
      echo "$domain"
      return 0
    fi
  fi

  # Priority 3: Fallback mapping
  _get_domain_from_issue_type "$issue_type"
  return 0
}
```

```bash
##
# @brief Parse subcommand and options from command-line arguments
# @description Analyzes arguments to determine subcommand and options.
#   If first argument starts with '--', treats it as option with default 'new' subcommand.
#   Otherwise, treats first argument as subcommand (default: 'new').
#   Options are parsed into associative array with keys: domain, base.
# @param $@ All command-line arguments
# @return 0 on success
# @stdout Subcommand name (new, commit, help)
# @global BRANCH_OPTIONS Associative array of parsed options (keys: domain, base)
# @example
#   declare -A BRANCH_OPTIONS=()
#   subcommand=$(parse_subcommand_and_options "$@")
#   # Input: "new --domain claude-command --base develop"
#   # Output: "new", BRANCH_OPTIONS["domain"]="claude_command", BRANCH_OPTIONS["base"]="develop"
#   # Input: "help"
#   # Output: "help", BRANCH_OPTIONS=()
#   # Input: "--domain scripts"
#   # Output: "new", BRANCH_OPTIONS["domain"]="scripts"
##
parse_subcommand_and_options() {
  ##
  # @brief Parse options into associative array
  # @description Helper function to parse --key value pairs into BRANCH_OPTIONS
  # @param $@ Array of command-line arguments
  # @global BRANCH_OPTIONS Associative array to store parsed options
  parse_options() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --domain)
          # Convert hyphens to underscores (e.g., "claude-command" → "claude_command")
          BRANCH_OPTIONS["domain"]="${2//-/_}"
          shift 2
          ;;
        --base)
          BRANCH_OPTIONS["base"]="$2"
          shift 2
          ;;
        *)
          # Skip unknown options
          shift
          ;;
      esac
    done
  }

  declare -g SUBCOMMAND="new"  # Initialize global subcommand variable
  declare -g -A BRANCH_OPTIONS=()  # Initialize global options array

  # Case 1: No arguments → default 'new' with no options
  if [ $# -eq 0 ]; then
    return 0
  fi

  # Case 2: First argument starts with '--' → option-only, use default 'new'
  if [[ "$1" == --* ]]; then
    parse_options "$@"
    return 0
  fi

  # Case 3: First argument is subcommand - validate it
  local subcmd="$1"
  case "$subcmd" in
    new|commit|help)
      SUBCOMMAND="$subcmd"
      ;;
    *)
      echo "Error: Invalid subcommand '$subcmd'. Valid subcommands: new, commit, help" >&2
      return 1
      ;;
  esac

  shift
  parse_options "$@"
  return 0
}

##
# @brief Validate Git working directory state
# @description Checks for uncommitted changes before branch creation
# @return 0 if clean or only untracked files, 1 if uncommitted changes exist
# @example
#   if validate_git_state; then
#     echo "Working directory is clean"
#   else
#     echo "Uncommitted changes detected"
#   fi
##
validate_git_state() {
  # Get git status in porcelain format
  local status_output
  status_output=$(git status --porcelain 2>/dev/null)

  # Early return: clean working tree
  if [ -z "$status_output" ]; then
    return 0
  fi

  # Filter out untracked files (lines starting with ??)
  # Only check for uncommitted changes (M, A, D, R, C, etc.)
  local uncommitted_changes
  uncommitted_changes=$(echo "$status_output" | grep -v '^??')

  # Early return: uncommitted changes detected (error case)
  if [ -n "$uncommitted_changes" ]; then
    echo "❌ Uncommitted changes detected"
    echo "💡 Please commit or stash your changes before creating a new branch:"
    echo "   - git status              # View changes"
    echo "   - git commit -am \"msg\"    # Commit changes"
    echo "   - git stash               # Stash changes temporarily"
    return 1
  fi

  # Normal termination: only untracked files exist
  return 0
}

##
# @brief Check if a Git branch exists
# @description Verifies branch existence using git rev-parse
# @param $1 Branch name to check
# @return 0 if branch exists, 1 if not
# @example
#   if check_branch_exists "feat-27/test"; then
#     echo "Branch exists"
#   else
#     echo "Branch does not exist"
#   fi
##
check_branch_exists() {
  local branch_name="$1"

  # Use git rev-parse to check branch existence
  # --verify: Check if reference exists
  # --quiet: Suppress output
  git rev-parse --verify --quiet "$branch_name" > /dev/null 2>&1
  return $?
}

##
# @brief Generate Git branch name from issue information
# @description Constructs branch name in format: {type}-{number}/{domain}/{slug}
# @param $1 Branch type (e.g., "feat", "fix", "docs")
# @param $2 Issue number (e.g., "27" or "new")
# @param $3 Domain (e.g., "claude-commands", "scripts")
# @param $4 Issue title (will be converted to slug)
# @return 0 on success
# @stdout Branch name (e.g., "feat-27/claude-commands/add-branch-command")
# @example
#   branch=$(generate_branch_name "feat" "27" "claude-commands" "Add branch command")
#   echo "$branch"  # "feat-27/claude-commands/add-branch-command"
##
generate_branch_name() {
  local branch_type="$1"
  local issue_number="$2"
  local domain="$3"
  local title="$4"

  # Generate slug from title using filename-utils.lib.sh
  local slug
  slug=$(generate_slug "$title")

  # Construct branch name: {type}-{number}/{domain}/{slug}
  echo "${branch_type}-${issue_number}/${domain}/${slug}"
}

##
# @brief Determine base branch for new branch creation
# @description Returns --base option if specified, otherwise current branch
# @param $1 Current branch name
# @param $2 BASE_BRANCH override (optional, from --base option)
# @return 0 on success
# @stdout Base branch name
# @example
#   base=$(determine_base_branch "main" "")
#   # Returns: "main"
#   base=$(determine_base_branch "main" "develop")
#   # Returns: "develop"
##
determine_base_branch() {
  local current_branch="$1"
  local base_override="${2:-}"

  if [ -n "$base_override" ]; then
    echo "$base_override"
  else
    echo "$current_branch"
  fi

  return 0
}

##
# @brief Create new Git branch from base branch
# @description Creates a new branch from the specified base branch.
#   If current branch differs from base, switches to base first.
#   Validates base branch existence before creation.
# @param $1 new_branch - Name of the branch to create
# @param $2 base_branch - Base branch to create from
# @return 0 on success
# @return 6 on git operation failure
# @return 7 on base branch not found
# @example
#   create_branch "feat-27/new-feature" "main"
#   create_branch "fix-28/bugfix" "develop"
##
create_branch() {
  local new_branch="$1"
  local base_branch="$2"

  # Get current branch
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # T11-3: Verify base branch exists
  if ! check_branch_exists "$base_branch"; then
    echo "❌ Base branch does not exist: $base_branch" >&2
    return 7
  fi

  # T11-1: Check if already on base branch
  if [ "$current_branch" = "$base_branch" ]; then
    echo "✓ Already on base branch: $base_branch"
  else
    # T11-2: Switch to base branch
    echo "→ Switching to base branch: $base_branch"
    if ! git switch "$base_branch" 2>/dev/null; then
      echo "❌ Failed to switch to base branch: $base_branch" >&2
      return 6
    fi
  fi

  # Create new branch
  if ! git switch -c "$new_branch" 2>/dev/null; then
    echo "❌ Failed to create branch: $new_branch" >&2
    return 6
  fi

  echo "✓ Branch created successfully: $new_branch"
  return 0
}

##
# @brief Save branch session to .branch.session file
# @description Saves branch proposal information including suggested branch name,
#   domain, base branch, issue number, and timestamp
# @param $1 Issues directory path
# @param $2 Suggested branch name (e.g., "feat-27/claude-commands/add-branch-command")
# @param $3 Domain (e.g., "claude-commands")
# @param $4 Base branch (e.g., "main")
# @param $5 Issue number (e.g., "27" or "new")
# @return 0 on success
# @example
#   save_branch_session "$ISSUES_DIR" \
#     "feat-27/claude-commands/add-branch-command" \
#     "claude-commands" \
#     "main" \
#     "27"
##
save_branch_session() {
  local issues_dir="$1"
  local suggested_branch="$2"
  local domain="$3"
  local base_branch="$4"
  local issue_number="$5"

  local session_file="$issues_dir/.branch.session"

  # Prepare session data as associative array
  local -A session_data=(
    ["suggested_branch"]="$suggested_branch"
    ["domain"]="$domain"
    ["base_branch"]="$base_branch"
    ["issue_number"]="$issue_number"
  )

  # Save session using shared function
  _save_session "$session_file" session_data
}

##
# @brief Load branch session from .branch.session file
# @description
#   Loads previously saved branch session data and exports as environment variables.
#   Uses _load_session() from idd-session.lib.sh for consistent session management.
#
# @param $1 issues_dir - Directory containing .branch.session file
#
# @return 0 on success
# @return 1 on error (file not found, invalid format, missing parameter)
#
# @env SUGGESTED_BRANCH - Loaded suggested branch name
# @env DOMAIN - Loaded domain value
# @env BASE_BRANCH - Loaded base branch name
# @env ISSUE_NUMBER - Loaded issue number
# @env LAST_MODIFIED - Loaded timestamp
#
# @example
#   load_branch_session "$ISSUES_DIR"
#   echo "Last branch: $SUGGESTED_BRANCH"
##
load_branch_session() {
  local issues_dir="$1"

  if [ -z "$issues_dir" ]; then
    error_print "❌ Error: issues_dir required"
    return 1
  fi

  local session_file="$issues_dir/.branch.session"

  if [ ! -f "$session_file" ]; then
    error_print "❌ Error: Session file not found: $session_file"
    return 1
  fi

  # Load session using shared function
  # shellcheck disable=SC1090
  if ! source "$session_file"; then
    error_print "❌ Error: Failed to load session file"
    return 1
  fi

  # Export loaded variables
  export SUGGESTED_BRANCH="${suggested_branch:-}"
  export DOMAIN="${domain:-}"
  export BASE_BRANCH="${base_branch:-}"
  export ISSUE_NUMBER="${issue_number:-}"
  export LAST_MODIFIED="${LAST_MODIFIED:-}"

  return 0
}

##
# @brief Update issue session with branch name
# @description
#   Updates the .last.session file to add or update the LAST_BRANCH_NAME field.
#   Preserves all existing fields while updating only the branch name.
#   Uses _load_session() and _save_session() from idd-session.lib.sh.
#
# @param $1 session_file - Path to the session file to update
# @param $2 branch_name - Branch name to save (e.g., "feat-27/test")
#
# @return 0 on success
# @return 1 on error (missing parameters, file operations failed)
#
# @example
#   update_session_with_branch "$SESSION_FILE" "feat-27/test"
#   # .last.session now contains: LAST_BRANCH_NAME="feat-27/test"
##
update_session_with_branch() {
  local session_file="$1"
  local branch_name="$2"

  if [ -z "$session_file" ] || [ -z "$branch_name" ]; then
    error_print "❌ Error: session_file and branch_name required"
    return 1
  fi

  # Create initial session if it doesn't exist
  if [ ! -f "$session_file" ]; then
    cat > "$session_file" << EOF
# Last session
LAST_BRANCH_NAME="$branch_name"
LAST_MODIFIED="$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"
EOF
    return 0
  fi

  # Load existing session
  if ! _load_session "$session_file"; then
    error_print "❌ Error: Failed to load session file"
    return 1
  fi

  # Prepare updated session data
  local -A session_data=(
    ["LAST_ISSUE_FILE"]="${LAST_ISSUE_FILE:-}"
    ["LAST_ISSUE_NUMBER"]="${LAST_ISSUE_NUMBER:-}"
    ["LAST_COMMAND"]="${LAST_COMMAND:-}"
    ["LAST_ISSUE_TITLE"]="${LAST_ISSUE_TITLE:-}"
    ["LAST_ISSUE_TYPE"]="${LAST_ISSUE_TYPE:-}"
    ["LAST_COMMIT_TYPE"]="${LAST_COMMIT_TYPE:-}"
    ["LAST_BRANCH_TYPE"]="${LAST_BRANCH_TYPE:-}"
    ["LAST_BRANCH_NAME"]="$branch_name"
  )

  # Save updated session
  _save_session "$session_file" session_data
}

##
# @brief Clean up branch session file
# @description
#   Deletes the .branch.session file if it exists.
#   Safe to call even if the file doesn't exist (no error).
#   Used after successful branch creation to clean up temporary session data.
#
# @param $1 session_file - Path to the branch session file to delete
#
# @return 0 on success (whether file existed or not)
#
# @example
#   cleanup_branch_session "$ISSUES_DIR/.branch.session"
#   # .branch.session is now deleted
##
cleanup_branch_session() {
  local session_file="$1"

  if [ -z "$session_file" ]; then
    return 0
  fi

  if [ -f "$session_file" ]; then
    rm -f "$session_file"
  fi

  return 0
}
```

**Note**: Git環境チェックは `.claude/commands/_libs/prereq-check.lib.sh` の `validate_git_full()` 関数を使用します。

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
