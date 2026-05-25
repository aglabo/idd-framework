#!/bin/bash
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
##
# IDD Environment Setup Library
#
# 環境セットアップ用のヘルパー関数を提供します。
#
# @file idd-env.lib.sh
# @version 1.1.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
source "$SCRIPT_DIR/io-utils.lib.sh"

##
# リポジトリルートを取得し、REPO_ROOTグローバル変数に設定
#
# @global REPO_ROOT
# @example
#   setup_repo_env
#   echo "Repository root: $REPO_ROOT"
setup_repo_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

  if [ -z "$REPO_ROOT" ]; then
    error_print "❌ Error: Not in a git repository"
    return 1
  fi

  export REPO_ROOT
}

##
# tempディレクトリのパスを取得 (サブディレクトリ指定可能)
#
# @param $1 サブディレクトリパス (オプション、例: "idd/issues")
# @return tempディレクトリの絶対パス
# @example
#   TEMP_DIR=$(get_temp_dir "idd/issues")
#   echo "$TEMP_DIR"  # → /path/to/repo/temp/idd/issues
get_temp_dir() {
  local subdir="${1:-}"

  if [ -z "$REPO_ROOT" ]; then
    setup_repo_env || return 1
  fi

  if [ -n "$subdir" ]; then
    echo "$REPO_ROOT/temp/$subdir"
  else
    echo "$REPO_ROOT/temp"
  fi
}

##
# ディレクトリが存在しない場合は作成
#
# @param $1 作成するディレクトリパス
# @return 0=成功, 1=失敗
# @example
#   ensure_dir "$REPO_ROOT/temp/idd/issues"
ensure_dir() {
  local dir_path="$1"

  if [ -z "$dir_path" ]; then
    error_print "❌ Error: Directory path required"
    return 1
  fi

  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path" 2>/dev/null || {
      error_print "❌ Error: Failed to create directory: $dir_path"
      return 1
    }
  fi

  return 0
}
