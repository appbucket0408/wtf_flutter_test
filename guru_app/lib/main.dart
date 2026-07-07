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
            child: _NotificationGate(user: user),
          ),
      },
    );
  }
}

/// Starts local notifications once DK is signed in (spec §15 stretch).
class _NotificationGate extends StatefulWidget {
  final AppUser user;
  const _NotificationGate({required this.user});

  @override
  State<_NotificationGate> createState() => _NotificationGateState();
}

class _NotificationGateState extends State<_NotificationGate> {
  NotificationCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    final trainerId = widget.user.assignedTrainerId;
    if (trainerId != null) {
      _coordinator = NotificationCoordinator(
        notif: NotificationService.instance,
        chat: chatService,
        schedule: scheduleService,
        me: widget.user,
      )..start(peerId: trainerId);
    }
  }

  @override
  void dispose() {
    _coordinator?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeScreen(user: widget.user);
}
