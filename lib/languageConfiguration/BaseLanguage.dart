import 'package:flutter/material.dart';

import 'LanguageDataConstant.dart';

class BaseLanguage {
  static BaseLanguage? of(BuildContext context) {
    try {
      return Localizations.of<BaseLanguage>(context, BaseLanguage);
    } catch (e) {
      throw e;
    }
  }

  String get lblGetStarted => getContentValueFromKey(4);
  String get lblNext => getContentValueFromKey(5);
  String get lblWelcomeBack => getContentValueFromKey(8);
  String get lblWelcomeBackDesc => getContentValueFromKey(9);
  String get lblLogin => getContentValueFromKey(7);
  String get lblEmail => getContentValueFromKey(10);
  String get lblEnterEmail => getContentValueFromKey(11);
  String get lblPassword => getContentValueFromKey(12);
  String get lblEnterPassword => getContentValueFromKey(13);
  String get lblRememberMe => getContentValueFromKey(14);
  String get lblForgotPassword => getContentValueFromKey(15);
  String get lblNewUser => getContentValueFromKey(17);
  String get lblHome => getContentValueFromKey(46);
  String get lblDiet => getContentValueFromKey(47);
  String get lblReport => getContentValueFromKey(232);
  String get lblProfile => getContentValueFromKey(49);
  String get lblAboutUs => getContentValueFromKey(120);
  String get lblBlog => getContentValueFromKey(110);
  String get lblChangePassword => getContentValueFromKey(128);
  String get lblEnterCurrentPwd => getContentValueFromKey(134);
  String get lblEnterNewPwd => getContentValueFromKey(137);
  String get lblCurrentPassword => getContentValueFromKey(133);
  String get lblNewPassword => getContentValueFromKey(135);
  String get lblConfirmPassword => getContentValueFromKey(27);
  String get lblEnterConfirmPwd => getContentValueFromKey(28);
  String get errorPwdLength => getContentValueFromKey(29);
  String get errorPwdMatch => getContentValueFromKey(30);
  String get lblSubmit => getContentValueFromKey(139);
  String get lblEditProfile => getContentValueFromKey(58);
  String get lblFirstName => getContentValueFromKey(21);
  String get lblEnterFirstName => getContentValueFromKey(22);
  String get lblEnterLastName => getContentValueFromKey(24);
  String get lblLastName => getContentValueFromKey(23);
  String get lblPhoneNumber => getContentValueFromKey(25);
  String get lblEnterPhoneNumber => getContentValueFromKey(26);
  String get lblEnterAge => getContentValueFromKey(60);
  String get lblAge => getContentValueFromKey(59);
  String get lblWeight => getContentValueFromKey(37);
  String get lblLbs => getContentValueFromKey(42);
  String get lblKg => getContentValueFromKey(43);
  String get lblEnterWeight => getContentValueFromKey(38);
  String get lblHeight => getContentValueFromKey(39);
  String get lblFeet => getContentValueFromKey(45);
  String get lblCm => getContentValueFromKey(44);
  String get lblEnterHeight => getContentValueFromKey(40);
  String get lblGender => getContentValueFromKey(61);
  String get lblSave => getContentValueFromKey(62);
  String get lblForgotPwdMsg => getContentValueFromKey(200);
  String get lblContinue => getContentValueFromKey(233);
  String get lblSelectLanguage => getContentValueFromKey(126);
  String get lblNoInternet => getContentValueFromKey(181);
  String get lblContinueWithPhone => getContentValueFromKey(190);
  String get lblRcvCode => getContentValueFromKey(191);
  String get lblYear => getContentValueFromKey(73);
  String get lblFavourite => getContentValueFromKey(234);
  String get lblSelectTheme => getContentValueFromKey(132);
  String get lblDeleteAccount => getContentValueFromKey(109);
  String get lblPrivacyPolicy => getContentValueFromKey(118);
  String get lblLogout => getContentValueFromKey(116);
  String get lblLogoutMsg => getContentValueFromKey(117);
  String get lblVerifyOTP => getContentValueFromKey(192);
  String get lblVerifyProceed => getContentValueFromKey(193);
  String get lblCode => getContentValueFromKey(194);
  String get lblTellUsAboutYourself => getContentValueFromKey(20);
  String get lblAlreadyAccount => getContentValueFromKey(31);
  String get lblWhtGender => getContentValueFromKey(32);
  String get lblMale => getContentValueFromKey(33);
  String get lblFemale => getContentValueFromKey(34);
  String get lblHowOld => getContentValueFromKey(35);
  String get lblLetUsKnowBetter => getContentValueFromKey(36);
  String get lblLight => getContentValueFromKey(129);
  String get lblDark => getContentValueFromKey(130);
  String get lblSystemDefault => getContentValueFromKey(131);
  String get lblStore => getContentValueFromKey(235);
  String get lblPlan => getContentValueFromKey(113);
  String get lblAboutApp => getContentValueFromKey(115);
  String get lblPasswordMsg => getContentValueFromKey(136);
  String get lblDelete => getContentValueFromKey(106);
  String get lblCancel => getContentValueFromKey(236);
  String get lblSettings => getContentValueFromKey(114);
  String get lblHeartRate => getContentValueFromKey(101);
  String get lblMonthly => getContentValueFromKey(195);
  String get lblNoFoundData => getContentValueFromKey(68);
  String get lblTermsOfServices => getContentValueFromKey(119);
  String get lblFollowUs => getContentValueFromKey(124);
  String get lblWorkouts => getContentValueFromKey(56);
  String get lblChatConfirmMsg => getContentValueFromKey(143);
  String get lblYes => getContentValueFromKey(144);
  String get lblNo => getContentValueFromKey(145);
  String get lblClearConversion => getContentValueFromKey(147);
  String get lblChatHintText => getContentValueFromKey(148);
  String get lblTapBackAgainToLeave => getContentValueFromKey(50);
  String get lblPro => getContentValueFromKey(237);
  String get lblCalories => getContentValueFromKey(173);
  String get lblCarbs => getContentValueFromKey(174);
  String get lblFat => getContentValueFromKey(175);
  String get lblProtein => getContentValueFromKey(176);
  String get lblKcal => getContentValueFromKey(178);
  String get lblIngredients => getContentValueFromKey(179);
  String get lblInstruction => getContentValueFromKey(180);
  String get lblStartExercise => getContentValueFromKey(85);
  String get lblDuration => getContentValueFromKey(69);
  String get lblBodyParts => getContentValueFromKey(86);
  String get lblEquipments => getContentValueFromKey(87);
  String get lblHomeWelMsg => getContentValueFromKey(52);
  String get lblBodyPartExercise => getContentValueFromKey(54);
  String get lblEquipmentsExercise => getContentValueFromKey(55);
  String get lblLevels => getContentValueFromKey(57);
  String get lblBuyNow => getContentValueFromKey(201);
  String get lblSearchExercise => getContentValueFromKey(65);
  String get lblAll => getContentValueFromKey(67);
  String get lblTips => getContentValueFromKey(202);
  String get lblDietCategories => getContentValueFromKey(94);
  String get lblSkip => getContentValueFromKey(6);
  String get lblWorkoutType => getContentValueFromKey(92);
  String get lblLevel => getContentValueFromKey(238);
  String get lblBmi => getContentValueFromKey(203);
  String get lblCopiedToClipboard => getContentValueFromKey(149);
  String get lblFullBodyWorkout => getContentValueFromKey(204);
  String get lblTypes => getContentValueFromKey(205);
  String get lblClearAll => getContentValueFromKey(206);
  String get lblSelectAll => getContentValueFromKey(207);
  String get lblShowResult => getContentValueFromKey(208);
  String get lblSelectLevels => getContentValueFromKey(209);
  String get lblUpdate => getContentValueFromKey(103);
  String get lblSteps => getContentValueFromKey(239);
  String get lblPackageTitle => getContentValueFromKey(70);
  String get lblPackageTitle1 => getContentValueFromKey(71);
  String get lblSubscriptionPlans => getContentValueFromKey(76);
  String get lblSubscribe => getContentValueFromKey(74);
  String get lblActive => getContentValueFromKey(77);
  String get lblHistory => getContentValueFromKey(78);
  String get lblSubscriptionMsg => getContentValueFromKey(79);
  String get lblCancelSubscription => getContentValueFromKey(82);
  String get lblViewPlans => getContentValueFromKey(80);
  String get lblHey => getContentValueFromKey(51);
  String get lblRepeat => getContentValueFromKey(210);
  String get lblEveryday => getContentValueFromKey(211);
  String get lblReminderName => getContentValueFromKey(212);
  String get lblDescription => getContentValueFromKey(213);
  String get lblSearch => getContentValueFromKey(53);
  String get lblTopFitnessReads => getContentValueFromKey(121);
  String get lblTrendingBlogs => getContentValueFromKey(122);
  String get lblBestDietDiscoveries => getContentValueFromKey(95);
  String get lblDietaryOptions => getContentValueFromKey(96);
  String get lblFav => getContentValueFromKey(214);


