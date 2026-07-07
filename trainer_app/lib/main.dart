import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wtf_shared/wtf_shared.dart';

import 'blocs/auth_cubit.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Singleton services shared across the trainer app.
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
  WtfLog.d(LogTag.auth, 'trainer app boot');
  runApp(const TrainerApp());
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authService)..restore(),
      child: MaterialApp(
        title: 'WTF Trainer',
        debugShowCheckedModeBanner: false,
        theme: wtfTheme(AppColors.trainerPrimary),
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
        AuthLoggedOut() => const LoginScreen(),
        AuthReady(:final user) => DevPanel(
            appName: 'Trainer',
            env: const {'TOKEN_URL': ApiEndpoints.baseUrl},
            child: HomeScreen(user: user),
          ),
      },
    );
  }
}
