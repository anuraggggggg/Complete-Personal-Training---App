import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_fitness/extensions/LiveStream.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

import '../components/HtmlWidget.dart';
import '../extensions/animatedList/animated_list_view.dart';
import '../extensions/app_button.dart';
import '../extensions/colors.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/loader_widget.dart';
import '../extensions/system_utils.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/user_response.dart';
import '../models/subscription_response.dart';
import '../network/rest_api.dart';
import '../screens/payment_screen.dart';
import '../screens/shop_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';

class SubscribeScreen extends StatefulWidget {
  SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  ScrollController scrollController = ScrollController();

  List<SubscriptionModel> mSubscriptionListNew = [];
  String mSubscriptionDataGet = '';

  int page = 1;
  int? numPage;
  int? currentIndex = 0;

  bool isLastPage = false;
  CompanyAccessResponse? companyAccessStatus;
  bool isCheckingCompanyAccess = false;
  bool isClaimingCompanyAccess = false;

  @override
  void initState() {
    super.initState();
    checkCompanyAccessStatus();
    if (Platform.isIOS) return;
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !appStore.isLoading) {
        if (page < numPage!) {
          page++;
          init();
        }
      }
    });
  }

  void init() async {
    getPackageData();
  }

  Future<void> getPackageData() async {
    appStore.setLoading(true);
    getSubscription().then((value) {
      appStore.setLoading(false);
      numPage = value.pagination!.totalPages;
      isLastPage = false;
      if (page == 1) {
        mSubscriptionListNew.clear();
      }
      Iterable it = value.data!;
      it.map((e) => mSubscriptionListNew.add(e)).toList();
      setState(() {});
    }).catchError((e) {
      isLastPage = true;
      appStore.setLoading(false);
    });
  }

  Future<void> checkCompanyAccessStatus() async {
    if (userStore.token.validate().isEmpty) return;

    setState(() {
      isCheckingCompanyAccess = true;
    });

    await getCompanyAccessStatusApi().then((value) async {
      companyAccessStatus = value;
      print(
        '[CompanyAccess][UI] eligible=${value.isEligible}, '
        'has_company_access=${value.hasCompanyAccess}, '
        'can_claim=${value.canClaim}',
      );
      if (value.subscriptionDetail != null) {
        await updateSubscriptionAccessState(value.subscriptionDetail!);
      }
    }).catchError((e) {
      print(e.toString());
    }).whenComplete(() {
      if (!mounted) return;
      setState(() {
        isCheckingCompanyAccess = false;
      });
    });
  }

  Future<void> claimCompanyAccess() async {
    if (isClaimingCompanyAccess) return;

    setState(() {
      isClaimingCompanyAccess = true;
    });

    await claimCompanyAccessApi().then((value) async {
      companyAccessStatus = value;
      print(
        '[CompanyAccess][UI] claim_success message=${value.message.validate()}',
      );
      final subscriptionDetail = value.subscriptionDetail;
      if (subscriptionDetail != null) {
        await updateSubscriptionAccessState(subscriptionDetail);
      }
      toast(value.message.validate().isNotEmpty
          ? value.message.validate()
          : 'Company access activated.');
      LiveStream().emit(PAYMENT);
    }).catchError((e) {
      toast(e.toString().validate().isNotEmpty
          ? e.toString()
          : 'Unable to activate company access. Please try again.');
    }).whenComplete(() async {
      await checkCompanyAccessStatus();
      if (!mounted) return;
      setState(() {
        isClaimingCompanyAccess = false;
      });
    });
  }

  Widget companyAccessWidget() {
    final subscriptionDetail =
        companyAccessStatus?.subscriptionDetail ?? userStore.subscriptionDetail;
    final isCompanyAccess =
        subscriptionDetail?.accessType.validate().toLowerCase() == 'company';
    final isCompanyActive = isCompanyAccess &&
        subscriptionDetail?.hasAccess == 1 &&
        subscriptionDetail?.isCompanyAccessActive != 0;
    final endsAtText = subscriptionDetail?.companyAccessEndsAt.validate();
    String activeSubtitle = 'Company Access is active.';

    if (isCompanyActive && endsAtText.validate().isNotEmpty) {
      final endsAt = DateTime.tryParse(endsAtText!);
      activeSubtitle = endsAt != null
          ? 'Active until ${parseDocumentDate(endsAt)}.'
          : 'Active until $endsAtText.';
    }

    if (isCompanyActive) {
      return Container(
        width: context.width(),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.all(16),
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(12),
          backgroundColor: primaryColor.withOpacity(0.08),
          border: Border.all(color: primaryColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user, color: primaryColor, size: 26),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company Access', style: boldTextStyle(size: 16)),
                4.height,
                Text(activeSubtitle, style: secondaryTextStyle()),
              ],
            ).expand(),
          ],
        ),
      );
    }

    if (companyAccessStatus?.canClaim != true) return Offstage();

    return Container(
      width: context.width(),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        border: Border.all(color: primaryColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: primaryColor, size: 24),
              10.width,
              Text('Company Access', style: boldTextStyle(size: 18)).expand(),
            ],
          ),
          6.height,
          Text('Claim 2 months free with your company access.',
              style: secondaryTextStyle()),
          14.height,
          AppButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: whiteColor,
                  size: 18,
                ),
                8.width,
                Text(
                  isClaimingCompanyAccess
                      ? 'Activating...'
                      : 'Activate Company Access',
                  style: boldTextStyle(color: whiteColor),
                ),
              ],
            ),
            width: context.width(),
            color: primaryColor,
            onTap: isClaimingCompanyAccess ? null : claimCompanyAccess,
          ),
        ],
      ),
    );
  }

  Widget overlayContainer() {
    return Container(
      height: context.height() / 2.4,
      width: context.width(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            appStore.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.transparent,
            appStore.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.3),
            appStore.isDarkMode
                ? context.scaffoldBackgroundColor
                : Colors.white,
          ],
        ),
      ),
    );
  }

  int selectedIndex = -1;

  Future<void> paymentConfirm(int? id) async {
    if (Platform.isIOS) {
      toast("Please use the App Store subscription flow on iOS.");
      return;
    }
    appStore.setLoading(true);
    Map req = {
      "package_id": id,
      "payment_status": "paid",
      "payment_type": 'free',
      "txn_id": "",
      "transaction_detail": ""
    };
    await subscribePackageApi(req).then((value) async {
      toast(value.message);
      // await getUSerDetail(context, userStore.userId).whenComplete(() {
      //   setState(() {
      //     appStore.setLoading(false);
      //     LiveStream().emit(PAYMENT);
      //     finish(context);
      //     finish(context);
      //   });
      // });
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return ShopScreen(topWidget: companyAccessWidget());
    }

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
          backgroundColor: context.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  // alignment: Alignment.topLeft,
                  children: [
                    Image.asset(Subscribe_Bg,
                        fit: BoxFit.fill,
                        height: context.height() / 2.4,
                        width: context.width()),
                    overlayContainer(),
                    Positioned(
                      left: 16,
                      bottom: 0,
                      right: appStore.selectedLanguageCode == 'ar' ? 16 : 100,
                      child: Text(languages.lblPackageTitle,
                          style: boldTextStyle(
                              size: 26, color: primaryColor, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true),
                    ),
                    Positioned(
                      top: context.statusBarHeight,
                      child: IconButton(
                        onPressed: () {
                          finish(context);
                        },
                        icon: Icon(
                            appStore.selectedLanguageCode == 'ar'
                                ? MaterialIcons.arrow_forward_ios
                                : Octicons.chevron_left,
                            color: whiteColor,
                            size: 28),
                      ),
                    ),
                  ],
                ),
                4.height,
                Text(languages.lblPackageTitle1, style: secondaryTextStyle())
                    .paddingSymmetric(horizontal: 16, vertical: 8),
                companyAccessWidget(),
                16.height,
                Loader().center().visible(appStore.isLoading),
                if (!appStore.isLoading)
                  mSubscriptionListNew.isNotEmpty
                      ? Column(
                          children: [
                            AnimatedListView(
                              itemCount: mSubscriptionListNew.length,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: appStore.selectedLanguageCode == 'ar'
                                      ? EdgeInsets.symmetric(horizontal: 16)
                                      : EdgeInsets.symmetric(horizontal: 0),
                                  decoration: boxDecorationWithRoundedCorners(
                                      borderRadius: radius(12),
                                      border: Border.all(
                                          color: selectedIndex == index
                                              ? primaryColor
                                              : context.dividerColor)),
                                  child: Column(
                                    children: [
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                    selectedIndex == index
                                                        ? ic_radio_fill
                                                        : ic_radio,
                                                    height: 20,
                                                    width: 20,
                                                    color: primaryColor),
                                                8.width,
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxWidth: 150),
                                                  child: Text(
                                                    mSubscriptionListNew[index]
                                                        .name
                                                        .validate(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        boldTextStyle(size: 18),
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                PriceWidget(
                                                  price: mSubscriptionListNew[
                                                          index]
                                                      .price
                                                      ?.toStringAsFixed(2)
                                                      .validate(),
                                                  color: primaryColor,
                                                  textStyle: boldTextStyle(
                                                      color: primaryColor,
                                                      size: 20),
                                                ),
                                                2.width,
                                                mSubscriptionListNew[index]
                                                            .durationUnit
                                                            .toString() ==
                                                        "monthly"
                                                    ? Text(
                                                        "/ " +
                                                            mSubscriptionListNew[
                                                                    index]
                                                                .duration
                                                                .toString()
                                                                .validate() +
                                                            " " +
                                                            languages.lblMonth,
                                                        style:
                                                            primaryTextStyle())
                                                    : Text(
                                                        "/ " +
                                                            mSubscriptionListNew[
                                                                    index]
                                                                .duration
                                                                .toString()
                                                                .validate() +
                                                            " " +
                                                            languages.lblYear
                                                                .capitalizeFirstLetter(),
                                                        style:
                                                            primaryTextStyle()),
                                              ],
                                            ),
                                          ]),
                                      10.height,
                                      HtmlWidget(
                                          postContent:
                                              mSubscriptionListNew[index]
                                                  .description
                                                  .validate()),
                                      8.height,
                                    ],
                                  ).paddingOnly(
                                      left: 16, right: 16, bottom: 8, top: 16),
                                ).onTap(() {
                                  setState(() {
                                    if (selectedIndex == index) {
                                      selectedIndex = -1;
                                    } else {
                                      selectedIndex = index;
                                    }
                                  });
                                });
                              },
                            ),
                            AppButton(
                              text: languages.lblSubscribe,
                              width: context.width(),
                              color: primaryColor,
                              onTap: () async {
                                print(
                                    "---------------->>>228${mSubscriptionListNew[selectedIndex].price ?? ''}");
                                selectedIndex == -1
                                    ? toast(languages.lblSelectPlanToContinue)
                                    : mSubscriptionListNew[selectedIndex]
                                                .price ==
                                            0
                                        ? paymentConfirm(
                                            mSubscriptionListNew[selectedIndex]
                                                .id)
                                        : PaymentScreen(
                                            mSubscriptionModel:
                                                mSubscriptionListNew[
                                                    selectedIndex],
                                          ).launch(context);
                              },
                            ).paddingSymmetric(horizontal: 16, vertical: 16),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(no_data_found,
                                height: context.height() * 0.2,
                                width: context.width() * 0.4),
                            16.height,
                            Text(languages.lblNoFoundData,
                                style: boldTextStyle()),
                          ],
                        ).center()
              ],
            ),
          )),
    );
  }
}
