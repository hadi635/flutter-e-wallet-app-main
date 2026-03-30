import 'package:flutter/material.dart';

class Appcolor {
  static const Color primary = Color(0xffFFB300);
  static const Color secondary = Color(0xffFF8F00);
  static const Color accent = Color(0xffFFD54F);
  static const Color darkText = Color(0xffFAFAFA);
  static const Color background = Color(0xff0B0B0D);
  static const Color glass = Color(0x33FFB300);
  static const Color glassBorder = Color(0x66FFCA66);

  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xff050505),
      Color(0xff121212),
      Color(0xff1A1408),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x44FFC107),
      Color(0x22000000),
    ],
  );
}
