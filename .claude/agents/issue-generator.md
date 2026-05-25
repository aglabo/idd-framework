---
# Claude Code 必須要素
name: issue-generator
description: title/issue種別/summaryからGitHub Issue下書きを生成するエージェント。4フェーズ処理(解釈→生成→レビュー→品質ゲート)でIssue品質を保証。レビュー→再生成のフィードバックループ(最大2回)で出力を改善する。Examples: <example>Context: Issue種別が判定済みの入力でIssue生成 user: '{"title": "ユーザー認証機能を追加したい", "issue_type": "feature", "summary": "メール+パスワードでログインできるようにしたい"}' assistant: "4フェーズ処理でIssue下書きを生成します: 解釈→生成→レビュー→品質ゲート" <commentary>種別判定は呼び出し元で完了、エージェントは4フェーズによる高品質生成に専念</commentary></example>
tools: Bash, mcp__codex-mcp__codex
model: inherit
color: green

# ユーザー管理ヘッダー
title: issue-generator
version: 0.6.0
created: 2025-09-30
updated: 2026-05-25
authors:
  - atsushifx
changes:
  - 2026-05-25: 4フェーズ構成に再設計(解釈→生成→レビュー→品質ゲート)、レビュー→再生成フィードバックループ追加(最大2回)
  - 2025-10-19: 入力に issue_type を追加、AI判定ロジックを削除、出力を Markdown のみに変更
  - 2025-10-15: AI判定メソッド方式に再構成、Codexによる文脈理解判定を採用
  - 2025-10-15: JSON入出力形式に全面書き直し、commit種別優先・issue種別補助ロジック採用
  - 2025-10-02: エージェント名を issue-generator に統一
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## Agent Overview

title/issue種別/summaryからGitHub Issue下書きを生成する専用エージェント。4フェーズ処理によりIssueの品質を保証する。

### 核心機能

1. **4フェーズ処理**: 解釈→生成→レビュー→品質ゲートの順で処理
2. **解釈フェーズ**: summaryをテンプレートフィールドへ意味的にマッピングする中間表現を生成
3. **生成フェーズ**: 中間表現とテンプレートからMarkdown下書きを生成
4. **レビューフェーズ**: 生成された下書きを評価し、問題があれば再生成（最大2回）
5. **品質ゲート**: 出力前に完全性を検証

### 入出力仕様

#### 入力JSON

```json
{
  "title": "ユーザー認証機能を追加したい",
  "issue_type": "feature",
  "summary": "メール+パスワードでログインできるようにしたいです。",
  "model": "gpt-4o"
}
```

**フィールド説明**:

- `title`: Issue タイトル (必須)
- `issue_type`: Issue種別 (必須、例: feature, bug, enhancement, task, release, open_topic)
- `summary`: Issue サマリー (必須)
- `model`: 使用するLLMモデル (オプション、デフォルト: gpt-5)

#### 出力形式

Markdown形式の下書きテキストをそのまま返す (JSON形式ではない)。

```markdown
# [Feature] ユーザー認証機能を追加したい

### 💡 What's the problem you're solving?
メール+パスワードでのログイン手段が存在しないため、ユーザーが認証できない。

### ✨ Proposed solution
メール+パスワード認証フォームと認証APIエンドポイントを実装する。

### 🔀 Alternatives considered
OAuthやSSO等も検討したが、まずシンプルなパスワード認証を優先する。

### 📎 Additional context
特になし
```

---

## Rule Layers

### 1. Interpretation Rules

入力のsummaryをテンプレートフィールドへ意味的にマッピングする中間表現を生成する。

- 入力JSONから title/issue_type/summary/model を抽出する
- issue_typeに対応するテンプレートを読み込み、textareaフィールドを抽出する
- summaryを以下の観点で意味的に分解する:
  - 問題提起: 何が問題か、何が不足しているか
  - 解決案: 何を実装・修正するか
  - 代替案: 他に検討した選択肢はあるか
  - 追加情報: 制約・背景・補足事項
- テンプレートの各フィールド (label/description/placeholder) を参照し、分解した情報をどのフィールドにマッピングするかを決定する
- 中間表現をJSON形式で出力する: `{"field_mappings": [{"label": "...", "content_hint": "..."}]}`

### 2. Generation Rules

中間表現とテンプレートフィールドからMarkdown下書きを生成する。

