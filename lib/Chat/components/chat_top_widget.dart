import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

import '../../../../main.dart';
import '../../../extensions/colors.dart';
import '../../../extensions/common.dart';
import '../../../extensions/decorations.dart';
import '../../../extensions/text_styles.dart';
import '../../../extensions/widgets.dart';
import '../../../utils/app_common.dart';
import '../../../utils/app_images.dart';
import '../screen/chat_user_profile_screen.dart';

class ChatAppBarWidget extends StatefulWidget {
  final UserModel? receiverUser;

  ChatAppBarWidget({required this.receiverUser});

  @override
  ChatAppBarWidgetState createState() => ChatAppBarWidgetState();
}

class ChatAppBarWidgetState extends State<ChatAppBarWidget> {
  bool isBlocked = false; // Local state only

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // String getTime(int val) {
  //   String? time;
  //   DateTime date = DateTime.fromMicrosecondsSinceEpoch(val * 1000);
  //   if (date.day == DateTime.now().day) {
  //     time = "at ${DateFormat('hh:mm a').format(date)}";
  //   } else {
  //     time = date.timeAgo;
  //   }
  //   return time;
  // }

  @override
  Widget build(BuildContext context) {
    final data = widget.receiverUser; // Use passed data directly

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Icon(Icons.arrow_back, color: whiteColor),
          ),
          8.width,
          InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              // Open full profile image or details if needed
            },
            child: Row(
              children: [
                (data?.profileImage != null && data!.profileImage!.isNotEmpty)
                    ? CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage(ic_profile),
                      )
                    : cachedImage(data!.profileImage,
                            height: 35, width: 35, fit: BoxFit.cover)
                        .cornerRadiusWithClipRRect(50),
              ],
            ).paddingSymmetric(vertical: 16),
          ),
          8.width,
          InkWell(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              // ChatUserProfileScreen(uid: data!.uid ?? '').launch(
              //     context,
              //     pageRouteAnimation: PageRouteAnimation.Scale,
              //     duration: 300.milliseconds);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(data!.firstName ?? '',
                //     style: boldTextStyle(color: whiteColor)),
                // 4.height,
                // data.isPresence == true
                //     ? Text('Online',
                //         style: secondaryTextStyle(color: Colors.white70))
                //     : Marquee(
                //         text:
                //             "Last seen ${getTime(data.lastSeen?.validate() ?? 0)}",
                //         style: secondaryTextStyle(
                //             size: 12, color: Colors.white70),
                //         scrollAxis: Axis.horizontal,
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         pauseAfterRound: const Duration(seconds: 1),
                //       ),
              ],
            ).paddingSymmetric(vertical: 16),
          ).expand(),
        ],
      ),
      actions: [
        PopupMenuButton(
          padding: EdgeInsets.zero,
          offset: Offset(10, -40),
          icon: Icon(Icons.more_vert, color: whiteColor),
          color: white,
          onSelected: (dynamic value) {
            if (value == 1) {
              // ChatUserProfileScreen(uid: data?.uid ?? '').launch(
              //     context,
              //     pageRouteAnimation: PageRouteAnimation.Scale,
              //     duration: 300.milliseconds);
            } else if (value == 2) {
              // Block/unblock logic can be implemented locally if needed
              setState(() {
                isBlocked = !isBlocked;
              });
            } else if (value == 3) {
              // Clear chat logic removed
              toast("Clear chat tapped");
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                  value: 1,
                  child: Text("View Contact", style: primaryTextStyle())),
              PopupMenuItem(
                  value: 2,
                  child: Text(isBlocked ? 'Unblock' : 'Block',
                      style: primaryTextStyle())),
              PopupMenuItem(
                  value: 3, child: Text('Clear Chat', style: primaryTextStyle())),
            ];
          },
        ),
      ],
      // backgroundColor: context.primaryColor,
    );
  }
}
