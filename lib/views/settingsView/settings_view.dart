import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/localization/app_translations.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/activityView/activity_view.dart';
import 'package:ewallet/views/profileSetUpView/profile_setup_view.dart';
import 'package:ewallet/views/settingsView/fees_view.dart';
import 'package:ewallet/views/settingsView/support_chat_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _showPolicyDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Appcolor.background,
        title: Text(
          'policy_privacy'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'wallet_policy_text'.tr,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: customAppbar(context: context, title: 'settings'.tr),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            Appcolor.accent.withAlpha(210),
                            Appcolor.secondary.withAlpha(190),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'app_name'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'security_reassurance'.tr,
                      style: const TextStyle(
                        color: Appcolor.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'settings_security_text'.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.person_rounded,
                      title: 'profile'.tr,
                      onTap: () => Get.to(
                        () => ProfileSetupView(emailAddress: email),
                      ),
                    ),
                    _settingTile(
                      icon: Icons.history_rounded,
                      title: 'history'.tr,
                      onTap: () => Get.to(() => ActivityView()),
                    ),
                    _settingTile(
                      icon: Icons.chat_rounded,
                      title: 'support_chat'.tr,
                      onTap: () => Get.to(() => const SupportChatView()),
                    ),
                    _settingTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'fees_table'.tr,
                      onTap: () => Get.to(() => const FeesView()),
                    ),
                    _settingTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'policy_privacy'.tr,
                      onTap: _showPolicyDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'language'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _languageButton(
                              active:
                                  languageController.locale.languageCode == 'en',
                              title: 'english'.tr,
                              onTap: () => languageController.changeLanguage('en'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _languageButton(
                              active:
                                  languageController.locale.languageCode == 'ar',
                              title: 'arabic'.tr,
                              onTap: () => languageController.changeLanguage('ar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffB83A34),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Get.snackbar('success'.tr, 'logout_success'.tr);
                    Get.offAllNamed(AppRoutes.welcome);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('logout'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Appcolor.accent.withAlpha(32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Appcolor.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageButton({
    required bool active,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? Appcolor.primary.withAlpha(38) : Colors.transparent,
          border: Border.all(
            color: active ? Appcolor.accent : Appcolor.glassBorder,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: active ? Appcolor.accent : Colors.white,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
