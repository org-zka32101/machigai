# 🚀 Phase 5: Backend Integration & Polish — Implementation Plan

**Target**: Connect Firebase Firestore, integrate petit_ai scoring, add Lottie animations, implement testing

**Duration**: 4-5 sessions | **Complexity**: High (data layer + AI + animations)

---

## 📊 Phase 5 Overview

| Component | Status | Priority | Complexity |
|-----------|--------|----------|-----------|
| **Firebase Firestore Integration** | 🔄 Next | P0 | High |
| **petit_ai AI Scoring** | 📋 Planned | P1 | High |
| **Lottie Animations** | 📋 Planned | P2 | Medium |
| **Testing Suite** | 📋 Planned | P3 | Medium |
| **Performance Optimization** | 📋 Planned | P3 | Low |

---

## 🔥 1. Firebase Firestore Integration

### 1.1 Challenge Data Flow (Read/Write)

**Current State**: Services exist but use mock data
**Target**: Real Firestore collections

#### Collections Schema

```dart
// challenges/
{
  id: string,
  templateId: string,
  creatorId: string,
  editedParams: {
    brightness: double,
    colorHue: double,
    positionX: double,
    positionY: double,
    cropX: double,
    cropY: double,
    cropWidth: double,
    cropHeight: double,
  },
  correctRegionIndex: int,
  difficulty: string,      // "easy" | "medium" | "hard"
  aiScore: double,         // 0.0-1.0 (quality score)
  shareToken: string,
  videoUrl: string,        // Firebase Storage URL
  createdAt: timestamp,
  publishedAt: timestamp,
  isPublished: boolean,
  moderated: boolean,
  rejectionReason: string? // null if accepted
}

// challenge_attempts/
{
  id: string,
  challengeId: string,
  userId: string,
  selectedRegionIndex: int,
  isCorrect: boolean,
  solveTimeSeconds: int,
  score: int,
  bonusMultiplier: double,
  timestamp: timestamp,
}

// users/
{
  uid: string,
  displayName: string,
  avatar: string,
  totalScore: int,
  level: int,
  currentStreak: int,
  longestStreak: int,
  challengesCreated: int,
  challengesSolved: int,
  createdAt: timestamp,
  updatedAt: timestamp,
}

// rankings/
{
  period: string,           // "daily" | "weekly" | "all-time"
  date: string,             // YYYY-MM-DD for daily/weekly
  userId: string,
  score: int,
  rank: int,
  scoreChange: int,         // score delta from previous period
}
```

#### Implementation Steps

**Step 1: Update ChallengeService**
- [ ] Implement `saveChallengeToFirestore()`
- [ ] Implement `getChallengeById()`
- [ ] Implement `getChallengeByShareToken()`
- [ ] Implement `getUserChallenges(userId)`
- [ ] Implement `publishChallenge()` (mark published)
- [ ] Add error handling + retry logic

**Step 2: Update ChallengeAttemptService**
- [ ] Implement `recordAttempt()`
- [ ] Implement `getUserAttempts(userId)`
- [ ] Implement `getAttemptsByChallenge(challengeId)`
- [ ] Calculate score + bonus based on difficulty

**Step 3: Update UserService (Create if missing)**
- [ ] Implement `getUserProfile(userId)`
- [ ] Implement `updateUserProfile()`
- [ ] Implement `incrementChallengesCreated()`
- [ ] Implement `incrementChallengesSolved()`
- [ ] Implement `updateStreak()`

#### Files to Modify

```
lib/services/
├── challenge_service.dart          (Firestore reads/writes)
├── challenge_attempt_service.dart  (Record attempts)
├── user_service.dart               (NEW - User profiles)
├── ranking_service.dart            (Query rankings)
└── index.dart                       (Export UserService)
```

---

### 1.2 Ranking System

**Current State**: Mock ranking data
**Target**: Real-time leaderboard from Firestore

#### Implementation

**Step 1: Create RankingProvider (Riverpod)**
```dart
// lib/viewmodels/ranking_provider.dart
final dailyRankingProvider = FutureProvider<List<RankingData>>(...);
final weeklyRankingProvider = FutureProvider<List<RankingData>>(...);
final allTimeRankingProvider = FutureProvider<List<RankingData>>(...);
final userRankProvider = FutureProvider<RankingData?>(...);
```

**Step 2: Update RankingScreen**
- [ ] Replace mock data with real providers
- [ ] Implement loading states
- [ ] Add error handling + retry

---

## 🤖 2. petit_ai Integration

### 2.1 AI Scoring Setup

**Current State**: AIGenerationService exists but unused
**Target**: Score challenges during creation

#### Implementation Steps

**Step 1: Integrate petit_ai Model**
- [ ] Initialize petit_ai model in AIGenerationService
- [ ] Load model asynchronously in app startup
- [ ] Add loading indicator during initialization

