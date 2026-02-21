import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mighty_fitness/extensions/constants.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/list_extensions.dart';
import '../extensions/colors.dart';
import '../screens/no_data_screen.dart';
import '../../components/progress_component.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/widgets.dart';
import '../../main.dart';
import '../components/horizontal_bar_chart.dart';
import '../extensions/decorations.dart';
import '../extensions/setting_item_widget.dart';
import '../extensions/text_styles.dart';
import '../models/graph_response.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart' hide cardDarkColor, cardLightColor;
import '../utils/app_common.dart';

enum SampleItem { month, year }

class ProgressDetailScreen extends StatefulWidget {
  static String tag = '/ProgressDetailScreen';

  final String? mType;
  final String? mUnit;
  final String? mTitle;
  final Function? onCall;

  ProgressDetailScreen({this.mType, this.mUnit, this.mTitle, this.onCall});

  @override
  ProgressDetailScreenState createState() => ProgressDetailScreenState();
}

class ProgressDetailScreenState extends State<ProgressDetailScreen> {
  GraphResponse? mGraphModel;
  SampleItem? selectedMenu;

  int page = 1;
  int? numPage;
  bool isLastPage = false;

  int? mWeight = 1;
  bool isKGClicked = false;
  bool isLBSClicked = false;

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    init();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !appStore.isLoading) {
        if ((numPage ?? 1) > page) {
          page++;
          init();
        }
      }
    });
  }

  /// ---------------- SAFE INIT ----------------
  Future<void> init({bool? isFilter = false, String? isFilterType}) async {
    appStore.setLoading(true);

    final res = await getProgressApi(
      widget.mType,
      isFilter: isFilter,
      isFilterType: isFilterType,
    );

    if (res == null) {
      appStore.setLoading(false);
      setState(() {});
      return;
    }

    mGraphModel = res;
    numPage = res.pagination?.totalPages ?? 1;
    isLastPage = false;

    appStore.setLoading(false);
    setState(() {});
  }

  /// ---------------- CONVERT KG → LBS ----------------
  GraphResponse _convertWeightsToLbs(GraphResponse response) {
    const double factor = 2.20462;

    response.data = response.data?.map((item) {
      if (item.value != null) {
        final v = item.value!.replaceAll('user', '').toDouble();
        item.value = (v * factor).toStringAsFixed(2);
        item.unit = 'lbs';
      }
      return item;
    }).toList();

    return response;
  }

  /// ---------------- SAFE LBS INIT ----------------
  Future<void> initLbs({bool? isFilter = false, String? isFilterType}) async {
    appStore.setLoading(true);

    final res = await getProgressApi(
      widget.mType,
      isFilter: isFilter,
      isFilterType: isFilterType,
    );

    if (res == null) {
      appStore.setLoading(false);
      setState(() {});
      return;
    }

    mGraphModel = _convertWeightsToLbs(res);
    numPage = res.pagination?.totalPages ?? 1;
    isLastPage = false;

    appStore.setLoading(false);
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: appBarWidget(
          widget.mTitle.toString(),
          backWidget: Icon(
            appStore.selectedLanguageCode == 'ar'
                ? MaterialIcons.arrow_back_ios
                : Octicons.chevron_left,
            color: primaryColor,
            size: 28,
          ).onTap(() {
            Navigator.pop(context, true);
          }),
          context: context,
          actions: [
            widget.mTitle == 'Weight'
                ? Container(
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: appStore.isDarkMode
                          ? context.cardColor
                          : GreyLightColor,
                    ),
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        mWeightOption(languages.lblLbs, 0),
                        4.width,
                        mWeightOption(languages.lblKg, 1),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
            PopupMenuButton<SampleItem>(
              icon: Icon(Icons.more_vert,
                  color:
                      appStore.isDarkMode ? Colors.white : Colors.black54),
              shape: RoundedRectangleBorder(borderRadius: radius()),
              onSelected: (item) {
                selectedMenu = item;
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SampleItem.month,
                  child:
                      Text(languages.lblMonth, style: primaryTextStyle()),
                  onTap: () => init(isFilter: true, isFilterType: "month"),
                ),
                PopupMenuItem(
                  value: SampleItem.year,
                  child: Text(languages.lblYear.capitalizeFirstLetter(),
                      style: primaryTextStyle()),
                  onTap: () => init(isFilter: true, isFilterType: "year"),
                ),
              ],
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              backgroundColor:
                  appStore.isDarkMode ? cardDarkColor : cardLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: radiusOnly(topRight: 18, topLeft: 18),
              ),
              builder: (_) => ProgressComponent(
                mType: widget.mType,
                mUnit: widget.mUnit,
                onCall: () {
                  isLBSClicked ? initLbs() : init();
                },
              ),
            );
          },
          child: Icon(Icons.add, color: Colors.white),
        ),
        body: Stack(
          children: [
            if (mGraphModel == null)
              NoDataScreen(mTitle: languages.lblResultNoFound).center()
            else if (mGraphModel!.data.validate().isEmpty)
              NoDataScreen(mTitle: languages.lblResultNoFound).center()
            else
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    HorizontalBarChart(mGraphModel!.data!)
                        .withSize(width: context.width(), height: 280),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: mGraphModel!.data!.length,
                      itemBuilder: (_, i) {
                        final d = mGraphModel!.data![i];
                        return SettingItemWidget(
                          title:
                              '${d.value.validate().replaceAll('user', '')} ${d.unit}',
                          trailing: Text(
                            progressDateStringWidget(d.date.toString()),
                            style: secondaryTextStyle(),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        );
                      },
                      separatorBuilder: (_, __) => Divider(thickness: 0.3),
                    ),
                  ],
                ),
              ),
            Loader().visible(appStore.isLoading),
          ],
        ),
      ),
    );
  }

  /// ---------------- WEIGHT TOGGLE ----------------
  Widget mWeightOption(String? value, int? index) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(6),
        backgroundColor:
            mWeight == index ? primaryColor : GreyLightColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        value!,
        style: secondaryTextStyle(
            color: mWeight == index ? Colors.white : textSecondaryColorGlobal),
      ),
    ).onTap(() {
      mWeight = index;
      if (index == 0) {
        initLbs();
        isLBSClicked = true;
        isKGClicked = false;
      } else {
        init();
        isKGClicked = true;
        isLBSClicked = false;
      }
      setState(() {});
    });
  }
}
