#!/bin/bash
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
##
# IDD Git Operations Library
#
# Git操作用のヘルパー関数を提供します。
#
# @file idd-git-ops.lib.sh
# @version 1.1.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
source "$SCRIPT_DIR/io-utils.lib.sh"

##
# GitHub Issueを新規作成
#
# @param $1 タイトル
# @param $2 本文ファイルパス
# @return Issue URL (標準出力), 終了コード 0=成功/1=失敗
# @example
#   NEW_URL=$(gh_issue_create "$TITLE" "$BODY_FILE")
#   ISSUE_NUM=$(echo "$NEW_URL" | sed 's/.*\/issues\///')
gh_issue_create() {
  local title="$1"
  local body_file="$2"

  if [ -z "$title" ] || [ -z "$body_file" ]; then
    error_print "❌ Error: Title and body file required"
    return 1
  fi

  if [ ! -f "$body_file" ]; then
    error_print "❌ Error: Body file not found: $body_file"
    return 1
  fi

  echo "🆕 Creating new issue..." >&2

  local url
  url=$(gh issue create --title "$title" --body-file "$body_file" 2>&1) || {
    error_print "❌ Failed to create issue: $url"
    return 1
  }

  echo "$url"
  return 0
}

##
# GitHub Issueを更新
#
# @param $1 Issue番号
# @param $2 タイトル
# @param $3 本文ファイルパス
# @return 0=成功, 1=失敗
# @example
#   gh_issue_update "$ISSUE_NUM" "$TITLE" "$BODY_FILE"
gh_issue_update() {
  local issue_num="$1"
  local title="$2"
  local body_file="$3"

  if [ -z "$issue_num" ] || [ -z "$title" ] || [ -z "$body_file" ]; then
    error_print "❌ Error: Issue number, title, and body file required"
    return 1
  fi

  if [ ! -f "$body_file" ]; then
    error_print "❌ Error: Body file not found: $body_file"
    return 1
  fi

  echo "🔄 Updating issue #$issue_num..." >&2

  gh issue edit "$issue_num" --title "$title" --body-file "$body_file" || {
    error_print "❌ Failed to update issue #$issue_num"
    return 1
  }

  echo "✅ Issue #$issue_num updated successfully!" >&2
  return 0
}

##
# Pull Requestを作成
#
# @param $1 タイトル
# @param $2 本文ファイルパス
# @param $3 ベースブランチ (オプション、デフォルト: main)
# @return PR URL (標準出力), 終了コード 0=成功/1=失敗
# @example
#   PR_URL=$(gh_pr_create "$TITLE" "$BODY_FILE")
#   PR_URL=$(gh_pr_create "$TITLE" "$BODY_FILE" "develop")
gh_pr_create() {
  local title="$1"
  local body_file="$2"
  local base="${3:-main}"

  if [ -z "$title" ] || [ -z "$body_file" ]; then
    error_print "❌ Error: Title and body file required"
    return 1
  fi

  if [ ! -f "$body_file" ]; then
    error_print "❌ Error: Body file not found: $body_file"
    return 1
  fi

  echo "🚀 Creating pull request (base: $base)..." >&2

  local url
  url=$(gh pr create --title "$title" --body-file "$body_file" --base "$base" 2>&1) || {
    error_print "❌ Failed to create PR: $url"
    return 1
  }

  echo "$url"
  return 0
}

##
# メッセージファイルを使用してコミット実行
#
# @param $1 メッセージファイルパス
# @return 0=成功, 1=失敗
# @example
#   git_commit_with_message "$MSG_FILE" && echo "✅ Committed"
git_commit_with_message() {
  local message_file="$1"

  if [ -z "$message_file" ]; then
    error_print "❌ Error: Message file required"
    return 1
  fi

  if [ ! -f "$message_file" ]; then
    error_print "❌ Error: Message file not found: $message_file"
    return 1
  fi

  # ステージされたファイル確認
  if [ -z "$(git diff --cached --name-only)" ]; then
    error_print "❌ No staged changes. Stage files with 'git add' first."
    return 1
  fi

  echo "📝 Committing with message from: $message_file" >&2

  git commit -F "$message_file" || {
    error_print "❌ Commit failed."
    return 1
  }

  echo "🎉 Commit successful!" >&2
  return 0
}

##
# Issue番号をURLから抽出
#
# @param $1 GitHub Issue URL
# @return Issue番号
# @example
#   ISSUE_NUM=$(extract_issue_number_from_url "$NEW_URL")
extract_issue_number_from_url() {
  local url="$1"
  echo "$url" | sed 's/.*\/issues\///'
}
