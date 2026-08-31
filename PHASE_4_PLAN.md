# 🎮 Phase 4: Solve & Stats Screens + Backend Integration

**Date**: 2026-08-31  
**Status**: Planning & Initialization  
**Branch**: `claude/phase-4-dev-172657`  
**Previous**: Phase 3 ✅ Merged to main  

---

## 🎯 Phase 4 Objectives

Complete the remaining user-facing screens and integrate with Firebase backend:

### Primary Goals
1. **Solve Flow** - Allow users to answer challenges created by others
2. **Result Flow** - Show success/failure with animations
3. **Stats Screens** - Display rankings and user profile
4. **Backend Ready** - Connect all views to Firebase Firestore

### Screens to Implement (4 core + optional)

| Screen | Priority | Lines | Status | Notes |
|--------|----------|-------|--------|-------|
| SolveScreen | ⭐⭐⭐ | 400-500 | ⏳ | Challenge playback + answer selection |
| ResultScreen | ⭐⭐⭐ | 300-400 | ⏳ | Success/failure feedback + animations |
| RankingScreen | ⭐⭐ | 250-350 | ⏳ | Daily/Weekly/AllTime leaderboards |
| ProfileScreen | ⭐⭐ | 200-300 | ⏳ | User stats + streak display |
| **Subtotal** | | **1,150-1,550** | | **Core screens** |
| SolveEntryScreen (optional) | ⭐ | 200-300 | ⏳ | Search/browse challenges |
| OnboardingScreen (optional) | ⭐ | 200-300 | ⏳ | First-time user tutorial |

---

## 📋 SolveScreen Implementation

**Purpose**: Display a challenge and allow user to select the edited region

### UI Components
```
Top Bar
├── Back button
├── Difficulty badge
└── Timer (optional)

Video Preview Area (Main)
├── Video display with edit indicator
├── Current edit highlight/overlay
└── Touch targets for regions to click

Hint Area
├── "間違い探しをしてね" (Find the mistake)
├── Region count indicator
└── Skip button (optional)

Answer Buttons
├── Region selector buttons
├── Submit button (disabled until selection)
└── Cancel button
```

### Key Features
- ✅ Fetch challenge from ChallengeService
- ✅ Display video with editable regions
- ✅ Highlight clickable areas
- ✅ Track selection state
- ✅ Submit answer to ChallengeAttemptService
- ✅ Navigate to ResultScreen with result data

### State Management
```dart
class SolveState {
  final UserGeneratedChallenge challenge;
  final int? selectedRegionIndex;
  final bool isSubmitting;
  final String? error;
}

// Via SolveNotifier
- selectRegion(index)
- submitAnswer()
- skipChallenge()
```

---

## 🎊 ResultScreen Implementation

**Purpose**: Celebrate success or encourage retry after failure

### UI Components (Success Path)
```
Success Indicator
├── Lottie confetti animation
├── "正解！" (Correct!) headline
└── Score display with star rating

Challenge Stats
├── Solve time
├── Difficulty completed
├── Friend's reaction (TBD)
└── Points earned

Action Buttons
├── Share result
├── Next challenge
└── Back to home
```

### UI Components (Failure Path)
```
Failure Indicator
├── Shake animation
├── "不正解です" (Incorrect) headline
└── Correct region highlight

Retry Options
├── Show correct answer
├── Try again button
├── Skip to next
└── Back to home
```

### Key Features
- ✅ Lottie animations (success/failure)
- ✅ Sound effects integration
- ✅ Haptic feedback
- ✅ Score calculation
- ✅ Analytics event tracking
- ✅ Difficulty badge display

### Animations
| Trigger | Animation | Library |
|---------|-----------|---------|
| Success | Confetti + star burst | Lottie |
| Failure | Shake + pulse | Built-in |
| Combo ×2/×3 | Combo badge | Lottie |

---

## 🏆 RankingScreen Implementation

**Purpose**: Show user rankings and leaderboards

