import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/widget/custome_height_picker.dart';
import 'package:mighty_fitness/widget/weight_widget.dart';
import 'package:tuple/tuple.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../main.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../extensions/app_button.dart';
import '../extensions/app_text_field.dart';
import '../extensions/colors.dart';
import '../extensions/common.dart';
import '../extensions/decorations.dart';
import '../extensions/shared_pref.dart';
import '../extensions/text_styles.dart';
import '../models/body_part_response.dart';
import '../models/gender_response.dart';
import '../models/level_response.dart';
import '../models/workout_type_response.dart';
import '../models/user_response.dart';
import '../network/network_utils.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController mFNameCont = TextEditingController();
  TextEditingController mLNameCont = TextEditingController();
  TextEditingController mEmailCont = TextEditingController();
  TextEditingController mAgeCont = TextEditingController();
  TextEditingController mMobileNumberCont = TextEditingController();
  TextEditingController mWeightCont = TextEditingController();
  TextEditingController mHeightCont = TextEditingController();

  FocusNode mEmailFocus = FocusNode();
  FocusNode mFNameFocus = FocusNode();
  FocusNode mLNameFocus = FocusNode();
  FocusNode mMobileNumberFocus = FocusNode();
  FocusNode mAgeFocus = FocusNode();
  FocusNode mWeightFocus = FocusNode();
  FocusNode mHeightFocus = FocusNode();

  List<String> item = [languages.lblFemale, languages.lblMale];
  List<GenderModel> GenderList = [];
  List<LevelModel> mLevelList = [];
  List<BodyPartModel> mGoalList = [];
  List<WorkoutTypeModel> mWorkoutModeList = [];

  String mGender = languages.lblFemale;
  String? profileImg = '';
  String? countryCode = '';

  int? mHeight;
  int? mWeight;

  XFile? image;

  double inputValue = 0.0;
  int selectGender = 0;

  bool isKGClicked = false;
  bool isLBSClicked = false;
  bool isFeetClicked = false;
  bool isCMClicked = false;
  int? selectedWorkoutLevelId;
  int? selectedGoalId;
  int? selectedWorkoutModeId;
  int selectedWorkoutDays = 3;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    getGender();
    _syncFormFromStore();
    await _loadLatestProfileDetails();
    await Future.wait([
      getWorkoutLevels(),
      getGoals(),
      getWorkoutModes(),
    ]);
    _syncFormFromStore();
    //userStore.heightUnit == FEET ? mHeight = 0 : mHeight = 1;
    //userStore.weightUnit == LBS ? mWeight = 0 : mWeight = 1;
    mGender = userStore.gender.isEmptyOrNull
        ? "female"
        : userStore.gender.capitalizeFirstLetter();
    _initializeProfileSelections();
    userStore.displayName = userStore.fName + userStore.lName;
  }

  void _syncFormFromStore() {
    final String savedAge = userStore.age.validate().isNotEmpty
        ? userStore.age.validate()
        : getStringAsync(AGE);
    final String savedWeight = userStore.weight.validate().isNotEmpty
        ? userStore.weight.validate()
        : getStringAsync(WEIGHT);
    final String savedWeightUnit = userStore.weightUnit.validate().isNotEmpty
        ? userStore.weightUnit.validate()
        : getStringAsync(WEIGHT_UNIT);
    final String savedHeight = userStore.height.validate().isNotEmpty
        ? userStore.height.validate()
        : getStringAsync(HEIGHT);
    final String savedHeightUnit = userStore.heightUnit.validate().isNotEmpty
        ? userStore.heightUnit.validate()
        : getStringAsync(HEIGHT_UNIT);

    mFNameCont.text = userStore.fName;
    mLNameCont.text = userStore.lName;
    mEmailCont.text = userStore.email;
    mAgeCont.text = savedAge;
    mMobileNumberCont.text = userStore.phoneNo;
    if (savedWeight.isNotEmpty) {
      mWeightCont.text = savedWeightUnit.isNotEmpty
          ? '$savedWeight $savedWeightUnit'
          : savedWeight;
    }
    profileImg = userStore.profileImage;
    if (savedHeight.isNotEmpty) {
      mHeightCont.text = savedHeightUnit.isNotEmpty
          ? '$savedHeight $savedHeightUnit'
          : savedHeight;
    }

    if (userStore.age.validate().isEmpty && savedAge.isNotEmpty) {
      userStore.setAge(savedAge);
    }
    if (userStore.weight.validate().isEmpty && savedWeight.isNotEmpty) {
      userStore.setWeight(savedWeight);
    }
    if (userStore.weightUnit.validate().isEmpty && savedWeightUnit.isNotEmpty) {
      userStore.setWeightUnit(savedWeightUnit);
    }
    if (userStore.height.validate().isEmpty && savedHeight.isNotEmpty) {
      userStore.setHeight(savedHeight);
    }
    if (userStore.heightUnit.validate().isEmpty && savedHeightUnit.isNotEmpty) {
      userStore.setHeightUnit(savedHeightUnit);
    }
  }

  Future<void> _loadLatestProfileDetails() async {
    if (userStore.userId <= 0) return;

    try {
      final UserResponse res = await getUserDataApi(id: userStore.userId);
      final Data? userData = res.data;
      final UserProfile? profile = userData?.userProfile;

      if (userData != null) {
        await userStore.setFirstName(userData.firstName.validate());
        await userStore.setLastName(userData.lastName.validate());
        await userStore.setUserEmail(userData.email.validate());
        await userStore.setPhoneNo(userData.phoneNumber.validate());
        await userStore.setGender(userData.gender.validate());
        await userStore.setUserImage(userData.profileImage.validate());
      }

      if (profile != null) {
        await userStore.setAge(profile.age.validate());
        await userStore.setHeight(profile.height.validate());
        await userStore.setHeightUnit(profile.heightUnit.validate());
        await userStore.setWeight(profile.weight.validate());
        await userStore.setWeightUnit(profile.weightUnit.validate());
        if (profile.goal != null) {
          await userStore.setGoal(profile.goal.toString());
        }
        if (profile.workoutMode != null) {
          await userStore.setWorkoutLoc(profile.workoutMode.toString());
        }
        if (profile.workoutLevel != null) {
          await userStore.setlevel(profile.workoutLevel.toString());
        }
        final workoutDaysNo = resolveWorkoutDaysCount(
          profile.workoutDaysNo ?? profile.workoutDays,
          fallback: userStore.workoutDaysNo,
        );
        await userStore.setWorkoutDaysNo(workoutDaysNo);
        await userStore
            .setWorkoutDays(defaultWorkoutDaysForCount(workoutDaysNo));
        selectedWorkoutDays = workoutDaysNo;
      }

      _syncFormFromStore();
    } catch (e) {
      debugPrint('Profile detail fetch failed: $e');
    }

    if (mounted) setState(() {});
  }

  String _extractMeasurementValue(String raw) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.first : '';
  }

  String _extractMeasurementUnit(String raw) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return parts.length > 1 ? parts.last : '';
  }

  Future<void> _persistProfileFieldsFromForm() async {
    final String weightValue = _extractMeasurementValue(mWeightCont.text);
    final String weightUnit = _extractMeasurementUnit(mWeightCont.text);
    final String heightValue = _extractMeasurementValue(mHeightCont.text);
    final String heightUnit = _extractMeasurementUnit(mHeightCont.text);

    await userStore.setAge(mAgeCont.text.validate());
    await userStore.setWeight(weightValue);
    if (weightUnit.isNotEmpty) {
      await userStore.setWeightUnit(weightUnit);
    }
    await userStore.setHeight(heightValue);
    if (heightUnit.isNotEmpty) {
      await userStore.setHeightUnit(heightUnit);
    }
  }

  Future<void> getWorkoutLevels() async {
    try {
      final LevelResponse res = await getLevelListApi();
      mLevelList = res.data ?? [];

      if (mLevelList.isNotEmpty) {
        final int savedLevel = int.tryParse(userStore.level) ?? -1;
        final LevelModel selectedLevel = mLevelList.firstWhere(
          (element) => element.id == savedLevel,
          orElse: () => mLevelList.first,
        );
        selectedWorkoutLevelId = selectedLevel.id;
        _ensureValidSelectedWorkoutLevel();
      }
    } catch (e) {
      debugPrint('Workout level fetch failed: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> getGoals() async {
    try {
      final BodyPartResponse res = await getBodyPartApi();
      mGoalList = res.data ?? [];
    } catch (e) {
      debugPrint('Goal fetch failed: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> getWorkoutModes() async {
    try {
      final WorkoutTypeResponse res = await getWorkoutTypeListApi();
      mWorkoutModeList = res.data ?? [];
      _ensureValidSelectedWorkoutLevel();
    } catch (e) {
      debugPrint('Workout mode fetch failed: $e');
    }

    if (mounted) setState(() {});
  }

  void _initializeProfileSelections() {
    final int? savedGoalId = int.tryParse(userStore.goal);
    final int? savedWorkoutModeId = int.tryParse(userStore.workLoc);

    if (mGoalList.isNotEmpty) {
      selectedGoalId = mGoalList.any((e) => e.id == savedGoalId)
          ? savedGoalId
          : mGoalList.first.id;
    }

    if (mWorkoutModeList.isNotEmpty) {
      selectedWorkoutModeId =
          mWorkoutModeList.any((e) => e.id == savedWorkoutModeId)
              ? savedWorkoutModeId
              : mWorkoutModeList.first.id;
    }

    selectedWorkoutDays = resolveWorkoutDaysCount(
      userStore.workoutDaysNo,
      fallback: selectedWorkoutDays,
    );
    _ensureValidSelectedWorkoutLevel();
  }

  List<LevelModel> _filteredLevelList() {
    WorkoutTypeModel? selectedWorkoutMode;
    for (final element in mWorkoutModeList) {
      if (element.id == selectedWorkoutModeId) {
        selectedWorkoutMode = element;
        break;
      }
    }
    final String workoutModeTitle =
        (selectedWorkoutMode?.title ?? '').toLowerCase();

    bool matchesLevel(LevelModel level) {
      final String title = (level.title ?? '').toLowerCase();
      final bool isBeginner = title.contains('beginner');
      final bool isIntermediate = title.contains('intermediate');
      final bool isAdvanced = title.contains('advance');

      if (workoutModeTitle.contains('home')) return isBeginner || isAdvanced;
      if (workoutModeTitle.contains('gym')) {
        return isBeginner || isIntermediate || isAdvanced;
      }
      return true;
    }

    return mLevelList.where(matchesLevel).toList();
  }

  void _ensureValidSelectedWorkoutLevel() {
    final List<LevelModel> visibleLevels = _filteredLevelList();
    if (visibleLevels.isEmpty) {
      selectedWorkoutLevelId = null;
      return;
    }

    if (!visibleLevels.any((element) => element.id == selectedWorkoutLevelId)) {
      selectedWorkoutLevelId = visibleLevels.first.id;
    }
  }

  String _goalAsset(String? title) {
    final value = (title ?? '').toLowerCase();
    if (value.contains('muscle') || value.contains('gain')) {
      return 'assets/Bodybuilding - Gym Power.json';
    }
    if (value.contains('weight') || value.contains('loss')) {
      return 'assets/Workout.json';
    }
    return ic_keep;
  }

  String _goalDescription(String? title) {
    final value = (title ?? '').toLowerCase();
    if (value.contains('muscle') || value.contains('gain')) {
      return 'Build strength, size and a more athletic physique.';
    }
    if (value.contains('weight') || value.contains('loss')) {
      return 'Burn fat, stay consistent and move toward a leaner body.';
    }
    return 'Stay active, feel better and build a sustainable routine.';
  }

  getGender() {
    GenderList.add(GenderModel(0, languages.lblMale, MALE));
    GenderList.add(GenderModel(1, languages.lblFemale, FEMALE));
    for (var element in GenderList) {
      print('userStore.gender${userStore.gender}');
      if (element.key == userStore.gender) {
        selectGender = element.id.validate();
      }
    }
  }

  Future save() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await _persistProfileFieldsFromForm();

    MultipartRequest multiPartRequest =
        await getMultiPartRequest('update-profile');

    multiPartRequest.fields['id'] = userStore.userId.toString();
    multiPartRequest.fields['first_name'] = mFNameCont.text;
    multiPartRequest.fields['last_name'] = mLNameCont.text;
    multiPartRequest.fields['email'] = mEmailCont.text;
    multiPartRequest.fields['username'] = mEmailCont.text;
    multiPartRequest.fields['phone_number'] = mMobileNumberCont.text;
    multiPartRequest.fields['gender'] = mGender.toLowerCase();
    multiPartRequest.fields['user_profile[age]'] = mAgeCont.text;
    multiPartRequest.fields['user_profile[weight]'] =
        mWeightCont.text.validate().split(' ').first;
    multiPartRequest.fields['user_profile[height]'] =
        mHeightCont.text.validate().split(' ').first;
    multiPartRequest.fields['user_profile[height_unit]'] = userStore.heightUnit;
    multiPartRequest.fields['user_profile[weight_unit]'] = userStore.weightUnit;
    if (selectedWorkoutLevelId != null) {
      multiPartRequest.fields['user_profile[workout_level]'] =
          selectedWorkoutLevelId.toString();
    }
    if (selectedGoalId != null) {
      multiPartRequest.fields['user_profile[goal]'] = selectedGoalId.toString();
    }
    if (selectedWorkoutModeId != null) {
      multiPartRequest.fields['user_profile[workout_mode]'] =
          selectedWorkoutModeId.toString();
    }
    multiPartRequest.fields['workout_days_no'] = selectedWorkoutDays.toString();
    multiPartRequest.fields['user_profile[workout_days_no]'] =
        selectedWorkoutDays.toString();
    multiPartRequest.fields['user_profile[workout_days]'] =
        selectedWorkoutDays.toString();

    if (image != null) {
      multiPartRequest.files.add(
        await MultipartFile.fromPath('profile_image', image!.path),
      );
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        jsonDecode(data);
        if (selectedWorkoutLevelId != null) {
          await userStore.setlevel(selectedWorkoutLevelId.toString());
        }
        if (selectedGoalId != null) {
          await userStore.setGoal(selectedGoalId.toString());
        }
        if (selectedWorkoutModeId != null) {
          await userStore.setWorkoutLoc(selectedWorkoutModeId.toString());
          await setValue(WORKOUT_MODE, selectedWorkoutModeId);
        }
        await userStore.setWorkoutDaysNo(selectedWorkoutDays);
        await userStore.setWorkoutDays(
          defaultWorkoutDaysForCount(selectedWorkoutDays),
        );
        await _loadLatestProfileDetails();

        await graphsave();
        _syncFormFromStore();

        appStore.setLoading(false);
        if (!mounted) return;
        setState(() {
          image = null;
        });
        toast("Profile updated successfully");
        Navigator.of(context).pop(true);
      },
      onError: (error) {
        toast(_extractApiErrorMessage(error.toString()));
        appStore.setLoading(false);
      },
    );
  }

  String _extractApiErrorMessage(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final allMessage = decoded['all_message'];
        if (allMessage is Map<String, dynamic>) {
          final phoneErrors = allMessage['phone_number'];
          if (phoneErrors is List && phoneErrors.isNotEmpty) {
            return phoneErrors.first.toString();
          }
        }
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {}
    return raw;
  }

  Future<void> graphsave({String? id}) async {
    try {
      Map<String, dynamic> req;

      double weightInPounds = userStore.weight.toDouble();
      double weightInKg = poundsToKilograms(weightInPounds);

      if (userStore.weightUnit.toLowerCase() == 'lbs') {
        req = {
          "id": userStore.weightId,
          "value": "${weightInKg.toStringAsFixed(2)} user",
          "type": "weight",
          "unit": "kg",
          "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        };
      } else {
        req = {
          "id": userStore.weightId,
          "value": "${userStore.weight} user",
          "type": "weight",
          "unit": "kg",
          "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        };
      }

      final saveRes = await setProgressApi(req);

      // 🔥 SAFE FETCH
      final progressRes = await getProgressApi(METRICS_WEIGHT);

      if (progressRes == null) {
        print("⚠️ getProgressApi skipped");
        return;
      }

      progressRes.data?.forEach((data) {
        userStore.setWeightId(data.id.toString());
        userStore.setWeightGraph(data.value ?? '');
      });
    } catch (e) {
      print("❌ graphsave error: $e");
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mHeightOption(String? value, int? index) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(6),
          backgroundColor: mHeight == index
              ? primaryColor
              : appStore.isDarkMode
                  ? context.cardColor
                  : GreyLightColor),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(value.toString(),
          style: secondaryTextStyle(
              color: mHeight == index ? Colors.white : textColor)),
    ).onTap(() {
      mHeight = index;
      hideKeyboard(context);
      if (index == 1) {
        if (!isFeetClicked) {
          convertFeetToCm();
          isFeetClicked = true;
          isCMClicked = false;
        }
      } else {
        if (!isCMClicked) {
          convertCMToFeet();
          isCMClicked = true;
          isFeetClicked = false;
        }
      }
      setState(() {});
    });
  }

  WeightType weightType =
      userStore.weightUnit == 'kg' ? WeightType.lb : WeightType.kg;

  double weight = 0;

  //Convert Feet to Cm
  void convertFeetToCm() {
    double a = double.parse(mHeightCont.text.isEmptyOrNull
            ? "0.0"
            : mHeightCont.text.validate()) *
        30.48;
    if (!mHeightCont.text.isEmptyOrNull) {
      mHeightCont.text = a.toStringAsFixed(2).toString();
    }
    mHeightCont.selection = TextSelection.fromPosition(
        TextPosition(offset: mHeightCont.text.length));
    print(a.toStringAsFixed(2).toString());
  }

  //Convert CM to Feet
  void convertCMToFeet() {
    double a = double.parse(mHeightCont.text.isEmptyOrNull
            ? "0.0"
            : mHeightCont.text.validate()) *
        0.0328;
    if (!mHeightCont.text.isEmptyOrNull) {
      mHeightCont.text = a.toStringAsFixed(2).toString();
    }
    mHeightCont.selection = TextSelection.fromPosition(
        TextPosition(offset: mHeightCont.text.length));
    print(a.toStringAsFixed(2).toString());
  }

  Widget mWeightOption(String? value, int? index) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(6),
        backgroundColor: mWeight == index
            ? primaryColor
            : appStore.isDarkMode
                ? Colors.black
                : const Color(0xffD9D9D9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(value!,
          style: secondaryTextStyle(
              color: mWeight == index ? Colors.white : textColor)),
    ).onTap(() {
      mWeight = index;
      hideKeyboard(context);
      if (index == 0) {
        if (!isLBSClicked) {
          convertKgToLbs();
          isLBSClicked = true;
          isKGClicked = false;
        }
      } else {
        if (!isKGClicked) {
          convertLbsToKg();
          isKGClicked = true;
          isLBSClicked = false;
        }
      }
      setState(() {});
    });
  }

  //Convert lbs to kg
  void convertLbsToKg() {
    double a = double.parse(mWeightCont.text.isEmptyOrNull
            ? "0.0"
            : mWeightCont.text.validate()) *
        0.45359237;
    if (!mWeightCont.text.isEmptyOrNull) {
      mWeightCont.text = a.toStringAsFixed(2).toString();
    }
    mWeightCont.selection = TextSelection.fromPosition(
        TextPosition(offset: mWeightCont.text.length));
  }

  void convertKgToLbs() {
    double a = double.parse(mWeightCont.text.isEmptyOrNull
            ? "0.0"
            : mWeightCont.text.validate()) *
        2.2046;
    if (!mWeightCont.text.isEmptyOrNull) {
      mWeightCont.text = a.toStringAsFixed(2).toString();
    }
    mWeightCont.selection = TextSelection.fromPosition(
        TextPosition(offset: mWeightCont.text.length));
  }

  Future getImage() async {
    image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 100);
    setState(() {});
  }

  Widget profileImage() {
    return Observer(
      builder: (_) {
        /// If user selected new image (local preview)
        if (image != null) {
          return Container(
            padding: const EdgeInsets.all(1),
            decoration: boxDecorationWithRoundedCorners(
              boxShape: BoxShape.circle,
              border:
                  Border.all(width: 2, color: primaryColor.withOpacity(0.5)),
            ),
            child: Image.file(
              File(image!.path),
              height: 90,
              width: 90,
              fit: BoxFit.cover,
            ).cornerRadiusWithClipRRect(65),
          );
        }

        /// If image exists from API / Store
        if (!userStore.profileImage.isEmptyOrNull) {
          return Container(
            padding: const EdgeInsets.all(1),
            decoration: boxDecorationWithRoundedCorners(
              boxShape: BoxShape.circle,
              border:
                  Border.all(width: 2, color: primaryColor.withOpacity(0.5)),
            ),
            child: cachedImage(
              userStore.profileImage,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ).cornerRadiusWithClipRRect(65),
          );
        }

        /// Default placeholder
        return Container(
          padding: const EdgeInsets.all(1),
          decoration: boxDecorationWithRoundedCorners(
            boxShape: BoxShape.circle,
            border: Border.all(width: 2, color: primaryColor.withOpacity(0.5)),
          ),
          child: const CircleAvatar(
            maxRadius: 60,
            backgroundColor: Colors.black,
            backgroundImage: AssetImage(ic_logo),
          ),
        );
      },
    );
  }

  int mSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
                child: Stack(
              children: [
                Container(height: context.height() * 0.4, color: primaryColor),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                              appStore.selectedLanguageCode == 'ar'
                                  ? MaterialIcons.arrow_forward_ios
                                  : Octicons.chevron_left,
                              color: white,
                              size: 28)
                          .onTap(() {
                        Navigator.pop(context);
                      }),
                      16.width,
                      Text(languages.lblEditProfile,
                          style: boldTextStyle(size: 20, color: white)),
                    ],
                  ).paddingOnly(
                      top: context.statusBarHeight + 16,
                      left: 16,
                      right: appStore.selectedLanguageCode == 'ar' ? 16 : 0),
                ),
                Container(
                  margin: EdgeInsets.only(top: context.height() * 0.2),
                  height: context.height() * 0.4,
                  decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radiusOnly(topRight: 16, topLeft: 16),
                      backgroundColor: theme.scaffoldBackgroundColor),
                ),
                Column(children: [
                  16.height,
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      profileImage(),
                      Container(
                              decoration: boxDecorationWithRoundedCorners(
                                  boxShape: BoxShape.circle,
                                  backgroundColor: primaryOpacity),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(ic_camera,
                                  color: primaryColor, height: 20, width: 20))
                          .onTap(() {
                        getImage();
                      }) /*.visible(!getBoolAsync(IS_SOCIAL))*/
                    ],
                  ).paddingOnly(top: context.height() * 0.11).center(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.height,
                      Text(languages.lblFirstName, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mFNameCont,
                        textFieldType: TextFieldType.NAME,
                        isValidationRequired: true,
                        focus: mFNameFocus,
                        nextFocus: mLNameFocus,
                        // suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context,
                            label: languages.lblEnterFirstName),
                      ),
                      16.height,
                      Text(languages.lblLastName, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mLNameCont,
                        textFieldType: TextFieldType.NAME,
                        isValidationRequired: true,
                        focus: mLNameFocus,
                        nextFocus: mMobileNumberFocus,
                        // suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context,
                            label: languages.lblEnterLastName),
                      ),
                      16.height,
                      Text(languages.lblEmail, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mEmailCont,
                        textFieldType: TextFieldType.EMAIL,
                        isValidationRequired: true,
                        focus: mEmailFocus,
                        readOnly: false,
                        nextFocus: mMobileNumberFocus,
                        // suffix: mSuffixTextFieldIconWidget(ic_mail),
                        decoration: defaultInputDecoration(context,
                            label: languages.lblEnterEmail),
                      ),
                      16.height,
                      Text(languages.lblPhoneNumber,
                          style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        controller: mMobileNumberCont,
                        textFieldType: TextFieldType.PHONE,
                        isValidationRequired: true,
                        focus: mMobileNumberFocus,
                        readOnly: false,
                        //  readOnly: getBoolAsync(IS_OTP) != true ? false : true,
                        nextFocus: mAgeFocus,
                        // suffix: mSuffixTextFieldIconWidget(ic_call),
                        decoration: defaultInputDecoration(
                          context,
                          label: languages.lblEnterPhoneNumber,
                          /* mPrefix: IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CountryCodePicker(
                                    initialSelection: getStringAsync(COUNTRY_CODE, defaultValue: countryCode!),
                                    showCountryOnly: false,
                                    showFlag: false,
                                    boxDecoration: BoxDecoration(borderRadius: radius(defaultRadius), color: appStore.isDarkMode ? context.cardColor : GreyLightColor),
                                    showFlagDialog: true,
                                    showOnlyCountryWhenClosed: false,
                                    alignLeft: false,
                                    dialogTextStyle: TextStyle(
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    searchStyle: TextStyle(
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    textStyle: primaryTextStyle(),
                                    onInit: (c) {
                                      countryCode = c!.code;
                                    },
                                    onChanged: (c) {
                                      countryCode = c.code;
                                    },
                                  ),
                                  VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                                  16.width,
                                ],
                              ),
                            )*/
                        ),
                      ),
                      16.height,
                      Text(languages.lblAge, style: secondaryTextStyle()),
                      4.height,
                      AppTextField(
                        readOnly: true,
                        onTap: () {
                          _openAgePickerBottomSheet(context);
                        },
                        controller: mAgeCont,
                        textFieldType: TextFieldType.NUMBER,
                        isValidationRequired: true,
                        focus: mAgeFocus,
                        nextFocus: mWeightFocus,
                        keyboardType: TextInputType.number,
                        /*  inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[ ]')), // Block space
                          FilteringTextInputFormatter.deny(RegExp(r'[!@#\$%^&*(),.?":{}|<>-]')), // Block special characters
                        ],*/
                        // suffix: mSuffixTextFieldIconWidget(ic_user),
                        decoration: defaultInputDecoration(context,
                            label: languages.lblEnterAge),
                      ),
                      16.height,
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(languages.lblWeight,
                                style: secondaryTextStyle()),
                            4.height,
                            AppTextField(
                              readOnly: true,
                              onTap: () {
                                _openWightPickerBottomSheet(context);
                              },
                              controller: mWeightCont,
                              textFieldType: TextFieldType.NUMBER,
                              focus: mWeightFocus,
                              nextFocus: mHeightFocus,
                              decoration: defaultInputDecoration(context,
                                  label: languages.lblEnterWeight),
                            ),
                            16.height,
                            Text(languages.lblHeight,
                                style: secondaryTextStyle()),
                            4.height,
                            AppTextField(
                              readOnly: true,
                              onTap: () {
                                CustomeHeightPicker(
                                  heightSelected: (val) {
                                    mHeightCont.text =
                                        "$val ${userStore.heightUnit.validate()}";
                                  },
                                ).launch(context);
                              },
                              controller: mHeightCont,
                              textFieldType: TextFieldType.NUMBER,
                              // keyboardType: TextInputType.number,
                              focus: mHeightFocus,
                              decoration: defaultInputDecoration(context,
                                  label: languages.lblEnterHeight),
                            ),
                          ],
                        ),
                      ),
                      16.height,
                      Text(languages.lblGender, style: secondaryTextStyle()),
                      4.height,
                      DropdownButtonFormField<GenderModel>(
                        items: GenderList.map((e) {
                          return DropdownMenuItem<GenderModel>(
                            value: e,
                            child: Text(
                                e.name.validate().capitalizeFirstLetter(),
                                style: primaryTextStyle()),
                          );
                        }).toList(),
                        isExpanded: false,
                        initialValue: GenderList.isNotEmpty
                            ? GenderList[selectGender]
                            : null,
                        isDense: true,
                        borderRadius: radius(),
                        decoration: defaultInputDecoration(context),
                        onChanged: (GenderModel? value) {
                          setState(() {
                            mGender = value!.key.toString();
                          });
                        },
                      ),
                      16.height,
                      Text(languages.lblWorkoutLevel,
                          style: secondaryTextStyle()),
                      4.height,
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        isDense: true,
                        borderRadius: radius(),
                        initialValue: selectedWorkoutLevelId,
                        decoration: defaultInputDecoration(context),
                        hint: Text(languages.lblWorkoutLevel,
                            style: primaryTextStyle()),
                        items: _filteredLevelList().map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.title.validate(),
                                style: primaryTextStyle()),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          setState(() {
                            selectedWorkoutLevelId = value;
                          });
                        },
                      ),
                      24.height,
                      Text("What's Your Goal?", style: boldTextStyle(size: 20)),
                      12.height,
                      _buildGoalSelector(),
                      24.height,
                      Text(
                        "Where Do You Workout ?",
                        style: boldTextStyle(size: 20, color: cs.onSurface),
                      ),
                      12.height,
                      _buildWorkoutModeSelector(),
                      24.height,
                      Text(
                        "How Many Days Can You Workout?",
                        style: boldTextStyle(size: 20, color: cs.onSurface),
                      ),
                      12.height,
                      _buildWorkoutDaysSelector(),
                      24.height,
                      AppButton(
                          text: languages.lblSave,
                          width: context.width(),
                          color: primaryColor,
                          onTap: () {
                            if (selectedGoalId == null) {
                              toast("Please select a goal");
                              return;
                            }
                            if (selectedWorkoutModeId == null) {
                              toast("Please select workout mode");
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              save();
                            }
                          }),
                      24.height,
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ])
              ],
            )),
            Observer(
              builder: (context) {
                return Loader().center().visible(appStore.isLoading);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSelector() {
    if (mGoalList.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: primaryColor),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: List.generate(mGoalList.length, (index) {
        final item = mGoalList[index];
        final bool selected = item.id == selectedGoalId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                selectedGoalId = item.id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? primaryColor.withOpacity(0.12)
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02)),
                border: Border.all(
                  color: selected
                      ? primaryColor
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _goalAsset(item.title).toLowerCase().endsWith(
                                '.json',
                              )
                          ? Lottie.asset(
                              _goalAsset(item.title),
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              _goalAsset(item.title),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  20.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.validate(),
                          style: boldTextStyle(
                            size: 18,
                            color: selected ? primaryColor : cs.onSurface,
                          ),
                        ),
                        4.height,
                        Text(
                          _goalDescription(item.title),
                          style: secondaryTextStyle(
                            size: 16,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: primaryColor, size: 26),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWorkoutModeSelector() {
    if (mWorkoutModeList.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: primaryColor),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final List<WorkoutTypeModel> viewModes = mWorkoutModeList.take(2).toList();

    return Row(
      children: List.generate(viewModes.length, (index) {
        final mode = viewModes[index];
        final bool selected = mode.id == selectedWorkoutModeId;
        final bool isHome =
            mode.title.validate().toLowerCase().contains('home');
        final String imagePath = isHome ? 'assets/home.png' : 'assets/gym.png';

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: index == 0 && viewModes.length > 1 ? 12 : 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  selectedWorkoutModeId = mode.id;
                  _ensureValidSelectedWorkoutLevel();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 155,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? primaryColor
                        : cs.onSurface.withOpacity(0.14),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(selected ? 0.32 : 0.40),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          mode.title.validate(),
                          style: boldTextStyle(
                            size: 18,
                            color: Colors.white,
                          ).copyWith(
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWorkoutDaysSelector() {
    final List<int> workoutOptions = [3, 6];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Wrap(
        spacing: 18,
        children: List.generate(workoutOptions.length, (index) {
          final int day = workoutOptions[index];
          final bool selected = selectedWorkoutDays == day;

          return GestureDetector(
            onTap: () {
              setState(() => selectedWorkoutDays = day);
            },
            child: Container(
              height: 90,
              width: 100,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary
                    : (isDark ? cs.surface : cs.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? cs.primary : cs.onSurface.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openWightPickerBottomSheet(BuildContext context) async {
    final res = await showModalBottomSheet<Tuple2<WeightType, double>>(
      context: context,
      isDismissible: false,
      elevation: 0,
      enableDrag: false,
      transitionAnimationController: AnimationController(
          vsync: this, duration: const Duration(milliseconds: 0)),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color:
                  appStore.isDarkMode ? Colors.black : const Color(0xffD9D9D9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            height: 250,
            child: Column(
              children: [
                Header(
                  weightType: weightType,
                  inKg: weight,
                ),
                Switcher(
                  weightType: weightType,
                  onChanged: (type) {
                    /*  Navigator.pop(context);
                    _openWightPickerBottomSheet(context);
                    setState(() => weightType = type);*/
                    weightType = type;
                    if (type.name == languages.lblKg && weight > 200) {
                      weight = 200;
                    } else if (type.name != languages.lblKg && weight > 400) {
                      weight = 400;
                    }
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: DivisionSlider(
                    key: ValueKey(weightType.name),
                    from: weightType.name == languages.lblKg ? 40 : 90,
                    max: weightType.name == "KG" ? 200 : 400,
                    initialValue: userStore.weight.toDouble(),
                    type: weightType,
                    onChanged: (value) {
                      setState(() => weight = value);
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
    if (res != null) {
      setState(() {
        mWeightCont.text =
            "${res.item2.toString()}  ${res.item1.name.toString().toLowerCase()}";
        userStore.setWeightUnit(res.item1.name.toString().toLowerCase());
        weightType = res.item1;
        weight = res.item2;
        print("-----------768>>>$weightType");
        print("-----------769>>>$weight");
      });
    }
  }

  void _openAgePickerBottomSheet(BuildContext context) async {
    final res = await showModalBottomSheet<Tuple2<WeightType, double>>(
      context: context,
      isDismissible: false,
      elevation: 0,
      transitionAnimationController: AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500)),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? scaffoldColorDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          height: 300,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: appStore.isDarkMode
                      ? Colors.black
                      : const Color(0xffD9D9D9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        color: appStore.isDarkMode
                            ? const Color(0xffD9D9D9)
                            : Colors.black,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                      Text(languages.lblAge,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: appStore.isDarkMode
                                  ? const Color(0xffD9D9D9)
                                  : Colors.black)),
                      IconButton(
                        color: appStore.isDarkMode
                            ? const Color(0xffD9D9D9)
                            : Colors.black,
                        onPressed: () {
                          mAgeCont.text = mSelectedIndex.toString();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CupertinoPicker(
                      magnification: 1.4,
                      squeeze: 0.8,
                      useMagnifier: true,
                      selectionOverlay: const SizedBox(),
                      itemExtent: 32.0,
                      scrollController: FixedExtentScrollController(
                          initialItem: userStore.age.validate().toInt() - 17),
                      onSelectedItemChanged: (int selectedItem) {
                        setState(() {
                          mSelectedIndex = selectedItem + 17;
                        });
                      },
                      children: List<Widget>.generate(99 - 17 + 1, (int index) {
                        int actualIndex = index + 17;
                        return Text(actualIndex.toString(),
                                style: boldTextStyle(size: 30))
                            .center();
                      }),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: 2, width: 100, color: primaryColor),
                        50.height,
                        Container(height: 2, width: 100, color: primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    /* if (res != null) {
      setState(() {
        mWeightCont.text = "${res.item2.toString()}  ${res.item1.name.toString().toLowerCase()}";
        userStore.setWeightUnit(res.item1.name.toString().toLowerCase());
        weightType = res.item1;
        weight = res.item2;
      });
    }*/
  }
}
