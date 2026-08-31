import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttermoji/fluttermoji.dart';
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

  Future<void> setAuthenticated() async {
    final store = getIt<InMemoryStore>();
    
    // SYNC AVATAR FOR THIS USER
    if (store.currentUser?.fluttermojiCode != null && store.currentUser!.fluttermojiCode!.isNotEmpty) {
      FluttermojiFunctions().decodeFluttermojifromString(store.currentUser!.fluttermojiCode!);
    }
    
    emit(AuthSuccess());
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    emit(AuthLoading());
    try {
      final store = getIt<InMemoryStore>();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Update in Firebase if logged in
      if (currentUser != null && currentUser.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(credential);
        await currentUser.updatePassword(newPassword);
      }

      // Update local store anyway for UI consistency
      if (store.currentUser != null && store.currentUser!.password == currentPassword) {
        store.currentUser = store.currentUser!.copyWith(password: newPassword);
        await store.saveToDisk();
        emit(AuthSuccess());
      } else {
        emit(AuthError('Incorrect current password.'));
      }
    } catch (e) {
      emit(AuthError('Failed to change password.'));
    }
  }

  Future<void> deleteAccount() async {
    emit(AuthLoading());
    try {
      final store = getIt<InMemoryStore>();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        await currentUser.delete();
      }
      
      await store.resetData();
      // Clear shared avatar state so next user starts fresh
      // Note: Fluttermoji doesn't have a direct 'clear' but saving a default/empty can help
      
      emit(AuthInitial()); // Reset to initial state to trigger router redirect
    } catch (e) {
      emit(AuthError('Failed to delete account. You may need to log in again.'));
    }
  }
  Future<void> logout() async {
    final store = getIt<InMemoryStore>();
    await FirebaseAuth.instance.signOut();
    await store.resetData();
    emit(AuthInitial());
  }
}
