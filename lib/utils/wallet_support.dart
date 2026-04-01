import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletSupport {
  static const String contactNumber = '+964 78 75 84 48 84';

  static Future<void> openSupportContactDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Appcolor.background,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '$message\n\n${'support_number'.tr}: $contactNumber',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await launchPhoneNumber();
            },
            child: Text(
              'contact_now'.tr,
              style: const TextStyle(color: Appcolor.accent),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> launchPhoneNumber() async {
    final normalized = contactNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$normalized');
    final launched = await launchUrl(uri);
    if (!launched) {
      Get.snackbar('error'.tr, contactNumber);
    }
  }
}
