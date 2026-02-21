import 'package:flutter/material.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/shared_pref.dart';
import '../../extensions/widgets.dart';
import '../extensions/common.dart';
import '../main.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';
import 'about_us_screen.dart';

class AboutAppScreen extends StatefulWidget {
  static String tag = '/AboutAppScreen';

  @override
  AboutAppScreenState createState() => AboutAppScreenState();
}

class AboutAppScreenState extends State<AboutAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(languages.lblAboutApp, context: context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Privacy Policy
            getStringAsync(PRIVACY_POLICY).isNotEmpty
                ? ListTile(
                    leading: Image.asset(ic_rate_us, height: 24, width: 24),
                    title: Text(languages.lblPrivacyPolicy),
                    onTap: () {
                      PrivacyPolicyScreen()
                          .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                    },
                  )
                : SizedBox.shrink(),
            Divider(height: 0).visible(getStringAsync(PRIVACY_POLICY).isNotEmpty),

            // Terms of Service
            getStringAsync(TERMS_SERVICE).isNotEmpty
                ? ListTile(
                    leading: Image.asset(ic_terms, height: 24, width: 24),
                    title: Text(languages.lblTermsOfServices),
                    onTap: () {
                      TermsAndConditionScreen()
                          .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                    },
                  )
                : SizedBox.shrink(),
            Divider(height: 0).visible(getStringAsync(TERMS_SERVICE).isNotEmpty),

            // About Us
            ListTile(
              leading: Image.asset(ic_info, height: 24, width: 24),
              title: Text(languages.lblAboutUs),
              onTap: () {
                AboutUsScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
              },
            ),
          ],
        ),
      ),
    );
  }
}
