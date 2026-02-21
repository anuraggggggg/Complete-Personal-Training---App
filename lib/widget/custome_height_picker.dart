import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/system_utils.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/widget/height_picker.dart';

class CustomeHeightPicker extends StatefulWidget {
  CustomeHeightPicker({super.key, required this.heightSelected});

  final ValueChanged<String> heightSelected;

  @override
  State<CustomeHeightPicker> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CustomeHeightPicker> {
  int height = (userStore.heightUnit == 'cm' || userStore.heightUnit.isEmpty)
      ? (userStore.height.isEmpty ? 180 : userStore.height.toInt())
      : userStore.height.isEmpty
          ? 180
          : (userStore.height.toDouble() * 30.48).toInt();

  List<String> get _listHeightText => ["CM", "FEET"];
  final ValueNotifier<int> _tabIndexUpdateProgrammatically = ValueNotifier(userStore.heightUnit == 'cm' ? 0 : 1);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appStore.isDarkMode ? scaffoldColorDark : BackgroundColorImageColor,
        leading: GestureDetector(
          onTap: ()  {
            finish(context);
          },
          child: Icon(
            Octicons.chevron_left,
            color: primaryColor,
            size: 28,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: ()async {
                await userStore.setHeightUnit(_tabIndexUpdateProgrammatically.value == 0 ? 'cm' : 'feet');
                print("---------------------->>>>${userStore.heightUnit}");
                await userStore.setHeight("${_tabIndexUpdateProgrammatically.value == 0 ? height : (height / 30.48).toStringAsFixed(1)}");
                widget.heightSelected("${_tabIndexUpdateProgrammatically.value == 0 ? height : (height / 30.48).toStringAsFixed(1)}");
                finish(context);
              },
              child: Icon(
                Icons.check,
                color: primaryColor,
                size: 28,
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ValueListenableBuilder(
            valueListenable: _tabIndexUpdateProgrammatically,
            builder: (context, currentIndex, _) {
              return FlutterToggleTab(
                width: 50,
                borderRadius: 10,
                selectedBackgroundColors: [primaryColor],
                selectedIndex: currentIndex,
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unSelectedTextStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                labels: _listHeightText,
                selectedLabelIndex: (index) {
                  _tabIndexUpdateProgrammatically.value = index;
                 // userStore.setHeightUnit(index == 0 ? 'cm' : 'feet');
                  setState(() {});
                },
              );
            },
          ),
          SizedBox(height: 20),
          Expanded(
            child: HeightSlider(
               sliderCircleColor: primaryColor,
              height: height,
              maxHeight: 245,
              minHeight: 140,
              onChange: (val) {
                setState(() => height = val);
              },
              unit: _tabIndexUpdateProgrammatically.value == 0 ? 'CM' : 'FEET',
              tabIndex: _tabIndexUpdateProgrammatically.value,
            ),
          ),
        ],
      ),
    );
  }
}
