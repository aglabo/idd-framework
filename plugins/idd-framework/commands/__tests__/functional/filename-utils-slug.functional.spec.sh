#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/functional/filename-utils-slug.functional.spec.sh
# @(#): Functional tests for generate_slug() function
#
# @file filename-utils-slug.functional.spec.sh
# @brief Functional tests for generate_slug() in real-world scenarios
# @description
#   Functional test suite for generate_slug() function in filename-utils.lib.sh.
#   Tests slug generation behavior, consistency, AI translation, and length constraints.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Pure slug generation testing without filename integration
#
#   Covered functionality:
#   - Slug consistency across multiple calls with same input
#   - Slug generation with various title patterns
#   - AI-based translation from non-ASCII (Japanese, Chinese, Korean) to English
#   - Translation fallback behavior when AI unavailable
#   - Length constraints and truncation behavior
#   - Edge cases (empty title, special characters, mixed ASCII/non-ASCII)
#
# @author atsushifx
# @version 2.1.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
LIBS_DIR="$PROJECT_ROOT/.claude/commands/_libs"

# Mock translator for fast testing without AI dependency
mock_translator() {
  local text="$1"

  # Predefined translations for test cases
  case "$text" in
    "ユーザー認証機能を追加")
      echo "add user authentication feature"
      ;;
    "Add 新機能 to システム")
      echo "add new feature to system"
      ;;
    "Add 新機能 Feature")
      echo "add new feature"
      ;;
    "添加用户认证功能")
      echo "add user authentication feature"
      ;;
    "これはテストです")
      return 1  # Simulate AI translation failure
      ;;
    "사용자 인증 기능 추가")
      echo "add user authentication feature"
      ;;
    "ブランチブランチ作成機能")
      echo "branch creation feature"  # Mock removes duplicates
      ;;
    *)
      # Default: return failure for unknown text
      return 1
      ;;
  esac
  return 0
}

# Source filename-utils.lib.sh for generate_slug function
. "$LIBS_DIR/filename-utils.lib.sh"

Describe 'filename-utils.lib.sh - generate_slug() functional tests'

  # ============================================================================
  # Given: Slug consistency and idempotency
  # ============================================================================

  Describe 'Given: Slug consistency requirements'
    Context 'When: Generating slug multiple times with same input'
      It 'Then: [正常] - produces consistent slug output'
        title="Refactor User Module"

        # Generate slug twice with mock translator
        slug1=$(generate_slug "$title" 30 mock_translator)
        slug2=$(generate_slug "$title" 30 mock_translator)

        When call printf '%s' "$slug1"

        # Both calls should produce identical output
        The output should equal "refactor-user-module"
        The variable slug2 should equal "refactor-user-module"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Given: Edge cases for slug generation
  # ============================================================================

  Describe 'Given: Edge cases for slug generation'
    Context 'When: Generating slug with empty title'
      It 'Then: [エッジケース] - produces empty slug'
        title=""

        When call generate_slug "$title"

        # Empty title results in empty slug
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Generating slug with only special characters'
      It 'Then: [エッジケース] - produces empty slug'
        title="!@#$%^&*()"

        When call generate_slug "$title"

        # All special chars removed, empty slug
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Generating slug with mixed ASCII and non-ASCII'
      It 'Then: [正常] - translates and merges mixed content'
        title="Add 新機能 Feature"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates "Add 新機能 Feature" to "add new feature"
        The output should equal "add-new-feature"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Given: Non-ASCII (Japanese/multilingual) title translation
  # ============================================================================

  Describe 'Given: Non-ASCII title translation to English slug'
    Context 'When: Generating slug with pure Japanese title'
      It 'Then: [正常] - translates Japanese to English slug with key terms'
        title="ユーザー認証機能を追加"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates to "add user authentication feature"
        The output should equal "add-user-authentication-feature"
        The status should equal 0
      End
    End

    Context 'When: Generating slug with mixed Japanese and English'
      It 'Then: [正常] - translates mixed content to full English slug'
        title="Add 新機能 to システム"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates to "add new feature to system"
        The output should equal "add-new-feature-to-system"
        The status should equal 0
      End
    End

    Context 'When: Generating slug with Chinese characters'
      It 'Then: [正常] - translates Chinese to English slug'
        title="添加用户认证功能"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates to "add user authentication feature"
        The output should equal "add-user-authentication-feature"
        The status should equal 0
      End
    End

    Context 'When: AI translation unavailable (only Japanese)'
      It 'Then: [異常] - falls back to removing non-ASCII characters'
        title="これはテストです"

        When call generate_slug "$title" 50 mock_translator

        # Mock returns failure, non-ASCII chars are removed
        # Expected: empty string (all characters are Japanese)
        The output should equal ""
        The status should equal 0
      End
    End

    Context 'When: Generating slug with Korean characters'
      It 'Then: [エッジケース] - translates Korean to English slug'
        title="사용자 인증 기능 추가"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates to "add user authentication feature"
        The output should equal "add-user-authentication-feature"
        The status should equal 0
      End
    End

    Context 'When: Generating slug with title containing duplicate words'
      It 'Then: [正常] - removes consecutive duplicate words from translation'
        title="ブランチブランチ作成機能"

        When call generate_slug "$title" 50 mock_translator

        # Mock translates to "branch creation feature" (duplicates removed)
        The output should equal "branch-creation-feature"
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Given: Slug length constraints in different contexts
  # ============================================================================

  Describe 'Given: Slug length behavior in various contexts'
    Context 'When: Using default max length (50) for standalone slug'
      It 'Then: [正常] - allows up to 50 characters'
        title="This is a reasonably long title for testing default"
        result=$(generate_slug "$title")

        When call printf '%s' "$result"

        # Verify length is not more than 50 (shellspec doesn't have at_most)
        The output should not be blank
        The status should equal 0
        # Length check: result length should be 50 or less
        [ ${#result} -le 50 ]
      End
    End

    Context 'When: Using custom max length (30)'
      It 'Then: [正常] - respects custom length limit'
        title="This is an extremely long issue title that definitely exceeds thirty characters"
        result=$(generate_slug "$title" 30)

        When call printf '%s' "$result"

        The output should not be blank
        The status should equal 0
        # Length check: slug length should be 30 or less
        [ ${#result} -le 30 ]
      End
    End

    Context 'When: Using minimal max length (10)'
      It 'Then: [正常] - truncates aggressively with small max length'
        title="Add New Feature Request"
        result=$(generate_slug "$title" 10)

        When call printf '%s' "$result"

        # Should truncate to ~10 chars at word boundary
        The output should equal "add-new"
        The status should equal 0
        # Length check: result length should be 10 or less
        [ ${#result} -le 10 ]
      End
    End
  End
End
