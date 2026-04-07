import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/main.dart';
import 'package:ewallet/services/admin_auth_service.dart';
import 'package:ewallet/services/wallet_request_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _authService = AdminAuthService();
  final _requestService = WalletRequestService();
  final _numberFormat = NumberFormat.compact();
  bool _authorised = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final valid = await _authService.isLoggedIn();
    if (!valid) {
      Get.offAllNamed(AppRoutes.admin);
      return;
    }
    if (!mounted) return;
    setState(() => _authorised = true);
  }

  Future<void> _logout() async {
    await _authService.logout();
    Get.offAllNamed(AppRoutes.admin);
  }

  Future<void> _confirm(String requestId) async {
    try {
      await _requestService.confirmRequest(requestId);
      Get.snackbar('success'.tr, 'Request confirmed.');
    } catch (e) {
      Get.snackbar('error'.tr, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reject(String requestId) async {
    try {
      await _requestService.rejectRequest(requestId);
      Get.snackbar('success'.tr, 'Request rejected.');
    } catch (e) {
      Get.snackbar('error'.tr, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleBlock(String email, bool blocked) async {
    try {
      await _requestService.setUserBlocked(email: email, blocked: blocked);
      Get.snackbar('success'.tr, blocked ? 'User blocked.' : 'User unblocked.');
    } catch (e) {
      Get.snackbar('error'.tr, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorised) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: Appcolor.appGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Operations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Users, pending requests, live balances, and financial exposure in real time.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: _logout,
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Appcolor.glassBorder),
                  ),
                  child: const TabBar(
                    indicatorColor: Appcolor.primary,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Requests'),
                      Tab(text: 'Users'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(numberFormat: _numberFormat),
                      _RequestsTab(
                        onConfirm: _confirm,
                        onReject: _reject,
                      ),
                      _UsersTab(onToggleBlock: _toggleBlock),
                      const _HistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.numberFormat});

  final NumberFormat numberFormat;

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('user').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(WalletRequestService.requestsCollection)
              .snapshots(),
          builder: (context, requestsSnapshot) {
            final userDocs = usersSnapshot.data?.docs ?? [];
            final requestDocs = requestsSnapshot.data?.docs ?? [];

            final walletLiability = userDocs.fold<double>(
              0,
              (total, doc) => total + _toDouble(doc.data()['Balance']),
            );
            final activeUsers =
                userDocs.where((doc) => doc.data()['IsBlocked'] != true).length;
            final blockedUsers = userDocs.length - activeUsers;
            final pendingAddMoney = requestDocs
                .where((doc) =>
                    doc.data()['status'] == 'pending' &&
                    doc.data()['kind'] == 'add_money')
                .fold<double>(
                  0,
                  (total, doc) => total + _toDouble(doc.data()['netAmount']),
                );
            final pendingCashOut = requestDocs
                .where((doc) =>
                    doc.data()['status'] == 'pending' &&
                    doc.data()['kind'] == 'cash_out')
                .fold<double>(
                  0,
                  (total, doc) =>
                      total + _toDouble(doc.data()['requestedAmount']),
                );
            final confirmedFees = requestDocs
                .where((doc) => doc.data()['status'] == 'confirmed')
                .fold<double>(
                  0,
                  (total, doc) => total + _toDouble(doc.data()['feeAmount']),
                );

            final countries = <String, int>{};
            for (final doc in userDocs) {
              final country =
                  (doc.data()['Country'] ?? 'Unknown').toString().trim();
              countries[country] = (countries[country] ?? 0) + 1;
            }
            final topCountries = countries.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard(
                      'Wallet Liability',
                      '\$${MoneyFormatter.fixed2(walletLiability)}',
                      'Current total user balances',
                    ),
                    _metricCard(
                      'Pending Add Money',
                      '\$${MoneyFormatter.fixed2(pendingAddMoney)}',
                      'Net pending credits waiting approval',
                    ),
                    _metricCard(
                      'Pending Cash Out',
                      '\$${MoneyFormatter.fixed2(pendingCashOut)}',
                      'Pending withdrawals waiting settlement',
                    ),
                    _metricCard(
                      'Fees Earned',
                      '\$${MoneyFormatter.fixed2(confirmedFees)}',
                      'Confirmed fees across manual requests',
                    ),
                    _metricCard(
                      'Active Users',
                      numberFormat.format(activeUsers),
                      'Users allowed to transact',
                    ),
                    _metricCard(
                      'Blocked Users',
                      numberFormat.format(blockedUsers),
                      'Users currently blocked',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _panel(
                  title: 'Country Analytics',
                  child: topCountries.isEmpty
                      ? const Text(
                          'No country data yet.',
                          style: TextStyle(color: Colors.white70),
                        )
                      : Column(
                          children: topCountries.take(8).map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      color: Appcolor.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _metricCard(String title, String value, String subtitle) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Appcolor.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolor.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.onConfirm,
    required this.onReject,
  });

  final Future<void> Function(String requestId) onConfirm;
  final Future<void> Function(String requestId) onReject;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(WalletRequestService.requestsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final pendingDocs =
            docs.where((doc) => doc.data()['status'] == 'pending').toList();

        if (pendingDocs.isEmpty) {
          return const Center(
            child: Text(
              'No pending requests.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: pendingDocs.length,
          itemBuilder: (context, index) {
            final data = pendingDocs[index].data();
            final method = (data['method'] ?? '').toString().toUpperCase();
            final kind = (data['kind'] ?? '').toString().replaceAll('_', ' ');
            final amount = MoneyFormatter.fixed2(data['requestedAmount'] ?? 0);
            final fee = MoneyFormatter.fixed2(data['feeAmount'] ?? 0);
            final net = MoneyFormatter.fixed2(data['netAmount'] ?? 0);
            final createdAt = data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Appcolor.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data['fullName'] ?? ''} · $method',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        kind,
                        style: const TextStyle(color: Appcolor.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _detail('Email', '${data['email'] ?? ''}'),
                      _detail('Wallet ID', '${data['walletId'] ?? ''}'),
                      _detail('Country', '${data['country'] ?? ''}'),
                      _detail('Requested', '\$$amount'),
                      _detail('Fee', '\$$fee'),
                      _detail('Net', '\$$net'),
                      if ((data['paymentReference'] ?? '')
                          .toString()
                          .isNotEmpty)
                        _detail('Reference', '${data['paymentReference']}'),
                      if ((data['senderPhone'] ?? '').toString().isNotEmpty)
                        _detail('Phone', '${data['senderPhone']}'),
                      if ((data['preferredLocation'] ?? '')
                          .toString()
                          .isNotEmpty)
                        _detail(
                          'Preferred location',
                          '${data['preferredLocation']}',
                        ),
                      if ((data['walletAddress'] ?? '').toString().isNotEmpty)
                        _detail('Wallet address', '${data['walletAddress']}'),
                      if ((data['promotionApplied'] ?? '')
                          .toString()
                          .isNotEmpty)
                        _detail('Promotion', 'First Wish payment free'),
                      if (createdAt != null)
                        _detail('Created',
                            DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                    ],
                  ),
                  if ((data['note'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${data['note']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: () => onConfirm(pendingDocs[index].id),
                        style: FilledButton.styleFrom(
                          backgroundColor: Appcolor.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Confirm'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => onReject(pendingDocs[index].id),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white70, height: 1.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.onToggleBlock});

  final Future<void> Function(String email, bool blocked) onToggleBlock;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('user').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final email = docs[index].id;
            final blocked = data['IsBlocked'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Appcolor.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data['Full Name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: blocked
                              ? Colors.red.withAlpha(30)
                              : Colors.green.withAlpha(28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          blocked ? 'Blocked' : 'Active',
                          style: TextStyle(
                            color:
                                blocked ? Colors.redAccent : Colors.greenAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _text('Email', email),
                      _text('Wallet ID', '${data['WalletId'] ?? ''}'),
                      _text('Country', '${data['Country'] ?? ''}'),
                      _text(
                        'Balance',
                        '\$${MoneyFormatter.fixed2(data['Balance'] ?? 0)}',
                      ),
                      _text(
                        'Avg monthly',
                        '${data['Average Monthly Transactions'] ?? ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => onToggleBlock(email, !blocked),
                    child: Text(blocked ? 'Unblock user' : 'Block user'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _text(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white70),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('history')
          .orderBy('Time', descending: true)
          .limit(120)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No transaction history yet.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final time = data['Time'] is Timestamp
                ? (data['Time'] as Timestamp).toDate()
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Appcolor.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['type'] ?? 'transaction'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data['Sender'] ?? ''} -> ${data['Receiver'] ?? ''}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${data['status'] ?? 'completed'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (time != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(time),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${MoneyFormatter.fixed2(data['amount'] ?? 0)}',
                    style: const TextStyle(
                      color: Appcolor.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
