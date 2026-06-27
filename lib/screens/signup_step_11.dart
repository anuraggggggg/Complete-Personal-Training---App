import 'package:flutter/material.dart';
import 'package:mighty_fitness/Chat/components/injurybox_widget.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/app_text_field.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/decorations.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/list_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/injury_response.dart';
import 'package:mighty_fitness/models/register_request.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import 'package:mighty_fitness/utils/subscription_navigation.dart';

class SignUpStep11Component extends StatefulWidget {
  const SignUpStep11Component({super.key});

  @override
  State<SignUpStep11Component> createState() => _SignUpStep11ComponentState();
}

class _SignUpStep11ComponentState extends State<SignUpStep11Component> {
  List<int> selectedJoints = [];
  TextEditingController infoCntr = TextEditingController();
  bool isSnackbarVisible = false;

  ScrollController scrollController = ScrollController();
  List<InjuryModel> mInjuryList = [];
  int page = 1;
  int? numPage;

  @override
  void initState() {
    super.initState();
    getInjuryList();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !appStore.isLoading) {
        if (page < (numPage ?? 1)) {
          page++;
          loadMoreInjury();
        }
      }
    });
  }

  // ================= API =================
  Future<void> getInjuryList() async {
    appStore.setLoading(true);
    await getInjuryListApi(page: page).then((value) {
      numPage = value.pagination?.totalPages;
      mInjuryList = value.data ?? [];
      appStore.setLoading(false);
      setState(() {});
    }).catchError((_) => appStore.setLoading(false));
  }

  Future<void> loadMoreInjury() async {
    appStore.setLoading(true);
    await getInjuryListApi(page: page).then((value) {
      mInjuryList.addAll(value.data ?? []);
      appStore.setLoading(false);
      setState(() {});
    }).catchError((_) => appStore.setLoading(false));
  }

  // ================= SELECT INJURY =================
  void toggleInjury(int id) {
    setState(() {
      selectedJoints.contains(id)
          ? selectedJoints.remove(id)
          : selectedJoints.add(id);
      userStore.setInjuredJoints(selectedJoints);
    });
  }

  // ================= SAVE =================
  Future<void> saveData() async {
    hideKeyboard(context);

    UserProfile userProfile = UserProfile()
      ..age = userStore.age.validate()
      ..height = userStore.height.validate()
      ..heightUnit = userStore.heightUnit.validate()
      ..weight = userStore.weight.validate()
      ..weightUnit = userStore.weightUnit.validate()
      ..goal = int.tryParse(userStore.goal)
      ..workoutMode = int.tryParse(userStore.workLoc)
      ..workoutLevel = int.tryParse(userStore.level)
      ..workoutDays = userStore.workoutDays.join(",")
      ..workoutTime = userStore.workoutDaysNo
      ..hasInjury = userStore.injury == "yes" ? 1 : 0
      ..equipmentIds = userStore.equipments.join(",");

    Map<String, dynamic> req = {
      'first_name': userStore.fName.validate(),
      'last_name': userStore.lName.validate(),
      'username': getBoolAsync(IS_OTP) != true
          ? userStore.email.validate()
          : userStore.phoneNo.validate(),
      'email': userStore.email.validate(),
      'password': userStore.password.validate(),
      'user_type': LoginUser,
      'status': statusActive,
      'phone_number': userStore.phoneNo.validate(),
      'gender': userStore.gender.validate().toLowerCase(),
      'user_profile': userProfile.toJson(),
      "player_id": getStringAsync(PLAYER_ID).validate(),
      "has_injury": userStore.injury == "yes" ? 1 : 0,
      "joints": selectedJoints,
      "injury_info": infoCntr.text.trim(),
      "equipments": userStore.equipments.validate(),
      "accepted_terms": 1,
      "accepted_privacy": 1,
      if (getBoolAsync(IS_OTP) != false) "login_type": LoginTypeOTP,
    };

    appStore.setLoading(true);

    await registerApi(req).then((value) async {
      appStore.setLoading(false);
      userStore.setLogin(true);
      userStore.setToken(value.data!.apiToken.validate());

      getUSerDetail(context, value.data!.id).then((_) {
        openPostAuthDestination(forceFreeAutopayPrompt: true);
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: cs.background,
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.height,

            /// ================= TITLE =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Select The Injured Joints",
                style: boldTextStyle(size: 22).copyWith(color: cs.onSurface),
              ),
            ),

            /// ================= JOINT GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 14,
                runSpacing: 20,
                children: mInjuryList.map((item) {
                  final selected = selectedJoints.contains(item.id);
                  return SizedBox(
                    width: 100,
                    child: SelectableInjuryBox(
                      label: item.title ?? "Joint",
                      imagePath: item.injuryImage ?? ic_help,
                      isSelected: selected,
                      onTap: () => toggleInjury(item.id!),
                    ),
                  );
                }).toList(),
              ),
            ),

            24.height,

            /// ================= MEDICAL CONDITION =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Any Specific Medical Condition",
                style: secondaryTextStyle(color: cs.onSurface),
              ),
            ),
            8.height,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTextField(
                controller: infoCntr,
                textFieldType: TextFieldType.MULTILINE,
                decoration: defaultInputDecoration(
                  context,
                  label: "Enter Any Medical Condition",
                ),
              ),
            ),

            30.height,

            /// ================= NEXT BUTTON =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text: languages.lblNext,
                width: context.width(),
                color: cs.primary,
                onTap: () async {
                  if (selectedJoints.isEmpty && infoCntr.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: cs.primary,
                        content: Text(
                          "Please select an injury",
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  userStore.setInjuredJoints(selectedJoints);
                  userStore.setMedCond(infoCntr.text.trim());

                  await saveData();
                },
              ),
            ),

            40.height,
          ],
        ),
      ),
    );
  }
}
