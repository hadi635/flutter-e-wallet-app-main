import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/localization/app_translations.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 820;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff060606), Color(0xff121212), Color(0xff1f1407)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: compact
                    ? ListView(
                        children: [
                          _topBar(languageController),
                          const SizedBox(height: 16),
                          _ctaCard(),
                          const SizedBox(height: 16),
                          _heroCard(compact: true),
                          const SizedBox(height: 16),
                          _footerLinks(),
                        ],
                      )
                    : Column(
                        children: [
                          _topBar(languageController),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(flex: 4, child: _ctaCard()),
                                const SizedBox(width: 16),
                                Expanded(flex: 7, child: _heroCard()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _footerLinks(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(LanguageController languageController) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo2.png', width: 42),
            const SizedBox(width: 10),
            Text(
              'app_name'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        _languageMenu(languageController),
      ],
    );
  }

  Widget _heroCard({bool compact = false}) {
    return GlassContainer(
      padding: EdgeInsets.all(compact ? 22 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Appcolor.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Appcolor.glassBorder),
            ),
            child: Text(
              'welcome_badge'.tr,
              style: const TextStyle(
                color: Appcolor.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'welcome_title'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 30 : 42,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'welcome_tagline'.tr,
            style: TextStyle(
              color: Appcolor.accent,
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'welcome_description'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.65,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroStat('welcome_stat_one'.tr),
              _heroStat('welcome_stat_two'.tr),
              _heroStat('welcome_stat_three'.tr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctaCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'welcome_cta_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'welcome_cta_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            title: 'create_new_account'.tr,
            ontap: () => Get.toNamed(AppRoutes.signup),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Get.toNamed(AppRoutes.login),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Appcolor.glassBorder),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              'login'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
         
          const SizedBox(height: 10),
          _supportRow(Icons.call_outlined, '+964 78 75 84 48 84'),
        ],
      ),
    );
  }

  Widget _footerLinks() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _RoutePill(label: 'about'.tr, route: AppRoutes.about),
        _RoutePill(label: 'services'.tr, route: AppRoutes.services),
        _RoutePill(label: 'contact'.tr, route: AppRoutes.contact),
        _RoutePill(label: 'privacy'.tr, route: AppRoutes.privacy),
        _RoutePill(label: 'terms'.tr, route: AppRoutes.terms),
        _RoutePill(label: 'admin'.tr, route: AppRoutes.admin),
      ],
    );
  }

  Widget _heroStat(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolor.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _supportRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Appcolor.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _languageMenu(LanguageController languageController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolor.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: languageController.locale.languageCode,
          dropdownColor: Appcolor.background,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: [
            DropdownMenuItem(value: 'en', child: Text('english'.tr)),
            DropdownMenuItem(value: 'ar', child: Text('arabic'.tr)),
          ],
          onChanged: (value) {
            if (value != null) {
              languageController.changeLanguage(value);
            }
          },
        ),
      ),
    );
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Appcolor.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
