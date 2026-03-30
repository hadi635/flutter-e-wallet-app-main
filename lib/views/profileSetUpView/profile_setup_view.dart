import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/controllers/profile_setup_controller.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/nav/nav_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSetupView extends StatelessWidget {
  final String? emailAddress;
  ProfileSetupView({Key? key, this.emailAddress}) : super(key: key);

  final controller = Get.put(ProfileSetupController());

  final fullName = TextEditingController();
  final nid = TextEditingController();
  final phoneNumber = TextEditingController();

  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: 'complete_setup'.tr),
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      GetBuilder<ProfileSetupController>(builder: (controller) {
                        ImageProvider profileImage;
                        if (controller.pickedImageBytes != null) {
                          profileImage =
                              MemoryImage(controller.pickedImageBytes!);
                        } else {
                          profileImage = const NetworkImage(
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRu9mCh1J0Pulu5JXw8cpYkMsCiyFJavo-esQ&usqp=CAU');
                        }

                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              radius: 60,
                              backgroundImage: profileImage,
                            ),
                            InkWell(
                              onTap: () => controller.imagePicker(),
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(40.0),
                                    border: Border.all(
                                        color: Colors.white, width: 2.00)),
                                child: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        );
                      }),
                      const SizedBox(height: 24.00),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          children: [
                            CustomField(
                              title: 'enter_full_name'.tr,
                              controller: fullName,
                            ),
                            const SizedBox(height: 20.00),
                            CustomField(
                              title: 'enter_nid_name'.tr,
                              controller: nid,
                            ),
                            const SizedBox(height: 20.00),
                            CustomField(
                              title: 'enter_phone_number'.tr,
                              controller: phoneNumber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CustomButton(
                    title: 'save_details'.tr,
                    ontap: () async {
                      if (emailAddress == null || emailAddress!.isEmpty) {
                        Get.snackbar('error'.tr, 'please_login_again'.tr);
                        return;
                      }

                      final userRef = FirebaseFirestore.instance
                          .collection('user')
                          .doc(emailAddress);
                      final existing = await userRef.get();
                      final existingWalletId =
                          existing.data()?['WalletId']?.toString();
                      final walletId = (existingWalletId != null &&
                              existingWalletId.trim().isNotEmpty)
                          ? existingWalletId
                          : _generateWalletId();

                      await userRef.set({
                        'Email': emailAddress,
                        'Full Name': fullName.text,
                        'Nid': nid.text,
                        'Phone': phoneNumber.text,
                        'Balance': existing.data()?['Balance'] ?? 0,
                        'WalletId': walletId,
                        'Profile Pic': controller.imageDownloadLnk.value,
                      }, SetOptions(merge: true)).then(
                        (value) => Get.to(() => NavView()),
                      );
                    },
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
