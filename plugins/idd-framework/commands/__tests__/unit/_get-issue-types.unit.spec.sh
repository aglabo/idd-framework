#!/usr/bin/env bash
# shellcheck shell=bash
# src: .claude/commands/__tests__/unit/_get-issue-types.unit.spec.sh
# @(#) _get-issue-types.md helper functions unit tests

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"

# テスト対象の関数を読み込み
# _get-issue-types.md はMarkdownファイルなので、関数部分を抽出して読み込む必要がある
# ここでは直接関数を定義する方式を採用

# extract_commit_types() 関数定義
extract_commit_types() {
  local config_file="${1:-configs/commitlint.config.js}"

  [[ ! -f "$config_file" ]] && return 1

  awk '/type-enum.*\[/,/\]\]/' "$config_file" \
    | grep -E "^\s*'[a-z]+'" \
    | sed -E "s/\s*'([a-z]+)',?\s*\/\/\s*(.*)/{\n  \"type\": \"\1\",\n  \"description\": \"\2\"\n},/" \
    | sed '$ s/,$//' \
    | sed '1 i[' \
    | sed '$ a]' \
    | jq -c '.'
}

# build_issue_types_table() 関数定義
build_issue_types_table() {
  jq -n -c '[
    {
      "type": "feature",
      "description": "新機能追加要求",
      "template": "feature_request.yml"
    },
    {
      "type": "bug",
      "description": "バグレポート",
      "template": "bug_report.yml"
    },
    {
      "type": "enhancement",
      "description": "既存機能改善",
      "template": "enhancement.yml"
    },
    {
      "type": "task",
      "description": "開発・メンテナンスタスク",
      "template": "task.yml"
    },
    {
      "type": "release",
      "description": "リリース関連",
      "template": "release.yml"
    },
    {
      "type": "question",
      "description": "質問・相談",
      "template": "question.yml"
    }
  ]'
}

# build_ai_judgment_prompt() 関数定義
build_ai_judgment_prompt() {
  local title="$1"
  local summary="$2"
  local commit_types_json="$3"
  local issue_types_json="$4"

  cat <<EOF
以下の情報から、最適なcommit種別、issue種別、branch種別を判定してJSON形式で返してください。

【コミット種別定義】
${commit_types_json}

【Issue種別定義】
${issue_types_json}

【入力】
- タイトル: "${title}"
- サマリー: "${summary}"

【判定ルール】
1. サマリーの内容を深く分析してcommit種別を判定 (第一優先)
   - 「何を」作成・修正するかを重視
   - 例: "ドキュメント作成" → docs、"機能追加" → feat
2. サマリーの内容からissue種別を判定 (第二優先)
   - バグ報告、機能追加、改善提案、タスクのいずれか
3. branch種別決定:
   - 基本: commit種別を採用
   - 相応しさ判定で切り替え:
     * docs + 改善文脈 → enhancement
     * test + bug文脈 → bug
     * refactor + enhancement文脈 → enhancement

【出力形式】
必ずJSON形式で返してください:
{
  "commit_type": "選択したcommit種別",
  "issue_type": "選択したissue種別",
  "branch_type": "最終決定したbranch種別",
  "reasoning": "判定理由の簡潔な説明 (日本語)"
}
EOF
}

Describe '_get-issue-types.md helper functions'
  Describe 'extract_commit_types() function'
    Describe 'Given: commitlint.config.js が存在する'
      Context 'When: extract_commit_types() を呼び出す'
        It 'Then: [正常] - 有効なJSON配列を返す'
          result() {
            extract_commit_types "$PROJECT_ROOT/configs/commitlint.config.js" | jq -r 'type'
          }
          When call result
          The status should be success
          The output should include 'array'
        End

        It 'Then: [正常] - feat type を含む'
          result() {
            extract_commit_types "$PROJECT_ROOT/configs/commitlint.config.js" | jq -r '.[] | select(.type == "feat") | .type'
          }
          When call result
          The output should include 'feat'
        End

        It 'Then: [正常] - fix type を含む'
          result() {
            extract_commit_types "$PROJECT_ROOT/configs/commitlint.config.js" | jq -r '.[] | select(.type == "fix") | .type'
          }
          When call result
          The output should include 'fix'
        End

        It 'Then: [正常] - 各要素にtype と description を持つ'
          result() {
            extract_commit_types "$PROJECT_ROOT/configs/commitlint.config.js" | jq -r '.[0] | has("type") and has("description")'
          }
          When call result
          The output should include 'true'
        End
      End
    End

    Describe 'Given: commitlint.config.js が存在しない'
      Context 'When: 存在しないファイルパスを指定'
        It 'Then: [異常] - 終了コード1を返す'
          When call extract_commit_types "/nonexistent/path/config.js"
          The status should equal 1
        End
      End
    End
  End

  Describe 'build_issue_types_table() function'
    Describe 'Given: 6種類のissue種別定義が存在する'
      Context 'When: build_issue_types_table() を呼び出す'
        It 'Then: [正常] - 有効なJSON配列を返す'
          result() {
            build_issue_types_table | jq -r 'type'
          }
          When call result
          The status should be success
          The output should include 'array'
        End

        It 'Then: [正常] - 6個の要素を持つ'
          result() {
            build_issue_types_table | jq 'length'
          }
          When call result
          The output should include '6'
        End

        It 'Then: [正常] - feature type を含む'
          result() {
            build_issue_types_table | jq -r '.[] | select(.type == "feature") | .type'
          }
          When call result
          The output should include 'feature'
        End

        It 'Then: [正常] - bug type を含む'
          result() {
            build_issue_types_table | jq -r '.[] | select(.type == "bug") | .type'
          }
          When call result
          The output should include 'bug'
        End

        It 'Then: [正常] - 各要素にtype, description, template を持つ'
          result() {
            build_issue_types_table | jq -r '.[0] | has("type") and has("description") and has("template")'
          }
          When call result
          The output should include 'true'
        End
      End
    End
  End

  Describe 'build_ai_judgment_prompt() function'
    Describe 'Given: タイトル、サマリー、commit種別、issue種別が与えられる'
      commit_types='[{"type":"feat","description":"New feature"},{"type":"fix","description":"Bug fix"}]'
      issue_types='[{"type":"feature","description":"新機能"},{"type":"bug","description":"バグ"}]'

      Context 'When: build_ai_judgment_prompt() を呼び出す'
        It 'Then: [正常] - プロンプトテキストを返す'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The status should be success
          The output should include "最適なcommit種別"
        End

        It 'Then: [正常] - タイトルを含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "テストタイトル"
        End

        It 'Then: [正常] - サマリーを含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "テストサマリー"
        End

        It 'Then: [正常] - commit種別定義を含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "New feature"
        End

        It 'Then: [正常] - issue種別定義を含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "新機能"
        End

        It 'Then: [正常] - 判定ルールを含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "【判定ルール】"
        End

        It 'Then: [正常] - 出力形式を含む'
          When call build_ai_judgment_prompt "テストタイトル" "テストサマリー" "$commit_types" "$issue_types"
          The output should include "【出力形式】"
        End
      End
    End
  End
End
