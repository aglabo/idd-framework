---
header:
  - src: 06-coding-conventions.md
  - @(#): Coding Conventions and MCP Integration
title: claude-idd-framework
description: AIコーディングエージェント向けコーディング規約・MCP活用パターン
version: 1.0.0
created: 2025-09-27
authors:
  - atsushifx
changes:
  - 2025-09-27: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## コーディング規約・MCP活用パターン

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトで開発する際のコーディング規約と MCP ツール活用パターンを定義します。
実装の一貫性と品質確保を目的とします。

## 必須MCPツール活用パターン

### 実装前必須調査

🔴 必須: ファイル編集前の既存パターン調査・理解。

実装前に以下のコマンドで既存パターンを調査します。

```bash
# 1. プロジェクト理解
mcp__lsmcp__get_project_overview --root "$ROOT"

# 2. 関連機能調査
mcp__lsmcp__search_symbols --query "<関連機能名>" --root "$ROOT"

# 3. 実装パターン調査
mcp__serena-mcp__find_symbol --name_path "<類似クラス>" --include_body true

# 4. 既存テストパターン確認
mcp__serena-mcp__search_for_pattern --substring_pattern "test.*<関連機能>"
```

### 実装中MCPツール活用

実装中は以下のコマンドで型情報や依存関係を確認します。

```bash
# 型情報確認
mcp__lsmcp__lsp_get_hover --textTarget "<型名>"

# 依存関係確認
mcp__lsmcp__lsp_find_references --symbolName "<シンボル名>"

# 実装詳細確認
mcp__serena-mcp__find_symbol --name_path "<参考実装>" --include_body true
```

### 実装後影響確認

実装後は変更の影響範囲を確認します。

```bash
# 変更影響範囲確認
mcp__serena-mcp__find_referencing_symbols --name_path "<変更シンボル>" --relative_path "<変更ファイル>"

# 診断情報確認
mcp__lsmcp__lsp_get_diagnostics --relativePath "<変更ファイル>" --root "$ROOT"
```

## TypeScript コーディング規約

### 型安全性確保

🔴 必須: 厳格な型定義・型チェック。

明確な型定義を使用し、`any` 型の使用を避けます。

```typescript
// ✅ 良い例: 明確な型定義
interface AgLoggerConfig {
  level: LogLevel;
  formatter: AgFormatter;
  outputs: readonly AgOutput[];
}

// ❌ 悪い例: any型の使用
function processData(data: any): any {
  return data;
}

// ✅ 良い例: ジェネリック型の活用
function processData<T>(data: T): T {
  return data;
}
```

### ファイル構成規約

ファイルは以下の順序で構成します: 型インポート、実装インポート、型定義、実装。

```typescript
/**
 * @fileoverview ファイルの目的・機能説明
 * @context Given - BDD文脈でのファイル位置
 */

// 1. 型インポート
import type { AgLogger, AgLoggerConfig } from '../types/index.js';

// 2. 実装インポート
import { validateConfig } from '../utils/validate.js';

// 3. 型定義
export interface LocalConfig extends AgLoggerConfig {
  // 拡張プロパティ
}

// 4. 実装
export class AgLoggerImpl implements AgLogger {
  // 実装
}
```

### JSDoc規約

すべての公開関数・クラスには JSDoc コメントを記述します。

````typescript
/**
 * ログレベルに基づいてメッセージをフィルタリング
 *
 * @param message - ログメッセージ
 * @param level - ログレベル
 * @returns フィルタリング結果
 * @throws {AgLoggerError} 無効なレベル指定時
 *
 * @example
 * ```typescript
 * const result = filterMessage("info message", LogLevel.INFO)
 * ```
 */
function filterMessage(message: string, level: LogLevel): boolean {
  // 実装
}
````

## 制御フロー規約

### 早期リターンの原則

🔴 必須: エラー条件や特殊ケースを関数の先頭で処理し早期リターンすること。正常系処理は最後に配置し、ネストを浅く保つ。

この原則は TypeScript、JavaScript、ShellScript すべてに適用されます。深いネスト構造を避け、読みやすく保守しやすいコードを実現します。

#### TypeScript/JavaScript での早期リターン

バリデーションやエラーチェックを関数の先頭に配置し、条件を満たさない場合は即座に return します。

```typescript
// ❌ 悪い例: 深いネスト構造
function processUser(user: User | null): Result<UserData, Error> {
  if (user !== null) {
    if (user.isActive) {
      if (user.hasPermission('read')) {
        const data = fetchUserData(user.id);
        if (data !== null) {
          return ok(data);
        } else {
          return err(new Error('Data not found'));
        }
      } else {
        return err(new Error('Permission denied'));
      }
    } else {
      return err(new Error('User inactive'));
    }
  } else {
    return err(new Error('User is null'));
  }
}

// ✅ 良い例: 早期リターンでフラットな構造
function processUser(user: User | null): Result<UserData, Error> {
  // エラー条件を先頭で処理
  if (user === null) {
    return err(new Error('User is null'));
  }

  if (!user.isActive) {
    return err(new Error('User inactive'));
  }

  if (!user.hasPermission('read')) {
    return err(new Error('Permission denied'));
  }

  // 正常系処理は最後に配置
  const data = fetchUserData(user.id);
  if (data === null) {
    return err(new Error('Data not found'));
  }

  return ok(data);
}
```

#### ShellScript での早期リターン

ShellScript でも同様に、検証失敗やエラー条件を関数先頭で処理します。`xcp.sh` の実装パターンを参考にしてください。

```bash
# ✅ 良い例: xcp.sh の validate_source 関数パターン
validate_source() {
  local source="$1"

  # エラー条件1: ファイルが存在しない
  if [[ ! -e "$source" ]]; then
    log_error "Source not found: $source"
    return 1
  fi

  # エラー条件2: 読み取り不可
  if [[ ! -r "$source" ]]; then
    log_error "Source not readable: $source"
    return 1
  fi

  # 正常終了は最後
  return 0
}

# ✅ 良い例: 複数の状態を判定する関数
check_destination_directory() {
  local dest_dir="$1"

  # エラー条件1: パスが空
  if [[ -z "$dest_dir" ]]; then
    log_error "Destination path is empty"
    return 1
  fi

  # 正常条件: ディレクトリが存在し書き込み可能
  if [[ -d "$dest_dir" ]]; then
    if [[ -w "$dest_dir" ]]; then
      return 0
    fi
    log_error "Destination directory not writable: $dest_dir"
    return 1
  fi

  # エラー条件2: パスが存在するがディレクトリではない
  if [[ -e "$dest_dir" ]]; then
    log_error "Destination path exists but is not a directory: $dest_dir"
    return 1
  fi

  # 特殊条件: ディレクトリが存在しない(別処理が必要)
  return 2
}
```

#### Result 型との組み合わせ

`neverthrow` の `Result` 型を使用する場合も早期リターン原則を適用します。

```typescript
import { err, ok, Result } from 'neverthrow';

function createLogger(config: unknown): Result<AgLogger, AglaError> {
  // バリデーション失敗時は早期リターン
  const validationResult = validateAgLoggerConfig(config);
  if (validationResult.isErr()) {
    return err(validationResult.error);
  }

  // 初期化失敗時も早期リターン
  const initResult = initializeLogger(validationResult.value);
  if (initResult.isErr()) {
    return err(initResult.error);
  }

  // 正常系は最後
  return ok(initResult.value);
}
```

#### 早期リターンのメリット

早期リターンパターンは以下の利点があります:

- コードのネストレベルを浅く保つ
- 関数の事前条件(前提条件)を明確にする
- エラーハンドリングと正常系処理を明確に分離
- テストケースの網羅性が向上(エラー条件ごとにテスト可能)
- BDD テストとの親和性が高い(Given-When-Then 構造と対応)

## プロジェクト固有規約

### ファイル命名規約

実装ファイルとテストファイルの命名規則を定義します。

```bash
# 実装ファイル
src/core/aglogger.ts          # クラス実装
src/types/aglogger.ts         # 型定義
src/utils/validate.ts         # ユーティリティ

# テストファイル
__tests__/unit/aglogger.test.ts      # Unit test
__tests__/functional/logging.test.ts # Functional test
tests/integration/system.test.ts     # Integration test
tests/e2e/complete.test.ts          # E2E test
```

### インポート・エクスポート規約

名前付きエクスポートを推奨し、型インポートは分離します。

```typescript
// ✅ 推奨: 名前付きエクスポート
export { AgLogger, AgLoggerConfig } from './aglogger.js';

// ✅ 推奨: 型インポート分離
import type { AgLogger } from '../types/index.js';
import { createLogger } from '../utils/factory.js';

// ❌ 非推奨: デフォルトエクスポート
export default AgLogger;

// ❌ 非推奨: 全てインポート
import * as Logger from '../aglogger.js';
```

### エラーハンドリング規約

`AglaError` と `Result` 型を使用したエラーハンドリングを推奨します。

> 注意:
> `AglaError`は抽象クラスなので、実際は継承した具象クラスを使用します。

```typescript
// ✅ 推奨: AglaError使用
import { AglaError } from '@aglabo/agla-error-core';

class AgLoggerImpl {
  validate(config: AgLoggerConfig): void {
    if (!config.level) {
      throw new AglaError('INVALID_CONFIG', 'Log level is required');
    }
  }
}

// ✅ 推奨: Result型活用
import { err, ok, Result } from 'neverthrow';

function createLogger(config: AgLoggerConfig): Result<AgLogger, AglaError> {
  try {
    return ok(new AgLoggerImpl(config));
  } catch (error) {
    return err(new AglaError('CREATION_FAILED', error.message));
  }
}
```

## MCPツール連携実装パターン

### 既存パターン調査後の実装

`MCP` ツールで調査した既存パターンを踏襲して実装します。

```typescript
// MCPツールで調査した既存パターンを踏襲
mcp__serena-mcp__find_symbol --name_path "AgLoggerCore" --include_body true

// 調査結果を基にした一貫した実装
export class AgLoggerExtended extends AgLoggerCore {
  // 既存パターンに従った実装
}
```

### 型システム整合性確保

型定義と型安全性を `MCP` ツールで確認します。

```bash
# 型定義確認
mcp__lsmcp__lsp_get_definitions --symbolName "<AgLogger>" --relativePath "<src/types/aglogger.ts>"

# 型安全性確認
mcp__lsmcp__lsp_get_diagnostics --relativePath "<src/core/aglogger.ts>"
```

## BDDスタイル記述の徹底

### テストコード規約

`BDD` スタイルでテストを記述し、`Given-When-Then` 構造を明確にします。

```typescript
/**
 * @fileoverview AgLoggerのテストスイート
 * @context Given - ロガー機能の基本動作
 */

describe('AgLogger', () => {
  /**
   * @context When - 基本的なログ出力
   */
  describe('When: ログメッセージを出力', () => {
    /**
     * @context Then - 正しい形式で出力される
     */
    test('Then: 設定に従ってフォーマットされる', () => {
      // Arrange (Given詳細)
      const config = createTestConfig();
      const logger = new AgLogger(config);

      // Act (When詳細)
      logger.info('test message');

      // Assert (Then詳細)
      expect(mockOutput.write).toHaveBeenCalledWith(
        expect.stringContaining('test message'),
      );
    });
  });
});
```

### 実装コード構造

実装コードも `BDD` 観点で構造化します: `Given` (設定) → `When` (処理) → `Then` (結果)。

```typescript
export class AgLogger {
  /**
   * ログメッセージを出力
   * BDD観点: Given(設定) → When(ログ実行) → Then(出力)
   */
  log(level: LogLevel, message: string): void {
    // Given: 設定確認
    if (!this.isLevelEnabled(level)) {
      return;
    }

    // When: メッセージ処理
    const formatted = this.formatter.format(message, level);

    // Then: 出力実行
    this.outputs.forEach((output) => output.write(formatted));
  }
}
```

## 品質確保のためのMCP活用

### 実装前パターン研究

実装前に類似機能のパターンを研究します。

```bash
# 1. 類似機能の実装パターン調査
mcp__serena-mcp__search_for_pattern --substring_pattern "class.*<Logger>" --relative_path "<src>"

# 2. インターフェース定義の確認
mcp__lsmcp__search_symbols --kind ["Interface"] --query "<Logger>"

# 3. 既存テストパターンの確認
mcp__serena-mcp__search_for_pattern --substring_pattern "describe.*<Logger>"
```

### 実装後整合性確認

実装後は型整合性と影響範囲を確認します。

```bash
# 1. 型整合性確認
mcp__lsmcp__lsp_get_diagnostics --relativePath "<実装ファイル>"

# 2. 参照箇所の影響確認
mcp__serena-mcp__find_referencing_symbols --name_path "<変更シンボル>"

# 3. テスト整合性確認
mcp__serena-mcp__search_for_pattern --substring_pattern "test.*<新機能>"
```

## セキュリティプラクティス

### 機密情報保護

機密情報をログに出力しないよう、コードに注意します。

```typescript
// ✅ 推奨: 機密情報をログに出力しない
function logUserAction(userId: string, action: string): void {
  // 個人識別情報は出力しない
  logger.info(`User performed action: ${action}`);
}

// ❌ 禁止: 機密情報のログ出力
function logUserData(user: User): void {
  logger.info(`User data: ${JSON.stringify(user)}`); // 機密情報露出
}
```

### 入力値検証

入力値は `Result` 型を使用して検証します。

```typescript
function createLogger(config: unknown): Result<AgLogger, AglaError> {
  // MCP調査で確認した既存バリデーションパターンを使用
  const validationResult = validateAgLoggerConfig(config);

  if (validationResult.isErr()) {
    return err(validationResult.error);
  }

  return ok(new AgLoggerImpl(validationResult.value));
}
```

## 開発フロー統合

### コミット前チェック

`BDD` サイクルに対応した細かいコミットを行います。

```bash
# 1 message = 1 test: BDDサイクルに対応した細かいコミット
git add <実装ファイル>
git commit -m "feat: add basic logging functionality

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 継続的品質改善

- MCP ツールによる定期的なコード分析
- BDD サイクルに基づく段階的実装
- レビュー可能な小さな変更単位の維持

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD 開発フロー詳細
- [08-quality-assurance.md](08-quality-assurance.md) - 品質ゲート詳細

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
