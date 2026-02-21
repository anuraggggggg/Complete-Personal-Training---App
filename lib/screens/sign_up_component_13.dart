import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mighty_fitness/components/equipment_component.dart';
import 'package:mighty_fitness/extensions/animatedList/animated_wrap.dart';
import 'package:mighty_fitness/extensions/app_button.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/list_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/equipment_response.dart';
import 'package:mighty_fitness/models/user_response.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

class SignUpStep13Component extends StatefulWidget {
  const SignUpStep13Component({super.key});

  @override
  State<SignUpStep13Component> createState() => _SignUpStep13ComponentState();
}

class _SignUpStep13ComponentState extends State<SignUpStep13Component> {
  ScrollController scrollController = ScrollController();

  List<EquipmentModel> mEquipmentList = [];
  List<int> selectedEquipments = [];

  int page = 1;
  int? numPage;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    getEquipmentData();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !appStore.isLoading) {
        if (page < (numPage ?? 1)) {
          page++;
          getEquipmentDataPagination();
        }
      }
    });
  }

  // ================= API =================
  Future<void> getEquipmentData() async {
    appStore.setLoading(true);
    await getEquipmentListApi(page: page).then((value) {
      numPage = value.pagination?.totalPages;
      if (page == 1) mEquipmentList.clear();
      mEquipmentList.addAll(value.data ?? []);
      appStore.setLoading(false);
      setState(() {});
    }).catchError((_) {
      isLastPage = true;
      appStore.setLoading(false);
    });
  }

  Future<void> getEquipmentDataPagination() async {
    appStore.setLoading(true);
    await getEquipmentListApi(page: page).then((value) {
      numPage = value.pagination?.totalPages;
      mEquipmentList.addAll(value.data ?? []);
      appStore.setLoading(false);
      setState(() {});
    }).catchError((_) {
      isLastPage = true;
      appStore.setLoading(false);
    });
  }

  // ================= SELECT EQUIPMENT =================
  void toggleEquipment(int id) {
    setState(() {
      selectedEquipments.contains(id)
          ? selectedEquipments.remove(id)
          : selectedEquipments.add(id);
      userStore.setEquipments(selectedEquipments);
    });
  }

  // ================= SAVE =================
  Future<void> saveData() async {
    hideKeyboard(context);

    UserProfile userProfile = UserProfile()
      ..age = userStore.age.toString()
      ..heightUnit = userStore.heightUnit.validate()
      ..height = userStore.height.validate()
      ..weight = userStore.weight.validate()
      ..weightUnit = userStore.weightUnit.validate();

    final req = {
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
      'user_profile': userProfile,
      "player_id": getStringAsync(PLAYER_ID).validate(),
      "goal": userStore.goal.validate(),
      "workout_mode": userStore.workLoc.validate(),
      "workout_level": userStore.level.validate(),
      "workout_days_no": userStore.workoutDaysNo.validate(),
      "workout_days": userStore.workoutDays.validate(),
      "has_injury": userStore.injury.validate(),
      "joints": userStore.injuredJoints.validate(),
      "injury_info": userStore.medCond.validate(),
      "equipments": userStore.equipments.validate(),
      if (getBoolAsync(IS_OTP) != false) "login_type": LoginTypeOTP,
    };

    appStore.setLoading(true);
    await registerApi(req).then((value) async {
      appStore.setLoading(false);
      userStore.setLogin(true);
      userStore.setToken(value.data!.apiToken.validate());

      getUSerDetail(context, value.data!.id).then((_) {
        DashboardScreen().launch(context, isNewTask: true);
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
      backgroundColor: cs.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= TITLE =================
                Text(
                  "Select The Available Equipments",
                  style:
                      boldTextStyle(size: 22).copyWith(color: cs.onBackground),
                ),

                30.height,

                /// ================= EQUIPMENT GRID =================
                AnimatedWrap(
                  runSpacing: 16,
                  spacing: 16,
                  children: List.generate(mEquipmentList.length, (index) {
                    final item = mEquipmentList[index];
                    return EquipmentComponent(
                      mEquipmentModel: item,
                      isSelected: selectedEquipments.contains(item.id),
                      onTap: () => toggleEquipment(item.id!),
                    );
                  }),
                ),

                70.height,

                /// ================= NEXT BUTTON =================
                AppButton(
                  text: languages.lblNext,
                  width: context.width(),
                  color: cs.primary,
                  onTap: saveData,
                ),
              ],
            ),
          ),

          /// ================= LOADER =================
          Observer(
            builder: (_) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
