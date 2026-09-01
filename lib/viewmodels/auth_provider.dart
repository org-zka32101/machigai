import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth プロバイダー
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 現在ログイン中のユーザーストリーム
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// 現在のユーザーID
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(authStateProvider).when(
    data: (user) => Future.value(user),
    loading: () => Future.value(null),
    error: (error, stack) => Future.value(null),
  );
  return user?.uid;
});

/// ユーザーがログインしているかどうか
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  return userId != null;
});
