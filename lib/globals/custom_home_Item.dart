import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomHomeItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final void Function()? ontap;
  final Color? bgColor;
  final Color? itemColor;
  const CustomHomeItem(
      {Key? key,
      required this.icon,
      required this.title,
      this.ontap,
      this.bgColor,
      this.itemColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return InkWell(
      onTap: ontap,
      child: Container(
        height: 130,
        width: size.width * .3,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (bgColor ?? Appcolor.primary).withOpacity(0.9),
                (bgColor ?? Appcolor.primary).withOpacity(0.65),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(20.00),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(
              icon,
              color: itemColor ?? Colors.white,
            ),
            Text(
              title,
              style: TextStyle(color: itemColor ?? Colors.white, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