**Step 2: Challenge Validation**
- [ ] Analyze edited video for problem quality
- [ ] Score: clarity, difficulty, fairness (0.0-1.0)
- [ ] Flag low-quality challenges
- [ ] Store aiScore in Firestore

**Step 3: Difficulty Calculation**
- [ ] Use AI analysis to set auto-difficulty
- [ ] Allow manual override
- [ ] Store in editState

#### Files to Modify

```
lib/services/
├── ai_generation_service.dart  (Model initialization + scoring)
└── challenge_service.dart      (Apply aiScore before save)

lib/viewmodels/
└── video_edit_provider.dart    (Show AI scoring UI during edit)
```

---

## 🎨 3. Lottie Animations

### 3.1 Animation Targets

| Screen | Animation | Trigger | Effect |
|--------|-----------|---------|--------|
| ResultScreen | Confetti | Success | Celebrate win |
| ResultScreen | Shake | Failure | React to loss |
| HomeScreen | Slide | Navigation | Smooth transitions |
| RankingScreen | Pulse | Rank update | Emphasize movement |
| ProfileScreen | Pop | Achievement unlock | Celebrate milestone |
| EditScreen | Loading | AI scoring | Show progress |

### 3.2 Asset Preparation

**Action**: Add Lottie JSON files to `assets/animations/`

```bash
assets/animations/
├── confetti.json       # Success celebration
├── shake.json          # Failure reaction
├── loading_ai.json     # AI processing
├── slide_up.json       # Page transition
└── pulse_rank.json     # Rank change
```

**Source**: LottieFiles.com (free tier) or Animate CC

### 3.3 Implementation

**Files to Modify**:
```
lib/views/
├── result.dart        (Add confetti + shake)
├── ranking.dart       (Add pulse on rank update)
└── profile.dart       (Add pop on achievement)

lib/widgets/
└── lottie_animation.dart  (NEW - Reusable wrapper)
```

---

## 🧪 4. Testing Suite

### 4.1 Unit Tests

**Target Coverage**: 70%+ of business logic

```
test/
├── services/
│   ├── challenge_service_test.dart
│   ├── challenge_attempt_service_test.dart
│   ├── user_service_test.dart
│   ├── ranking_service_test.dart
│   └── ai_generation_service_test.dart
├── models/
│   ├── user_test.dart
│   ├── challenge_test.dart
│   └── ranking_test.dart
└── viewmodels/
    ├── challenge_provider_test.dart
    ├── video_template_provider_test.dart
    └── ranking_provider_test.dart
```

**Focus Areas**:
- Score calculation logic
- Difficulty determination
- Data model serialization
- Error handling

### 4.2 Widget Tests

**Target Coverage**: Key screens (Create, Solve, Ranking)

```
test/widgets/
├── home_screen_test.dart
├── edit_screen_test.dart
├── solve_screen_test.dart
└── ranking_screen_test.dart
```

### 4.3 Integration Tests

**Target**: Full user flows (create → solve → rank)

```
integration_test/
├── create_challenge_test.dart
├── solve_challenge_test.dart
└── full_game_flow_test.dart
```

---

## 📋 Implementation Checklist

### Session 1: Firestore Integration (Today)
- [ ] Design & document collection schemas ✅
- [ ] Update ChallengeService (Firestore reads)
- [ ] Update ChallengeService (Firestore writes)
- [ ] Update ChallengeAttemptService
- [ ] Commit + PR

### Session 2: User & Ranking
- [ ] Create UserService
- [ ] Update RankingService (Firestore queries)
- [ ] Create RankingProvider (Riverpod)
- [ ] Update RankingScreen with real data
- [ ] Commit + PR

### Session 3: petit_ai Integration
- [ ] Initialize petit_ai in AIGenerationService
- [ ] Implement challenge scoring
- [ ] Difficulty auto-calculation
- [ ] Update EditScreen UI (show AI score)
- [ ] Commit + PR

### Session 4: Lottie Animations
- [ ] Download animation JSON files
- [ ] Implement in ResultScreen
- [ ] Implement in RankingScreen
- [ ] Implement in ProfileScreen
- [ ] Commit + PR

### Session 5: Testing
- [ ] Unit tests for services (40+ tests)
- [ ] Widget tests for screens (20+ tests)
- [ ] Integration test flow
- [ ] CI/CD setup
- [ ] Final polish + merge

---

## 🎯 Success Criteria

✅ Real Firestore data flowing through all screens  
✅ AI scoring working during challenge creation  
✅ Animations enhancing UX without jank  
✅ 70%+ test coverage for critical paths  
✅ All flows tested end-to-end  
✅ Zero compile errors + type safety  

---

## 🚨 Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Firestore quota limits | Implement request batching + caching |
| Network latency | Add loading states + offline fallback |
| petit_ai model size | Lazy load model, cache in memory |
| Animation performance | Profile on actual devices, optimize |
| Test flakiness | Mock Firebase, use TestWidgets properly |

---

**Phase 5 Status**: 📋 Ready to Begin  
**Next Action**: Implement Firestore Integration (Session 1)
