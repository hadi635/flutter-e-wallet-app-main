import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

PreferredSizeWidget customAppbar(
    {String? title,
    bool? arrorw = false,
    List<Widget>? action,
    required context}) {
  return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: title != null
          ? Text(
              title,
              style: const TextStyle(
                  color: Appcolor.darkText,
                  fontSize: 19,
                  fontWeight: FontWeight.w700),
            )
          : null,
      centerTitle: true,
      leading: arrorw == true
          ? IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.arrow_back, color: Appcolor.darkText))
          : null,
      actions: action);
}
