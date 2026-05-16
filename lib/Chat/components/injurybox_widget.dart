
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/app_theme.dart';
import 'package:mighty_fitness/extensions/colors.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/utils/app_common.dart';



class SelectableInjuryBox extends StatelessWidget {
  // final List<String> imageList;
  final bool isSelected;
  final VoidCallback onTap;
  final String imagePath;
  final String label;
  const SelectableInjuryBox({
// required this.imageList,
    required this.isSelected,
    required this.imagePath,
    required this.onTap,
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
                width: 100,
                height: 100,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                  // image:
                  // DecorationImage(
                  //   opacity: isSelected ? 1: 0.5,
                  //   image: cachedImage(imagePath),
                  //   fit: BoxFit.cover, // Important: fills entire circle
                  // ),
                ),
                child: ClipOval(
                    child: Opacity(
                  opacity: isSelected ? 1.0 : 0.5,
                  child: cachedImage(imagePath, fit: BoxFit.cover),
                )
                    //
                    )),
          10.height,
SizedBox(
  width: 100, // Match the image/container width
  child: Text(
    label,
    textAlign: TextAlign.center, // Center text inside box
    maxLines: 2,
    overflow: TextOverflow.ellipsis, // Prevent overflow
    style: TextStyle(
      color: isSelected ? primary : white,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      fontSize: 14,
    ),
  ),
),

          ],
        ));
  }
}
