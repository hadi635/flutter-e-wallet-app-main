import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/views/nav/nav_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'dart:math';

class SignUpService {
  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  Future<void> createAccount({
    required BuildContext context,
    required String fullName,
    required String dateOfBirth,
    required String email,
    required String password,
    required String averageMonthlyTransactions,
    required String profileImage,
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
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        _closeLoader(context);
        // Create or update the wallet user document in the same collection
        // used by the rest of the app.
        await FirebaseFirestore.instance
            .collection("user")
            .doc(email)
            .set({
          "Email": email,
          "Full Name": fullName,
          "Date of Birth": dateOfBirth,
          "Average Monthly Transactions": averageMonthlyTransactions,
          "Profile Pic": profileImage,
          "Balance": 0.00,
          "WalletId": _generateWalletId(),
        }, SetOptions(merge: true));

        Get.offAll(() => NavView());
        Get.snackbar("congratulations".tr, "signup_success".tr);
        return;
      }

      return;
    } on FirebaseAuthException catch (e) {
      _closeLoader(context);

      if (e.code == 'weak-password') {
        showAlert(
            title: 'error'.tr, text: "weak_password".tr, context: context);
        return;
      } else if (e.code == 'email-already-in-use') {
        showAlert(title: 'error'.tr, text: "email_used".tr, context: context);

        return;
      } else {
        showAlert(
            title: 'error'.tr,
            text: "account_creation_failed".tr,
            context: context);
        return;
      }
    } catch (_) {
      _closeLoader(context);
      showAlert(
          title: 'error'.tr, text: "account_creation_failed".tr, context: context);
    }
  }

  void _closeLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void showAlert({
    required String title,
    required String text,
    required BuildContext context,
  }) {
    Get.snackbar(title, text);
  }
}