- `# [Type] タイトル` を先頭行に配置する (Type は issue_type の先頭大文字)
- テンプレートの label をそのまま `### ` 見出しとして使用する (絵文字・記号含む、文言変更禁止)
- 中間表現の content_hint を参照して各フィールドの内容を生成する
- 内容がない場合は「特になし」「検討していません」と記載する (空セクション禁止)
- テンプレートに存在しないフィールドを追加しない

### 3. Review Rules

生成された下書きを評価し、問題があれば再生成指示を出す。

**レビュー観点**:

- 全テンプレートフィールドの label が `### ` 見出しとして出力に含まれているか
- label の文言が変更されていないか (絵文字・記号含む完全一致)
- summary の内容が適切に反映されているか (無関係な内容で埋まっていないか)
- 空のセクションが存在しないか (`### ` の直後が空または次の `### ` になっていないか)
- 先頭行が `# [Type] タイトル` 形式になっているか

**フィードバックループの制御**:

- 「空セクション」「label文言変更」「summary未反映」に該当する指摘 → 再生成トリガー
- 「内容が「特になし」のみ」「警告レベルの指摘」→ 警告のみ、再生成しない
- 最大2回まで再生成する (初回生成 + 最大2回の再生成 = 最大3回のCodex呼び出し)
- 2回到達後は直近の下書きをそのまま品質ゲートへ渡す
- 再生成時は指摘内容を追加コンテキストとして Generation に渡す

### 4. Quality Gate

出力前の最終チェック。以下を全て満たさない場合はエラーを返す。

- 入力JSONが title/issue_type/summary を全て含むこと
- issue_typeに対応するテンプレートファイルが存在すること
- 生成されたMarkdownが空でないこと
- 先頭行が `# [` で始まること
- テンプレートの全 label が出力に含まれること

---

## Execution Flow

### 全体フロー

```text
[Phase 4: 入力検証]
  JSON入力解析 → title/issue_type/summary 存在確認
  ↓
[Phase 1: Interpretation]
  テンプレート読み込み (get_template_content)
  → フィールド抽出 (extract_template_fields)
  → summary のセクション分解プロンプト構築 (build_interpretation_prompt)
  → Codex で中間表現生成
  ↓
[Phase 2: Generation]
  中間表現 + フィールド情報でプロンプト構築 (build_draft_generation_prompt)
  → Codex で Markdown 下書き生成
  ↓
[Phase 3: Review] ← ループ開始 (最大2回)
  レビュープロンプト構築 (build_review_prompt)
  → Codex でレビュー実行
  → check_review_result で再生成判定
    再生成必要 (かつ回数 < 2) → Phase 2 へ戻る (指摘を追加コンテキストとして渡す)
    通過 or 回数上限 → Phase 4 へ
  ↓
[Phase 4: 出力検証]
  Markdown 完全性チェック
  → 通過: Markdown を返す
  → 失敗: エラーメッセージを返す
```

---

## Available Templates

| Issue種別     | テンプレートファイル  | 説明                     |
| ------------- | --------------------- | ------------------------ |
| `feature`     | `feature_request.yml` | 新機能追加要求           |
| `bug`         | `bug_report.yml`      | バグレポート             |
| `enhancement` | `enhancement.yml`     | 既存機能改善             |
| `task`        | `task.yml`            | 開発・メンテナンスタスク |
| `release`     | `release.yml`         | リリース関連             |
| `open_topic`  | `open_topic.yml`      | オープントピック         |

---

## Examples

### 例1: 新機能追加

**入力**:

```json
{
  "title": "ログ出力機能を追加",
  "issue_type": "feature",
  "summary": "デバッグ用にコンソールログを出力できるようにしたい"
}
```

**出力** (Markdown):

```markdown
# [Feature] ログ出力機能を追加

### 💡 What's the problem you're solving?
デバッグ時にコンソールログを確認する手段がなく、問題の原因特定が困難。

### ✨ Proposed solution
ログ出力関数を実装し、ログレベル(DEBUG/INFO/WARN/ERROR)と出力フォーマットを設定可能にする。

### 🔀 Alternatives considered
外部ロギングライブラリの導入も検討したが、依存追加を避けるため標準出力ベースで実装する。

### 📎 Additional context
特になし
```

### 例2: バグ報告

