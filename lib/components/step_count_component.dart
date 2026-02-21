import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/utils/app_config.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/colors.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import 'package:pedometer/pedometer.dart';
import '../extensions/decorations.dart';
import '../main.dart';
import '../utils/app_colors.dart';
import '../utils/app_images.dart';



class StepCountComponent extends StatefulWidget {
  static String tag = '/StepCountComponent';

  @override
  StepCountComponentState createState() => StepCountComponentState();
}

class StepCountComponentState extends State<StepCountComponent> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  String _status = '?', _steps = '0';

  bool? isError = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    initPlatformState();
  }



  void onStepCount(StepCount event) {

    if (mounted) {
      setState(() {
        print("------------50>>>${getStringAsync(ISSTEP)}");
        if(getStringAsync(ISSTEP)=='newUser'){
          initialSteps = event.steps;
          userStore.setIsSTEP('oldUser');
        }
       /* if (initialSteps == 0) {
          initialSteps = event.steps;
        }*/
        _steps = (event.steps - initialSteps).toString();

        // _steps = event.steps.toString();
      });
    }



  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    if (mounted) {
      setState(() {
        _status = event.status;
      });
    }
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      isError = true;
      _steps = 'Not Supported';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(onPedestrianStatusChanged).onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
    if (!mounted) return;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: appStore.isDarkMode ? boxDecorationWithRoundedCorners(borderRadius: radius(16),backgroundColor: context.cardColor):boxDecorationRoundedWithShadow(16,backgroundColor: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: boxDecorationWithRoundedCorners(borderRadius: radius(8), backgroundColor: appStore.isDarkMode ? Colors.black : Colors.white),
                padding: EdgeInsets.all(6),
                child: Image.asset(ic_step, width: 22, height: 22, color: primaryColor),
              ),
              Text(languages.lblSteps, style: boldTextStyle(color: appStore.isDarkMode ? primaryColor : black), overflow: TextOverflow.ellipsis, maxLines: 2),
            ],
          ),
          10.height,
          Image.asset(ic_running,  width: 50, height: 50, color: primaryColor),
          8.height,
          isError == true ? Text(_steps, style: secondaryTextStyle()).paddingSymmetric(vertical: 8).center() : Text(_steps, style: boldTextStyle(size: 22)).center(),
          Text(languages.lblTotalSteps, style: secondaryTextStyle()).center().visible(isError != true)
        ],
      ),
    );
  }
}
