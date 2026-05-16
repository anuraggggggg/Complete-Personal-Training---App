import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/controllers/google_sign_in_controller/google_sign_in_controller.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/screens/privacy_policy_screen.dart';
import 'package:mighty_fitness/screens/terms_and_conditions_screen.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _hasAcceptedLegal = false;

  final GoogleAuthController controller =
      Get.put(GoogleAuthController());

  @override
  void initState() {
    super.initState();
    _hasAcceptedLegal = getBoolAsync(ACCEPTED_TERMS, defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center,
                    size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                Text(
                  "Welcome to Mighty Fitness",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Train smarter. Live stronger.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.redAccent,
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Image.asset(
                          "assets/google.png",
                          height: 24,
                        ),
                        label: const Text("Continue with Google"),
                        onPressed: () {
                          if (!_hasAcceptedLegal) {
                            toast(
                                'Please accept Terms of Service and Privacy Policy to continue with Google.');
                            return;
                          }
                          setValue(ACCEPTED_TERMS, true);
                          controller.loginWithGoogle();
                        },
                      ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _hasAcceptedLegal,
                        activeColor: primaryColor,
                        onChanged: (value) async {
                          final isAccepted = value ?? false;
                          await setValue(ACCEPTED_TERMS, isAccepted);
                          setState(() {
                            _hasAcceptedLegal = isAccepted;
                          });
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(
                              'I agree to the ',
                              style: secondaryTextStyle(
                                color: Colors.white70,
                                size: 12,
                              ),
                            ),
                            Text(
                              languages.lblTermsOfServices,
                              style: primaryTextStyle(
                                color: Colors.redAccent,
                                size: 12,
                              ),
                            ).onTap(() {
                              const TermsAndConditionScreen().launch(context);
                            }),
                            Text(
                              ' and ',
                              style: secondaryTextStyle(
                                color: Colors.white70,
                                size: 12,
                              ),
                            ),
                            Text(
                              languages.lblPrivacyPolicy,
                              style: primaryTextStyle(
                                color: Colors.redAccent,
                                size: 12,
                              ),
                            ).onTap(() {
                              const PrivacyPolicyScreen().launch(context);
                            }),
                            Text(
                              '.',
                              style: secondaryTextStyle(
                                color: Colors.white70,
                                size: 12,
                              ),
                            ),
                          ],
                        ).paddingTop(12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
