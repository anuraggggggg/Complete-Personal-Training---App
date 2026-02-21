import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import '../components/chat_option_dialog.dart';
import '../components/last_message_container.dart';
import '../../extensions/colors.dart';
import '../../extensions/common.dart';
import '../../extensions/confirmation_dialog.dart';
import '../../extensions/loader_widget.dart';
import '../../extensions/text_styles.dart';
import '../../extensions/widgets.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../model/contact_model.dart';
import 'ChatScreen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  String id = '';
  String searchCont = "";

  UserModel sender = UserModel(
    firstName: getStringAsync(FIRSTNAME) ?? 'Unknown',
    profileImage: getStringAsync(USER_PROFILE_IMG) ?? '',
    uid: getStringAsync(UID) ?? '',
    playerId: getStringAsync(PLAYER_ID) ?? '',
  );

  // Dummy list to replace Firestore contacts
  List<ContactModel> contacts = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    WidgetsBinding.instance.addObserver(this);
    Map<String, dynamic> presenceStatusTrue = {
      KEY_IS_PRESENT: true,
      KEY_LAST_SEEN: DateTime.now().millisecondsSinceEpoch,
    };
    String? userId = getStringAsync(UID);
    await userService.updateUserStatus(presenceStatusTrue, userId);
    id = userId;

    // TODO: Replace with your local/fake data
    contacts = [
      // Example contact
      // ContactModel(uid: "1", firstName: "John"),
      // ContactModel(uid: "2", firstName: "Alice"),
    ];

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Map<String, dynamic> presenceStatusFalse = {
      KEY_IS_PRESENT: false,
      KEY_LAST_SEEN: DateTime.now().millisecondsSinceEpoch,
    };

    String? userId = getStringAsync(UID);
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      userService.updateUserStatus(presenceStatusFalse, userId);
    }

    if (state == AppLifecycleState.resumed) {
      Map<String, dynamic> presenceStatusTrue = {
        KEY_IS_PRESENT: true,
        KEY_LAST_SEEN: DateTime.now().millisecondsSinceEpoch,
      };
      userService.updateUserStatus(presenceStatusTrue, userId);
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        "Chat",
        context: context,
        color: primaryColor,
        textColor: Colors.white,
        showBack: false,
        titleTextStyle: boldTextStyle(size: 18, isHeader: true, color: Colors.white),
        elevation: 1,
        actions: [],
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 65, top: 8),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          ContactModel contact = contacts[index];
          // return buildChatItemWidget(contact: contact);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.chat, color: white),
        backgroundColor: primaryColor,
        onPressed: () {
          hideKeyboard(context);
          NewChatScreen().launch(context, pageRouteAnimation: PageRouteAnimation.SlideBottomTop, duration: 300.milliseconds);
        },
      ),
    );
  }

  // Widget buildChatItemWidget({required ContactModel contact}) {
  //   UserModel data = UserModel(
  //     uid: contact.uid,
  //     firstName: contact.firstName,
  //     profileImage: contact.profileImage ?? '',
  //   );

  //   return InkWell(
  //     onTap: () async {
  //       if (id != data.uid) {
  //         hideKeyboard(context);
  //         await ChatScreen(userData: data).launch(context);
  //       }
  //     },
  //     onLongPress: () async {
  //       await showInDialog(context, builder: (_) {
  //         return ChatOptionDialog(receiverUser: data);
  //       }, contentPadding: EdgeInsets.zero, dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM);
  //       setState(() {});
  //     },
  //     child: Container(
  //       width: context.width(),
  //       child: Row(
  //         children: [
  //           (data.profileImage == null || data.profileImage!.isEmpty)
  //               ? CircleAvatar(
  //                   radius: 22,
  //                   backgroundImage: AssetImage(ic_profile),
  //                 )
  //               : Hero(
  //                   tag: data.uid ?? 0,
  //                   child: cachedImage(data.profileImage ?? '', height: 40, width: 40, fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
  //                 ),
  //           10.width,
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Text(
  //                     data.firstName?.capitalizeFirstLetter() ?? '',
  //                     style: primaryTextStyle(),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ).expand(),
  //                 ],
  //               ),
  //               2.height,
  //               Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   LastMessageContainer(messages: []), // Replace with local messages
  //                 ],
  //               ),
  //             ],
  //           ).expand(),
  //         ],
  //       ).paddingSymmetric(horizontal: 16, vertical: 8),
  //     ),
  //   );
  // }
}
