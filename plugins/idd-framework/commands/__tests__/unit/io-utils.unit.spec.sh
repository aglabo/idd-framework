#!/usr/bin/env bash
# shellcheck shell=bash
# src: .claude/commands/__tests__/unit/io-utils.unit.spec.sh
# @(#) io-utils.lib.sh unit tests

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
COMMANDS_ROOT="${COMMANDS_ROOT:-$PROJECT_ROOT/plugins/idd-framework/commands}"

# テスト対象のライブラリを読み込み
# shellcheck disable=SC1091
. "$COMMANDS_ROOT/_libs/io-utils.lib.sh"

Describe 'io-utils.lib.sh'
  Describe 'error_print() function'
    Describe 'Given: Error message string'
      Context 'When: Printing error with single argument'
        It 'Then: [正常] - outputs to stderr'
          When call error_print "Error message"
          The error should equal "Error message"
          The status should be success
        End
      End

      Context 'When: Printing error with multiple arguments'
        It 'Then: [正常] - concatenates all arguments'
          When call error_print "Error:" "Multiple" "arguments"
          The error should equal "Error: Multiple arguments"
          The status should be success
        End
      End
    End

    Describe 'Given: No arguments (heredoc mode)'
      Context 'When: Reading from stdin'
        Data
          #|Multi-line
          #|error message
        End

        It 'Then: [正常] - outputs heredoc to stderr'
          When call error_print
          The error should equal "Multi-line
error message"
          The status should be success
        End
      End
    End
  End

  Describe 'is_non_ascii() function'
    Describe 'Given: Pure ASCII text input'
      Context 'When: Checking basic ASCII string'
        It 'Then: [正常] - returns 1 (false) for pure ASCII'
          When call is_non_ascii "hello world"
          The status should equal 1
        End
      End

      Context 'When: Checking ASCII with numbers and symbols'
        It 'Then: [正常] - returns 1 (false) for ASCII alphanumeric with symbols'
          When call is_non_ascii "test-123_ABC!@#"
          The status should equal 1
        End
      End

      Context 'When: Checking empty string'
        It 'Then: [エッジケース] - returns 1 (false) for empty string'
          When call is_non_ascii ""
          The status should equal 1
        End
      End

      Context 'When: Checking ASCII whitespace only'
        It 'Then: [正常] - returns 1 (false) for whitespace'
          When call is_non_ascii "   	"
          The status should equal 1
        End
      End
    End

    Describe 'Given: Non-ASCII text input'
      Context 'When: Checking Japanese hiragana'
        It 'Then: [正常] - returns 0 (true) for hiragana'
          When call is_non_ascii "こんにちは"
          The status should equal 0
        End
      End

      Context 'When: Checking Japanese katakana'
        It 'Then: [正常] - returns 0 (true) for katakana'
          When call is_non_ascii "カタカナ"
          The status should equal 0
        End
      End

      Context 'When: Checking Japanese kanji'
        It 'Then: [正常] - returns 0 (true) for kanji'
          When call is_non_ascii "日本語"
          The status should equal 0
        End
      End

      Context 'When: Checking mixed ASCII and Japanese'
        It 'Then: [正常] - returns 0 (true) for mixed content'
          When call is_non_ascii "hello 世界"
          The status should equal 0
        End
      End

      Context 'When: Checking emoji characters'
        It 'Then: [正常] - returns 0 (true) for emoji'
          When call is_non_ascii "😀🎉"
          The status should equal 0
        End
      End

      Context 'When: Checking other Unicode characters'
        It 'Then: [正常] - returns 0 (true) for accented characters'
          When call is_non_ascii "café"
          The status should equal 0
        End

        It 'Then: [正常] - returns 0 (true) for Cyrillic'
          When call is_non_ascii "Привет"
          The status should equal 0
        End
      End
    End

    Describe 'Given: Edge cases'
      Context 'When: Checking extended ASCII (0x80-0xFF)'
        It 'Then: [エッジケース] - returns 0 (true) for extended ASCII'
          # Using printf to generate byte 0x80
          When call is_non_ascii "$(printf '\x80')"
          The status should equal 0
        End
      End

      Context 'When: Checking newline characters'
        It 'Then: [エッジケース] - returns 1 (false) for newline in ASCII text'
          When call is_non_ascii "line1
line2"
          The status should equal 1
        End
      End
    End
  End
End
