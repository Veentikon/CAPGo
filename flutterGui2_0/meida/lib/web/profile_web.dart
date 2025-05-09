import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class ProfileWeb extends StatefulWidget {
  const ProfileWeb({super.key});

  @override
  State<ProfileWeb> createState() => _ProfileWebState();
}

class _ProfileWebState extends State<ProfileWeb> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.account_box_rounded, size: 200,),
        SansBold(text: "User Profile", size: 20.0)
      ]
    );
  }
}