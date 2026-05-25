#!/bin/bash
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
##
# IDD I/O Utilities Library
#
# I/O操作用のヘルパー関数を提供します。
#
# @file io-utils.lib.sh
# @version 1.1.0
# @license MIT

##
# エラーメッセージを標準エラー出力に表示
#
# 可変長引数とヒアドキュメントの両方に対応します。
# - 引数が渡された場合: すべての引数を結合して出力
# - 引数がない場合: 標準入力 (ヒアドキュメント) から読み込んで出力
#
# @param $@ エラーメッセージ (可変長引数、オプション)
# @return 常に0を返す
# @example
#   # 引数指定
#   error_print "❌ Error: File not found: $file"
#   error_print "❌" "Error:" "Multiple arguments"
#
#   # ヒアドキュメント
#   error_print <<EOF
#   ❌ Error: Invalid configuration
#   Please check the following:
#   - Config file exists
#   - JSON syntax is valid
#   EOF
error_print() {
  if [ $# -gt 0 ]; then
    # 引数が渡された場合: すべての引数を結合して出力
    echo "$@" >&2
  else
    # 引数がない場合: 標準入力から読み込んで出力
    cat >&2
  fi
}

##
# 非ASCII文字が含まれているかチェック
#
# テキストに非ASCII文字 (0x80以上のバイト) が含まれているかを判定します。
# Windows環境でも動作するよう、LC_ALL=C でバイトレベルチェックを使用します。
#
# @param $1 チェック対象のテキスト
# @return 0 (true) if non-ASCII characters found, 1 (false) if pure ASCII
# @example
#   if is_non_ascii "こんにちは"; then
#     echo "Non-ASCII detected"
#   fi
#
#   if is_non_ascii "hello world"; then
#     echo "This won't print"
#   fi
is_non_ascii() {
  local text="$1"

  # 改行コードを削除
  text=$(printf '%s' "$text" | tr -d '\n\r')

  # sedでASCII文字 (0x00-0x7F) のみを削除
  # 残りがあれば非ASCII文字が含まれている
  local non_ascii_chars
  non_ascii_chars=$(printf '%s' "$text" | LC_ALL=C sed 's/[\x00-\x7F]//g')

  if [ -n "$non_ascii_chars" ]; then
    return 0  # non-ASCII found
  fi

  return 1  # pure ASCII
}
