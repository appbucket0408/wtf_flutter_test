import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No local session — show onboarding.
class AuthOnboarding extends AuthState {
  final List<AppUser> trainers;
  const AuthOnboarding({this.trainers = const []});
}

class AuthReady extends AuthState {
  final AppUser user;
  const AuthReady(this.user);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _auth;

  AuthCubit(this._auth) : super(const AuthLoading());

  Future<void> restore() async {
    final user = await _auth.restoreSession();
    if (user != null) {
      emit(AuthReady(user));
      return;
    }
    try {
      emit(AuthOnboarding(trainers: await _auth.seededTrainers()));
    } on AppException catch (e) {
      WtfLog.d(LogTag.auth, 'trainer fetch failed: ${e.raw}');
      emit(const AuthOnboarding());
    }
  }

  Future<void> completeOnboarding({
    required String name,
    required String trainerId,
  }) async {
    try {
      emit(const AuthLoading());
      final user =
          await _auth.onboardMember(name: name, trainerId: trainerId);
      emit(AuthReady(user));
    } on AppException catch (e) {
      AppToast.error(e.userMessage);
      emit(AuthOnboarding(trainers: await _auth.seededTrainers()));
    }
  }
}
