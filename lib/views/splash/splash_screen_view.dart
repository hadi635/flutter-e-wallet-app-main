import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  final user = FirebaseAuth.instance.currentUser;

  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  Future<void> _ensureWalletId() async {
    if (user?.email == null) return;
    final ref = FirebaseFirestore.instance.collection('user').doc(user!.email);
    final snap = await ref.get();
    if (!snap.exists) return;
    final walletId = snap.data()?['WalletId']?.toString() ?? '';
    if (walletId.trim().isNotEmpty) return;
    await ref.set({'WalletId': _generateWalletId()}, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      if (user == null) {
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      await _ensureWalletId();
      Get.offAllNamed(AppRoutes.nav);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo2.png', width: 82),
                const SizedBox(height: 8),
                Text(
                  "app_name".tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
