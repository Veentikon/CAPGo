import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class ProfileMobile extends StatefulWidget {
  const ProfileMobile({super.key});

  @override
  State<ProfileMobile> createState() => _ProfileMobileState();
}

class _ProfileMobileState extends State<ProfileMobile> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.account_box_rounded, size: 200,),
        SansBold(text: "User Profile Mobile", size: 20.0)
      ]
    );
  }
}