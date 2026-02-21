import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mighty_fitness/extensions/common.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/html_widget.dart';
import 'package:mighty_fitness/extensions/system_utils.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:mighty_fitness/utils/app_images.dart';

import '../components/ChatitemWidget.dart';
import '../components/chat_top_widget.dart';
import '../../extensions/decorations.dart';
import '../../extensions/text_styles.dart';

class ChatScreen extends StatefulWidget {
  final UserModel? userData;

  ChatScreen({this.userData});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  var messageCont = TextEditingController();
  var messageFocus = FocusNode();

  @override
  void dispose() {
    messageCont.dispose();
    messageFocus.dispose();
    super.dispose();
  }

  // Static placeholder for sending messages
  void sendMessage() {
    if (messageCont.text.isNotEmpty) {
      print("Message sent: ${messageCont.text}");
      messageCont.clear();
      setState(() {});
    }
  }

  showAttachmentDialog() {
    return showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 78, left: 12, right: 12),
            decoration: BoxDecoration(
                color: primaryColor, borderRadius: BorderRadius.circular(12)),
            child: Material(
              color: primaryColor,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  iconsBackgroundWidget(context,
                          name: "Camera",
                          image: ic_camera,
                          color: Colors.purple.shade400)
                      .onTap(() async {
                    var result = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (result != null) {
                      print("Picked image from camera: ${result.path}");
                    }
                    finish(context);
                  }),
                  iconsBackgroundWidget(context,
                          name: "Gallery",
                          image: ic_wallpaper,
                          color: Colors.white)
                      .onTap(() async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                            allowCompression: true);
                    if (result != null) {
                      print("Picked images from gallery: ${result.paths}");
                    }
                    finish(context);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(context.width(), kToolbarHeight),
        child: ChatAppBarWidget(
          receiverUser: widget.userData!,
        ),
      ),
      body: Container(
        height: context.height(),
        width: context.width(),
        child: Stack(
          children: [
            // Static placeholder for chat messages
            ListView.builder(
              padding: EdgeInsets.only(bottom: 76),
              itemCount: 10, // dummy 10 messages
              reverse: true,
              itemBuilder: (context, index) {
                bool isMe = index % 2 == 0;
                return null;
                // return ChatItemWidget(
                //   data: null, // null because static
                //   isMe: isMe,
                //   message: isMe
                //       ? "This is a sent message #$index"
                //       : "This is a received message #$index",
                // );
              },
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: boxDecorationWithShadow(
                  borderRadius: BorderRadius.circular(30),
                  spreadRadius: 1,
                  blurRadius: 1,
                  backgroundColor: context.cardColor,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    TextField(
                      controller: messageCont,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Write a Message",
                        hintStyle: secondaryTextStyle(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                      ),
                      cursorColor: Colors.black,
                      focusNode: messageFocus,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      style: primaryTextStyle(),
                      maxLines: 5,
                    ).expand(),
                    IconButton(
                      visualDensity: VisualDensity(horizontal: 0, vertical: 1),
                      icon: Icon(Icons.attach_file),
                      iconSize: 25.0,
                      padding: EdgeInsets.all(2),
                      color: Colors.grey,
                      onPressed: () {
                        showAttachmentDialog();
                        hideKeyboard(context);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: primaryColor),
                      onPressed: sendMessage,
                    )
                  ],
                ),
                width: context.width(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