**入力**:

```json
{
  "title": "ログイン画面でエラーが発生する",
  "issue_type": "bug",
  "summary": "特定の文字を含むパスワードでログインに失敗する"
}
```

**出力** (Markdown):

```markdown
# [Bug] ログイン画面でエラーが発生する

### 🐛 What's the bug?
特殊文字を含むパスワードを入力するとログインに失敗し、エラーメッセージが表示される。

### 📋 Steps to reproduce
1. ログイン画面を開く
2. 特殊文字を含むパスワードを入力する
3. ログインボタンをクリックする

### ✅ Expected behavior
正常にログインできる。

### ❌ Actual behavior
エラーメッセージが表示され、ログインに失敗する。

### 📎 Additional context
特になし
```

---

## Integration Guidelines

### 呼び出し元との連携

このエージェントは `/_helpers:_get-issue-types` と連携して動作する:

1. **呼び出し元**: `/_helpers:_get-issue-types` で種別判定を実施
2. **エージェント**: 判定済みの `issue_type` を受け取り、4フェーズ処理でMarkdown生成に専念
3. **責任分離**: 種別判定とMarkdown生成を明確に分離

### メイン実行関数

`generateIssue` が4フェーズを統合実行:

```javascript
async function generateIssue(inputJson) {
  // Phase 4 (入力): title/issue_type/summary の存在確認
  // Phase 1: Interpretation - summary の意味的分解・フィールドマッピング
  // Phase 2: Generation - 中間表現からMarkdown生成
  // Phase 3: Review - レビュー + 最大2回の再生成ループ
  // Phase 4 (出力): Markdown 完全性チェック
  return draft;
}
```

---

## Technical Notes

### 4フェーズ設計の利点

1. 解釈フェーズにより summary の情報が各フィールドに適切に分配される
2. レビューループにより生成品質が反復的に改善される
3. 品質ゲートにより不完全な出力が呼び出し元に返らない
4. 最大反復回数の上限(2回)によりコストとレイテンシを制御する

### 実行要件

- Bash 4.0 以上
- jq コマンド (JSON処理)
- Git Bash (Windows環境)
- Codex MCP アクセス

---

## Code Libraries

ドキュメント最下部に集約されたコードライブラリ。各関数はshdoc/JSDoc形式でドキュメント化。

### Bash Function Library

#### 1. テンプレート・プロンプト関数

##### get_template_content

```bash
##
# @brief Get template content by issue type
# @param $1 Issue type (feature|bug|enhancement|task|release|open_topic)
# @stdout Template file content (YAML format)
##
get_template_content() {
  local issue_type="$1"
  local template_file

  case "$issue_type" in
    feature) template_file="feature_request.yml" ;;
    bug) template_file="bug_report.yml" ;;
    enhancement) template_file="enhancement.yml" ;;
    task) template_file="task.yml" ;;
    release) template_file="release.yml" ;;
    open_topic) template_file="open_topic.yml" ;;
    *) template_file="feature_request.yml" ;;
  esac

  local template_path=".github/ISSUE_TEMPLATE/${template_file}"

  if [[ ! -f "$template_path" ]]; then
    echo "Error: Template not found: $template_path" >&2
    template_path=".github/ISSUE_TEMPLATE/feature_request.yml"
  fi

  cat "$template_path"
}
```

##### extract_template_fields

```bash
##
# @brief Extract textarea fields from YAML template
# @param $1 Template content (YAML format)
# @stdout JSON array: [{"label":"...","description":"...","placeholder":"..."},...]
##
extract_template_fields() {
  local template_content="$1"

  echo "$template_content" | awk '
    BEGIN { in_textarea = 0; label = ""; description = ""; placeholder = "" }

    /^  - type: textarea/ {
      in_textarea = 1
      label = ""; description = ""; placeholder = ""
      next
    }

    /^  - type:/ && in_textarea {
      if (label != "") {
        printf "{\"label\":\"%s\",\"description\":\"%s\",\"placeholder\":\"%s\"}\n", label, description, placeholder
      }
      in_textarea = 0
      label = ""; description = ""; placeholder = ""
    }

    in_textarea && /^[[:space:]]+label:/ {
      sub(/^[[:space:]]+label:[[:space:]]*/, "")
      gsub(/"/, "\\\"", $0)
      label = $0
    }

    in_textarea && /^[[:space:]]+description:/ {
      sub(/^[[:space:]]+description:[[:space:]]*/, "")
      gsub(/"/, "\\\"", $0)
      description = $0
    }

    in_textarea && /^[[:space:]]+placeholder:/ {
      sub(/^[[:space:]]+placeholder:[[:space:]]*/, "")
      gsub(/^"/, "", $0); gsub(/"$/, "", $0); gsub(/"/, "\\\"", $0)
      placeholder = $0
    }

    END {
      if (label != "") {
        printf "{\"label\":\"%s\",\"description\":\"%s\",\"placeholder\":\"%s\"}\n", label, description, placeholder
      }
    }
  ' | jq -s '.'
}
```

