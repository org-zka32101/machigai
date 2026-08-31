# まちがいラボ（Machigai）

動く間違い探し × UGC対戦型アプリ。テンプレート動画から1箇所編集して友達に出題する、新しい間違い探しゲーム。

## 🎯 Vision

楽しくゲーム感覚で脳トレできる、全年代向け（7歳〜）の間違い探し。「作る楽しさ」× 「許された悪意（ひっかける快感）」で、既存の静止画型間違い探しのレッドオーシャンを回避。

## 📋 プロジェクト概要

- **アプリ名**: まちがいラボ（内部コード: machigai）
- **プラットフォーム**: Flutter/Dart (iOS/Android/Web)
- **技術スタック**: 
  - Flutter/Dart 3.x
  - Riverpod（状態管理）
  - Firebase（Firestore/Auth/Storage/Analytics/Crashlytics/Remote Config/Cloud Functions）
  - RevenueCat（課金管理）
  - Lottie（アニメーション）
- **アーキテクチャ**: MVVM
- **マネタイズ**: フリーミアム（2週間無料 → ¥200/月）

## 🏗️ ディレクトリ構成

```
lib/
├── models/              # データモデル ✅
│   ├── user_generated_challenge.dart
│   ├── challenge_attempt.dart
│   ├── user.dart
│   ├── daily_streak.dart
│   ├── ranking.dart
│   └── moderation_config.dart
├── services/            # ビジネスロジック層 ✅
│   ├── moderation_service.dart                # UGCモデレーション（★必須）
│   ├── challenge_service.dart                 # チャレンジ管理
│   ├── challenge_attempt_service.dart         # 解答記録
│   ├── ai_generation_service.dart             # AI診断
│   ├── ranking_service.dart                   # ランキング計算
│   ├── analytics_service.dart                 # 計測（Analytics/Crashlytics）
│   ├── initial_problem_pool_service.dart      # 初期問題プール（Must7）
│   ├── video_template_service.dart            # ビデオテンプレ管理
│   └── index.dart
├── viewmodels/          # Riverpod Provider群 ✅
│   ├── challenge_provider.dart                # チャレンジ状態管理
│   ├── video_template_provider.dart           # ビデオ編集状態管理
│   └── index.dart
├── views/               # UI画面 ✅ 部分実装
│   ├── home.dart                              # ホーム画面（ナビゲーションハブ）
│   ├── template_select.dart                   # テンプレート選択画面
│   ├── edit.dart                              # ビデオ編集画面（4種類の編集ツール）
│   ├── challenge_published.dart               # 問題出題確認＆シェア画面
│   └── index.dart
├── widgets/             # カスタムウィジェット（未実装）
├── config/              # 設定ファイル
│   └── firebase_options.dart
└── main.dart            # GoRouter設定 ✅
```

## 🚨 Critical Must-Features

### 1. **UGCモデレーション** ⭐ Must実装
- NGワード検知（実装済）
- 簡易審査フロー（実装中）
- リリース時点では**外せない**（批判的レビューで必須化）

### 2. **初期問題プール** ⭐ Must7（コールドスタート対策）
- ✅ 50-100件の事前生成問題（InitialProblemPoolService実装済）
- ✅ AI検診スクリプト（seed_initial_problems.dart完備）
- ✅ Firestore一括投入パイプライン
- ✅ リリース初速でUGCが0でも解答体験可能

### 3. **動画編集 + AI検診** ⭐ 技術検証優先
- ✅ テンプレート動画から1箇所編集（VideoTemplateService実装済）
- ✅ 4種類の編集タイプ実装（明るさ/色/配置/クロップ）
- ✅ AI診断で問題成立度を判定
- ✅ ViewModel層統合（VideoEditNotifier）

## 📊 実装優先順序

| # | 項目 | Status | Notes |
|---|---|---|---|
| 1 | petit_core/petit_ui/petit_ai導入 | ✅ Path設定済 | pubspec.yaml参照 |
| 2 | データモデル | ✅ 実装済 | 5モデル + ModerationConfig |
| 3 | Service層 | ✅ 8サービス実装 | 初期問題プール+動画編集追加 |
| 4 | **初期問題プール投入パイプライン** | ✅ **実装済** | Must7対応・seed script完備 |
| 5 | 計測3点セット | ✅ 実装済 | Analytics/Crashlytics/Remote Config |
| 6 | ViewModel(Riverpod) | ✅ **実装済** | ChallengeProvider, VideoTemplateProvider |
| 7 | **動画編集ツール + AI検診** | ✅ **実装済** | VideoTemplateService + Edit types |
| 8 | **Aha Moment最短動線（Core）** | ✅ **実装済** | Home→Select→Edit→Publish完成 |
| 9 | **各画面View（Phase 3）** | ✅ **部分実装** | Home ✅, TemplateSelect ✅, Edit ✅, ChallengePublished ✅ |
| 10 | SolveScreen + ResultScreen | ⏳ 進行中 | 解答フロー実装予定 |
| 11 | Ranking + Profile画面 | ⏳ 予定 | ユーザー統計表示 |
| 12 | アニメ・エフェクト・サウンド | ⏳ 予定 | Lottie/ハプティクス |
| 13 | **UGCモデレーション実装** | 🟡 部分実装 | NGワード✅ + 簡易審査フロー⏳ |
| 14 | Firebase統合（Firestore保存） | ⏳ 予定 | Backend接続 |
| 15 | petit_ai統合 | ⏳ 予定 | AI診断スコアリング |
| 16 | オンボ + ペイウォール | ⏳ 予定 | Remote Config連携 |
| 17 | テスト | ⏳ 予定 | unit/widget/integration |

