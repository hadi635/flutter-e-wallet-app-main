import 'package:ewallet/controllers/profile_setup_controller.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/sign_up_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/authView/login_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final averageMonthlyController = TextEditingController();
  final SignUpService service = SignUpService();
  final ProfileSetupController imageController =
      Get.put(ProfileSetupController(), tag: 'signup');

  @override
  void dispose() {
    fullNameController.dispose();
    dobController.dispose();
    emailController.dispose();
    passwordController.dispose();
    averageMonthlyController.dispose();
    Get.delete<ProfileSetupController>(tag: 'signup');
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: latest,
      firstDate: DateTime(1940),
      lastDate: latest,
    );
    if (selected == null) return;
    dobController.text = DateFormat('yyyy-MM-dd').format(selected);
  }

  bool _isAdult(String value) {
    try {
      final dob = DateFormat('yyyy-MM-dd').parseStrict(value);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age >= 18;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (fullNameController.text.trim().isEmpty ||
        dobController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        averageMonthlyController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'fields_cant_be_empty'.tr);
      return;
    }
    if (!_isAdult(dobController.text.trim())) {
      Get.snackbar('error'.tr, 'must_be_18'.tr);
      return;
    }
    await service.createAccount(
      context: context,
      fullName: fullNameController.text.trim(),
      dateOfBirth: dobController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      averageMonthlyTransactions: averageMonthlyController.text.trim(),
      profileImage: imageController.imageDownloadLnk.value.trim(),
    );
  }

  Widget _imagePicker() {
    return GetBuilder<ProfileSetupController>(
      tag: 'signup',
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
              radius: 52,
              backgroundColor: Colors.white12,
              backgroundImage: imageProvider,
            ),
            if (controller.isUploading)
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            InkWell(
              onTap: controller.isUploading ? null : controller.imagePicker,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Appcolor.primary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.black87,
                  size: 18,
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
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo2.png', width: 72),
                  const SizedBox(height: 8),
                  Text(
                    'create_account'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _imagePicker(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'profile_photo_optional'.tr,
                      style: TextStyle(
                        color: Colors.white.withAlpha(185),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomField(
                    title: 'enter_full_name'.tr,
                    controller: fullNameController,
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'date_of_birth'.tr,
                    controller: dobController,
                    readOnly: true,
                    onTap: _pickDob,
                    prefixIcon: Icons.cake_rounded,
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'email_address'.tr,
                    controller: emailController,
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'password'.tr,
                    secure: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'average_monthly_transactions'.tr,
                    controller: averageMonthlyController,
                    keybard: TextInputType.number,
                    prefixIcon: Icons.bar_chart_rounded,
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 18),
                  CustomButton(
                    title: 'create_account'.tr,
                    ontap: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.to(() => const LoginView()),
                    child: Text(
                      'already_have_account'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
