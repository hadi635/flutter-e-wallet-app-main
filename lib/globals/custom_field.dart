import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomField extends StatelessWidget {
  final String title;
  final bool secure;
  final IconData? prefixIcon;
  final TextInputType? keybard;
  final Color? focusColor;
  final Color? borderColor;
  final TextEditingController? controller;
  final bool readOnly;
  final void Function()? onTap;
  final int maxLines;

  const CustomField(
      {Key? key,
      required this.title,
      this.secure = false,
      this.focusColor,
      this.borderColor,
      this.prefixIcon,
      this.keybard,
      this.controller,
      this.readOnly = false,
      this.onTap,
      this.maxLines = 1})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keybard,
      obscureText: secure,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: secure ? 1 : maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black.withOpacity(0.28),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Appcolor.accent)
              : null,
          hintText: title,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.68)),
          //Border
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: borderColor ?? Appcolor.glassBorder)),
          //Focus Border
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: focusColor ?? Appcolor.primary, width: 2.00)),
          //Error Border
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2.00))),
    );
  }
}
