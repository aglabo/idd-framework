#!/bin/bash
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
##
# IDD File Operations Library
#
# ファイル操作用のヘルパー関数を提供します。
#
# @file idd-file-ops.lib.sh
# @version 1.1.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
source "$SCRIPT_DIR/io-utils.lib.sh"

##
# ファイルの存在を確認、なければエラーメッセージを表示して終了
#
# @param $1 ファイルパス
# @param $2 エラーメッセージ
# @return 0=ファイル存在, 1=ファイルなし
# @example
#   require_file "$MSG_FILE" "No commit message found. Run '/idd-commit-message new' first."
require_file() {
  local file_path="$1"
  local error_msg="$2"

  if [ ! -f "$file_path" ]; then
    error_print "❌ $error_msg"
    return 1
  fi

  return 0
}

##
# Markdownファイルから先頭行のH1タイトルを抽出
#
# @param $1 ファイルパス
# @return タイトル文字列 (H1マーカーなし)
# @example
#   TITLE=$(extract_title "$ISSUE_FILE")
#   echo "$TITLE"  # → "Feature request title"
extract_title() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  head -1 "$file_path" | sed 's/^#[[:space:]]*//'
}

##
# ファイルをページャで表示
#
# @param $1 ファイルパス
# @param $2 ページャ (オプション、デフォルト: $PAGER または less)
# @return 0=成功, 1=失敗
# @example
#   view_file "$DRAFT_FILE"
#   view_file "$ISSUE_FILE" "cat"
view_file() {
  local file_path="$1"
  local pager="${2:-${PAGER:-less}}"

  if [ ! -f "$file_path" ]; then
    error_print "❌ File not found: $file_path"
    return 1
  fi

  $pager "$file_path"
}

##
# ファイルをエディタで編集
#
# @param $1 ファイルパス
# @param $2 エディタ (オプション、デフォルト: $EDITOR または code)
# @return 0=成功, 1=失敗
# @example
#   edit_file "$MSG_FILE"
#   edit_file "$ISSUE_FILE" "vim"
edit_file() {
  local file_path="$1"
  local editor="${2:-${EDITOR:-vim}}"

  if [ ! -f "$file_path" ]; then
    error_print "❌ File not found: $file_path"
    return 1
  fi

  echo "📝 Opening in editor: $editor"
  "$editor" "$file_path"
}

##
# ファイルのタイムスタンプを取得 (YYYY-MM-DD HH:MM形式)
#
# @param $1 ファイルパス
# @return タイムスタンプ文字列
# @example
#   MODIFIED=$(get_file_timestamp "$ISSUE_FILE")
get_file_timestamp() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  # クロスプラットフォーム対応
  stat -c %y "$file_path" 2>/dev/null | cut -d' ' -f1,2 | cut -d: -f1,2 ||
    date -r "$file_path" '+%Y-%m-%d %H:%M' 2>/dev/null
}
