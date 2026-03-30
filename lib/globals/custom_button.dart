import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Color? bgColor;
  final void Function()? ontap;
  const CustomButton({Key? key, required this.title, this.ontap, this.bgColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (bgColor ?? Appcolor.primary).withOpacity(0.92),
              (bgColor ?? Appcolor.primary).withOpacity(0.72),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: (bgColor ?? Appcolor.primary).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
