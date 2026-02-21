import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../models/diet_response.dart';
import '../components/HtmlWidget.dart';
import '../extensions/text_styles.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../utils/app_colors.dart';
import '../utils/app_common.dart';
import '../utils/app_images.dart';

class DietDetailScreen extends StatefulWidget {
  final DietModel? dietModel;
  final Function? onCall;
  final bool? isCategory;
  final bool? isFeatured;

  const DietDetailScreen({
    Key? key,
    this.dietModel,
    this.onCall,
    this.isFeatured,
    this.isCategory,
  }) : super(key: key);

  @override
  State<DietDetailScreen> createState() => _DietDetailScreenState();
}

class _DietDetailScreenState extends State<DietDetailScreen> {
  bool showIngredients = true;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> setDiet(int? id) async {
    appStore.setLoading(true);
    await setDietFavApi({"diet_id": id}).then((value) {
      toast(value.message);
      widget.dietModel!.isFavourite =
          widget.dietModel!.isFavourite == 1 ? 0 : 1;
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
    });
    appStore.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: [
            /// ================= HEADER IMAGE =================
           
            /// ================= BOTTOM CONTENT =================
            DraggableScrollableSheet(
              initialChildSize: 0.66,
              maxChildSize: 0.92,
              minChildSize: 0.66,
              builder: (context, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        12.height,

                        /// ================= DIET BADGES =================
                        _dietBadges(cs),

                        16.height,
                        Divider(color: cs.outline.withOpacity(0.25)),

                        /// ================= NUTRITION =================
                        Row(
                          children: [
                            _nutrition(ic_calories,
                                "${widget.dietModel!.calories} kcal",
                                languages.lblCalories),
                            divider(),
                            _nutrition(ic_carbs,
                                "${widget.dietModel!.carbs} g",
                                languages.lblCarbs),
                            divider(),
                            _nutrition(ic_fat,
                                "${widget.dietModel!.fat} g",
                                languages.lblFat),
                            divider(),
                            _nutrition(ic_protein,
                                "${widget.dietModel!.protein} g",
                                languages.lblProtein),
                          ],
                        ).paddingSymmetric(horizontal: 12),

                        20.height,

                        /// ================= TABS =================
                        Row(
                          children: [
                            _tab(
                              languages.lblIngredients,
                              active: showIngredients,
                              cs: cs,
                              onTap: () =>
                                  setState(() => showIngredients = true),
                            ).expand(),
                            _tab(
                              languages.lblInstruction,
                              active: !showIngredients,
                              cs: cs,
                              onTap: () =>
                                  setState(() => showIngredients = false),
                            ).expand(),
                          ],
                        ).paddingSymmetric(horizontal: 16),

                        16.height,

                        showIngredients ? ingredients() : instruction(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ================= COMPONENTS =================

  Widget _dietBadges(ColorScheme cs) {
  final String title =
      widget.dietModel!.title.validate().toLowerCase();

  /// 🥗 SAFE VEG / NON-VEG DETECTION
  final bool isVeg = title.contains('veg') &&
      !title.contains('non');

  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      /// 🥗 DIET TYPE BADGE
      _badge(
        icon: isVeg
            ? MaterialIcons.eco
            : MaterialCommunityIcons.food_steak,
        text: isVeg ? "VEG" : "NON-VEG",
        color: isVeg ? Colors.green : Colors.redAccent,
        cs: cs,
      ),

      /// 🔥 CALORIES
      _badge(
        icon: Feather.activity,
        text: "${widget.dietModel!.calories} kcal",
        color: Colors.orange,
        cs: cs,
      ),

      /// 🎯 GOAL / CATEGORY
      if (widget.dietModel!.categorydietTitle
          .validate()
          .isNotEmpty)
        _badge(
          icon: Feather.target,
          text: widget.dietModel!.categorydietTitle.validate(),
          color: cs.primary,
          cs: cs,
        ),
    ],
  ).paddingSymmetric(horizontal: 16);
}


  Widget _badge({
    required IconData icon,
    required String text,
    required Color color,
    required ColorScheme cs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          6.width,
          Text(text, style: boldTextStyle(size: 12)),
        ],
      ),
    );
  }

  Widget _nutrition(String img, String value, String label) {
    return Column(
      children: [
        Image.asset(img, height: 26, color: primaryColor),
        8.height,
        Text(value, style: boldTextStyle()),
        4.height,
        Text(label, style: secondaryTextStyle()),
      ],
    ).expand();
  }

  Widget divider() => VerticalDivider(
        thickness: 1,
        width: 12,
        indent: 10,
        endIndent: 10,
        color: context.dividerColor,
      );

  Widget ingredients() =>
      HtmlWidget(postContent: widget.dietModel!.ingredients.validate())
          .paddingSymmetric(horizontal: 12);

  Widget instruction() =>
      HtmlWidget(postContent: widget.dietModel!.description.validate())
          .paddingSymmetric(horizontal: 12);
}

Widget _tab(String text,
    {required bool active,
    required VoidCallback onTap,
    required ColorScheme cs}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Text(
          text,
          style: boldTextStyle(
            color: active ? cs.primary : cs.onSurface.withOpacity(0.6),
          ),
        ),
        6.height,
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          width: active ? 42 : 0,
          color: cs.primary,
        ),
      ],
    ),
  );
}
