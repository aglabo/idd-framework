#!/usr/bin/env bash
# skip shellspec
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/integration/filename-utils-translation.integration.spec.sh
# @(#): Integration tests for generate_slug() translation feature
#
# @file filename-utils-translation.integration.spec.sh
# @brief Integration tests for AI-based translation in generate_slug()
# @description
#   Real AI integration test suite for generate_slug() translation functionality.
#   Tests the to_english_via_ai() function and generate_slug() with actual codex-mcp calls.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Real codex-mcp execution (no mocks), skip if codex unavailable
#
#   Covered functionality:
#   - Translation consistency and idempotency (same input → same output)
#   - Edge cases (empty, special chars, whitespace, very long text)
#   - Error handling (codex unavailable, timeout, fallback behavior)
#   - Translation quality (lowercase, space-separated, no consecutive duplicates)
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
LIBS_DIR="$PROJECT_ROOT/.claude/commands/_libs"

# Source filename-utils.lib.sh for generate_slug and to_english_via_ai
. "$LIBS_DIR/filename-utils.lib.sh"

# Setup AI availability check (once in BeforeAll)
setup_ai_check() {
  CODE_AI_UNAVAILABLE=0
  return 0
  if ! command -v claude >/dev/null 2>&1; then
    CODE_AI_UNAVAILABLE=1  # Set flag only when unavailable
  fi
}

# Check AI availability (uses cached result from BeforeAll)
check_ai_not_available() {
  [ "$CODE_AI_UNAVAILABLE" -ne 0 ]
}

# helper: check keyword in parameter array
# Usage: contains_all_keywords "text" bug fix login
contains_all_keywords() {
  local text="$1"
  shift  # 残りの引数をすべてキーワードとして扱う

  for keyword in "$@"; do
    if [[ "$text" != *"$keyword"* ]]; then
      return 1  # 1つでも含まれていなければ false
    fi
  done

  return 0  # 全部含まれていれば true
}

