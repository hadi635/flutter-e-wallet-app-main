import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_list.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/amountView/amount_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

class ContactsView extends StatefulWidget {
  final String appbarTitle;
  const ContactsView({super.key, required this.appbarTitle});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final walletIdController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: widget.appbarTitle),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: walletIdController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "search_by_wallet_id".tr,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Appcolor.accent),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder(
                  stream:
                      FirebaseFirestore.instance.collection("user").snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: SpinKitCircle(
                        color: Colors.white,
                      ));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final docs = snapshot.data?.docs;
                      final filteredDocs = docs?.where((doc) {
                        final walletId = doc["WalletId"] ?? '';
                        return walletIdController.text.isEmpty ||
                            walletId
                                .toString()
                                .contains(walletIdController.text.trim());
                      }).toList();

                      final filteredDataList = filteredDocs!
                          .where((item) => item["Email"] != user!.email)
                          .toList();

                      return Expanded(
                          child: ListView.builder(
                        itemCount: filteredDataList.length,
                        itemBuilder: (context, index) {
                          final data = filteredDataList[index];
                          return CustomList(
                            price: "\$${data["Balance"]}",
                            subTitle: "${data["WalletId"] ?? ""}",
                            title: "${data["Full Name"]}",
                            ontap: () async {
                              try {
                                final doc = await FirebaseFirestore.instance
                                    .collection("user")
                                    .doc(data["Email"])
                                    .get();
                                final sender = await FirebaseFirestore.instance
                                    .collection("user")
                                    .doc(user!.email)
                                    .get();

                                final receiverData = doc.data();

                                Get.off(() => AmountView(
                                    amoutViewTitle: widget.appbarTitle,
                                    receiverData: receiverData,
                                    senderData: sender.data()));
                              } catch (e) {
                                Get.snackbar('error'.tr, 'transfer_failed'.tr);
                              }
                            },
                          );
                        },
                      ));
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