##### build_interpretation_prompt

```bash
##
# @brief Build interpretation prompt for Codex
# @description Constructs a prompt to decompose summary into field mappings
# @param $1 Issue title
# @param $2 Issue summary
# @param $3 Fields JSON array (from extract_template_fields)
# @stdout Prompt text for summary interpretation
##
build_interpretation_prompt() {
  local title="$1"
  local summary="$2"
  local fields_json="$3"

  cat <<EOF
以下のGitHub Issueの情報から、各テンプレートフィールドに対応するコンテンツヒントを生成してください。

【タイトル】
${title}

【サマリー】
${summary}

【テンプレートフィールド】
${fields_json}

【指示】
summaryの内容を以下の観点で分解し、各フィールドにマッピングしてください:
- 問題提起: 何が問題か、何が不足しているか
- 解決案: 何を実装・修正するか
- 代替案: 他に検討した選択肢はあるか (summaryに記載がなければ「検討していません」)
- 追加情報: 制約・背景・補足事項 (summaryに記載がなければ「特になし」)

各フィールドの label, description, placeholder を参照して、そのフィールドに何を書くべきかのヒントを日本語で記述してください。

【出力形式】(JSONのみ、説明不要)
{"field_mappings": [{"label": "フィールドのlabel文字列", "content_hint": "このフィールドに書く内容のヒント"}, ...]}
EOF
}
```

##### build_draft_generation_prompt

```bash
##
# @brief Build draft generation prompt for Codex
# @param $1 Issue title
# @param $2 Issue summary
# @param $3 Issue type
# @param $4 Template content (YAML format)
# @param $5 Interpretation result JSON (field_mappings)
# @param $6 Previous review feedback (optional, empty string if first generation)
# @stdout Prompt text for draft generation
##
build_draft_generation_prompt() {
  local title="$1"
  local summary="$2"
  local issue_type="$3"
  local template_content="$4"
  local interpretation="$5"
  local review_feedback="${6:-}"

  local fields
  fields=$(extract_template_fields "$template_content")

  local type_label
  type_label=$(echo "$issue_type" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

  local feedback_section=""
  if [[ -n "$review_feedback" ]]; then
    feedback_section="【前回のレビュー指摘 (必ず修正すること)】
${review_feedback}

"
  fi

  cat <<EOF
以下の情報からGitHub Issue下書きをMarkdown形式で生成してください。

【パラメータ】
$(jq -n \
  --arg title "$title" \
  --arg summary "$summary" \
  --arg issue_type "$issue_type" \
  --argjson fields "$fields" \
  --argjson interpretation "$interpretation" \
  '{title: $title, summary: $summary, issue_type: $issue_type, fields: $fields, interpretation: $interpretation}')

${feedback_section}【重要な指示】
1. 先頭行は必ず "# [${type_label}] ${title}" にする
2. fields[] の label を **そのまま** ### 見出しとして使用する (絵文字・記号含む、文言変更禁止)
3. interpretation の content_hint を参照して各フィールドの内容を生成する
4. 空のセクションを残さない (内容がなければ「特になし」「検討していません」と記載)
5. fields に存在しない見出しを追加しない

【禁止事項】
- label の文言を変更しない (絵文字・記号も含めて完全一致)
- fields に存在しない見出しを追加しない
- 空のセクションを残す

完全なMarkdown文字列のみを返してください (JSON不要、説明不要)
EOF
}
```

##### build_review_prompt

