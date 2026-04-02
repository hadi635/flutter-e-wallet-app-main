import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_home_Item.dart';
import 'package:ewallet/globals/custom_list.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/utils/profile_image_url.dart';
import 'package:ewallet/views/activityView/activity_view.dart';
import 'package:ewallet/views/profileSetUpView/profile_setup_view.dart';
import 'package:ewallet/views/sendMoneyView/send_money_view.dart';
import 'package:ewallet/views/wallet/cash_out_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection("user")
                .doc(user!.email)
                .snapshots(),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data();
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: userSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? Shimmer.fromColors(
                              baseColor: const Color(0xffd7dde9),
                              highlightColor: Colors.white,
                              child: const SizedBox(
                                height: 130,
                                child: Center(
                                  child: SpinKitThreeInOut(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/images/logo2.png",
                                          width: 42,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'app_name'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () => Get.to(
                                        () => ProfileSetupView(
                                          emailAddress: user.email,
                                        ),
                                      ),
                                      child: Container(
                                        height: 44,
                                        width: 44,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                          image: DecorationImage(
                                            image: (userData?["Profile Pic"] ??
                                                        "")
                                                    .toString()
                                                    .isNotEmpty
                                                ? NetworkImage(
                                                    normalizeProfileImageUrl(
                                                      userData?["Profile Pic"]
                                                              ?.toString() ??
                                                          '',
                                                    ),
                                                  )
                                                : const NetworkImage(
                                                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRu9mCh1J0Pulu5JXw8cpYkMsCiyFJavo-esQ&usqp=CAU"),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  "${'hello'.tr} ${userData?["Full Name"] ?? ""}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "\$ ${MoneyFormatter.fixed2(userData?["Balance"] ?? 0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'available_balance'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.to(() => const SendMoneyView()),
                            child: CustomHomeItem(
                              title: 'send_money'.tr,
                              icon: Icons.send_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => Get.to(() => const CashOutView()),
                            child: CustomHomeItem(
                              title: 'cash_out'.tr,
                              icon: Icons.local_atm_rounded,
                              bgColor: Appcolor.secondary,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'recent_activity'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.to(() => ActivityView()),
                          child: Text(
                            'see_all'.tr,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection("history")
                            .orderBy("Time", descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SpinKitCircle(color: Colors.white),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          final myDocs = docs
                              .where((d) =>
                                  d.data()["Sender Email"] == user.email ||
                                  d.data()["Receiver Email"] == user.email)
                              .toList();
                          if (myDocs.isEmpty) {
                            return Center(
                              child: Text(
                                'no_transactions_yet'.tr,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: myDocs.length,
                            itemBuilder: (context, index) {
                              final data = myDocs[index].data();
                              final timeValue = data["Time"];
                              final trxTime = timeValue is Timestamp
                                  ? timeValue.toDate()
                                  : DateTime.now();
                              final formatted =
                                  DateFormat.yMMMEd().format(trxTime);
                              final isOutgoing =
                                  data["Sender Email"] == user.email;
                              final receiverWalletId =
                                  data["Receiver Wallet ID"]?.toString() ??
                                      'unknown'.tr;
                              final senderName =
                                  data["Sender"]?.toString() ?? 'unknown'.tr;

                              return CustomList(
                                price:
                                    "\$${MoneyFormatter.fixed2(data["amount"] ?? 0)}",
                                subTitle: formatted,
                                title: isOutgoing
                                    ? "${'wallet_id'.tr}: $receiverWalletId"
                                    : senderName,
                                itemColor: isOutgoing
                                    ? Colors.redAccent
                                    : Appcolor.secondary,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
