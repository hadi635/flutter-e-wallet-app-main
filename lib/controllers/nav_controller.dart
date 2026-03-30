import 'package:ewallet/views/Home/home.dart';
import 'package:ewallet/views/settingsView/settings_view.dart';
import 'package:ewallet/views/wallet/topup_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavController extends GetxController {
  RxInt currentValue = RxInt(0);

  List<Widget> pages = [
    const Home(),
    const TopUpView(),
    const SettingsView(),
  ];

  void changeValue(int index) {
    currentValue.value = index;
    update();
  }
}
