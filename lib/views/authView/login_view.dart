import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/login_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/authView/sign_up_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final emailCotroller = TextEditingController();
  final passwordController = TextEditingController();
  final LoginService service = LoginService();

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
                  Image.asset("assets/images/infinity_logo.png", width: 72),
                  const SizedBox(height: 8),
                  Text(
                    "login".tr,
                    style: TextStyle(
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
                  const SizedBox(height: 18),
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
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.to(() => SignUpView()),
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
