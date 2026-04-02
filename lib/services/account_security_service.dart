import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AccountSecurityService {
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'User must log in again.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  String resolvePasswordError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'wrong_password'.tr;
        case 'weak-password':
          return 'weak_new_password'.tr;
        case 'requires-recent-login':
          return 'recent_login_required'.tr;
      }
    }

    return 'password_change_failed'.tr;
  }
}