### UI Components
```
Tab Bar
├── Daily (24h ranking)
├── Weekly (7d ranking)
└── All Time (lifetime ranking)

User's Rank Card
├── User avatar
├── Current rank position
├── Points/Score display
└── Change indicator (↑↓)

Leaderboard List
├── Rank # (1-100)
├── User name + avatar
├── Score/Points
├── Trend indicator
└── Friend indicator (⭐)

Pagination
├── Top 100 display
└── Load more button (optional)
```

### Key Features
- ✅ Fetch rankings from RankingService
- ✅ Display user's own rank highlighted
- ✅ Show friend rankings with indicator
- ✅ Rank change visualization (↑↓)
- ✅ Tab switching (Daily/Weekly/AllTime)
- ✅ Real-time updates via listener

### Data Integration
```dart
final dailyRankingProvider = FutureProvider<List<Ranking>>((ref) async {
  return ref.watch(rankingServiceProvider).getDailyRanking();
});

final userRankProvider = FutureProvider<int?>((ref) async {
  return ref.watch(rankingServiceProvider).getUserDailyRank();
});
```

---

## 👤 ProfileScreen Implementation

**Purpose**: Display user stats and achievements

### UI Components
```
Header Section
├── User avatar (large)
├── Display name + level
├── Edit profile button
└── Settings button

Stats Grid
├── Total score / Level
├── Challenges created
├── Challenges solved
├── Success rate %
├── Current streak days
├── Best streak days

Achievement Badges
├── First challenge
├── Week warrior (7-day streak)
├── Month master (30-day streak)
└── Custom badges (TBD)

Recent Activity
├── Last 5 challenges created
├── Last 5 challenges solved
└── View all button
```

### Key Features
- ✅ Fetch user profile from UserService
- ✅ Display streak count
- ✅ Show statistics
- ✅ Achievement badges
- ✅ Recent activity list
- ✅ Sign out button

### Data Binding
```dart
final userProfileProvider = FutureProvider<User?>((ref) async {
  return ref.watch(userServiceProvider).getCurrentUser();
});

final userStatsProvider = FutureProvider<UserStats?>((ref) async {
  return ref.watch(analyticsServiceProvider).getUserStats();
});
```

---

## 🔗 Backend Integration Checklist

### Firestore Reads
- [ ] ChallengeService.getChallengeByShareToken()
- [ ] ChallengeService.getRandomChallenge()
- [ ] ChallengeService.getApprovedChallenges(filter)
- [ ] RankingService.getDailyRanking()
- [ ] RankingService.getUserRank()
- [ ] UserService.getUserProfile()
- [ ] AnalyticsService.getUserStats()

### Firestore Writes
- [ ] ChallengeAttemptService.recordAttempt()
- [ ] AnalyticsService.trackEvent()
- [ ] RankingService.updateDailyStreak()

### Providers to Update
- [ ] challengeServiceProvider (already has most methods)
- [ ] challengeAttemptServiceProvider (new)
- [ ] rankingServiceProvider (new FutureProvider)
- [ ] userServiceProvider (new)

### Route Updates
- [ ] `/solve` → SolveScreen
- [ ] `/result` → ResultScreen (with result data)
- [ ] `/ranking` → RankingScreen
- [ ] `/profile` → ProfileScreen

---

## 🎨 UI/UX Enhancements (Phase 4)

### Animations to Add
- ✅ Lottie confetti (success)
- ✅ Lottie star burst (correct answer)
- ✅ Shake animation (failure)
- ✅ Page transitions (slide left/right)
- ✅ Loading spinners (skeleton screens)

### Sound Effects
- ✅ Success chime (correct answer)
- ✅ Buzzer (incorrect answer)
- ✅ Combo notification sound
- ✅ Rank up jingle

### Haptic Feedback
- ✅ Heavy impact (success)
- ✅ Medium impact (selection)
- ✅ Light tap (button press)
- ✅ Pattern vibration (error)

### Polish
- ✅ Proper loading states
- ✅ Error messages with retry
- ✅ Empty state screens
- ✅ Skeleton loaders
- ✅ Toast notifications

---

## 📊 Implementation Order

