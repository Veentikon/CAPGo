import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class SettingsMobile extends StatefulWidget {
  const SettingsMobile({super.key});

  @override
  State<SettingsMobile> createState() => _SettingsMobileState();
}

class _SettingsMobileState extends State<SettingsMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(61, 61, 61, 1),
      body: Center(
        child: SansBold(text: "This is settings page Mobile", size: 22.0),
      ),
    );
  }
}