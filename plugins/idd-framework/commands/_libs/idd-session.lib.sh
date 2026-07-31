#!/bin/bash
##
# src: .claude/commands/_libs/idd-session.lib.sh
# @(#) IDD Session Management Library
#
# セッション管理用のヘルパー関数を提供します。
#
# @version 1.2.0
# @license MIT
#
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Source guard - prevent multiple inclusion
if [[ -n "${_IDD_SESSION_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly _IDD_SESSION_LIB_LOADED=1

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
. "$SCRIPT_DIR/io-utils.lib.sh"

# セッションフォーマット定数
readonly SESSION_VERSION="1.0.0"
readonly SESSION_FORMAT="key-value"

##
# セッション情報を保存(連想配列を参照渡しで受け取る形式)
#
# @param $1 セッションファイルパス
# @param $2 ファイル名（拡張子なし）
# @param $3 Issue番号（空文字列可）
# @param $4 コマンド名（"new", "push", "edit"など）
# @return 0=成功, 1=失敗
# @example
#   # グローバル変数として TITLE, ISSUE_TYPE 等が設定済みと仮定
#   _save_issue_session "$SESSION_FILE" "$filename" "$issue_number" "push"
_save_issue_session() {
  local session_file="$1"
  local new_filename="$2"
  local new_issue_number="$3"
  local new_command="$4"

  # Build session data as associative array
  # shellcheck disable=SC2034  # session_data used by _save_session via nameref
  declare -A session_data=(
    [SESSION_VERSION]="$SESSION_VERSION"
    [SESSION_FORMAT]="$SESSION_FORMAT"
    [LAST_ISSUE_FILE]="$new_filename"
    [LAST_ISSUE_NUMBER]="$new_issue_number"
    [LAST_COMMAND]="$new_command"
    [LAST_ISSUE_TITLE]="${TITLE:-}"
    [LAST_ISSUE_TYPE]="${ISSUE_TYPE:-}"
    [LAST_COMMIT_TYPE]="${COMMIT_TYPE:-}"
    [LAST_BRANCH_TYPE]="${BRANCH_TYPE:-}"
  )

  # Use _save_session library function
  _save_session "$session_file" session_data
}

##
# Issueセッションを読み込み（エラーハンドリング付き）
#
# セッションファイルを読み込み、存在しない場合は親切なエラーメッセージを表示します。
# Issue管理コマンド用のラッパー関数です。
# LAST_* プレフィックス付き変数を標準的な変数名に変換します。
#
# @param $1 セッションファイルパス
# @return 0=成功, 1=失敗（セッションファイルなし）
# @sets filename (可変、小文字) - ファイル名
# @sets issue_number (可変、小文字) - Issue番号
# @sets TITLE (不変、大文字) - Issueタイトル
# @sets ISSUE_TYPE (不変、大文字) - Issue種別
# @sets COMMIT_TYPE (不変、大文字) - Commit種別
# @sets BRANCH_TYPE (不変、大文字) - Branch種別
# @sets command (可変、小文字) - コマンド名
# @example
#   if ! _load_issue_session "$SESSION_FILE"; then
#     exit 1
#   fi
#   echo "Loaded issue: $filename"
#   echo "Title: $TITLE"
_load_issue_session() {
  local session_file="$1"

  if ! _load_session "$session_file"; then
    echo "❌ No issue selected."
    echo "💡 Run '/idd:issue:list' to select an issue, or"
    echo "   '/idd:issue:new' to create one."
    return 1
  fi

  # LAST_* 変数を標準変数名に変換
  # 可変データ（小文字）
  filename="${LAST_ISSUE_FILE:-}"
  # shellcheck disable=SC2034  # Used by external callers
  issue_number="${LAST_ISSUE_NUMBER:-}"
  # shellcheck disable=SC2034  # Used by external callers
  command="${LAST_COMMAND:-}"

  # 不変データ（大文字）
  TITLE="${LAST_ISSUE_TITLE:-}"
  ISSUE_TYPE="${LAST_ISSUE_TYPE:-}"
  COMMIT_TYPE="${LAST_COMMIT_TYPE:-}"
  BRANCH_TYPE="${LAST_BRANCH_TYPE:-}"

  echo "📋 Loaded issue: $filename"
  return 0
}

##
# Issueファイルの存在を検証
#
# セッションから取得したIssueファイルの存在を確認します。
# ファイルが存在しない場合はエラーメッセージを表示します。
#
# @param $1 ディレクトリパス (ISSUES_DIR)
# @param $2 ファイル名 (拡張子なし)
# @return 0=成功, 1=失敗（ファイルなし）
# @sets issue_file (グローバル変数) - フルパス
# @example
#   if ! _validate_issue_file "$ISSUES_DIR" "$filename"; then
#     exit 1
#   fi
#   echo "Using: $issue_file"
_validate_issue_file() {
  local dir="$1"
  local filename="$2"
  issue_file="$dir/${filename}.md"

  if [[ ! -f "$issue_file" ]]; then
    echo "❌ Issue file not found: ${filename}.md"
    echo "💡 The session references a file that no longer exists."
    echo "   Run '/idd:issue:list' to select an available issue."
    return 1
  fi

  echo "✅ Issue file found: ${filename}.md"
  return 0
}

##
# セッション情報を保存(連想配列を参照渡しで受け取る形式)
#
# @param $1 セッションファイルパス
# @param $2 連想配列変数名(nameref)
# @param $3 (optional) LAST_MODIFIED固定値(テスト用、省略時は現在時刻)
# @return 0=成功, 1=失敗(ファイルパスが指定されていない場合など)
# @example
#   declare -A session_data=(
#     [LAST_ISSUE_FILE]="$filename"
#     [LAST_ISSUE_NUMBER]="$issue_num"
#     [LAST_COMMAND]="$command"
#   )
#   _save_session "$SESSION_FILE" session_data
#   _save_session "$SESSION_FILE" session_data "2025-10-26T10:00:00+09:00"  # For tests
_save_session() {
  local session_file="$1"
  local -n data="$2"
  local custom_timestamp="${3:-}"

  if [ -z "$session_file" ]; then
    error_print "❌ Error: Session file path required"
    return 1
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$session_file")"

  {
    echo "# Last session"

    for key in "${!data[@]}"; do
      # Skip readonly variables (SESSION_VERSION, SESSION_FORMAT)
      if [[ "$key" == "SESSION_VERSION" || "$key" == "SESSION_FORMAT" ]]; then
        continue
      fi
      echo "$key=\"${data[$key]}\""
    done

    if [[ -n "$custom_timestamp" ]]; then
      echo "LAST_MODIFIED=\"$custom_timestamp\""
    else
      echo "LAST_MODIFIED=\"$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)\""
    fi
  } >"$session_file"
}

##
# セッション情報を読み込み、変数として展開
#
# @param $1 セッションファイルパス
# @return 0=成功 (変数が展開される), 1=失敗
# @example
#   load_session "$SESSION_FILE"
#   echo "Last issue: $LAST_ISSUE_NUMBER"
_load_session() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$session_file"
  return 0
}

##
# セッションファイルの存在確認
#
# @param $1 セッションファイルパス
# @return 0=存在, 1=存在しない
# @example
#   if has_session "$SESSION_FILE"; then
#     echo "Session exists"
#   fi
_has_session() {
  local session_file="$1"
  [ -f "$session_file" ]
}

##
# 最終使用ファイル名を保存
#
# @param $1 ディレクトリパス
# @param $2 ファイル名
# @return 0=成功, 1=失敗
# @example
#   _save_last_file "$PR_DIR" "feature-123.md"
#   # → $PR_DIR/.last_draft に "feature-123.md" を保存
_save_last_file() {
  local dir="$1"
  local filename="$2"

  if [ -z "$dir" ] || [ -z "$filename" ]; then
    error_print "❌ Error: Directory and filename required"
    return 1
  fi

  echo "$filename" >"$dir/.last_draft"
}

##
# 最終使用ファイル名を読み込み
#
# @param $1 ディレクトリパス
# @param $2 デフォルトファイル名 (ファイルがない場合)
# @return ファイル名
# @example
#   OUTPUT_FILE=$(_load_last_file "$PR_DIR" "pr_current_draft.md")
_load_last_file() {
  local dir="$1"
  local default="$2"

  if [ -f "$dir/.last_draft" ]; then
    cat "$dir/.last_draft"
  else
    echo "$default"
  fi
}

##
# Issueファイルからタイトルと本文を抽出
#
# Issue下書きファイルの標準フォーマット（1行目: H1タイトル、2行目以降: 本文）
# からタイトルと本文を抽出します。
#
# @param $1 Issueファイルのフルパス
# @return 0=成功, 1=失敗（タイトルなし）
# @sets TITLE (グローバル変数、大文字) - タイトル
# @sets body (グローバル変数) - 本文
# @example
#   if ! _extract_issue_content "$issue_file"; then
#     exit 1
#   fi
#   echo "Title: $TITLE"
#   echo "Body: $body"
_extract_issue_content() {
  local file="$1"

  # Extract title from H1 heading (line 1)
  TITLE=$(head -n 1 "$file" | sed 's/^# //')

  # Validate title
  if [[ -z "$TITLE" ]]; then
    echo "❌ Issue file has no title (H1 heading on line 1)"
    echo "💡 Please ensure the first line starts with '# Title'"
    return 1
  fi

  echo "📝 Title: $TITLE"

  # Extract body (lines 2+)
  body=$(tail -n +2 "$file")
  echo "📄 Body extracted (${#body} characters)"

  return 0
}
