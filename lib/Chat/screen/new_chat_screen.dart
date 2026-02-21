import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

import '../../extensions/system_utils.dart';
import '../../extensions/text_styles.dart';
import '../../extensions/widgets.dart';
import '../../utils/app_common.dart';
import 'ChatScreen.dart';

class NewChatScreen extends StatefulWidget {
  final bool? isCall;

  NewChatScreen({this.isCall = false});

  @override
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  bool isSearch = true;
  bool autoFocus = false;
  TextEditingController searchCont = TextEditingController();
  String search = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        context: context,
        "New Chat",
        textColor: primaryColor,
        actions: [
          AnimatedContainer(
            margin: EdgeInsets.only(left: 8),
            duration: Duration(milliseconds: 100),
            curve: Curves.decelerate,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: Colors.white,
                  onChanged: (s) {
                    setState(() {});
                  },
                  style: primaryTextStyle(),
                  controller: searchCont,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search Here",
                    hintStyle: secondaryTextStyle(),
                  ),
                ).expand(),
                IconButton(
                  icon: isSearch ? Icon(Icons.close) : Icon(Icons.search),
                  onPressed: () async {
                    isSearch = !isSearch;
                    searchCont.clear();
                    search = "";
                    setState(() {});
                  },
                  color: primaryColor,
                )
              ],
            ),
            width: isSearch ? context.width() - 86 : 50,
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userService.users(searchText: searchCont.text),
        builder: (_, snap) {
          if (snap.hasData) {
            // Filter out the current user from the list
            List<UserModel> users = snap.data!
                .where((user) => user.uid != getStringAsync(UID))
                .toList();

            // Sort the list alphabetically by first name
            if (users.isNotEmpty) {
              users.sort((a, b) => a.firstName?.toLowerCase().compareTo(b.firstName?.toLowerCase()??'')??0);

              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    UserModel data = users[index];

                    return Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          (data.profileImage == null ||
                                  data.profileImage!.isEmpty)
                              ? Hero(
                                  tag: data.uid??0,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    padding: EdgeInsets.all(10),
                                    color: primaryColor,
                                    child: Text(
                                      data.firstName?.isNotEmpty??true
                                          ? data.firstName!
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : '', // Ensure safety
                                      style: secondaryTextStyle(
                                          color: Colors.white),
                                    ).center().fit(),
                                  ).cornerRadiusWithClipRRect(50),
                                )
                              : cachedImage(data.profileImage??'',
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  .cornerRadiusWithClipRRect(80),
                          12.width,
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.firstName?.capitalizeFirstLetter()??''}',
                                style: primaryTextStyle(),
                              ),
                              Text(
                                '${data.status.validate()}',
                                style: secondaryTextStyle(),
                              ),
                            ],
                          ).expand(),
                        ],
                      ),
                    ).onTap(() {
                      finish(context);
                      ChatScreen(userData: data).launch(context);
                    });
                  },
                ),
              );
            } else {
              return Text("no_data_found").center();
            }
          }
          return snapWidgetHelper(snap);
        },
      ),
    );
  }
}
