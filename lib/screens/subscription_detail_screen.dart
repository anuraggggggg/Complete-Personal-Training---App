import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';
import '../components/HtmlWidget.dart';
import '../extensions/extension_util/num_extensions.dart';
import '../extensions/LiveStream.dart';
import '../extensions/colors.dart';
import '../extensions/common.dart';
import '../extensions/decorations.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/string_extensions.dart';
import '../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';
import '../screens/no_data_screen.dart';
import '../screens/subscribe_screen.dart';
import '../utils/app_colors.dart' hide cardDarkColor;
import '../extensions/animatedList/animated_list_view.dart';
import '../extensions/app_button.dart';
import '../extensions/constants.dart';
import '../main.dart';

import '../models/subscribePlan_response.dart';
import '../models/user_response.dart' as user_model;
import '../network/rest_api.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';
import '../utils/app_images.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionPlan? mList;

  const SubscriptionDetailScreen({super.key, this.mList});

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  List<SubscriptionPlan> mSubscriptionPlanList = [];
  String? activePlanData;
  bool select = true;

  ScrollController scrollController = ScrollController();

  int page = 1;
  int? numPage;

  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
    LiveStream().on(PAYMENT, (p0) {
      page = 1;
      init();
    });
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !appStore.isLoading) {
        if (numPage != null && page < numPage!) {
          page++;
          init();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void init() async {
    getSubscriptionList();
  }

  Future<void> getSubscriptionList() async {
    appStore.setLoading(true);
    try {
      if (userStore.userId > 0) {
        await getUSerDetail(context, userStore.userId);
      }

      final value = await getSubScriptionPlanList(page: page);
      numPage = value.pagination?.totalPages ?? page;
      isLastPage = false;
      if (page == 1) {
        mSubscriptionPlanList.clear();
      }
      mSubscriptionPlanList.addAll(value.data ?? []);

      if (mounted) setState(() {});
    } catch (e) {
      isLastPage = true;
      if (mounted) setState(() {});
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> cancelPackage({int? id}) async {
    appStore.setLoading(true);
    Map req = {
      "id":
          id != null ? id : userStore.subscriptionDetail?.subscriptionPlan?.id,
    };
    await cancelPlanApi(req).then((value) async {
      // await getUSerDetail(context, userStore.userId).whenComplete(() {
      //   userStore.isSubscribe = 0;
      //   setState(() {});
      //   toast(value.message);
      //   appStore.setLoading(false);
      //   finish(context);
      // });
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
    });
  }

  Color getTextColor(String? state) {
    switch (state) {
      case ACTIVE:
        return GreenColor;
      case INACTIVE:
        return Colors.grey;
      case CANCELLED:
        return RedColor;
      case EXPIRED:
        return YellowColor;
      default:
        return Colors.black;
    }
  }

  Color getBgColor(String? state) {
    switch (state) {
      case ACTIVE:
        return GreenColor.withOpacity(0.15);
      case INACTIVE:
        return Colors.grey.withOpacity(0.10);
      case CANCELLED:
        return RedColor.withOpacity(0.10);
      case EXPIRED:
        return YellowColor.withOpacity(0.5);
      default:
        return Colors.black;
    }
  }

  String _clean(String? value) => value?.trim() ?? '';

  String _displayText(String? value) {
    final text = _clean(value).replaceAll('_', ' ');
    return text.isEmpty ? '-' : text.capitalizeFirstLetter();
  }

  String _formatSubscriptionDate(String? value) {
    final raw = _clean(value);
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    return parsed != null ? parseDocumentDate(parsed) : raw;
  }

  bool _isInactiveSubscription(String? status) {
    final normalized = _clean(status).toLowerCase();
    return normalized == INACTIVE ||
        normalized == CANCELLED ||
        normalized == EXPIRED;
  }

  user_model.SubscriptionPlan? get _activeUserPlan {
    final plan = userStore.subscriptionDetail?.subscriptionPlan;
    if (plan == null || _isInactiveSubscription(plan.status)) return null;

    if (hasPremiumSubscriptionAccess(includeCachedAccess: false)) return plan;
    return _clean(plan.status).toLowerCase() == ACTIVE ? plan : null;
  }

  SubscriptionPlan? get _activeHistoryPlan {
    for (final plan in mSubscriptionPlanList) {
      if (_clean(plan.status).toLowerCase() == ACTIVE) return plan;
    }
    return null;
  }

  Widget _subscriptionInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: secondaryTextStyle()).expand(flex: 2),
          Text(value, style: primaryTextStyle(), textAlign: TextAlign.end)
              .expand(flex: 3),
        ],
      ),
    );
  }

  Widget _buildActivePlanCard({
    required String? packageName,
    required num? totalAmount,
    required String? planType,
    required String? paymentType,
    required String? startDate,
    required String? endDate,
    required String? status,
    required String? description,
    required VoidCallback onCancel,
  }) {
    final statusText = _displayText(status);

    return SingleChildScrollView(
      child: Column(
        children: [
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: appStore.isDarkMode
                  ? cardDarkColor
                  : GreenColor.withOpacity(0.10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(packageName.validate(), style: boldTextStyle())
                        .expand(),
                    PriceWidget(
                      price: totalAmount?.validate().toStringAsFixed(2),
                      color: primaryColor,
                      textStyle: boldTextStyle(color: primaryColor, size: 20),
                    ),
                  ],
                ),
                8.height,
                Text(
                  "${languages.lblYourPlanValid} ${_formatSubscriptionDate(startDate)} ${languages.lblTo} ${_formatSubscriptionDate(endDate)}",
                  style: primaryTextStyle(color: primaryColor, size: 12),
                ),
                8.height,
                _subscriptionInfoRow(
                    'Subscription Plan Name', packageName.validate(value: '-')),
                _subscriptionInfoRow(
                    'Plan Type',
                    _displayText(
                        _clean(planType).isNotEmpty ? planType : paymentType)),
                _subscriptionInfoRow(
                    'Start Date', _formatSubscriptionDate(startDate)),
                _subscriptionInfoRow(
                    'Expiry/Renewal Date', _formatSubscriptionDate(endDate)),
                _subscriptionInfoRow('Subscription Status', statusText),
                8.height,
                HtmlWidget(postContent: description.validate()),
                16.height,
              ],
            ),
          ),
          24.height,
          AppButton(
            text: languages.lblCancelSubscription,
            width: context.width(),
            color: primaryOpacity,
            textColor: primaryColor,
            onTap: onCancel,
          ),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }

  Widget _buildNoSubscriptionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(no_data_found,
            height: context.height() * 0.2, width: context.width() * 0.4),
        20.height,
        Text(
          languages.lblSubscriptionMsg,
          style: boldTextStyle(size: 16, color: textSecondaryColorGlobal),
        ),
        50.height,
        AppButton(
          text: languages.lblViewPlans,
          width: context.width(),
          color: primaryColor,
          onTap: () {
            SubscribeScreen()
                .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          },
        ).paddingAll(16),
      ],
    );
  }

  Widget buildSubscriptionWidget() {
    final userPlan = _activeUserPlan;
    if (userPlan != null) {
      return _buildActivePlanCard(
        packageName: userPlan.packageName,
        totalAmount: userPlan.totalAmount,
        planType: userPlan.packageType ?? userPlan.packageData?.packageType,
        paymentType: userPlan.paymentType,
        startDate: userPlan.subscriptionStartDate,
        endDate: userPlan.subscriptionEndDate,
        status: userPlan.status,
        description: userPlan.packageData?.description,
        onCancel: () => cancelPackage(),
      );
    }

    final historyPlan = _activeHistoryPlan;
    if (historyPlan != null) {
      return _buildActivePlanCard(
        packageName: historyPlan.packageName,
        totalAmount: historyPlan.totalAmount,
        planType:
            historyPlan.packageType ?? historyPlan.packageData?.packageType,
        paymentType: historyPlan.paymentType,
        startDate: historyPlan.subscriptionStartDate,
        endDate: historyPlan.subscriptionEndDate,
        status: historyPlan.status,
        description: historyPlan.packageData?.description,
        onCancel: () => cancelPackage(id: historyPlan.id),
      );
    }

    return _buildNoSubscriptionWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(languages.lblSubscriptionPlans,
          context: context,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(45),
            child: Container(
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: context.dividerColor))),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 1.5,
                                color: select
                                    ? primaryColor
                                    : Colors.transparent))),
                    child: Text(languages.lblActive,
                            style: boldTextStyle(
                                color: select
                                    ? primaryColor
                                    : textSecondaryColorGlobal))
                        .center(),
                  ).onTap(() {
                    setState(() {
                      select = !select;
                    });
                  }).expand(),
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 1.5,
                                color: select
                                    ? Colors.transparent
                                    : primaryColor))),
                    child: Text(languages.lblHistory,
                            style: boldTextStyle(
                                color: select
                                    ? textSecondaryColorGlobal
                                    : primaryColor))
                        .center(),
                  ).onTap(() {
                    setState(() {
                      select = !select;
                      print("-----167>>>${select}");
                    });
                  }).expand(),
                ],
              ).paddingSymmetric(horizontal: 16),
            ),
          )),
      body: Stack(children: [
        select
            ? /*userStore.subscriptionDetail == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(no_data_found, height: context.height() * 0.2, width: context.width() * 0.4),
                      20.height,
                      Text(languages.lblSubscriptionMsg, style: boldTextStyle(size: 16, color: textSecondaryColorGlobal)),
                      50.height,
                      AppButton(
                        text: languages.lblViewPlans,
                        width: context.width(),
                        color: primaryColor,
                        onTap: () {
                          SubscribeScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                        },
                      ).paddingAll(16)
                    ],
                  )
                : userStore.subscriptionDetail!.subscriptionPlan == null || userStore.subscriptionDetail!.subscriptionPlan!.status == "inactive"
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(no_data_found, height: context.height() * 0.2, width: context.width() * 0.4),
                          20.height,
                          Text(languages.lblSubscriptionMsg, style: boldTextStyle(size: 16, color: textSecondaryColorGlobal)),
                          50.height,
                          AppButton(
                            text: languages.lblViewPlans,
                            width: context.width(),
                            color: primaryColor,
                            onTap: () {
                              SubscribeScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
                            },
                          ).paddingAll(16)
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            16.height,
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: boxDecorationWithRoundedCorners(backgroundColor: appStore.isDarkMode ? cardDarkColor : GreenColor.withOpacity(0.10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userStore.subscriptionDetail?.subscriptionPlan?.packageName ?? '', style: boldTextStyle()).expand(),
                                      PriceWidget(
                                          price: userStore.subscriptionDetail?.subscriptionPlan?.totalAmount.validate().toStringAsFixed(2),
                                          color: primaryColor,
                                          textStyle: boldTextStyle(color: primaryColor, size: 20)),
                                    ],
                                  ),
                                  Text(
                                      languages.lblYourPlanValid +
                                          " " +
                                          parseDocumentDate(DateTime.parse(userStore.subscriptionDetail!.subscriptionPlan!.subscriptionStartDate.validate())) +
                                          " ${languages.lblTo} " +
                                          parseDocumentDate(DateTime.parse(userStore.subscriptionDetail!.subscriptionPlan!.subscriptionEndDate.validate())),
                                      style: primaryTextStyle(color: primaryColor, size: 12)),
                                  8.height,
                                  HtmlWidget(postContent: userStore.subscriptionDetail!.subscriptionPlan!.packageData!.description.validate()),
                                  16.height,
                                ],
                              ),
                            ),
                            24.height,
                            AppButton(
                              text: languages.lblCancelSubscription,
                              width: context.width(),
                              color: primaryOpacity,
                              textColor: primaryColor,
                              onTap: () {
                                cancelPackage();
                              },
                            ),
                          ],
                        ).paddingSymmetric(horizontal: 16),
                      )*/

            buildSubscriptionWidget()
            : mSubscriptionPlanList.isNotEmpty
                ? AnimatedListView(
                    itemCount: mSubscriptionPlanList.length,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    shrinkWrap: true,
                    controller: scrollController,
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return mSubscriptionPlanList[index].status == 'inactive'
                          ? Container(
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: boxDecorationWithRoundedCorners(
                                  backgroundColor: appStore.isDarkMode
                                      ? cardDarkColor
                                      : getBgColor(mSubscriptionPlanList[index]
                                          .status
                                          .validate())),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                              mSubscriptionPlanList[index]
                                                  .packageName
                                                  .validate(),
                                              style: boldTextStyle())
                                          .expand(),
                                      PriceWidget(
                                        price: mSubscriptionPlanList[index]
                                            .totalAmount
                                            .validate()
                                            .toStringAsFixed(2),
                                        color: primaryColor,
                                        textStyle: boldTextStyle(),
                                      ),
                                    ],
                                  ),
                                  8.height,
                                  Text(
                                    "${_formatSubscriptionDate(mSubscriptionPlanList[index].subscriptionStartDate)} ${languages.lblTo} ${_formatSubscriptionDate(mSubscriptionPlanList[index].subscriptionEndDate)}",
                                    style: secondaryTextStyle(),
                                  ),
                                  8.height,
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                              height: 6,
                                              width: 6,
                                              decoration:
                                                  boxDecorationWithRoundedCorners(
                                                      boxShape: BoxShape.circle,
                                                      backgroundColor:
                                                          textSecondaryColorGlobal)),
                                          6.width,
                                          Text(
                                              mSubscriptionPlanList[index]
                                                  .paymentType
                                                  .validate()
                                                  .capitalizeFirstLetter(),
                                              style: primaryTextStyle()),
                                        ],
                                      ).expand(),
                                      Text(
                                          mSubscriptionPlanList[index]
                                              .status
                                              .validate()
                                              .capitalizeFirstLetter(),
                                          style: boldTextStyle(
                                              color: getTextColor(
                                                  mSubscriptionPlanList[index]
                                                      .status
                                                      .validate())))
                                    ],
                                  )
                                ],
                              ),
                            )
                          : SizedBox.shrink();
                    },
                  )
                : SizedBox(
                        height: context.height() * 0.65,
                        child: NoDataScreen().center())
                    .visible(!appStore.isLoading),
        Observer(builder: (context) {
          return Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                  child: Loader().center())
              .visible(appStore.isLoading);
        })
      ]),
    );
  }
}
