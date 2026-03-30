import 'dart:ui';

import 'package:ewallet/controllers/nav_controller.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavView extends StatelessWidget {
  NavView({super.key});

  final controller = Get.put(NavController());
  final List<_NavItemData> _items = const [
    _NavItemData(
      labelKey: 'home',
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
    ),
    _NavItemData(
      labelKey: 'wallet',
      icon: Icons.account_balance_wallet_rounded,
      activeIcon: Icons.account_balance_wallet,
    ),
    _NavItemData(
      labelKey: 'settings',
      icon: Icons.settings_rounded,
      activeIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        extendBody: true,
        body: controller.pages[controller.currentValue.value],
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(28),
                      Appcolor.primary.withAlpha(36),
                    ],
                  ),
                  border: Border.all(
                    color: Appcolor.glassBorder.withAlpha(180),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: List.generate(_items.length, (index) {
                      final selected = controller.currentValue.value == index;
                      final item = _items[index];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: selected
                                  ? Appcolor.accent.withAlpha(36)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? Appcolor.accent.withAlpha(130)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => controller.changeValue(index),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  scale: selected ? 1.03 : 1.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          selected
                                              ? item.activeIcon
                                              : item.icon,
                                          key: ValueKey(
                                              '${item.labelKey}_$selected'),
                                          size: selected ? 25 : 23,
                                          color: selected
                                              ? Appcolor.accent
                                              : Colors.white.withAlpha(200),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeOut,
                                        style: TextStyle(
                                          color: selected
                                              ? Appcolor.accent
                                              : Colors.white.withAlpha(185),
                                          fontSize: selected ? 12 : 11,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                        child: Text(item.labelKey.tr),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String labelKey;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });
}
