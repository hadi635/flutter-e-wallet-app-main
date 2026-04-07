import 'package:ewallet/main.dart';
import 'package:ewallet/services/admin_auth_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AdminAuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _redirectIfSessionExists();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _redirectIfSessionExists() async {
    if (await _authService.isLoggedIn()) {
      Get.offAllNamed(AppRoutes.adminDashboard);
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      Get.snackbar('error'.tr, 'fields_cant_be_empty'.tr);
      return;
    }

    setState(() => _loading = true);
    final success = await _authService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!success) {
      Get.snackbar('error'.tr, 'Invalid admin username or password.');
      return;
    }

    Get.offAllNamed(AppRoutes.adminDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(14),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Appcolor.glassBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local encrypted credential check for operations, approvals, and reporting.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Username'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Password'),
                    onSubmitted: (_) => _loading ? null : _login(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: Appcolor.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(_loading ? 'Please wait...' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.welcome),
                    child: const Text(
                      'Back to app',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withAlpha(180)),
      filled: true,
      fillColor: Colors.black.withAlpha(55),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Appcolor.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Appcolor.primary, width: 1.4),
      ),
    );
  }
}
