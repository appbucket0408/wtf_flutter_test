import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wtf_shared/wtf_shared.dart';

import 'blocs/auth_cubit.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

/// Singleton services shared across the guru app.
final authService = FirebaseAuthService();
final chatService = FirebaseChatService();
final scheduleService =
    FirebaseScheduleService(api: ApiService.instance, chat: chatService);
final logService = FirebaseLogService();
final callService = AgoraCallService(api: ApiService.instance);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp();
  WtfLog.d(LogTag.auth, 'guru app boot');
  runApp(const GuruApp());
}

class GuruApp extends StatelessWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authService)..restore(),
      child: MaterialApp(
        title: 'WTF Guru',
        debugShowCheckedModeBanner: false,
        theme: wtfTheme(AppColors.guruPrimary),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => switch (state) {
        AuthLoading() =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthOnboarding(:final trainers) =>
          OnboardingScreen(trainers: trainers),
        AuthReady(:final user) => DevPanel(
            appName: 'Guru',
            env: const {'TOKEN_URL': ApiEndpoints.baseUrl},
            child: HomeScreen(user: user),
          ),
      },
    );
  }
}
