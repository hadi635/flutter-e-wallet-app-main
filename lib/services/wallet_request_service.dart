import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletRequestService {
  WalletRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String requestsCollection = 'wallet_requests';

  double _toMoney(num value) {
    return (value * 100).roundToDouble() / 100;
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'wish':
        return 'Wish Money';
      case 'card':
        return 'Visa / Mastercard';
      case 'crypto':
        return 'Crypto';
      case 'agent':
        return 'Agent';
      default:
        return method;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> currentUserSnapshot() async {
    final email = _auth.currentUser?.email;
    if (email == null) {
      throw Exception('Please log in again.');
    }
    final snap = await _firestore.collection('user').doc(email).get();
    if (!snap.exists) {
      throw Exception('User profile not found.');
    }
    return snap;
  }

  Future<Map<String, dynamic>> createAddMoneyRequest({
    required String method,
    required double amount,
    String note = '',
    String paymentReference = '',
    String senderName = '',
    String senderPhone = '',
    String senderWallet = '',
  }) async {
    if (amount <= 0) {
      throw Exception('Enter a valid amount greater than 0.');
    }

    final user = _auth.currentUser;
    final email = user?.email;
    if (email == null) {
      throw Exception('Please log in again.');
    }

    final userSnap = await currentUserSnapshot();
    final userData = userSnap.data() ?? {};
    if (userData['IsBlocked'] == true) {
      throw Exception('Your account is blocked.');
    }

    final walletId = (userData['WalletId'] ?? '').toString();
    final fullName = (userData['Full Name'] ?? email).toString();
    final country = (userData['Country'] ?? '').toString();
    final completedWishCount =
        (userData['WishAddMoneyCompletedCount'] as num?)?.toInt() ?? 0;

    double feePercent = 0;
    double feeFixed = 0;
    bool firstWishFree = false;

    switch (method) {
      case 'wish':
        firstWishFree = completedWishCount == 0;
        feePercent = firstWishFree ? 0 : 1;
        break;
      case 'card':
        feePercent = 5.5;
        feeFixed = 0.30;
        break;
      default:
        throw Exception('Unsupported add money method.');
    }

    final feeAmount = _toMoney(amount * (feePercent / 100) + feeFixed);
    final netAmount = _toMoney(amount - feeAmount);
    if (netAmount <= 0) {
      throw Exception('Amount is too low after fees.');
    }

    final requestRef = _firestore.collection(requestsCollection).doc();
    final historyRef = _firestore.collection('history').doc();

    await requestRef.set({
      'requestId': requestRef.id,
      'kind': 'add_money',
      'method': method,
      'status': 'pending',
      'email': email,
      'walletId': walletId,
      'fullName': fullName,
      'country': country,
      'requestedAmount': _toMoney(amount),
      'feePercent': feePercent,
      'feeFixed': feeFixed,
      'feeAmount': feeAmount,
      'netAmount': netAmount,
      'promotionApplied': firstWishFree ? 'wish_first_payment_free' : '',
      'paymentReference': paymentReference.trim(),
      'senderName': senderName.trim(),
      'senderPhone': senderPhone.trim(),
      'senderWallet': senderWallet.trim(),
      'note': note.trim(),
      'historyId': historyRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await historyRef.set({
      'Sender': _methodLabel(method),
      'Receiver': fullName,
      'Receiver Email': email,
      'Sender Email': '${method}_pending@system',
      'Sender Wallet ID': method.toUpperCase(),
      'Receiver Wallet ID': walletId,
      'type': 'pending',
      'method': method,
      'status': 'pending',
      'Time': FieldValue.serverTimestamp(),
      'amount': 0,
      'requestedAmount': _toMoney(amount),
      'feeAmount': feeAmount,
      'netAmount': netAmount,
      'reference': requestRef.id,
    });

    return {
      'requestId': requestRef.id,
      'feeAmount': feeAmount,
      'netAmount': netAmount,
      'firstWishFree': firstWishFree,
    };
  }

  Future<Map<String, dynamic>> createCashOutRequest({
    required String method,
    required double amount,
    String note = '',
    String contactPhone = '',
    String preferredLocation = '',
    String walletAddress = '',
  }) async {
    if (amount <= 0) {
      throw Exception('Enter a valid amount greater than 0.');
    }

    final email = _auth.currentUser?.email;
    if (email == null) {
      throw Exception('Please log in again.');
    }

    final userSnap = await currentUserSnapshot();
    final userData = userSnap.data() ?? {};
    if (userData['IsBlocked'] == true) {
      throw Exception('Your account is blocked.');
    }

    final balance = _toDouble(userData['Balance']);
    if (balance < amount) {
      throw Exception('Insufficient balance');
    }

    final walletId = (userData['WalletId'] ?? '').toString();
    final fullName = (userData['Full Name'] ?? email).toString();
    final country = (userData['Country'] ?? '').toString();
    final requestRef = _firestore.collection(requestsCollection).doc();
    final historyRef = _firestore.collection('history').doc();

    await requestRef.set({
      'requestId': requestRef.id,
      'kind': 'cash_out',
      'method': method,
      'status': 'pending',
      'email': email,
      'walletId': walletId,
      'fullName': fullName,
      'country': country,
      'requestedAmount': _toMoney(amount),
      'feePercent': 0,
      'feeFixed': 0,
      'feeAmount': 0,
      'netAmount': _toMoney(amount),
      'contactPhone': contactPhone.trim(),
      'preferredLocation': preferredLocation.trim(),
      'walletAddress': walletAddress.trim(),
      'note': note.trim(),
      'historyId': historyRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await historyRef.set({
      'Sender': fullName,
      'Receiver': '${_methodLabel(method)} Cash Out',
      'Receiver Email': '${method}_cashout@system',
      'Sender Email': email,
      'Sender Wallet ID': walletId,
      'Receiver Wallet ID': method.toUpperCase(),
      'type': 'cash_out_request',
      'method': method,
      'status': 'pending',
      'Time': FieldValue.serverTimestamp(),
      'amount': 0,
      'requestedAmount': _toMoney(amount),
      'reference': requestRef.id,
    });

    return {
      'requestId': requestRef.id,
      'netAmount': _toMoney(amount),
    };
  }

  Future<void> confirmRequest(String requestId) async {
    final requestRef = _firestore.collection(requestsCollection).doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnap = await transaction.get(requestRef);
      if (!requestSnap.exists) {
        throw Exception('Request not found.');
      }

      final request = requestSnap.data() ?? {};
      final status = (request['status'] ?? '').toString();
      if (status == 'confirmed') {
        return;
      }
      if (status == 'rejected') {
        throw Exception('Request is already rejected.');
      }

      final email = (request['email'] ?? '').toString();
      if (email.isEmpty) {
        throw Exception('Request email is missing.');
      }

      final userRef = _firestore.collection('user').doc(email);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw Exception('User not found.');
      }

      final userData = userSnap.data() ?? {};
      if (userData['IsBlocked'] == true) {
        throw Exception('Blocked users cannot be settled.');
      }

      final historyId = (request['historyId'] ?? '').toString();
      final historyRef = historyId.isEmpty
          ? _firestore.collection('history').doc()
          : _firestore.collection('history').doc(historyId);
      final method = (request['method'] ?? '').toString();
      final kind = (request['kind'] ?? '').toString();
      final requestedAmount = _toDouble(request['requestedAmount']);
      final feeAmount = _toDouble(request['feeAmount']);
      final netAmount = _toDouble(request['netAmount']);
      final balance = _toDouble(userData['Balance']);

      if (kind == 'add_money') {
        transaction.update(userRef, {
          'Balance': _toMoney(balance + netAmount),
          if (method == 'wish')
            'WishAddMoneyCompletedCount':
                ((userData['WishAddMoneyCompletedCount'] as num?)?.toInt() ??
                        0) +
                    1,
        });

        transaction.set(
          historyRef,
          {
            'type': 'topup',
            'status': 'confirmed',
            'amount': netAmount,
            'requestedAmount': requestedAmount,
            'feeAmount': feeAmount,
            'netAmount': netAmount,
            'Time': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else if (kind == 'cash_out') {
        if (balance < requestedAmount) {
          throw Exception('User balance is no longer sufficient.');
        }

        transaction.update(userRef, {
          'Balance': _toMoney(balance - requestedAmount),
        });

        transaction.set(
          historyRef,
          {
            'type': 'cash_out',
            'status': 'confirmed',
            'amount': requestedAmount,
            'requestedAmount': requestedAmount,
            'feeAmount': 0,
            'netAmount': requestedAmount,
            'Time': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        throw Exception('Unsupported request type.');
      }

      transaction.update(requestRef, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String requestId, {String reason = ''}) async {
    final requestRef = _firestore.collection(requestsCollection).doc(requestId);
    final snap = await requestRef.get();
    if (!snap.exists) {
      throw Exception('Request not found.');
    }

    final historyId = (snap.data()?['historyId'] ?? '').toString();
    await requestRef.set({
      'status': 'rejected',
      'rejectionReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (historyId.isNotEmpty) {
      await _firestore.collection('history').doc(historyId).set({
        'status': 'rejected',
        'rejectionReason': reason.trim(),
        'Time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> setUserBlocked({
    required String email,
    required bool blocked,
  }) async {
    await _firestore.collection('user').doc(email).set({
      'IsBlocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