  String get lblBreak=> getContentValueFromKey(100);

  String get lblProductCategory=> getContentValueFromKey(98);

  String get lblProductList=> getContentValueFromKey(99);

  String get lblTipsInst=> getContentValueFromKey(215);

  String get lblContactAdmin=> getContentValueFromKey(19);

  String get lblOr=> getContentValueFromKey(16);

  String get lblRegisterNow=> getContentValueFromKey(18);

  String get lblDailyReminders=> getContentValueFromKey(112);

  String get lblPayments=> getContentValueFromKey(91);

  String get lblPay=> getContentValueFromKey(92);

  String get lblAppThemes=> getContentValueFromKey(127);

  String get lblTotalSteps=> getContentValueFromKey(142);

  String get lblDate=> getContentValueFromKey(105);

  String get lblDeleteAccountMSg=> getContentValueFromKey(107);

  String get lblHint=> getContentValueFromKey(104);

  String get lblAdd=> getContentValueFromKey(216);

  String get lblNotifications=> getContentValueFromKey(63);

  String get lblNotificationEmpty=> getContentValueFromKey(64);

  String get lblQue1=> getContentValueFromKey(150);

  String get lblQue2=> getContentValueFromKey(151);

  String get lblQue3=> getContentValueFromKey(152);

  String get lblFitBot=> getContentValueFromKey(146);