### Day 1 (SolveScreen)
1. Create SolveScreen widget + SolveNotifier
2. Integrate ChallengeService.getChallengeByShareToken()
3. Build region selection UI
4. Wire answer submission
5. Navigation to ResultScreen

### Day 2 (ResultScreen)
1. Create ResultScreen (success/failure paths)
2. Add Lottie animations
3. Integrate analytics tracking
4. Score calculation logic
5. Sound effects + haptics

### Day 3 (RankingScreen + ProfileScreen)
1. Create RankingScreen with tab navigation
2. Implement leaderboard fetching
3. Create ProfileScreen with stats
4. User profile data binding
5. Achievement badge system

### Day 4+ (Polish & Testing)
1. Firebase Firestore integration
2. Real-time updates
3. Error handling
4. Performance optimization
5. Widget/Integration testing

---

## 📁 Files to Create

```
lib/
├── views/
│   ├── solve.dart              # SolveScreen + widgets
│   ├── result.dart             # ResultScreen (success/failure)
│   ├── ranking.dart            # RankingScreen + leaderboard
│   ├── profile.dart            # ProfileScreen + stats
│   └── index.dart              # (update to export new screens)
├── viewmodels/
│   ├── solve_provider.dart     # SolveNotifier + state
│   ├── ranking_provider.dart   # RankingNotifier + providers
│   ├── profile_provider.dart   # ProfileNotifier + providers
│   └── index.dart              # (update exports)
└── models/
    └── user_stats.dart         # (new model if needed)

lib/main.dart
  └── (update GoRouter routes)
```

---

## 🧪 Testing Strategy

### Widget Tests
- [ ] SolveScreen region selection
- [ ] ResultScreen animation triggers
- [ ] RankingScreen tab switching
- [ ] ProfileScreen stat displays

### Integration Tests
- [ ] Full solve flow (challenge → result → home)
- [ ] Ranking updates after solve
- [ ] Profile stats refresh

### Unit Tests
- [ ] SolveNotifier logic
- [ ] Score calculation
- [ ] Streak updates

---

## 🔄 Branch & PR Strategy

**Development Branch**: `claude/phase-4-dev-172657`

**PR Cadence**:
- PR after SolveScreen (core feature)
- PR after ResultScreen (feedback layer)
- PR after Ranking/Profile (stats layer)
- Final PR for backend integration

**Draft → Ready for Review** transition when:
- All screens implemented
- Navigation hooked up
- Basic testing passes
- Backend ready to integrate

---

## ⏱️ Time Estimate

| Task | Est. Time | Status |
|------|-----------|--------|
| SolveScreen | 1.5-2h | ⏳ |
| ResultScreen | 1-1.5h | ⏳ |
| RankingScreen | 1-1.5h | ⏳ |
| ProfileScreen | 1-1.5h | ⏳ |
| Backend integration | 1-2h | ⏳ |
| Testing & polish | 1-1.5h | ⏳ |
| **Total** | **7-10h** | **⏳** |

---

## 📝 Known Dependencies

### Services (Already Implemented)
✅ ChallengeService - All CRUD methods ready  
✅ ChallengeAttemptService - Answer recording ready  
✅ RankingService - Ranking calculations ready  
✅ AnalyticsService - Event tracking ready  

### Still Needed
⏳ UserService - Profile fetching (new)  
⏳ UserStatsCalculation - Stat computation logic  
⏳ petit_ai integration for challenge scoring  

### Firebase Setup
- ✅ Firestore document structure (models define it)
- ⏳ Security rules for reads/writes
- ⏳ Indexes for ranking queries

---

## 🎯 Success Criteria

✅ All 4 core screens implemented  
✅ Complete solve → result flow working  
✅ Rankings display with real data  
✅ Profile shows user stats  
✅ Animations & effects polished  
✅ All routes wired in GoRouter  
✅ Firebase integration ready  
✅ No console errors or warnings  

---

**Phase 4 Status**: 🚀 Ready to Start  
**Next Step**: Implement SolveScreen  
**Branch**: `claude/phase-4-dev-172657`

