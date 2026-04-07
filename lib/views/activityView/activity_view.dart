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
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return data['Sender Email'] == user!.email ||
                      data['Receiver Email'] == user!.email;
                }).toList();
                docs.sort((a, b) {
                  final aTime = (a['Time'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime = (b['Time'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });
                return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15.00),
                    shrinkWrap: true,
                    primary: false,
                    itemCount: docs.length,
                    itemBuilder: ((context, index) {
                      final data = docs[index].data();
                      final timeValue = data['Time'];
                      final trxTime = timeValue is Timestamp
                          ? timeValue.toDate()
                          : DateTime.now();
                      final formatedTime = DateFormat.yMMMEd().format(trxTime);
                      final bool outgoing = data['Sender Email'] == user!.email;
                      final status = (data['status'] ?? 'completed')
                          .toString()
                          .toUpperCase();

                      return CustomList(
                        price:
                            "\$${MoneyFormatter.fixed2(data['amount'] ?? data['requestedAmount'] ?? 0)}",
                        subTitle: '$formatedTime · $status',
                        title: outgoing
                            ? '${data['Receiver'] ?? data['Receiver Wallet ID'] ?? 'unknown'.tr}'
                            : '${data['Sender'] ?? 'unknown'.tr}',
                        itemColor:
                            outgoing ? Colors.redAccent : Appcolor.secondary,
                      );
                    }));
              }
            }),
      ),
    );
  }
}