  String get lblG=> getContentValueFromKey(153);

  String get lblEnterText=> getContentValueFromKey(217);

  String get lblYourPlanValid=> getContentValueFromKey(81);

  String get lblTo=> getContentValueFromKey(83);

  String get lblSets=> getContentValueFromKey(218);

  String get lblSuccessMsg=> getContentValueFromKey(89);

  String get lblPaymentFailed=> getContentValueFromKey(90);

  String get lblSuccess=> getContentValueFromKey(88);

  String get lblDone=> getContentValueFromKey(41);

  String get lblWorkoutLevel=> getContentValueFromKey(93);

  String get lblReps=> getContentValueFromKey(219);

  String get lblSecond=> getContentValueFromKey(220);

  String get lblFavoriteWorkoutAndNutristions=> getContentValueFromKey(111);

  String get lblShop=> getContentValueFromKey(48);

  String get lblDeleteMsg=> getContentValueFromKey(108);

  String get lblSelectPlanToContinue=> getContentValueFromKey(75);

  String get lblResultNoFound=> getContentValueFromKey(97);

  String get lblExerciseNoFound=> getContentValueFromKey(66);

  String get lblBlogNoFound=> getContentValueFromKey(123);

  String get lblWorkoutNoFound=> getContentValueFromKey(221);

  String get lblTenSecondRemaining=> getContentValueFromKey(222);

  String get lblThree=> getContentValueFromKey(223);

  String get lblTwo=> getContentValueFromKey(224);

  String get lblOne=> getContentValueFromKey(225);

  String get lblExerciseDone=> getContentValueFromKey(240);

  String get lblMonth=> getContentValueFromKey(72);

  String get lblDay=> getContentValueFromKey(241);

  String get lblPushUp=> getContentValueFromKey(102);

  String get lblEnterReminderName=> getContentValueFromKey(226);

  String get lblEnterDescription=> getContentValueFromKey(227);

  String get lblMetricsSettings=> getContentValueFromKey(125);

  String get lblIdealWeight=> getContentValueFromKey(140);

  String get lblBmr=> getContentValueFromKey(141);

  String get lblErrorThisFiledIsRequired=> getContentValueFromKey(228);

  String get lblSomethingWentWrong=> getContentValueFromKey(229);

  String get lblErrorInternetNotAvailable=> getContentValueFromKey(230);

  String get lblErrorNotAllow=> getContentValueFromKey(170);

  String get lblPleaseTryAgain=> getContentValueFromKey(171);

  String get lblInvalidUrl=> getContentValueFromKey(172);

  String get lblUsernameShouldNotContainSpace=> getContentValueFromKey(165);

  String get lblMinimumPasswordLengthShouldBe=> getContentValueFromKey(166);

  String get lblInternetIsConnected=> getContentValueFromKey(167);

  String get lblNoSetsMsg=> getContentValueFromKey(84);

  String get lblNoDurationMsg=> getContentValueFromKey(168);

  String get lblWalkTitle1=> getContentValueFromKey(1);

  String get lblWalkTitle2=> getContentValueFromKey(2);

  String get lblWalkTitle3=> getContentValueFromKey(3);

  String get lblEmailIsInvalid=> getContentValueFromKey(231);

  String get lblMainGoal=> getContentValueFromKey(154);

  String get lblHowExperienced=> getContentValueFromKey(155);

  String get lblHoweEquipment=> getContentValueFromKey(157);

  String get lblHoweOftenWorkout=> getContentValueFromKey(158);

  String get lblFinish=> getContentValueFromKey(245);

  String get lblProgression=> getContentValueFromKey(160);

  String get lblEasyHabit=> getContentValueFromKey(161);

  String get lblRecommend=> getContentValueFromKey(162);

  String get lblTimesWeek=> getContentValueFromKey(163);

  String get lblOnlyTimesWeek=> getContentValueFromKey(164);

  String get lblSchedule=> getContentValueFromKey(242);
  String get lblChangeView=> getContentValueFromKey(243);
  String get lblJoin=> getContentValueFromKey(244);
  String get lblUpdateNow=> getContentValueFromKey(246);
  String get lblUpdateAvailable => getContentValueFromKey(247);
  String get lblUpdateNote => getContentValueFromKey(248);


}
