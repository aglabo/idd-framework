---
header:
  - src: 09-templates-and-standards.md
  - @(#): Templates and Coding Standards
title: claude-idd-framework
description: AIコーディングエージェント向けソースコードテンプレート・JSDocルール集
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

## ソースコードテンプレート・JSDocルール

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトで使用するソースコードテンプレート・JSDoc ルール・コーディング標準を定義します。
一貫した実装品質と可読性を確保することを目的とします。

## TypeScriptファイルテンプレート

### 基本クラステンプレート

````typescript
// src: <ファイルパス>
// @(#): <クラス名とその説明>
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import type { <型インポート> } from "../types/index.js"
import { <実装インポート> } from "../utils/index.js"

/**
 * <クラスの概要説明>
 *
 * @example
 * ```typescript
 * const instance = new <クラス名>({ config })
 * const result = instance.method(param)
 * ```
 *
 * @public
 */
export class <クラス名> implements <インターフェース名> {
  private readonly _config: <Config型>

  /**
   * <クラス名>のインスタンスを作成
   *
   * @param config - 設定オブジェクト
   * @throws {AglaError} 無効な設定時
   */
  constructor(config: <Config型>) {
    this._config = this.validateConfig(config)
  }

  /**
   * <メソッドの概要説明>
   *
   * @param param - パラメータ説明
   * @returns 戻り値の説明
   * @throws {AglaError} エラー条件
   *
   * @example
   * ```typescript
   * const result = instance.method("value")
   * ```
   */
  public method(param: string): <戻り値型> {
    // 実装
  }

  /**
   * 設定の妥当性検証
   *
   * @param config - 検証対象の設定
   * @returns 検証済み設定
   * @throws {AglaError} 無効な設定時
   * @internal
   */
  private validateConfig(config: <Config型>): <Config型> {
    // バリデーション実装
    return config
  }
}
````

### インターフェース・型定義テンプレート

```typescript
// src: <ファイルパス>
// @(#): <機能名> Type Definitions
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

/**
 * <インターフェースの概要説明>
 *
 * @public
 */
export interface <インターフェース名> {
  /**
   * <プロパティの説明>
   */
  readonly property: <型>

  /**
   * <メソッドの概要説明>
   *
   * @param param - パラメータ説明
   * @returns 戻り値の説明
   */
  method(param: <型>): <戻り値型>
}

/**
 * <型エイリアスの説明>
 *
 * @public
 */
export type <型名> = <型定義>

/**
 * <列挙型の説明>
 *
 * @public
 */
export enum <列挙型名> {
  /** <値の説明> */
  VALUE1 = "value1",
  /** <値の説明> */
  VALUE2 = "value2"
}
```

### ユーティリティ関数テンプレート

````typescript
// src: <ファイルパス>
// @(#): <機能名> Utility Functions
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import type { <型インポート> } from "../types/index.js"
import { AglaError } from "@aglabo/agla-error"

/**
 * <関数の概要説明>
 *
 * @param param1 - 第1パラメータの説明
 * @param param2 - 第2パラメータの説明
 * @returns 戻り値の説明
 * @throws {AglaError} エラー条件
 *
 * @example
 * ```typescript
 * const result = utilityFunction("value1", "value2")
 * if (result.isOk()) {
 *   console.log(result.value)
 * }
 * ```
 *
 * @public
 */
export function <関数名>(
  param1: <型>,
  param2: <型>
): Result<<成功型>, AglaError> {
  try {
    // 実装
    return ok(result)
  } catch (error) {
    return err(new AglaError("ERROR_CODE", error.message))
  }
}
````

## テストファイルテンプレート

### Unit Testテンプレート

```typescript
// src: <テストファイルパス>
// @(#): <対象クラス名> Unit Tests
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import { describe, it, expect, beforeEach } from "vitest"
import { <対象クラス> } from "../src/<パス>/<ファイル名>.js"
import { createMock<依存関係> } from "./helpers/mock-helpers.js"

/**
 * @context Given - <テスト対象の基本機能>
 */
describe("<対象クラス名>", () => {
  let instance: <対象クラス>
  let mockDependency: Mock<依存関係型>

  beforeEach(() => {
    mockDependency = createMock<依存関係>()
    instance = new <対象クラス>({ dependency: mockDependency })
  })

  /**
   * @context When - <テスト対象の動作・条件>
   */
  describe("When: <動作・条件>", () => {
    /**
     * @context Then - <期待結果>
     */
    // 正常系: 標準的な入力で期待通りの結果を返すことを検証
    it("Then: [正常] <期待結果の詳細>", () => {
      // Arrange (Given詳細)
      const input = "test input"
      const expected = "expected output"

      // Act (When詳細)
      const result = instance.method(input)

      // Assert (Then詳細)
      expect(result).toBe(expected)
      expect(mockDependency.method).toHaveBeenCalledWith(input)
    })

    // 異常系: 不正な入力に対して適切にエラーを投げることを検証
    it("Then: [異常] <異常系の期待結果>", () => {
      // Arrange
      const invalidInput = null

      // Act & Assert
      expect(() => instance.method(invalidInput)).toThrow(AglaError)
    })

    // エッジケース: 境界値や特殊なケースでの動作を検証
    it("Then: [エッジケース] <エッジケースの期待結果>", () => {
      // Arrange
      const edgeInput = ""

      // Act
      const result = instance.method(edgeInput)

      // Assert
      expect(result).toBeDefined()
    })
  })
})
```

### Integration Testテンプレート

```typescript
// src: <テストファイルパス>
// @(#): <システム名> Integration Tests
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import { describe, it, expect, beforeAll, afterAll } from "vitest"
import { <システムクラス> } from "../src/<パス>/index.js"
import { createTestEnvironment } from "./helpers/test-environment.js"

/**
 * @context Given - <統合対象システム全体>
 */
describe("<システム名> Integration", () => {
  let system: <システムクラス>
  let testEnv: TestEnvironment

  beforeAll(async () => {
    testEnv = await createTestEnvironment()
    system = new <システムクラス>(testEnv.config)
  })

  afterAll(async () => {
    await testEnv.cleanup()
  })

  /**
   * @context When - <統合シナリオ>
   */
  describe("When: <統合シナリオの説明>", () => {
    /**
     * @context Then - <統合レベルでの期待結果>
     */
    it("Then: <統合結果の期待値>", async () => {
      // Arrange
      const inputData = testEnv.createTestData()

      // Act
      const result = await system.processData(inputData)

      // Assert
      expect(result.isOk()).toBe(true)
      expect(result.value).toMatchObject({
        processedCount: inputData.length,
        errors: []
      })
    })
  })
})
```

## JSDoc規約詳細

### 必須JSDocタグ

| タグ        | 使用場面           | 説明           | 例                                       |
| ----------- | ------------------ | -------------- | ---------------------------------------- |
| `@context`  | ファイル・describe | BDD文脈の種別  | `@context Given - ロガー基本機能`        |
| `@param`    | 関数・メソッド     | パラメータ説明 | `@param config - ロガー設定オブジェクト` |
| `@returns`  | 関数・メソッド     | 戻り値説明     | `@returns 設定済みロガーインスタンス`    |
| `@throws`   | 関数・メソッド     | 例外条件       | `@throws {AglaError} 無効設定時`         |
| `@example`  | 関数・クラス       | 使用例         | `@example const logger = new AgLogger()` |
| `@public`   | 公開要素           | 公開API        | `@public`                                |
| `@internal` | 内部要素           | 内部実装       | `@internal`                              |

**プレースホルダー表記**: テンプレート内のプレースホルダーは `<>` で囲む (例: `<クラス名>`, `<型>`)

### ファイルヘッダー形式

すべてのソースファイル・テストファイルには以下の形式のヘッダーを付与:

```typescript
// src: <ファイルパス>
// @(#): <ファイルの簡潔な説明>
//
// Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
```

- `src:` - パッケージルートからの相対パス (サブパッケージの場合は、サブパッケージルート)
- `@(#):` - ファイルの目的・内容の簡潔な説明

### JSDoc記述パターン

#### クラスドキュメント

````typescript
/**
 * TypeScript用構造化ロガーのコア実装
 *
 * AgLoggerは軽量で拡張可能なロガーシステムを提供します。
 * プラガブルなフォーマッターと出力先により、柔軟なログ処理を実現。
 *
 * @example
 * ```typescript
 * const logger = new AgLogger({
 *   level: LogLevel.INFO,
 *   formatter: new JSONFormatter(),
 *   outputs: [new ConsoleOutput()]
 * })
 *
 * logger.info("Application started", { version: "1.0.0" })
 * ```
 *
 * @public
 */
export class AgLogger implements IAgLogger {
  // 実装
}
````

#### メソッドドキュメント

````typescript
/**
 * 指定レベルのログメッセージを出力
 *
 * 設定されたレベルフィルタとフォーマッターを使用して、
 * メッセージを処理し、すべての出力先に配信します。
 *
 * @param level - ログレベル (DEBUG, INFO, WARN, ERROR)
 * @param message - ログメッセージ
 * @param meta - 追加メタデータ (オプション)
 * @returns Promise<void> 出力完了時に解決
 * @throws {AglaError} 無効なレベル指定時
 *
 * @example
 * ```typescript
 * await logger.log(LogLevel.INFO, "User login", { userId: "123" })
 * ```
 */
async log(
  level: LogLevel,
  message: string,
  meta?: Record<string, unknown>
): Promise<void> {
  // 実装
}
````

#### 型定義ドキュメント

```typescript
/**
 * ログ出力先のインターフェース
 *
 * カスタム出力先を実装する際に継承するベースインターフェース。
 * フォーマット済みメッセージを受け取り、適切な出力先に書き込み。
 *
 * @public
 */
export interface IAgOutput {
  /**
   * フォーマット済みログメッセージを出力
   *
   * @param message - フォーマット済みメッセージ
   * @returns Promise<void> 出力完了時に解決
   */
  write(message: FormattedMessage): Promise<void>;
}
```

## エラーハンドリングテンプレート

### AglaError活用パターン

```typescript
import { AglaError } from '@aglabo/agla-error-core';
import { err, ok, Result } from 'neverthrow';

/**
 * <処理名>を実行し、結果をResult型で返す
 *
 * @param input - 入力データ
 * @returns 成功時は処理結果、失敗時はAglaError
 */
export function processWithErrorHandling(
  input: InputType,
): Result<OutputType, AglaError> {
  try {
    // 入力検証
    if (!isValidInput(input)) {
      return err(
        new AglaError(
          'INVALID_INPUT',
          'Invalid input provided',
          { input },
        ),
      );
    }

    // 処理実行
    const result = performProcessing(input);

    return ok(result);
  } catch (error) {
    return err(
      new AglaError(
        'PROCESSING_FAILED',
        `Processing failed: ${error.message}`,
        { originalError: error },
      ),
    );
  }
}
```

## コード品質テンプレート

### 型安全性確保パターン

```typescript
// ✅ 推奨: 厳格な型定義
interface StrictConfig {
  readonly level: LogLevel;
  readonly outputs: readonly IAgOutput[];
  readonly formatter: IAgFormatter;
}

// ✅ 推奨: ユニオン型の活用
type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

// ✅ 推奨: ジェネリック型の適切な使用
function createLogger<T extends AgLoggerConfig>(
  config: T,
): AgLogger<T> {
  return new AgLogger(config);
}

// ❌ 避ける: any型の使用
function badFunction(data: any): any {
  return data;
}
```

### インポート・エクスポート標準

```typescript
// ✅ 推奨: 型インポートの分離
import type { Result } from 'neverthrow';
import type { AgLoggerConfig, IAgLogger } from '../types/index.js';

// ✅ 推奨: 実装インポート
import { AglaError } from '@aglabo/agla-error-core';
import { validateConfig } from '../utils/validation.js';

// ✅ 推奨: 名前付きエクスポート
export { AgLogger } from './aglogger.js';
export type { IAgLogger } from './types.js';

// ❌ 避ける: デフォルトエクスポート
export default AgLogger;
```

## パフォーマンス考慮テンプレート

### 非同期処理パターン

```typescript
/**
 * 非同期ログ出力の実装
 *
 * @param messages - 出力対象メッセージ配列
 * @returns 全出力完了時に解決するPromise
 */
async function batchLogOutput(
  messages: LogMessage[],
): Promise<Result<void, AglaError>> {
  try {
    // 並列出力で高速化
    const outputs = await Promise.allSettled(
      messages.map((msg) => this.writeToOutput(msg)),
    );

    // エラーチェック
    const failures = outputs.filter(
      (result): result is PromiseRejectedResult => result.status === 'rejected',
    );

    if (failures.length > 0) {
      return err(
        new AglaError(
          'BATCH_OUTPUT_FAILED',
          `${failures.length} outputs failed`,
          { failures },
        ),
      );
    }

    return ok(undefined);
  } catch (error) {
    return err(
      new AglaError(
        'BATCH_OUTPUT_ERROR',
        error.message,
        { originalError: error },
      ),
    );
  }
}
```

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [06-coding-conventions.md](06-coding-conventions.md) - コーディング規約詳細
- [07-test-implementation.md](07-test-implementation.md) - テスト実装ガイド

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
