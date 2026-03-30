import 'package:ewallet/localization/app_translations.dart';
import 'package:ewallet/views/welcomeView/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('Welcome view renders', (WidgetTester tester) async {
    Get.put(LanguageController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const WelcomeView(),
      ),
    );

    expect(find.text('Upay Wallet'), findsOneWidget);
  });
}
