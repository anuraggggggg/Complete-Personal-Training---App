import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

import '../../../extensions/colors.dart';
import '../../../extensions/common.dart';
import '../../../extensions/confirmation_dialog.dart';
import '../../../extensions/constants.dart';
import '../../../extensions/decorations.dart';
import '../../../extensions/shared_pref.dart';
import '../../../extensions/system_utils.dart';
import '../../../extensions/text_styles.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';

class ChatOptionDialog extends StatefulWidget {
  final UserModel? receiverUser;

  ChatOptionDialog({this.receiverUser});

  @override
  ChatOptionDialogState createState() => ChatOptionDialogState();
}

class ChatOptionDialogState extends State<ChatOptionDialog> {
  List<String> chatOptionList = ['Clear Chat', 'Delete Chat'];

  int currentIndex = 0;

  UserModel sender = UserModel(
    firstName: getStringAsync(FIRSTNAME),
    profileImage: getStringAsync(USER_PROFILE_IMG),
    uid: getStringAsync(UID),
    playerId: getStringAsync(PLAYER_ID),
  );

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    currentIndex = getIntAsync(THEME_MODE_INDEX);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        itemCount: chatOptionList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            onTap: () {
              // Functionality removed
              toast("${chatOptionList[index]} tapped");
            },
            title: Text(chatOptionList[index], style: primaryTextStyle()),
          );
        },
      ),
    );
  }
}
 