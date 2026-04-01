import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/controllers/profile_setup_controller.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/nav/nav_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfileSetupView extends StatefulWidget {
  final String? emailAddress;
  const ProfileSetupView({super.key, this.emailAddress});

  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  final ProfileSetupController controller =
      Get.put(ProfileSetupController(), tag: 'profile_edit');
  final fullName = TextEditingController();
  final dob = TextEditingController();
  final email = TextEditingController();
  final averageMonthly = TextEditingController();
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    fullName.dispose();
    dob.dispose();
    email.dispose();
    averageMonthly.dispose();
    Get.delete<ProfileSetupController>(tag: 'profile_edit');
    super.dispose();
  }

  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  Future<void> _loadProfile() async {
    final accountEmail =
        widget.emailAddress ?? FirebaseAuth.instance.currentUser?.email ?? '';
    if (accountEmail.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('user')
        .doc(accountEmail)
        .get();
    final data = snap.data() ?? {};

    fullName.text = data['Full Name']?.toString() ?? '';
    dob.text = data['Date of Birth']?.toString() ?? '';
    email.text = accountEmail;
    averageMonthly.text =
        data['Average Monthly Transactions']?.toString() ?? '';
    controller.setExistingImage(data['Profile Pic']?.toString() ?? '');

    if (mounted) {
      setState(() {
        _loading = false;
        _initialized = true;
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    DateTime initial = latest;
    if (dob.text.trim().isNotEmpty) {
      try {
        initial = DateFormat('yyyy-MM-dd').parseStrict(dob.text.trim());
      } catch (_) {}
    }
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(latest) ? latest : initial,
      firstDate: DateTime(1940),
      lastDate: latest,
    );
    if (selected == null) return;
    dob.text = DateFormat('yyyy-MM-dd').format(selected);
  }

  bool _isAdult(String value) {
    try {
      final birthDate = DateFormat('yyyy-MM-dd').parseStrict(value);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age >= 18;
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    final accountEmail =
        widget.emailAddress ?? FirebaseAuth.instance.currentUser?.email ?? '';
    if (accountEmail.isEmpty) {
      Get.snackbar('error'.tr, 'please_login_again'.tr);
      return;
    }
    if (fullName.text.trim().isEmpty ||
        dob.text.trim().isEmpty ||
        averageMonthly.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'fields_cant_be_empty'.tr);
      return;
    }
    if (!_isAdult(dob.text.trim())) {
      Get.snackbar('error'.tr, 'must_be_18'.tr);
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('user').doc(accountEmail);
    final existing = await userRef.get();
    final existingWalletId = existing.data()?['WalletId']?.toString();
    final walletId = (existingWalletId != null && existingWalletId.trim().isNotEmpty)
        ? existingWalletId
        : _generateWalletId();

    await userRef.set({
      'Email': accountEmail,
      'Full Name': fullName.text.trim(),
      'Date of Birth': dob.text.trim(),
      'Average Monthly Transactions': averageMonthly.text.trim(),
      'Balance': existing.data()?['Balance'] ?? 0,
      'WalletId': walletId,
      'Profile Pic': controller.imageDownloadLnk.value.trim(),
    }, SetOptions(merge: true));

    Get.snackbar('success'.tr, 'profile_updated'.tr);
    if (!mounted) return;
    Get.off(() => NavView());
  }

  Widget _imagePicker() {
    return GetBuilder<ProfileSetupController>(
      tag: 'profile_edit',
      builder: (controller) {
        ImageProvider imageProvider;
        if (controller.pickedImageBytes != null) {
          imageProvider = MemoryImage(controller.pickedImageBytes!);
        } else if (controller.imageDownloadLnk.value.isNotEmpty) {
          imageProvider = NetworkImage(controller.imageDownloadLnk.value);
        } else {
          imageProvider = const NetworkImage(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRu9mCh1J0Pulu5JXw8cpYkMsCiyFJavo-esQ&usqp=CAU',
          );
        }

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 60,
              backgroundImage: imageProvider,
            ),
            InkWell(
              onTap: controller.imagePicker,
              child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _policyCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'policy_privacy'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'wallet_policy_text'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'security_reassurance'.tr,
            style: const TextStyle(
              color: Appcolor.accent,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: 'profile'.tr, arrorw: true),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: _loading && !_initialized
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _imagePicker(),
                        const SizedBox(height: 24),
                        CustomField(
                          title: 'enter_full_name'.tr,
                          controller: fullName,
                        ),
                        const SizedBox(height: 16),
                        CustomField(
                          title: 'date_of_birth'.tr,
                          controller: dob,
                          readOnly: true,
                          onTap: _pickDob,
                          prefixIcon: Icons.cake_rounded,
                        ),
                        const SizedBox(height: 16),
                        CustomField(
                          title: 'email_address'.tr,
                          controller: email,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        CustomField(
                          title: 'average_monthly_transactions'.tr,
                          controller: averageMonthly,
                          keybard: TextInputType.number,
                          prefixIcon: Icons.bar_chart_rounded,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'data_secure_note'.tr,
                            style: TextStyle(
                              color: Colors.white.withAlpha(185),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _policyCard(),
                        const SizedBox(height: 20),
                        CustomButton(
                          title: 'save_details'.tr,
                          ontap: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
