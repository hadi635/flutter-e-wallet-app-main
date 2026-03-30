import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/localization/app_translations.dart';
import 'package:ewallet/services/stripe_service.dart';
import 'package:ewallet/views/Home/home.dart';
import 'package:ewallet/views/activityView/activity_view.dart';
import 'package:ewallet/views/amountView/amount_view.dart';
import 'package:ewallet/views/authView/login_view.dart';
import 'package:ewallet/views/authView/sign_up_view.dart';
import 'package:ewallet/views/contactsView/contacts_view.dart';
import 'package:ewallet/views/nav/nav_view.dart';
import 'package:ewallet/views/paymentResult/payment_result_view.dart';
import 'package:ewallet/views/profileSetUpView/profile_setup_view.dart';
import 'package:ewallet/views/sendMoneyView/send_money_view.dart';
import 'package:ewallet/views/settingsView/settings_view.dart';
import 'package:ewallet/views/splash/splash_screen_view.dart';
import 'package:ewallet/views/successView/success_view.dart';
import 'package:ewallet/views/wallet/topup_view.dart';
import 'package:ewallet/views/welcomeView/welcome_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyACJ3Fvbraxc4sSc3vgiJH_UPohOMeceaY",
      authDomain: "ewallet-12201.firebaseapp.com",
      projectId: "ewallet-12201",
      storageBucket: "ewallet-12201.firebasestorage.app",
      messagingSenderId: "722404891598",
      appId: "1:722404891598:web:2e04b726efc4f5831ae99f",
      measurementId: "G-HTXRZDZKN5",
    ),
  );
  await StripeService.init();
  final languageController = Get.put(LanguageController(), permanent: true);
  await languageController.loadLocale();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _initialRoute() {
    if (!kIsWeb) return AppRoutes.root;

    var path = Uri.base.path.toLowerCase().trim();
    if (path.isEmpty) return AppRoutes.root;
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    if (path == AppRoutes.cancel) {
      return AppRoutes.reject;
    }
    if (AppRoutes.webRoutable.contains(path)) {
      return path;
    }
    return AppRoutes.root;
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Infinity E-wallet',
        debugShowCheckedModeBanner: false,
        initialRoute: _initialRoute(),
        getPages: [
          GetPage(
            name: AppRoutes.root,
            page: () => const SplashScreenView(),
          ),
          GetPage(
            name: AppRoutes.welcome,
            page: () => const WelcomeView(),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => LoginView(),
          ),
          GetPage(
            name: AppRoutes.signup,
            page: () => SignUpView(),
          ),
          GetPage(
            name: AppRoutes.nav,
            page: () => NavView(),
          ),
          GetPage(
            name: AppRoutes.home,
            page: () => const Home(),
          ),
          GetPage(
            name: AppRoutes.wallet,
            page: () => const TopUpView(),
          ),
          GetPage(
            name: AppRoutes.settings,
            page: () => const SettingsView(),
          ),
          GetPage(
            name: AppRoutes.sendMoney,
            page: () => const SendMoneyView(),
          ),
          GetPage(
            name: AppRoutes.contacts,
            page: () => const ContactsView(appbarTitle: 'send_money'),
          ),
          GetPage(
            name: AppRoutes.activity,
            page: () => ActivityView(),
          ),
          GetPage(
            name: AppRoutes.profileSetup,
            page: () => ProfileSetupView(),
          ),
          GetPage(
            name: AppRoutes.transferAmount,
            page: () => const AmountView(amoutViewTitle: 'send_money'),
          ),
          GetPage(
            name: AppRoutes.transferSuccess,
            page: () => const SuccessView(),
          ),
          GetPage(
            name: AppRoutes.success,
            page: () => const PaymentResultView(success: true),
          ),
          GetPage(
            name: AppRoutes.reject,
            page: () => const PaymentResultView(success: false),
          ),
          GetPage(
            name: AppRoutes.cancel,
            page: () => const PaymentResultView(success: false),
          ),
        ],
        unknownRoute: GetPage(
          name: AppRoutes.root,
          page: () => const SplashScreenView(),
        ),
        translations: AppTranslations(),
        locale: languageController.locale,
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ar', 'IQ'),
        ],
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Appcolor.background,
            appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Appcolor.darkText,
                elevation: 0.00,
                surfaceTintColor: Colors.transparent),
            colorScheme: ColorScheme.dark(
                surface: Appcolor.background, primary: Appcolor.primary),
            fontFamily: 'Segoe UI',
            primaryTextTheme: TextTheme(
              headlineSmall: TextStyle(color: Appcolor.darkText),
            )),
      ),
    );
  }
}

class AppRoutes {
  static const String root = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String nav = '/nav';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String settings = '/settings';
  static const String sendMoney = '/send-money';
  static const String contacts = '/contacts';
  static const String activity = '/activity';
  static const String profileSetup = '/profile-setup';
  static const String transferAmount = '/amount';
  static const String transferSuccess = '/transfer-success';
  static const String success = '/success';
  static const String reject = '/reject';
  static const String cancel = '/cancel';

  static const Set<String> webRoutable = {
    root,
    welcome,
    login,
    signup,
    nav,
    home,
    wallet,
    settings,
    sendMoney,
    contacts,
    activity,
    profileSetup,
    transferAmount,
    transferSuccess,
    success,
    reject,
  };
}
