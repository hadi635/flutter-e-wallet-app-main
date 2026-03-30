import 'package:ewallet/views/nav/nav_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class LoginService {
  Future<void> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    //Loading Effect
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SpinKitThreeInOut(
                    color: Colors.black,
                  ),
                ]),
          );
        });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        _closeLoader(context);
        //Navigate to NavView
        Get.to(() => NavView());
        Get.snackbar("congratulations".tr, "login_success".tr);
        return;
      }

      return;
    } on FirebaseAuthException catch (e) {
      _closeLoader(context);

      if (e.code == 'user-not-found') {
        showAlert(
            title: 'error'.tr,
            text: "user_not_found_email".tr,
            context: context);
        return;
      } else if (e.code == 'wrong-password') {
        showAlert(
            title: 'error'.tr, text: "wrong_password".tr, context: context);

        return;
      } else {
        showAlert(title: 'error'.tr, text: "login_failed".tr, context: context);
        return;
      }
    } catch (_) {
      _closeLoader(context);
      showAlert(title: 'error'.tr, text: "login_failed".tr, context: context);
    }
  }

  void _closeLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void showAlert(
      {required String title, required String text, BuildContext? context}) {
    Get.snackbar(title, text);
  }
}