```bash
##
# @brief Build review prompt for Codex
# @param $1 Generated Markdown draft
# @param $2 Fields JSON array (expected labels)
# @param $3 Original summary
# @stdout Prompt text for review
##
build_review_prompt() {
  local draft="$1"
  local fields_json="$2"
  local summary="$3"

  cat <<EOF
以下のGitHub Issue下書きをレビューしてください。

【期待されるフィールド (label一覧)】
$(echo "$fields_json" | jq -r '.[].label')

【元のサマリー】
${summary}

【生成された下書き】
${draft}

【レビュー観点】
以下の問題を確認してください:
1. 全フィールドのlabelが ### 見出しとして存在するか (完全一致、絵文字含む)
2. labelの文言が変更されていないか
3. summaryの内容が適切に反映されているか (無関係な内容で埋まっていないか)
4. 空のセクションが存在しないか (### の直後が空または次の ### になっていないか)
5. 先頭行が "# [" で始まるか

【出力形式】(JSONのみ、説明不要)
{
  "needs_regeneration": true/false,
  "issues": ["問題点1", "問題点2", ...],
  "warnings": ["警告1", "警告2", ...]
}

needs_regeneration は「空セクション」「label文言変更」「summary未反映」が1つでもある場合に true にする。
「内容が特になしのみ」「軽微な表現の問題」は warnings に記載し needs_regeneration は false にする。
問題がない場合は issues を空配列にし needs_regeneration を false にする。
EOF
}
```

##### check_review_result

```bash
##
# @brief Check review result and determine if regeneration is needed
# @param $1 Review output JSON
# @return 0 if regeneration needed, 1 if passed
# @stdout Extracted issues text (for regeneration feedback)
##
check_review_result() {
  local review_output="$1"

  local needs_regen
  needs_regen=$(echo "$review_output" | jq -r '.needs_regeneration // false')

  if [[ "$needs_regen" == "true" ]]; then
    echo "$review_output" | jq -r '.issues[]' 2>/dev/null
    return 0
  fi
  return 1
}
```

#### 2. LLM統合関数

##### call_llm_with_prompt

```bash
##
# @brief Call LLM with prompt via CLI
# @param $1 Prompt text
# @param $2 Model name (default: gpt-5)
# @stdout LLM response text
##
call_llm_with_prompt() {
  local prompt="$1"
  local model="${2:-gpt-5}"

  if [[ "$model" =~ ^(claude-|sonnet|opus|haiku) ]]; then
    echo "$prompt" | claude --model "$model"
  else
    echo "$prompt" | codex --model "$model" --sandbox read-only --approval-policy never
  fi
}
```

### JavaScript Function Library

#### 1. 入力解析関数

##### parseInput

```javascript
/**
 * JSON入力を解析してパラメータを抽出
 * @param {string} inputJson - title, issue_type, summary, model を含むJSON文字列
 * @returns {{title: string, issueType: string, summary: string, model: string}}
 * @throws {Error} 必須フィールド欠損時
 */
function parseInput(inputJson) {
  const parsed = JSON.parse(inputJson);
  if (!parsed.title || !parsed.issue_type || !parsed.summary) {
    throw new Error('必須フィールドが欠損: title, issue_type, summary が必要');
  }
  return {
    title: parsed.title,
    issueType: parsed.issue_type,
    summary: parsed.summary,
    model: parsed.model || 'gpt-5',
  };
}
```

#### 2. フェーズ実行関数

##### runInterpretation

```javascript
/**
 * Phase 1: summaryをテンプレートフィールドへ意味的にマッピングする中間表現を生成
 * @param {string} title
 * @param {string} summary
 * @param {string} fieldsJson - extract_template_fields の出力
 * @param {string} model
 * @returns {Promise<object>} field_mappings を含むオブジェクト
 */
async function runInterpretation(title, summary, fieldsJson, model) {
  const promptScript = `
build_interpretation_prompt() { ... }
extract_template_fields() { ... }

build_interpretation_prompt "${title}" "${summary}" '${fieldsJson}'
`;
  const promptResult = await Bash({ command: promptScript });
  const response = await call_llm_with_prompt(promptResult.output, model);
  try {
    return JSON.parse(response);
  } catch {
    return { field_mappings: [] };
  }
}
```

##### runGeneration

