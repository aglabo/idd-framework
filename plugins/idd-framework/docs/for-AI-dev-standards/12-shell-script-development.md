---
header:
  - src: 12-shell-script-development.md
  - @(#): Shell Script Development with BDD
title: claude-idd-framework
description: shellspec/shellcheck を使用したシェルスクリプトBDD開発ガイド
version: 1.0.0
created: 2025-10-06
authors:
  - atsushifx
changes:
  - 2025-10-06: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## シェルスクリプト開発概要

このドキュメントは shellspec と shellcheck を使用したシェルスクリプト開発の標準手順を定義します。
BDD (Behavior-Driven Development) 手法による品質保証とテスト駆動開発を実現します。

## 開発ツール

### shellspec

BDD スタイルのシェルスクリプトテストフレームワーク。Given-When-Then 構文でテストを記述します。

### shellcheck

シェルスクリプト静的解析ツール。構文エラー、一般的な問題、ベストプラクティス違反を検出します。

## プロジェクト構造

```bash
claude-idd-framework/
├── scripts/                      # シェルスクリプト本体
│   ├── setup-idd.sh
│   ├── merge-mcp.sh
│   ├── prepare-commit-msg.sh
│   ├── __tests__/                # テストファイル
│   │   ├── setup-idd.spec.sh
│   │   ├── merge-mcp.spec.sh
│   │   └── prepare-commit-msg.spec.sh
│   └── specs
│       └── spec_helper.sh        # ShellSpec用ヘルパ
└── .shellspec                    # ShellSpec設定ファイル
```

### テストファイル配置規則

- テスト対象スクリプトと同階層に `__tests__/` ディレクトリを作成
- テストファイル名: `{スクリプト名}.spec.sh`
- 例: `scripts/setup-idd.sh` → `scripts/__tests__/setup-idd.spec.sh`

## BDD階層構造 (shellspec)

### 基本構文

```bash
Describe 'Given: 前提条件 / Feature 機能名'
  Describe 'When: 動作/条件'
    It 'Then: [タグ] - 期待される結果'
      # Arrange (Given詳細)
      # Act (When詳細)
      # Assert (Then詳細)
    End
  End
End
```

### 必須タグ

- `[正常]`: 正常系 (成功ケース)
- `[異常]`: 異常系 (エラーケース)
- `[エッジケース]`: 境界値・特殊ケース

### サンプルテスト

```bash
Describe 'Given: setup-idd.sh script exists'
  setup_idd_script="$SHELLSPEC_PROJECT_ROOT/scripts/setup-idd.sh"

  Describe 'When: checking script properties'
    It 'Then: [正常] - script file should exist'
      The file "$setup_idd_script" should be exist
    End

    It 'Then: [正常] - script should be executable'
      The file "$setup_idd_script" should be executable
    End
  End

  Describe 'When: executing script without jq'
    It 'Then: [異常] - should fail with error message'
      Skip if 'jq is installed' command -v jq >/dev/null 2>&1
      When run bash "$setup_idd_script"
      The status should be failure
      The error should include "jq not found"
    End
  End
End
```

## 開発ワークフロー

### 1. スクリプト作成前の準備

```bash
# 1. テストディレクトリ作成
mkdir -p scripts/__tests__

# 2. テストファイル作成
touch scripts/__tests__/new-script.spec.sh

# 3. スクリプト本体作成
touch scripts/new-script.sh
chmod +x scripts/new-script.sh
```

### 2. BDD開発サイクル (RED-GREEN-REFACTOR)

#### ステップ0: タスク分割

実装前にテストケース(It単位)にタスクを分割します。

- 各Itは1つの独立したテストケース
- TodoWriteツールでタスク管理
- 1 message = 1 testの原則に従い、1つずつ実装

タスク分割例:

```bash
# テストケースの洗い出し
Describe 'Given: setup script'
  Describe 'When: validating prerequisites'
    It 'Then: [正常] - jq command should exist'     # タスク1
    It 'Then: [異常] - should fail without jq'      # タスク2
    It 'Then: [正常] - should detect git repo'      # タスク3
  End
End
```

TodoWrite例:

```typescript
[
  { content: 'jq存在確認テストを実装', status: 'pending', activeForm: 'jq存在確認テストを実装中' },
  { content: 'jq不在時エラーテストを実装', status: 'pending', activeForm: 'jq不在時エラーテストを実装中' },
  { content: 'gitリポジトリ検出テストを実装', status: 'pending', activeForm: 'gitリポジトリ検出テストを実装中' },
];
```

#### RED: 失敗するテストを書く

```bash
# テストファイル: scripts/__tests__/example.spec.sh
Describe 'Given: example.sh script'
  It 'Then: [正常] - should print hello message'
    When run bash scripts/example.sh
    The output should equal "Hello, World!"
  End
End
```

```bash
# テスト実行
pnpm test

# 結果: FAILED (スクリプト未実装のため)
```

#### GREEN: テストを通過する最小実装

```bash
# スクリプト実装: scripts/example.sh
#!/usr/bin/env bash
echo "Hello, World!"
```

```bash
# テスト実行
pnpm test

# 結果: SUCCESS
```

#### REFACTOR: コード品質向上

```bash
# スクリプト改善: scripts/example.sh
#!/usr/bin/env bash
set -euo pipefail

readonly MESSAGE="Hello, World!"

main() {
  echo "$MESSAGE"
}

main "$@"
```

```bash
# 静的解析実行
pnpm run lint:shell

# テスト再実行
pnpm test
```

### 3. 品質チェック

#### shellcheck による静的解析

```bash
# 個別ファイルチェック
shellcheck scripts/example.sh

# 全スクリプトチェック
pnpm run lint:shell

# pre-commit フックで自動実行 (staged files のみ)
git add scripts/example.sh
git commit -m "feat: add example script"
```

#### shellspec テスト実行

```bash
# 全テスト実行
pnpm test

# カバレッジ付き実行
pnpm run test:coverage

# 特定ファイルのみ実行
shellspec scripts/__tests__/example.spec.sh
```

## ベストプラクティス

### スクリプト作成規則

```bash
#!/usr/bin/env bash
# src: ./scripts/example.sh
# @(#) : script description
#
# Copyright (c) 2025 atsushifx
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail  # 必須: エラー時即終了

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
  # スクリプトロジック
  :
}

main "$@"
```

### テスト作成規則

```bash
#!/usr/bin/env bash
# src: ./scripts/__tests__/example.spec.sh
# @(#) : shellspec tests for example.sh
#
# Copyright (c) 2025 atsushifx
# Released under the MIT License.
# https://opensource.org/licenses/MIT

Describe 'Given: example.sh script exists'
  script_path="$SHELLSPEC_PROJECT_ROOT/scripts/example.sh"

  Describe 'When: checking script properties'
    It 'Then: [正常] - script should be executable'
      The file "$script_path" should be executable
    End
  End
End
```

### 1 message = 1 test の原則

```bash
# ❌ 悪い例: 複数テストを一度に実装
Describe 'Given: script'
  It 'Then: [正常] - test 1' ... End
  It 'Then: [正常] - test 2' ... End  # 同時実装は禁止
  It 'Then: [正常] - test 3' ... End
End

# ✅ 良い例: 1つずつテスト追加
# 最初のメッセージ
Describe 'Given: script'
  It 'Then: [正常] - test 1' ... End
End

# 次のメッセージ (test 1 が GREEN 確認後)
Describe 'Given: script'
  It 'Then: [正常] - test 1' ... End
  It 'Then: [正常] - test 2' ... End
End
```

## 設定ファイル

### .shellspec

```bash
--require spec_helper

--kcov-options "--exclude-pattern=/__tests__/,/spec/,/node_modules/"
--pattern '**/__tests__/*.spec.sh'

--format documentation
--color
```

### package.json

```json
{
  "scripts": {
    "test": "shellspec",
    "test:coverage": "shellspec --kcov",
    "lint:shell": "shellcheck scripts/*.sh"
  }
}
```

### lefthook.yml

```yaml
pre-commit:
  parallel: true
  commands:
    shellcheck:
      glob: "*.sh"
      run: shellcheck {staged_files}
```

## トラブルシューティング

### shellspec エラー

```bash
# 1. シンタックスエラー
Error: Unmatched 'End'
→ Describe/It/End の対応を確認

# 2. テストファイルが見つからない
No examples found
→ .shellspec の --pattern 設定を確認
→ ファイル名が *.spec.sh か確認

# 3. SHELLSPEC_PROJECT_ROOT 未定義
Error: SHELLSPEC_PROJECT_ROOT: unbound variable
→ spec_helper.sh が読み込まれているか確認
→ .shellspec に --require spec_helper があるか確認
```

### shellcheck 警告

```bash
# SC2086: Double quote to prevent globbing
echo $var  # ❌
echo "$var"  # ✅

# SC2155: Declare and assign separately
local var="$(command)"  # ❌
local var
var="$(command)"  # ✅

# SC2164: Use 'cd ... || exit' in case cd fails
cd /path  # ❌
cd /path || exit 1  # ✅
```

## See Also

- `05-bdd-workflow.md`: BDD開発フロー詳細
- `07-test-implementation.md`: テスト実装ガイド
- `08-quality-assurance.md`: 品質保証プロセス
- `11-bdd-implementation-details.md`: BDD実装詳細

## 参考リンク

- [shellspec公式ドキュメント](https://shellspec.info/)
- [shellcheck Wiki](https://github.com/koalaman/shellcheck/wiki)
