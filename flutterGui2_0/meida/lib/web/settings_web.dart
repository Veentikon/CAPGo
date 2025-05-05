import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class SettingsWeb extends StatefulWidget {
  const SettingsWeb({super.key});

  @override
  State<SettingsWeb> createState() => _SettingsWebState();
}

class _SettingsWebState extends State<SettingsWeb> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(61, 61, 61, 1),
      body: Center(
        child: SansBold(text: "This is settings page", size: 22.0),
      ),
    );
  }
}