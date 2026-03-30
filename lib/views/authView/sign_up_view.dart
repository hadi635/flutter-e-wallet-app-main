import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/sign_up_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/authView/login_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpView extends StatelessWidget {
  SignUpView({super.key});

  final emailCotroller = TextEditingController();
  final passwordController = TextEditingController();
  final reEnterPasswordController = TextEditingController();
  final SignUpService service = SignUpService();

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
                    "create_account".tr,
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
                  const SizedBox(height: 14),
                  CustomField(
                    title: "re_enter_password".tr,
                    secure: true,
                    controller: reEnterPasswordController,
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    title: "create_account".tr,
                    ontap: () async {
                      if (emailCotroller.text.isEmpty ||
                          passwordController.text.isEmpty ||
                          reEnterPasswordController.text.isEmpty) {
                        Get.snackbar("error".tr, "fields_cant_be_empty".tr);
                        return;
                      }
                      if (passwordController.text !=
                          reEnterPasswordController.text) {
                        Get.snackbar("error".tr, "passwords_do_not_match".tr);
                        return;
                      }
                      await service.createAccount(
                        context: context,
                        email: emailCotroller.text.trim(),
                        password: passwordController.text,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.to(() => LoginView()),
                    child: Text(
                      "already_have_account".tr,
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
