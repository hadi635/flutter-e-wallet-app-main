import 'package:ewallet/controllers/profile_setup_controller.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/services/sign_up_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/country_options.dart';
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
  String? _selectedCountry;

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
        averageMonthlyController.text.trim().isEmpty ||
        (_selectedCountry ?? '').isEmpty) {
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
      country: _selectedCountry!,
      averageMonthlyTransactions: averageMonthlyController.text.trim(),
      profileImage: imageController.imageDownloadLnk.value.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _intro()),
                          const SizedBox(width: 18),
                          Expanded(child: _form()),
                        ],
                      )
                    : Column(
                        children: [
                          _intro(),
                          const SizedBox(height: 16),
                          _form(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo2.png', width: 82),
          const SizedBox(height: 18),
          const Text(
            'Create your Infinity account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Country is required for admin analytics, date of birth is required for the 18+ rule, and your first Wish Money add money request opens with a free-fee promotion.',
            style: TextStyle(color: Colors.white.withAlpha(190), height: 1.6),
          ),
          const SizedBox(height: 20),
          Text(
            'wallet_policy_text'.tr,
            style: TextStyle(color: Colors.white.withAlpha(185), height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          CustomField(
              title: 'enter_full_name'.tr, controller: fullNameController),
          const SizedBox(height: 14),
          CustomField(
            title: 'date_of_birth'.tr,
            controller: dobController,
            readOnly: true,
            onTap: _pickDob,
            prefixIcon: Icons.cake_rounded,
          ),
          const SizedBox(height: 14),
          _countryField(),
          const SizedBox(height: 14),
          CustomField(title: 'email_address'.tr, controller: emailController),
          const SizedBox(height: 14),
          CustomField(
              title: 'password'.tr,
              secure: true,
              controller: passwordController),
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
              style:
                  TextStyle(color: Colors.white.withAlpha(185), fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(title: 'create_account'.tr, ontap: _submit),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.login),
            child: Text(
              'already_have_account'.tr,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.28),
        hintText: 'Country',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.68)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Appcolor.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Appcolor.primary, width: 2),
        ),
      ),
      dropdownColor: Appcolor.background,
      style: const TextStyle(color: Colors.white),
      items: kCountryOptions
          .map((country) =>
              DropdownMenuItem(value: country, child: Text(country)))
          .toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
    );
  }
}
