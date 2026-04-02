import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/services/login_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailCotroller = TextEditingController();
  final passwordController = TextEditingController();
  final LoginService service = LoginService();
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    emailCotroller.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? true;
    });
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
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
                  Image.asset("assets/images/logo2.png", width: 72),
                  const SizedBox(height: 8),
                  Text(
                    "login".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomField(
                    title: "email_address".tr,
                    controller: emailCotroller,
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: "password".tr,
                    secure: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (emailCotroller.text.trim().isEmpty) {
                          Get.snackbar(
                            'error'.tr,
                            'enter_email_for_reset'.tr,
                          );
                          return;
                        }

                        await service.resetPassword(
                          emailCotroller.text.trim(),
                        );
                      },
                      child: Text(
                        'reset_password'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() => _rememberMe = value);
                          await _saveRememberMe(value);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'remember_me'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    title: "login".tr,
                    ontap: () async {
                      if (emailCotroller.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        Get.snackbar("error".tr, "fields_cant_be_empty".tr);
                        return;
                      }
                      await service.login(
                        context: context,
                        email: emailCotroller.text.trim(),
                        password: passwordController.text,
                        rememberMe: _rememberMe,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                    child: Text(
                      "create_account".tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
