import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:crisp_chat/crisp_chat.dart';
import 'package:mighty_fitness/extensions/widgets.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/utils/app_colors.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final String websiteID = '5d202cf3-303a-4abb-ad53-fae5cee3919b';
  late CrispConfig config;

   @override
  void initState() {
    super.initState();
    User user = User(email: userStore.email, nickName: "${userStore.displayName}", avatar: userStore.profileImage ?? "");
    // config = CrispConfig(
    //   user: user,
    //   tokenId: userStore.userId.toString(),
    //   enableNotifications: true,
    //   // websiteID: getStringAsync(CRISP_CHAT_WEB_SITE_ID),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColorImageColor,
      appBar: appBarWidget("Live chat",
          context: context,
          color: BackgroundColorImageColor,
          elevation: 1),
      body: Observer(
        builder: (context) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FlutterCrispChat.openCrispChat(config: config);
                        FlutterCrispChat.setSessionString(
                          key: "a_string",
                          value: userStore.displayName,
                        );
                        FlutterCrispChat.setSessionInt(
                          key: "a_number",
                          value: userStore.userId,
                        );

                        /// Checking session ID After 5 sec
                        await Future.delayed(const Duration(seconds: 5),
                            () async {
                          String? sessionId =
                              await FlutterCrispChat.getSessionIdentifier();
                          if (sessionId != null) {
                            if (kDebugMode) {
                            }
                          } else {
                            if (kDebugMode) {
                            }
                          }
                        });
                      },
                      child: const Text('Open Crisp Chat'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await FlutterCrispChat.resetCrispChatSession();
                      },
                      child: const Text('Reset Chat Session'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
