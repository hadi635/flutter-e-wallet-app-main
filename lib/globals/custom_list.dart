import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';

class CustomList extends StatelessWidget {
  final String title;
  final String subTitle;
  final String price;
  final Widget? icon;
  final Color? itemColor;
  final void Function()? ontap;
  const CustomList(
      {Key? key,
      this.icon,
      this.ontap,
      required this.price,
      required this.subTitle,
      required this.title,
      this.itemColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        tileColor: Colors.black.withOpacity(0.35),
        onTap: ontap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: icon ??
            CircleAvatar(
              backgroundColor: Appcolor.primary.withOpacity(0.3),
              child: Text(title.isNotEmpty ? title[0] : ""),
            ),
        title: Text(
          title.isNotEmpty ? title : "No Name",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subTitle,
          style: TextStyle(color: Colors.white.withOpacity(.72)),
        ),
        trailing: Text(
          price,
          style: TextStyle(color: itemColor ?? Appcolor.primary, fontSize: 18),
        ),
      ),
    );
  }
}
