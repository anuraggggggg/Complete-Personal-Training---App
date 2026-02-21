import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/app_theme.dart';
import '../../extensions/decorations.dart';
import '../../extensions/extension_util/context_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../extensions/text_styles.dart';
import '../models/equipment_response.dart';
import '../screens/exercise_list_screen.dart';
import '../utils/app_colors.dart' hide primary;
import '../utils/app_common.dart';

class EquipmentComponent extends StatelessWidget {
  final EquipmentModel? mEquipmentModel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isGrid;
  final bool isSearch;

  const EquipmentComponent({
    super.key,
    this.mEquipmentModel,
    required this.isSelected,
    required this.onTap,
    this.isGrid = false,
    this.isSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    double width = isGrid ? (context.width() - 110) / 2 : context.width() * 0.2;
    double height = isGrid ? 125 : 140;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Image with red border if selected
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? primary : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: isSelected ? 1 : 0.5,
                    child: cachedImage(
                      mEquipmentModel!.equipmentImage?.validate(),
                      height: 100,
                      width: 120,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),

              // Title label with blur (only behind the label)
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                      //  borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        mEquipmentModel!.title.validate(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
