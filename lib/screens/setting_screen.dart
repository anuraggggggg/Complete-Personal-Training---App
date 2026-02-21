import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import '../main.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/widget_extensions.dart';

class SettingScreen extends StatefulWidget {
  static String tag = '/SettingScreen';

  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Settings",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: primaryColor,
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: Text(
              "No settings available",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          backgroundColor: appStore.isDarkMode ? Colors.black : Colors.white,
        );
      },
    );
  }
}
