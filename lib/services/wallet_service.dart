import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _toMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  double _toDoubleBalance(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed.toDouble();
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> transfer({
    required String receiverWalletId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw Exception("amount_must_be_greater");
    }

    final senderEmail = _auth.currentUser?.email;
    if (senderEmail == null) {
      throw Exception("User is not authenticated");
    }

    final senderRef = _firestore.collection("user").doc(senderEmail);

    return _firestore.runTransaction((transaction) async {
      final senderSnap = await transaction.get(senderRef);
      if (!senderSnap.exists) {
        throw Exception("sender_or_receiver_not_found");
      }

      final senderWalletId =
          (senderSnap.data()?["WalletId"] ?? "").toString().trim();
      if (senderWalletId.isNotEmpty && senderWalletId == receiverWalletId) {
        throw Exception("cannot_transfer_self");
      }

      final receiverQuery = await _firestore
          .collection("user")
          .where("WalletId", isEqualTo: receiverWalletId)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        throw Exception("user_not_found");
      }

      final receiverDoc = receiverQuery.docs.first;
      final receiverRef = _firestore.collection("user").doc(receiverDoc.id);
      final receiverSnap = await transaction.get(receiverRef);

      if (!receiverSnap.exists) {
        throw Exception("sender_or_receiver_not_found");
      }

      if (receiverDoc.id == senderEmail) {
        throw Exception("cannot_transfer_self");
      }

      final senderBalance = _toDoubleBalance(senderSnap.data()?["Balance"]);
      final receiverBalance = _toDoubleBalance(receiverSnap.data()?["Balance"]);

      if (senderBalance < amount) {
        throw Exception("insufficient_balance");
      }

      final newSenderBalance = _toMoney(senderBalance - amount);
      final newReceiverBalance = _toMoney(receiverBalance + amount);

      transaction.update(senderRef, {"Balance": newSenderBalance});
      transaction.update(receiverRef, {"Balance": newReceiverBalance});

      transaction.set(_firestore.collection("history").doc(), {
        "Sender": senderSnap.data()?["Full Name"] ?? senderEmail,
        "Receiver": receiverSnap.data()?["Full Name"] ?? "Unknown",
        "Receiver Email": receiverDoc.id,
        "Sender Email": senderEmail,
        "Sender Wallet ID": senderWalletId,
        "Receiver Wallet ID": receiverWalletId,
        "type": "send",
        "Time": FieldValue.serverTimestamp(),
        "amount": amount,
      });

      return {
        'receiverWalletId': receiverWalletId,
        'receiverName': receiverSnap.data()?["Full Name"] ?? "Unknown",
      };
    });
  }

  Future<void> addBalance({
    required String email,
    required double amount,
    required String source,
    String? reference,
  }) async {
    if (amount <= 0) {
      throw Exception("amount_must_be_greater");
    }

    final userRef = _firestore.collection("user").doc(email);
    final topUpRef = _firestore.collection("topups").doc();

    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw Exception("User not found");
      }

      final currentBalance = _toDoubleBalance(userSnap.data()?["Balance"]);
      final newBalance = _toMoney(currentBalance + amount);

      transaction.update(userRef, {"Balance": newBalance});
      transaction.set(topUpRef, {
        "email": email,
        "amount": amount,
        "source": source,
        "reference": reference,
        "status": "completed",
        "createdAt": FieldValue.serverTimestamp(),
      });
      transaction.set(_firestore.collection("history").doc(), {
        "Sender": "Stripe",
        "Receiver": userSnap.data()?["Full Name"] ?? email,
        "Receiver Email": email,
        "Sender Email": "stripe@system",
        "Sender Wallet ID": "STRIPE",
        "Receiver Wallet ID": userSnap.data()?["WalletId"] ?? "",
        "type": "topup",
        "Time": FieldValue.serverTimestamp(),
        "amount": amount,
      });
    });
  }
}
