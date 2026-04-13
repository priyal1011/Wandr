import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    final store = getIt<InMemoryStore>();
    if (store.currentUser?.email == email && store.currentUser?.password == password) {
      emit(AuthSuccess());
    } else {
      emit(AuthError('Invalid credentials or user not found.'));
    }
  }

  Future<void> signup(String name, String email, String password) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    final store = getIt<InMemoryStore>();
    store.currentUser = UserModel(id: 'new_user', name: name, email: email, password: password);
    emit(AuthSuccess());
  }

  void setAuthenticated() {
    emit(AuthSuccess());
  }

  Future<void> logout() async {
    final store = getIt<InMemoryStore>();
    await FirebaseAuth.instance.signOut();
    await store.resetData();
    emit(AuthInitial());
  }
}