## 🎮 Aha Moment定義

初回ユーザーが以下を3分以内に体験：
1. **自分で作成** → テンプレート選択 → 1箇所編集 → 友達に出題
2. **解答体験** → 既存UGC問題を3問解く（全て正解）
3. **リアクション** → 友達の失敗リアクションを観戦 OR スコア＆ランキング表示

**KPI**: Aha到達率 60%+（ソフトローンチゲート）

## 📈 計測設計（KPI 5個）

| KPI | 定義 | ゲート |
|---|---|---|
| aha_moment_reached | 出題後3分以内 OR 解答3問正解 | 60%+ |
| daily_challenge_completed | チャレンジ完了数 | 日次追跡 |
| streak_day_n | Day7/14/30リテンション | 20%+ (Day7) |
| paywall_shown | ペイウォール表示 | 計測 |
| subscription_started | 購読開始 | LTV検証 |

**計測方式**: Firebase Analytics + Crashlytics + Remote Config

## 🔐 セキュリティ・パフォーマンス

- タイムアウト: 10秒
- リトライ: 3回
- オフラインキャッシュ: 有効
- **UGCモデレーション**: NGワード + 簡易審査フロー（必須）
- APIキー: 環境変数管理
- 通信: HTTPS必須

## 🎨 UI/UX品質

- 正解: Lottie紙吹雪 + 教科カラー
- 不正解: シェイク + SE
- コンボ: ×2×3表示
- レベルアップ: 全画面ゴール演出
- フォント: 丸ゴシック 18sp+
- ボタン: 44pt+ + バウンス + ハプティクス
- ダークモード: 必須
- コントラスト: WCAG AA

## 📦 Dependencies（pubspec.yaml）

```yaml
# State Management
flutter_riverpod: ^2.4.0
riverpod_annotation: ^2.1.0

# Firebase
firebase_core: ^2.28.0
cloud_firestore: ^4.15.0
firebase_auth: ^4.17.0
firebase_analytics: ^10.9.0
firebase_storage: ^11.7.0
firebase_crashlytics: ^3.5.0
firebase_remote_config: ^4.4.0
cloud_functions: ^4.7.0

# Monetization
purchases_flutter: ^7.0.0

# Animation
lottie: ^2.6.0

# Shared Packages
petit_core: path: ../packages/petit_core
petit_ui: path: ../packages/petit_ui
petit_ai: path: ../packages/petit_ai
```

## ⚠️ 実装時の注意点

### 必須
- [ ] UGCモデレーション（リリース必須・外せない）
- [ ] 初期問題プール 50-100件（コールドスタート対策）
- [ ] 動画編集ツール技術検証（最優先）
- [ ] Aha Moment到達率計測

### 推奨
- [ ] petit_core/petit_ui再実装禁止
- [ ] min_supported_version設定
- [ ] 通知プレプロンプト実装
- [ ] 画像認識モデレーション検討（実装時に判断）

## 🧪 テスト戦略

```
unit test     → ロジック・provider
widget test   → Must画面
integration   → 課金動線＋UGC作成→出題→解答
```

## 🚀 リリース戦略

1. **ソフトローンチ** (TestFlight外部テスト)
   - Aha到達率 60%+
   - クラッシュフリー率 99.5%+
   - UGCモデレーション実効性検証

2. **審査対策**
   - UGCモデレーション機能明記必須（Apple/Google共に要確認）

3. **LiveOps**
   - 季節テーマの動画テンプレ追加パック
   - Remote Config発火

## 📝 批判的レビュー結果

**判定**: ⭐ 3.5/5 → Must7追加・UGCモデレーション必須化を条件に実装ゴー

- ✅ 致命的リスク①コールドスタート問題 → Must7（初期問題プール）で対応
- ✅ 致命的リスク②モデレーション実装コスト過小評価 → NGワード+簡易審査を必須化
- ⚠️ ㉙7日プロト可否「△」のまま実装 → 動画編集+AI検診を最優先検証

## 🔗 References

- 設計資料: `machigai_sagashi_code_handoff_v1_0.md`
- 親プロジェクト: `yourwish`（モノレポ）

---

**開発ステージ**: 🎬 Phase 3: View Layer Implementation (Aha Moment最短動線完成)

**Phase 1-3 Summary**:
- ✅ Phase 1: Models + Services (1,572 lines)
- ✅ Phase 2: Must7 + Video Editing (1,053 lines)
- ✅ Phase 3: Aha Moment View Flow (2,000+ lines)

**Current**: 4 screens完成（Home → TemplateSelect → Edit → ChallengePublished）

**Next Steps**:
1. SolveScreen + ResultScreen 実装（解答フロー）
2. Ranking + Profile 画面実装
3. petit_ai 統合（AIスコアリング）
4. Firebase Firestore 接続（問題保存）
