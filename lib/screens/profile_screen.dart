import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mighty_fitness/features/profile/viewmodels/profile_view_model.dart';
import 'package:mighty_fitness/screens/edit_profile_screen.dart';
import 'package:mighty_fitness/screens/home_page_wigets/faq_screen.dart';
import 'package:mighty_fitness/screens/progress_screen.dart';
import 'package:mighty_fitness/screens/subscription_order_list.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../extensions/confirmation_dialog.dart';
import '../extensions/text_styles.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileViewModel vm = Get.put(ProfileViewModel());

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final bool isDark = appStore.isDarkMode;
      final cs = Theme.of(context).colorScheme;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                /// ================= HEADER =================
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 24,
                  ),
                  color: primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      languages.lblProfile,
                      style: boldTextStyle(
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                /// ================= CONTENT =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// 👤 PROFILE CARD (TAPPABLE)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final updated =
                              await Get.to(() => EditProfileScreen());
                          if (updated == true && mounted) {
                            await vm.refreshWorkoutModeFromStore();
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _profileImage(),
                                  _editIcon(),
                                ],
                              ),
                              14.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userStore.fName.capitalizeFirstLetter()} '
                                    '${userStore.lName.capitalizeFirstLetter()}',
                                    style: boldTextStyle(
                                      size: 18,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  4.height,
                                  Text(
                                    userStore.email.validate(),
                                    style: secondaryTextStyle(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ).expand(),
                            ],
                          ),
                        ),
                      ),

                      24.height,

                      /// 🌗 THEME SWITCH
                      _settingsCard(
                        context,
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: primaryColor,
                            ),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDark ? "Dark Mode" : "Light Mode",
                                  style: boldTextStyle(
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  "Switch app theme",
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ).expand(),
                            Switch(
                              value: isDark,
                              activeThumbColor: primaryColor,
                              onChanged: (val) {
                                appStore.applyThemeSelection(
                                  val ? ThemeModeDark : ThemeModeLight,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      24.height,

                      /// 🏋️ WORKOUT PREFERENCE
                      Obx(() {
                        final bool isGymSelected = vm.isGym;

                        return _settingsCard(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Workout Preference",
                                style: boldTextStyle(
                                  size: 16,
                                  color: cs.onSurface,
                                ),
                              ),
                              16.height,
                              Row(
                                children: [
                                  _workoutTile(
                                    title: "Gym",
                                    icon: Icons.fitness_center,
                                    selected: isGymSelected,
                                    onTap: () {
                                      vm.updateWorkoutMode(vm.gymModeId.value);
                                    },
                                  ),
                                  12.width,
                                  _workoutTile(
                                    title: "Home",
                                    icon: Icons.home,
                                    selected: !isGymSelected,
                                    onTap: () {
                                      vm.updateWorkoutMode(vm.homeModeId.value);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      24.height,

                      _settingsCard(
                        context,
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite_outline_rounded,
                              color: primaryColor,
                            ),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Platform.isIOS
                                      ? "Apple Health (HealthKit)"
                                      : "Google Health Connect",
                                  style: boldTextStyle(
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  "View heart-rate tracking and health integration",
                                  style: secondaryTextStyle(
                                    size: 12,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ).expand(),
                            IconButton(
                              onPressed: () {
                                Get.to(() => const ProgressScreen());
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: cs.onSurface.withOpacity(0.7),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      24.height,

                      /// 🚪 LOGOUT
                      _actionButton(
                        label: "Logout",
                        icon: Icons.logout,
                        onTap: () {
                          vm.logoutUser();
                        },
                      ),

                      14.height,

                      Obx(
                        () => _actionButton(
                          label: vm.isDeletingAccount.value
                              ? "Deleting..."
                              : languages.lblDeleteAccount,
                          icon: Icons.delete_forever_outlined,
                          onTap: () {
                            if (vm.isDeletingAccount.value) return;

                            showConfirmDialogCustom(
                              context,
                              title: languages.lblDeleteAccount,
                              subTitle: languages.lblDeleteAccountMSg,
                              positiveText: languages.lblDeleteAccount,
                              primaryColor: Colors.red,
                              onAccept: (_) {
                                vm.deleteAccount();
                              },
                            );
                          },
                        ),
                      ),

                      14.height,

                      /// 📄 SUBSCRIPTION LIST
                      _actionButton(
                        label: "Subscription Order List",
                        icon: Icons.list_alt,
                        onTap: () {
                          Get.to(() => SubscriptionOrderListScreen());
                        },
                      ),

                      14.height,

                      /// ❓ FAQ BUTTON
                      _actionButton(
                        label: "FAQs",
                        icon: Icons.help_outline_rounded,
                        onTap: () {
                          Get.to(() => FaqScreen());
                        },
                      ),

                      40.height,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ================= HELPERS =================

  Widget _settingsCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
      ),
      child: child,
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _workoutTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: selected ? primaryColor : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primaryColor : cs.onSurface.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : cs.onSurface.withOpacity(0.6),
              ),
              6.height,
              Text(
                title,
                style: boldTextStyle(
                  color:
                      selected ? Colors.white : cs.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileImage() {
    return Observer(
      builder: (_) {
        final imageUrl = userStore.profileImage;

        return CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(
                  // 🔥 cache-busting (instant refresh)
                  "$imageUrl?ts=${DateTime.now().millisecondsSinceEpoch}",
                )
              : null,
          child: imageUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
        );
      },
    );
  }

  Widget _editIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor,
      ),
      child: Image.asset(
        ic_edit,
        height: 14,
        width: 14,
        color: Colors.white,
      ),
    );
  }
}