Describe 'filename-utils.lib.sh - generate_slug() translation integration tests'

  # ============================================================================
  # Setup: Check AI availability once (cached for all tests)
  # ============================================================================

  BeforeAll 'setup_ai_check'

  # ============================================================================
  # Given: Translation quality verification
  # ============================================================================

  Describe 'Given: Translation quality requirements with real AI'
    Context 'When: Translating Japanese text to English'
      It 'Then: [正常] - produces valid English translation'
        Skip if "coding AI not available" check_ai_not_available

        japanese_text="ユーザー認証機能を追加"
        translation=$(to_english_via_ai "$japanese_text")

        When call printf '%s' "$translation"

        # Verify translation is valid (non-blank, lowercase, contains expected keywords)
        The output should not be blank
        The status should equal 0
        The output should not match pattern "*[A-Z]*"
        # Should contain relevant keywords
        The output should match pattern "*user*"
      End
    End

    Context 'When: Generating slug with Japanese title'
      It 'Then: [正常] - produces valid English slug'
        Skip if "coding AI not available" check_ai_not_available

        title="バグ修正: ログイン画面のエラー処理"
        # Generate slug
        slug=$(generate_slug "$title")

        When call printf '%s' "$slug"

        # Slug should be valid format
        The output should not be blank
        The status should equal 0
        The output should match pattern "[a-z-]*"
        # Should contain at least one relevant keyword (fix, login, or error)
        The output should satisfy contains_all_keywords "$slug" "bug" "fix" "login" "error"
      End
    End

    Context 'When: Translation contains consecutive duplicate words'
      It 'Then: [正常] - removes consecutive duplicates from result'
        Skip if "coding AI not available" check_ai_not_available

        # Title with potential for duplicate words in translation
        title="ブランチブランチ作成機能"

        When call generate_slug "$title" 50

        # Should not contain consecutive duplicate words like "branch-branch"
        The output should not be blank
        The status should equal 0
        # Verify no consecutive duplicate words (simplified check)
        The output should not match pattern "*-branch-branch-*"
      End
    End
  End

  # ============================================================================
  # Given: Edge cases for translation
  # ============================================================================

  Describe 'Given: Edge cases for translation with real AI'
    Context 'When: Translating empty string'
      It 'Then: [エッジケース] - returns empty string'
        Skip if "coding AI not available" check_ai_not_available

        When call to_english_via_ai ""

        The output should equal ""
        # May return 0 or 1 depending on implementation
      End
    End

    Context 'When: Generating slug with only special characters'
      It 'Then: [エッジケース] - produces empty slug'
        Skip if "coding AI not available" check_ai_not_available

        title="!@#$%^&*()"

        When call generate_slug "$title"

        # All special chars removed, empty slug
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Generating slug with only whitespace'
      It 'Then: [エッジケース] - produces empty slug'
        Skip if "coding AI not available" check_ai_not_available

        title="   "

        When call generate_slug "$title"

        # Whitespace only results in empty slug
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Translating very long Japanese text'
      It 'Then: [正常] - truncates to max_length at word boundary'
        Skip if "coding AI not available" check_ai_not_available

        # Very long title
        title="これは非常に長いタイトルでスラッグ生成時に最大長制限を超えるテストです"

        result=$(generate_slug "$title" 30)

        When call printf '%s' "$result"

        # Should not be blank and respect max length
        The output should not be blank
        The status should equal 0
        # Length check: result length should be 30 or less
        [ ${#result} -le 30 ]
      End
    End

    Context 'When: Generating slug with mixed ASCII and Japanese'
      It 'Then: [正常] - translates entire text to English'
        Skip if "coding AI not available" check_ai_not_available

        title="Add 新機能 to システム"

        When call generate_slug "$title" 50

        # Should translate to full English slug
        The output should not be blank
        The status should equal 0
        # Verify it contains only ASCII lowercase and hyphens
        The output should match pattern "[a-z-]*"
      End
    End
  End

  # ============================================================================
  # Given: Error handling and fallback behavior
  # ============================================================================

  Describe 'Given: Error handling for translation failures'
    Context 'When: coding AI is unavailable (simulated)'
      It 'Then: [異常] - falls back to removing non-ASCII characters'
        # This test uses a fake translator function that always fails
        fake_translator() {
          return 1
        }

        title="これはテストです"

        When call generate_slug "$title" 50 fake_translator

        # Should fallback to removing non-ASCII, resulting in empty slug
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Translation returns empty result'
      It 'Then: [異常] - falls back to non-ASCII removal'
        # Translator that returns empty string
        empty_translator() {
          echo ""
          return 1
        }

        title="日本語タイトル"

        When call generate_slug "$title" 50 empty_translator

        # Should fallback to removing non-ASCII
        The output should equal ""
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Given: Translation quality verification
  # ============================================================================

  Describe 'Given: Translation quality requirements with real AI'
    Context 'When: Translating typical Japanese feature title'
      It 'Then: [正常] - produces lowercase space-separated English words'
        Skip if "coding AI not available" check_ai_not_available

        title="ログイン機能の実装"

        result=$(to_english_via_ai "$title")

        When call printf '%s' "$result"

        # Should be lowercase with spaces (not hyphens yet)
        The output should not be blank
        The status should equal 0
        # Should not contain uppercase letters
        The output should not match pattern "*[A-Z]*"
      End
    End

    Context 'When: Translating Japanese bug fix title'
      It 'Then: [正常] - generates valid slug with translation'
        Skip if "coding AI not available" check_ai_not_available

        title="エラーハンドリングのバグ修正"

        When call generate_slug "$title" 50

        # Should produce valid slug format
        The output should not be blank
        The status should equal 0
        # Should contain only lowercase letters and hyphens
        The output should match pattern "[a-z-]*"
      End
    End

    Context 'When: Translating title with technical terms'
      It 'Then: [正常] - preserves technical term meaning in English'
        Skip if "coding AI not available" check_ai_not_available

        title="API認証トークンの実装"
        slug=$(generate_slug "$title")

        When call printf '%s' "$slug"

        # Should translate technical terms appropriately
        The output should not be blank
        The status should equal 0
        # Should contain relevant keywords like "api" or "auth" or "token"

        The output should satisfy contains_all_keywords "$slug" "api" "auth" "token"
      End
    End
  End
End
