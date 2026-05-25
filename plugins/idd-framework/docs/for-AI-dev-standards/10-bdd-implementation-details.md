---
header:
  - src: 10-bdd-implementation-details.md
  - @(#): Spec-Driven BDD Implementation Guide
title: claude-idd-framework
description: コーディングエージェント向け atsushifx 式 BDD 実践ガイド
version: 1.0.0
created: 2025-09-29
authors:
  - atsushifx
changes:
  - 2025-09-29: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## ドキュメント概要

このドキュメントは、エージェントが atsushifx 式 BDD を一貫して実践するための総合的なリファレンスです。
Spec-Driven-Development (SDD) に合わせて要件定義から品質検証までの流れを整備し、Red-Green-Refactor サイクルと ToDo 管理を統合して開発します。

### 適用範囲

- 対象プロジェクト: agla-logger モノレポ全体
- 対象エージェント: typescript-bdd-coder を含むすべての実装エージェント
- 対象フェーズ: 企画、設計、実装、リファクタリング、品質検証

## atsushifx 式 BDD のコア

### BDD の本質とビジネス価値

`Behavior Driven Development` は、ビジネス価値を起点に要求をシナリオ化し、期待する挙動が常にテストで裏付けられるようにする開発手法です。
テストファースト (`TDD`) が実装単位での正しさを重視するのに対し、`BDD` はユーザーストーリーやユースケースを具体的な振る舞いに落とし込み、関係者間で共通言語を形成します。これにより、要件の曖昧さを排除しつつ、価値提供の優先順位を明確にできます。

ビジネス価値との結び付けは、以下の三点で測定します。

1. 振る舞い記述が直接的に顧客価値へ言及しているか。
2. シナリオが成果物の受け入れ基準として機能するか。
3. リリース後の評価指標 (成功条件) が明文化されているか。

### atsushifx 式独自要素

- 三層階層構造:
  メインフェーズ (`Given`)、サブフェーズ (`When`)、タスクグループ (`Then`) から成り、それぞれが `ToDo` リストの親子関係と直結。
  この構造を守ることで、シナリオ分解から実装タスクへのマッピングが自動的に維持される。

- `Given`/`When`/`Then` の厳格分類:
  境界条件を明示し、想定外挙動を防ぐための基盤。
  各 it 文には `[正常]`, `[異常]`, `[エッジケース]` のタグを必ず付け、テスト報告だけでケース分類が把握できるようにする。

- `ToDo` リスト連携:
  ドキュメント内のタスク `ID` を `temp/todo.md` と同期させ、`Red-Green-Refactor` の進行とタスク消化が常に一致する状態を作る。
  これにより、途中離脱があっても再開位置を正確に示す。

### 実践原則とチェック

- `1 message = 1 test` 原則: 各メッセージで扱う検証範囲を最小化し、失敗時の切り戻しを容易にする

- 段階的詳細化: 要求から仕様、テスト、実装へと粒度を揃えながら掘り下げる手法。各段階で必ずレビュー (自己または他者) を実施

- 品質ゲート統合: 以下の五項目を通過しなければタスク完了とみなしません。
  - `pnpm run check:types`
  - `pnpm run lint:all`
  - `pnpm run test:develop`
  - `pnpm run check:dprint`
  - `pnpm run build`

- 理解度チェック: 以下の問いを自問
  - シナリオは誰にどんな価値を届けるのか。
  - `Given` 条件は前提不足なく列挙できているか。
  - `When` の操作は単一の行動に絞られているか。
  - `Then` の期待結果は定量的か、検証可能か。
  - タスク `ID` は `temp/todo.md` と対応付けられているか。

## ToDo リスト作成・管理方法

### 三層構造の定義

- メインフェーズ (例: `DOC-01`):
  プロジェクトの大項目で、プロセス的な責務 (基盤作成、概念整理、テンプレート整備など) を担当

- サブフェーズ (例: `DOC-01-01`):
  `Given` 前提に相当し、条件設定や準備作業を記述

- タスクグループ (例: `DOC-01-01-01`):
  `When` の行動であり、実際の操作と期待結果 (`Then`) を橋渡し

- 最小単位の `ToDo`:
  `expect` 文レベルで管理し、`Then` の検証を粒度の揃ったチェック項目に変換。
  これにより、タスクの完了基準を自明化し、途中から参入するエージェントでも迷わず再開可能

### タスク ID とテンプレート

- ID 体系: `<PREFIX>-XX-YY-ZZ` を基本形とする:
  - PREFIX: 領域を表し、DOC (ドキュメント基盤)、BDD (概念・実践)、TPL (テンプレート)、MGT (マネジメント) などを使用
  - XX: メインフェーズ
  - YY: サブフェーズ
  - ZZ: タスクグループまたは expect 番号
  - 採番: 01 から連番とし、欠番が生じた場合は履歴に明記

- テンプレート例:

  ```markdown
  #### DOC-01-01-01: When - 基本ドキュメント構造作成

  - DOC-01-01-01-01: ファイル作成完了
  - DOC-01-01-01-02: フロントマター整備
  - DOC-01-01-01-03: 主要セクション配置
  - DOC-01-01-01-04: 目次整合性確認
  ```

- テンプレート活用: プレースホルダー (例: `<FEATURE_NAME>`, `<SCENARIO_NAME>`) を活用し、他フェーズでも再利用可能

### TodoWrite ツール運用指針

- タスク登録: `TodoWrite` ツールでは、タスク登録時に `pending`, `in_progress`, `completed` を必ず指定

- 状態遷移: `pending → in_progress → completed` のみ許可し、逆方向遷移が必要な場合はコメントで理由を記録

- 同期管理: `docs/rules/09-todo-task-management.md` に従い、ToDo を更新したら Git の差分として残るようにコミット前に同期。

### 必須実行ルール：個別タスク完了時のチェック更新

🔴 重要: 1つのタスク (expect 文レベル) が完了したら、即座に以下を実行する。

- TodoWrite ツールでの状態更新: 該当タスクを `completed` に変更
- temp/todo.md のチェックボックス更新: 対応する `- [ ]` を `- [x]` に変更
- 進捗コミット: 変更を即座にコミットして進捗を記録

### 必須実行ルール：タスクグループ完了時の進捗報告

🔴 重要: タスクグループ (When 単位) が完了したら、以下を実行する。

- 進捗サマリー作成: 完了した expect 文の数と全体に対する割合を算出
- 品質ゲート実行: 5 項目チェック (types/lint/test/dprint/build) を実行
- 次タスクグループ準備: 次の作業範囲を明確化
- 作業工程記録: 完了時刻と所要時間をドキュメントに記録

### temp/todo.md チェックボックス管理の厳格化

```markdown
### チェックボックス更新テンプレート

### 作業前確認

- [ ] 現在取り組むタスクのID確認
- [ ] 依存関係の確認 (前提タスクの完了確認)
- [ ] 作業開始時刻の記録

### 作業中管理

- 1つのexpect文が完了するごとに即座にチェック
- TodoWriteツールとtemp/todo.mdの同期維持
- 作業が中断される場合は進捗状況を記録

### 作業完了確認

- [ ] 対象タスクの全expect文が完了
- [ ] チェックボックスが全て`[*]`になっている
- [ ] 品質ゲート5項目が全てpass
- [ ] 変更がコミット済み
```

### 進捗追跡の自動化強化

`Red-Green-Refactor` の各フェーズ終了時に、関連する `expect` 文を完了済みへ更新します。`/sdd task` で再生成されるタスクリストと差異が出ないようにします。

- 進捗レポート自動生成:
  - 完了タスク数 / 全タスク数 (%)
  - 各メインフェーズの進捗状況
  - 推定残り作業時間

進捗の自動追跡には `TodoWrite` のレポート機能を利用します。ブロッカーが発生した場合は新しい expect ID を予約して調査タスクを追加し、依存関係を明示します。

## Red-Green-Refactor サイクル実践

### RED フェーズ

- 基本目的: 失敗するテストを意図的に作成し、要件を自動化された形で固定
  - `Given` 条件: 必要な前提データ、依存モジュール、初期化手順を列挙
  - `When` 操作: 単一の操作を選び、複数操作が関与する場合は追加のタスクへ分割
  - `Then` 期待結果: `[正常]`, `[異常]`, `[エッジケース]` のいずれかを付け、期待する結果を定量化
  - 失敗確認: テストが失敗することを確認し、意図しない成功が起きていないかログで検証

### GREEN フェーズ

- 最小実装: 最小限の実装で `RED` のテストを通過。過剰実装を避けるため、テストで要求されていない分岐や最適化は後回し
  - 影響範囲確認: テストが通過したら、影響範囲を `mcp__serena-mcp__get_symbols_overview` や `mcp__lsmcp__search_symbols` で確認。予期せぬ副作用がないかをチェック
  - 品質確認: 型エラーがないか、リンターが警告を出していないか、ログが意図しない機密情報を含んでいないかを点検

### REFACTOR フェーズ

- 基本方針: テストを緑の状態に保ちながら可読性・拡張性を向上
  - 実施内容: コードの重複削減、命名の再考、ドキュメント補強、ロギングの統一
  - 範囲制限: リファクタリング範囲は、RED と GREEN で触れた箇所に限定し、周辺が必要な場合でもテストを追加してから着手
  - 品質測定: 複雑度 (Cyclomatic Complexity)、カバレッジ、レビュー指摘件数などで測定

### フェーズ移行条件とテンプレート

- `RED` → `GREEN` の移行条件: 失敗テストが追加され、意図した箇所以外が失敗していないこと。

- `GREEN` → `REFACTOR` の移行条件: 追加したテストを含む全テストが成功し、型チェックとリンターが通過していること。

- `REFACTOR` → 次サイクルの移行条件: 可読性改善が完了し、テストが再度成功していること、品質ゲート五項目が完了していること。

- サイクル実行テンプレート:

  ```markdown
  1. RED
     - 新しいシナリオを ToDo へ登録
     - 失敗するテストを実装
     - テストが失敗することを確認
  2. GREEN
     - 最小限の実装を追加
     - テストと型チェックを実行
     - 成果を ToDo へ反映
  3. REFACTOR
     - コードとドキュメントを整理
     - 可読性と再利用性を向上
     - 品質ゲートを再実行
  ```

## BDD 階層構造テンプレート

### Feature レベルテンプレート

```typescript
// src: /path/to/test-file.spec.ts
// @(#): <FEATURE_NAME> Feature Tests

describe('Given: <FEATURE_SUMMARY>', () => {
  /**
   * @suite <FEATURE_NAME> | <CATEGORY>
   * @description <FEATURE_PURPOSE>
   * @testType <unit|functional|integration|e2e>
   * Scenarios: <SCENARIO_1>, <SCENARIO_2>, <SCENARIO_3>
   */

  beforeAll(() => {
    // 共通セットアップ: 環境初期化
  });

  afterAll(() => {
    // 共通ティアダウン: リソース解放
  });

  // サブシナリオをここに追加
});
```

- 機能説明コメント: `@suite` と `@description` に集約し、コメント冒頭の `@( # )` 表記と合わせて三段構えでメタ情報を提示

- 共通設定: 共通セットアップとティアダウンはプレースホルダーで明示し、変数置換 (`<FEATURE_NAME>`, `<CATEGORY>`, `<FEATURE_PURPOSE>`) により再利用可能

### Scenario レベルテンプレート

```typescript
/**
 * @context Given
 * @scenario <SCENARIO_NAME>
 * @description <SCENARIO_PURPOSE>
 */
describe('When: <ACTION_SUMMARY>', () => {
  const baseContext = createBaseContext();

  beforeEach(() => {
    context = {
      ...baseContext,
      // 前提条件の継承/上書き
    };
    prepareTestData(context);
  });

  afterEach(cleanupTestData);

  // テストケースをここに追加
});
```

- 前提条件の継承: `baseContext` で表現し、シナリオ固有の上書きを `beforeEach` で実装

- テストデータ管理: テストデータ準備とクリーンアップのテンプレート関数を用意し、共通の生成ロジックを共有

### Case レベルテンプレート

```typescript
it('Then: [正常] - <EXPECTED_BEHAVIOR>', () => {
  // arrange
  const input = buildInput({/* 単一責務 */});

  // act
  const result = actOnSubject(input);

  // assert
  expect(result).toStrictEqual(expectedOutput);
});
```

- 単一責務の徹底: arrange/act/assert の三段構成を強制

- 可読性確保: Given/When/Then の記述は `it` 名への埋め込みとコメントで二重化し、可読性を確保

### ネスト規則とアンチパターン

- `describe` ネストは最大三階層 (`Feature` → `Scenario` → `Case`)
- 追加の文脈が必要な場合は `describe.each` やヘルパー関数で表現し、四階層以上のネストを禁止する
- 階層間の責務を混在させないこと (例: Feature レベルで具象的アサーションを行うのはアンチパターン)
- 可読性維持のため、各 describe ブロックの末尾に閉じコメント (`// end Given` など) を追加してもよいが、冗長にならないよう配慮する

### 命名規則ガイドライン

- Feature レベル: `Given: <条件と目的>` を簡潔に記述
- Scenario レベル: `When: <単一操作>` を命令形ではなく動作説明で表現
- Case レベル: `Then: [タグ] - <期待結果>` を定量的に記述
- ヘルパー関数: `build<対象>`, `prepare<対象>`, `assert<対象>` など、処理の役割が一目でわかる名前を付ける
- 命名チェックはレビュー時に `mcp__serena-mcp__search_for_pattern` を使い、違反を機械的に検出する

## Given/When/Then 分類実装ガイド

### Given 実装パターン

- 状態設定パターン: `setupState()` ヘルパーで初期状態を構築
- データ準備パターン: `createFixture()` または `factory.build()` を使用
- 環境設定パターン: `mockEnv()` で環境変数や設定を上書き
- 条件独立性: Given 同士が依存しないようにし、依存が必要な場合は補助関数にまとめて副作用を隔離する

### When 実装パターン

- 単一動作パターン: `const result = subject(actionInput);` のように一件のみ呼び出し
- API 呼び出しパターン: `await apiClient.request(params);` をラップし、レスポンス/エラーハンドリングを記録
- 状態変更パターン: `mutateState(context);` などで、変更対象を明示
- 副作用制御: モックやスパイを活用し、`expect(spy).toHaveBeenCalledTimes(1);` で制御する

### Then 実装パターン

- 結果検証: `expect(result).toStrictEqual(expected);`
- 状態検証: `expect(store.state).toMatchObject({...});`
- 副作用検証: `expect(logger.warn).toHaveBeenCalledWith(message);`
- 包括的検証: `expect(obj).toMatchSnapshot();` や `expect.objectContaining({...});` を併用して複数の側面を検証する

### 分類基準と誤用対策

Given/When/Then の分類は、責務と時系列の観点から判定します。責務として、Given は「環境設定」、When は「操作実行」、Then は「結果検証」に限定します。
時系列として、Given の後に When、When の後に Then の順序を維持し、逆行は許可しません。
境界線判定では、操作性のあるものは When、確認性のあるものは Then として扱います。

誤分類防止チェック項目として、以下を確認します。

- Given 内で検証 (`expect`) が含まれていないか
- When 内で複数の操作が実行されていないか
- Then 内で新しいデータ作成や状態変更がないか
- 各ブロックが単一の責務に集中しているか

### よくあるアンチパターン

- アンチパターン 1: `Given` での検証混在

  ```typescript
  // 悪い例: Given で検証を行っている
  it('should handle invalid input', () => {
    const input = createInvalidInput();
    expect(input).toBeDefined(); // Given で検証するのは不適切

    const result = processInput(input);
    expect(result).toBeNull();
  });
  ```

- 正しいパターン: `Given` は準備のみ

  ```typescript
  // 良い例: Given は準備のみ、Then で検証
  it('should handle invalid input', () => {
    // arrange (Given相当)
    const input = createInvalidInput();

    // act (When相当)
    const result = processInput(input);

    // assert (Then相当)
    expect(result).toBeNull();
    expect(input).toBeDefined(); // 必要であればここで検証
  });
  ```

- アンチパターン 2: `When` での複数操作

  ```typescript
  // 悪い例: When で複数の操作を実行
  it('should process data pipeline', () => {
    const data = createData();

    const validated = validateData(data); // 操作1
    const transformed = transformData(validated); // 操作2
    const saved = saveData(transformed); // 操作3

    expect(saved).toBe(true);
  });
  ```

- 正しいパターン: `When` は単一操作

  ```typescript
  // 良い例: パイプライン全体を単一の操作として扱う
  it('should process data pipeline', () => {
    // arrange
    const data = createData();

    // act (単一の高レベル操作)
    const result = processDataPipeline(data);

    // assert
    expect(result.success).toBe(true);
    expect(result.data).toMatchObject(expectedData);
  });
  ```

- アンチパターン 3: `Then` での状態変更

  ```typescript
  // 悪い例: Then で状態を変更している
  it('should update counter', () => {
    const counter = new Counter(0);

    counter.increment();

    expect(counter.value).toBe(1);
    counter.reset(); // Then で状態変更するのは不適切
  });
  ```

- 正しいパターン: `Then` は検証のみ

  ```typescript
  // 良い例: Then は検証のみ、状態変更は afterEach で
  it('should update counter', () => {
    // arrange
    const counter = new Counter(0);

    // act
    counter.increment();

    // assert
    expect(counter.value).toBe(1);
  });

  afterEach(() => {
    // クリーンアップは適切な場所で
    counter?.reset();
  });
  ```

## 実行チェックリスト

### 品質確認項目

### コード構造チェック項目

- [ ] `BDD` 階層遵守: `Feature`/`Scenario`/`Case` の三層構造が維持されているか
- [ ] ネスト深度制限: `describe` のネストが最大 3 階層に収まっているか
- [ ] 単一責務原則: 各 `it()` が 1つの振る舞いのみテストしているか
- [ ] 命名規則適合: `Given`/`When`/`Then` の命名パターンに従っているか
- [ ] 判定基準: 各項目について `pass`/`fail` の明確な基準があるか

### テスト品質チェック項目

- [ ] テスト独立性: 各テストが他のテストに依存せず実行可能か
- [ ] データ隔離: テストデータが他のテストに影響しないか
- [ ] モック適切性: 必要最小限のモックが適切に使用されているか
- [ ] アサーション妥当性: 期待結果が定量的かつ検証可能か
- [ ] エラーハンドリング: 異常ケースが適切にテストされているか

### `BDD` サイクルチェック項目

- [ ] `RED` 確認: テストが意図通り失敗することを確認したか
- [ ] `GREEN` 確認: 最小限の実装でテストが通過することを確認したか
- [ ] `REFACTOR` 完了: コード品質向上とテスト継続通過を確認したか
- [ ] 移行条件満足: 各フェーズ間の移行条件をクリアしているか
- [ ] 品質ゲート通過: 5 項目の品質チェックを完了しているか

### 完了基準と測定指標

### 機能実装完了基準

- [ ] 要件充足率: 要求仕様の 95% 以上が実装されている
- [ ] テストカバレッジ: ブランチカバレッジ 85% 以上を達成している
- [ ] 品質スコア: 静的解析ツールで A 評価以上を取得している
- [ ] パフォーマンス: 指定された性能要件を満たしている
- [ ] セキュリティ: 脆弱性スキャンで重大な問題が検出されない

### 品質基準達成基準

- [ ] 型安全性: `TypeScript` 厳格モードでエラーゼロを維持
- [ ] リンター通過: `ESLint` ・ `Prettier` 設定で warning 以下に抑制
- [ ] テスト成功率: 全自動テストが 100% 成功している
- [ ] ビルド成功: 本番ビルドが警告なしで完了している
- [ ] ドキュメント整合性: `API` 仕様書と実装が一致している

### プロジェクト統合基準

- [ ] 依存関係整合性: `package.json` の依存関係が最新かつ安全
- [ ] `CI/CD` 正常性: 自動化パイプラインが正常に動作している
- [ ] 環境一貫性: 開発・検証・本番環境での動作一致を確認
- [ ] バックワード互換性: 既存 `API` との互換性を維持している
- [ ] デプロイ可能性: プロダクション環境に問題なくデプロイ可能

### 測定可能な指標

| 指標分類 | 指標名           | 目標値   | 測定方法                     |
| -------- | ---------------- | -------- | ---------------------------- |
| 品質     | テストカバレッジ | 85%以上  | `pnpm run test:coverage`     |
| 品質     | 型エラー         | 0件      | `pnpm run check:types`       |
| 品質     | リンターエラー   | 0件      | `pnpm run lint:all`          |
| 性能     | ビルド時間       | 60秒以内 | `time pnpm run build`        |
| 性能     | テスト実行時間   | 30秒以内 | `time pnpm run test:develop` |

### 自動化と検証フロー

### 自動化可能項目

- [ ] 型チェック: `pnpm run check:types` での自動実行
- [ ] リンター: `pnpm run lint:all` での規約チェック
- [ ] テスト実行: `pnpm run test:develop` での品質確認
- [ ] フォーマット: `pnpm run check:dprint` でのコード整形確認
- [ ] ビルド検証: `pnpm run build` での統合確認

### 手動確認必須項目

- [ ] 要件適合性: 仕様書との照合による機能確認
- [ ] ユーザビリティ: 実際の使用を想定した操作確認
- [ ] エラーメッセージ: 利用者にとって理解しやすい表現かの確認
- [ ] パフォーマンス: 実環境での応答速度・メモリ使用量確認
- [ ] セキュリティ: 潜在的な脆弱性の手動検査

### 自動化実装方法

`lefthook` による `Git` フック設定:

```yaml
### lefthook.yml
pre-commit:
  parallel: true
  commands:
    type-check:
      run: pnpm run check:types
    lint:
      run: pnpm run lint:all
    test:
      run: pnpm run test:develop
    format:
      run: pnpm run check:dprint
    build:
      run: pnpm run build
```

`GitHub Actions` による継続的統合:

```yaml
name: Quality Gate
on: [push, pull_request]
jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "20"
      - name: Install dependencies
        run: pnpm install
      - name: Run quality checks
        run: |
          pnpm run check:types
          pnpm run lint:all
          pnpm run test:develop
          pnpm run check:dprint
          pnpm run build
```

#### 段階別チェックリストテンプレート

```markdown
## [フェーズ名] 実装チェックリスト

### 必須確認項目

- [ ] 要件定義との適合性確認
- [ ] Given/When/Then構造適用
- [ ] 単一責務原則遵守
- [ ] 命名規則準拠

### 技術品質項目

- [ ] 型チェック通過 (`pnpm run check:types`)
- [ ] リンター通過 (`pnpm run lint:all`)
- [ ] テスト通過 (`pnpm run test:develop`)
- [ ] フォーマット準拠 (`pnpm run check:dprint`)
- [ ] ビルド成功 (`pnpm run build`)

### TODO進捗管理項目 🔴 必須

- [ ] 作業開始前に TodoWrite ツールでタスクを `in_progress` に更新
- [ ] expect文完了ごとに temp/todo.md のチェックボックス更新 (`- [ ]` → `- [x]`)
- [ ] expect文完了ごとに TodoWrite ツールで `completed` に更新
- [ ] タスクグループ完了時に進捗レポート作成
- [ ] 変更を即座にコミット (進捗履歴の保持)

### 測定結果記録

- テストカバレッジ: ___%
- ビルド時間: ___秒
- テスト実行時間: ___秒
- 型エラー件数: ___件
- リンター警告: ___件
- 進捗状況: ***/27 タスク完了 (***%)

### 完了判定

- [ ] 全必須項目クリア
- [ ] 全技術品質項目クリア
- [ ] **全TODO進捗管理項目クリア** 🔴
- [ ] 測定指標が目標値達成
- [ ] 不合格項目の解決完了
```

### TODO作成者向け進捗チェック機能

🔴 重要: temp/todo.md を作成・管理する側の責務として、以下を厳格に実行する。

#### TODO進捗チェック実行テンプレート

```markdown
### 作業開始時チェック

- [ ] 全タスクの初期状態確認 (全て `- [ ]` になっている)
- [ ] TodoWriteツールの初期設定確認
- [ ] 依存関係マップの作成 (前提タスク → 実行タスクの関係図)

### 実行中チェック (1日3回実行推奨)

- [ ] 完了済みチェックボックス数の確認
- [ ] TodoWriteツールとの同期状況確認
- [ ] 未完了タスクの依存関係確認
- [ ] ブロッカーの有無確認

### タスクグループ完了時チェック

- [ ] 該当グループの全expect文が完了 (`- [x]` になっている)
- [ ] 品質ゲート5項目の実行・成功確認
- [ ] 次タスクグループの実行可能性確認
- [ ] 進捗レポートの作成・記録

### 最終完了時チェック

- [ ] 全タスクが完了 (`- [x]` になっている)
- [ ] 完了率100%の確認
- [ ] 最終品質ゲートの実行・成功
- [ ] 作業ログの完全性確認
```

### チェック結果記録方法

結果記録テンプレート:

```markdown
### 品質チェック実行結果

実行日時: YYYY-MM-DD HH:MM:SS
実行者: [エージェント名/開発者名]
対象フェーズ: [RED/GREEN/REFACTOR]
対象タスクグループ: [例: DOC-01-01-01]

### チェック結果サマリー

| 項目         | 結果 | 詳細          |
| ------------ | ---- | ------------- |
| 型チェック   | ☑/×  | エラー数: X件 |
| リンター     | ☑/×  | 警告数: X件   |
| テスト       | ☑/×  | 成功率: X%    |
| フォーマット | ☑/×  | 違反箇所: X件 |
| ビルド       | ☑/×  | 所要時間: Xms |

### 🔴 新規追加: TODO進捗記録

| 項目                         | 結果 | 詳細                   |
| ---------------------------- | ---- | ---------------------- |
| TodoWrite同期                | ☑/×  | 不整合件数: X件        |
| temp/todo.mdチェックボックス | ☑/×  | 更新済み: X/Y件        |
| 進捗コミット                 | ☑/×  | コミットハッシュ: [値] |
| 全体進捗率                   | X%   | 完了: X/27タスク       |
```

### 作業工程記録 🔴 新規追加

#### 作業工程詳細ログ

```markdown
### タスクグループ: [ID] - [概要]

- 開始時刻: YYYY-MM-DD HH:MM:SS
- 完了時刻: YYYY-MM-DD HH:MM:SS
- 所要時間: X分Y秒
- 実行したexpect文:
  - [ID]: [内容] - ☑/× (所要: X分)
  - [ID]: [内容] - ☑/× (所要: X分)
  - [ID]: [内容] - ☑/× (所要: X分)

### 発生した課題・ブロッカー

- [課題1]: [詳細] - [解決策/対応状況]
- [課題2]: [詳細] - [解決策/対応状況]

### 品質ゲート実行履歴

- 実行1: [時刻] - [結果] - [詳細]
- 実行2: [時刻] - [結果] - [詳細]

### 学習・改善点

- [学習した内容・改善アイデア]

### 次タスクグループへの引き継ぎ事項

- [必要な準備・注意点]

### 不合格項目詳細

[不合格項目がある場合の詳細記録]。

### 次回アクション

[改善が必要な項目の対応方針]。
```

### 🔴 新規追加: 作業工程記録の自動化と管理

#### 作業工程記録管理システム

### 記録タイミング

- タスク開始時: 開始時刻・対象範囲の記録
- expect 文完了時: 個別の所要時間・結果記録
- ブロッカー発生時: 課題内容・対応記録
- タスクグループ完了時: 総所要時間・学習点記録

### 記録形式の統一

- 時刻表記: `YYYY-MM-DD HH:MM:SS` 形式で統一
- 所要時間: `X分Y秒` 形式で統一
- 結果表記: `☑` (成功) / `×` (失敗) / `#⃣` (中断) で統一
- 進捗表記: `X/Y件 (Z%)` 形式で統一

### 記録保存場所

- 主要記録: temp/todo.md 内の該当タスクセクション
- 詳細ログ: 記録が長大な場合などに応じて別ファイル作成
- コミット履歴: Git コミットメッセージに進捗情報含める

### 記録の活用方法

- 進捗予測: 過去の所要時間から残り作業量を推定
- ボトルネック特定: 時間のかかるタスクタイプの特定
- 品質改善: エラー発生パターンの分析
- プロセス最適化: できるだけ効率のよい作業順序の発見

### 不合格時の対処手順

1. 問題の特定: エラーメッセージ・ログから根本原因を特定
2. 影響範囲の評価: 他の機能・テストへの影響を調査
3. 修正方針の決定: 最小限の修正で解決可能かを判断
4. 修正実装: Red-Green-Refactor サイクルに従って修正
5. 再検証: 修正後に品質チェックを再実行
6. 記録の更新: 修正内容と結果をドキュメントに記録

緊急時のエスカレーション:

- 修正に 2 時間以上要する場合は上位タスクに報告
- セキュリティ問題が発見された場合は即座に報告
- 依存関係の問題で解決困難な場合は技術責任者に相談

---

### ドキュメント運用注意事項

このドキュメントは、エージェントが迷わず atsushifx 式 BDD を実践できることを目的としています。実装時は必ず以下の順序を守ってください。

### 基本実行順序 (変更なし)

1. ToDo リスト確認: 現在のタスクと期待結果を明確化
2. Red-Green-Refactor 開始: 必ず RED から開始し、各フェーズの完了を確認
3. 品質ゲート実行: 5 項目のチェックを経て次のタスクへ進行
4. TodoWrite 更新: 完了したタスクの状態を適切に更新

### 🔴 必須追加: タスクグループ完了時の進捗更新プロトコル

**タスクグループ (When単位) 完了時に以下を必ず実行する**。

```markdown
## タスクグループ完了チェックリスト

### 即座実行項目 (5分以内)

- [ ] 該当するexpect文全てのtemp/todo.mdチェックボックス更新確認
- [ ] TodoWriteツールでの完了状態同期確認
- [ ] 進捗コミットの実行 (メッセージ: "feat: complete [タスクグループID] - [概要]")

### 品質確認項目 (10分以内)

- [ ] 品質ゲート5項目の実行
  - [ ] `pnpm run check:types`
  - [ ] `pnpm run lint:all`
  - [ ] `pnpm run test:develop`
  - [ ] `pnpm run check:dprint`
  - [ ] `pnpm run build`

### 進捗報告項目 (5分以内)

- [ ] 進捗レポートの作成・記録
  - 完了タスク数: ***/27 (***%)
  - 所要時間: ___分
  - 次タスクグループ: [ID]
  - 発見した課題: [あれば記録]

### 次工程準備項目 (2分以内)

- [ ] 次タスクグループの実行可能性確認
- [ ] 依存関係の解決状況確認
- [ ] ブロッカーの有無確認
```

### 🔴 必須追加: 区切りよいいタイミングでの進捗更新

以下のタイミングで必ず進捗更新を実行する。

1. **タスクグループ完了時** (上記プロトコル実行)
2. **メインフェーズ完了時** (例: DOC-01 全体完了)
3. **作業中断時** (例: 2時間以上の休憩前)
4. **エラー発生時** (例: 品質ゲート不合格)
5. **依存関係ブロック発生時**

### 異常時対応プロトコル

```markdown
## 異常検出時の対応手順

### 進捗同期エラー検出時

1. TodoWriteツールとtemp/todo.mdの差分確認
2. 最新の正確な状態への復旧
3. 不整合原因の記録
4. 再発防止策の適用

### 品質ゲート不合格時

1. 該当タスクを `in_progress` に戻す
2. temp/todo.mdのチェックボックスを `- [ ]` に戻す
3. エラー内容と対応方針を記録
4. 修正完了後に再度完了プロセス実行

### ブロッカー発生時

1. ブロッカー内容の詳細記録
2. 調査タスクの新規作成
3. 依存関係の再評価
4. 代替実行可能タスクの特定
```

エージェント実行の成功基準として、このドキュメントの指示に従うことで 95%以上の確率で期待される実装が完了できることを目指しています。
不明な点があれば、該当セクションを再確認し、例示されたテンプレートを活用してください。

---

### See Also

- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD 開発フロー概要
- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCP ツール完全活用ガイド
- [08-quality-assurance.md](08-quality-assurance.md) - AI 用品質ゲート・自動チェック

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
