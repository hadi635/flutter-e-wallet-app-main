import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_list.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ActivityView extends StatelessWidget {
  ActivityView({Key? key}) : super(key: key);
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(
          context: context,
          title: 'activity'.tr,
          arrorw: true,
          action: [const Icon(Icons.search, color: Colors.white)]),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('history').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else {
                return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15.00),
                    shrinkWrap: true,
                    primary: false,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: ((context, index) {
                      final data = snapshot.data!.docs[index];
                      final timeValue = data['Time'];
                      final trxTime = timeValue is Timestamp
                          ? timeValue.toDate()
                          : DateTime.now();
                      final formatedTime = DateFormat.yMMMEd().format(trxTime);
                      final bool isMe = data['Sender Email'] == user!.email;

                      return isMe
                          ? CustomList(
                              price:
                                  "\$${MoneyFormatter.fixed2(data['amount'] ?? 0)}",
                              subTitle: formatedTime,
                              title:
                                  "${'wallet_id'.tr}: ${data['Receiver Wallet ID'] ?? 'unknown'.tr}",
                              itemColor: Colors.red,
                              icon: CircleAvatar(
                                // Show first char of wallet id if available.
                                child: Text(
                                  (() {
                                    final value =
                                        (data['Receiver Wallet ID'] ?? '?')
                                            .toString();
                                    return value.isEmpty
                                        ? '?'
                                        : value.substring(0, 1);
                                  })(),
                                ),
                              ),
                            )
                          : const SizedBox();
                    }));
              }
            }),
      ),
    );
  }
}