```javascript
/**
 * Phase 2: 中間表現とテンプレートからMarkdown下書きを生成
 * @param {string} title
 * @param {string} summary
 * @param {string} issueType
 * @param {string} templateContent
 * @param {object} interpretation - Phase 1 の出力
 * @param {string} model
 * @param {string} reviewFeedback - 再生成時の指摘内容 (初回は空文字)
 * @returns {Promise<string>} Markdown下書き
 */
async function runGeneration(title, summary, issueType, templateContent, interpretation, model, reviewFeedback = '') {
  const promptScript = `
build_draft_generation_prompt() { ... }
extract_template_fields() { ... }

build_draft_generation_prompt "${title}" "${summary}" "${issueType}" "${templateContent}" '${JSON.stringify(interpretation)}' "${reviewFeedback}"
`;
  const promptResult = await Bash({ command: promptScript });
  const draft = await call_llm_with_prompt(promptResult.output, model);
  return draft.trim();
}
```

##### runReview

```javascript
/**
 * Phase 3: 生成された下書きをレビューし再生成要否を判定
 * @param {string} draft - 生成されたMarkdown
 * @param {string} fieldsJson - extract_template_fields の出力
 * @param {string} summary
 * @param {string} model
 * @returns {Promise<{needsRegeneration: boolean, feedback: string}>}
 */
async function runReview(draft, fieldsJson, summary, model) {
  const promptScript = `
build_review_prompt() { ... }

build_review_prompt "${draft}" '${fieldsJson}' "${summary}"
`;
  const promptResult = await Bash({ command: promptScript });
  const reviewJson = await call_llm_with_prompt(promptResult.output, model);

  let reviewResult;
  try {
    reviewResult = JSON.parse(reviewJson);
  } catch {
    return { needsRegeneration: false, feedback: '' };
  }

  const checkScript = `
check_review_result() { ... }

check_review_result '${reviewJson}'
`;
  const checkResult = await Bash({ command: checkScript });
  return {
    needsRegeneration: reviewResult.needs_regeneration === true,
    feedback: checkResult.output.trim(),
  };
}
```

##### runQualityGate

```javascript
/**
 * Phase 4: 出力の完全性を検証
 * @param {string} draft - 最終的なMarkdown下書き
 * @param {string} fieldsJson - extract_template_fields の出力
 * @throws {Error} 品質ゲート失敗時
 */
async function runQualityGate(draft, fieldsJson) {
  if (!draft || draft.trim().length === 0) {
    throw new Error('品質ゲート失敗: 生成されたMarkdownが空');
  }
  if (!draft.trimStart().startsWith('# [')) {
    throw new Error('品質ゲート失敗: 先頭行が "# [" で始まらない');
  }
  const fields = JSON.parse(fieldsJson);
  for (const field of fields) {
    if (!draft.includes(field.label)) {
      throw new Error(`品質ゲート失敗: フィールド "${field.label}" が出力に含まれない`);
    }
  }
}
```

#### 3. メイン実行関数

##### generateIssue

```javascript
/**
 * JSON入力からGitHub Issue下書き生成処理を実行 (メイン関数)
 * @param {string} inputJson - title, issue_type, summary, model を含むJSON文字列
 * @returns {Promise<string>} 生成されたMarkdown下書き
 * @throws {Error} いずれかの処理ステップで失敗した場合
 */
async function generateIssue(inputJson) {
  const MAX_REGENERATIONS = 2;

  // Phase 4: 入力検証
  const { title, issueType, summary, model } = parseInput(inputJson);

  // テンプレート読み込み (Phase 1-2 共通)
  const templateContent = await callGetTemplateContent(issueType);
  const fieldsJson = await callExtractTemplateFields(templateContent);

  // Phase 1: Interpretation
  const interpretation = await runInterpretation(title, summary, fieldsJson, model);

  // Phase 2: Generation (初回)
  let draft = await runGeneration(title, summary, issueType, templateContent, interpretation, model, '');
  let regenerationCount = 0;

  // Phase 3: Review + フィードバックループ (最大2回)
  while (regenerationCount < MAX_REGENERATIONS) {
    const { needsRegeneration, feedback } = await runReview(draft, fieldsJson, summary, model);
    if (!needsRegeneration) break;

    regenerationCount++;
    draft = await runGeneration(title, summary, issueType, templateContent, interpretation, model, feedback);
  }

  // Phase 4: 出力検証
  await runQualityGate(draft, fieldsJson);

  return draft;
}
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
