import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import '../../extensions/decorations.dart';
import '../../extensions/text_styles.dart';
import '../../extensions/widgets.dart';

class ChatUserProfileScreenStatic extends StatelessWidget {
  final UserModel currentUser;
  final bool isBlocked;

  ChatUserProfileScreenStatic({
    Key? key,
    required this.currentUser,
    this.isBlocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: appBarWidget('Profile', context: context, showBack: true),
      body: Container(
        height: context.height(),
        color: context.scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildImageIconWidget(),
            16.height,
            aboutDetail(context),
            16.height,
            statusWidget(context),
            16.height,
            buildBlockMSG(context),
          ],
        ),
      ),
    );
  }

  Widget buildImageIconWidget() {
    if (currentUser.profileImage != null && currentUser.profileImage!.isNotEmpty) {
      return Hero(
        tag: currentUser.uid ?? '',
        child: cachedImage(
          currentUser.profileImage!,
          radius: 50,
          height: 100,
          width: 100,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ).cornerRadiusWithClipRRect(50),
      ).center();
    }

    // Fallback placeholder
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(Icons.person, size: 50, color: Colors.white),
    ).center();
  }

  Widget aboutDetail(BuildContext context) {
    return Container(
      color: context.cardColor,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: context.width(),
      child: Column(
        children: [
          16.height,
          Text("${currentUser.firstName}", style: boldTextStyle(letterSpacing: 0.5)),
          8.height,
          if (currentUser.phoneNumber != null)
            Text('+91' + '*' * (currentUser.phoneNumber!.length - 3),
                style: secondaryTextStyle()),
          8.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  IconButton(
                    icon: Image.asset(ic_messages,
                        height: 25, width: 25, color: primaryColor),
                    onPressed: () {
                      // Static placeholder
                      print("Message button tapped");
                    },
                  ),
                  Text('Message',
                      style: boldTextStyle(size: 12, letterSpacing: 0.5, color: primaryColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 8),
      width: context.width(),
      child: Row(
        children: [
          8.width,
          Text('Last seen: 2 hours ago') // Static placeholder
        ],
      ),
    );
  }

  Widget buildBlockMSG(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10),
      width: context.width(),
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red[800]),
          8.width,
          Text(isBlocked
              ? "Unblock ${currentUser.firstName}"
              : "Block ${currentUser.firstName}")
        ],
      ),
    ).onTap(() {
      // Static block/unblock action
      print(isBlocked ? "Unblock user" : "Block user");
    });
  }
}
