import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No local session — show the mock login.
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
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
    emit(user != null ? AuthReady(user) : const AuthLoggedOut());
  }

  /// Mock login (spec §3A): any credentials seed and sign in Aarav.
  Future<void> login() async {
    try {
      emit(const AuthLoading());
      emit(AuthReady(await _auth.loginTrainer()));
    } on AppException catch (e) {
      AppToast.error(e.userMessage);
      emit(const AuthLoggedOut());
    }
  }
}
