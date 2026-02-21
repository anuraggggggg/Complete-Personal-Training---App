import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mighty_fitness/extensions/extension_util/context_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/utils/app_colors.dart';

import '../../../../main.dart';
import '../../../extensions/colors.dart';
import '../../../extensions/common.dart';
import '../../../extensions/constants.dart';
import '../../../extensions/decorations.dart';
import '../../../extensions/loader_widget.dart';
import '../../../extensions/text_styles.dart';
import '../../../extensions/widgets.dart';
import '../../../utils/app_constants.dart';
import '../model/chat_message_model.dart';

class ChatItemWidget extends StatefulWidget {
  final ChatMessageModel? data;

  ChatItemWidget({this.data});

  @override
  _ChatItemWidgetState createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {
  String? images;

  @override
  Widget build(BuildContext context) {
    String time;

    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.data!.createdAt!);
    if (dateTime.day == DateTime.now().day) {
      time = DateFormat('hh:mm a').format(dateTime);
    } else {
      time = DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    }


    Widget chatItem(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: widget.data!.isMe!
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(widget.data!.message!,
                  style: primaryTextStyle(
                      color: widget.data!.isMe!
                          ? Colors.white
                          : textPrimaryColorGlobal),
                  maxLines: null),
              1.height,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: primaryTextStyle(
                        color: !(widget.data?.isMe??false)
                            ? Colors.blueGrey.withOpacity(0.6)
                            : whiteColor.withOpacity(0.6),
                        size: 10),
                  ),
                  2.width,
                  widget.data!.isMe!
                      ? !widget.data!.isMessageRead!
                          ? Icon(Icons.done, size: 12, color: Colors.white60)
                          : Icon(Icons.done_all,
                              size: 12, color: Colors.white60)
                      : Offstage()
                ],
              ),
            ],
          );
        case IMAGE:
          if (widget.data?.photoUrl?.isNotEmpty??false ||
              widget.data!.photoUrl != null) {
            return Stack(
              children: [
                CachedNetworkImage(
                        imageUrl: widget.data?.photoUrl??'',
                        fit: BoxFit.cover,
                        width: 250,
                        height: 200)
                    .cornerRadiusWithClipRRect(10),
                Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time,
                            style: primaryTextStyle(
                                color: !(widget.data?.isMe??false)
                                    ? Colors.blueGrey.withOpacity(0.6)
                                    : whiteColor.withOpacity(0.6),
                                size: 10)),
                        2.width,
                        widget.data!.isMe!
                            ? !widget.data!.isMessageRead!
                                ? Icon(Icons.done,
                                    size: 12, color: Colors.white60)
                                : Icon(Icons.done_all,
                                    size: 12, color: Colors.white60)
                            : Offstage()
                      ],
                    ))
              ],
            );
          } else {
            return Container(child: Loader(), height: 250, width: 250);
          }
        default:
          return Container();
      }
    }

    EdgeInsetsGeometry customPadding(String? messageTypes) {
      switch (messageTypes) {
        case TEXT:
          return EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        case IMAGE:
          return EdgeInsets.symmetric(horizontal: 4, vertical: 4);
        default:
          return EdgeInsets.symmetric(horizontal: 4, vertical: 4);
      }
    }

    return GestureDetector(
      onLongPress: !widget.data!.isMe!
          ? null
          : () async {
              bool? res = await showConfirmDialog(context, "Delete Message",
                  positiveText: "Yes",
                  negativeText: "No",
                  buttonColor: primaryColor);
              if (res ?? false) {
                hideKeyboard(context);
                // chatMessageService
                //     .deleteSingleMessage(
                //         senderId: widget.data!.senderId,
                //         receiverId: widget.data!.receiverId!,
                //         documentId: widget.data!.id)
                //     .then((value) {
                //   //
                // }).catchError(
                //   (e) {
                //     log(e.toString());
                //   },
                // );
              }
            },
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.data?.isMe??false
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisAlignment: widget.data!.isMe!
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              margin:widget.data?.isMe??false
                  ? EdgeInsets.only(
                      top: 0.0,
                      bottom: 0.0,
                      left: context.width() * 0.25,
                      right: 8)
                  : EdgeInsets.only(
                      top: 2.0,
                      bottom: 2.0,
                      left: 8,
                      right: context.width() * 0.25),
              padding: customPadding(widget.data!.messageType),
              decoration: BoxDecoration(
                boxShadow: defaultBoxShadow(),
                color: widget.data?.isMe??false
                    ? primaryColor
                    : context.cardColor,
                borderRadius: widget.data?.isMe??false
                    ? radiusOnly(
                        bottomLeft: 12,
                        topLeft: 12,
                        bottomRight: 0,
                        topRight: 12)
                    : radiusOnly(
                        bottomLeft: 0,
                        topLeft: 12,
                        bottomRight: 12,
                        topRight: 12),
              ),
              child: chatItem(widget.data!.messageType),
            ),
          ],
        ),
        margin: EdgeInsets.only(top: 2, bottom: 2),
      ),
    );
  }
}
