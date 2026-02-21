
import 'package:mighty_fitness/utils/app_constants.dart';

class ChatMessageModel {
  String? id;
  String? senderId;
  String? receiverId;
  String? photoUrl;
  String? messageType;
  bool? isMe;
  bool? isMessageRead;
  String? message;
  int? createdAt;

  ChatMessageModel({
    this.id,
    this.senderId,
    this.receiverId,
    this.createdAt,
    this.message,
    this.isMessageRead,
    this.photoUrl,
    this.messageType,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json[KEY_ID],
      senderId: json[KEY_SENDER_ID],
      receiverId: json[KEY_RECEIVER_ID],
      message: json[KEY_MESSAGE],
      isMessageRead: json[KEY_IS_MESSAGE_READ],
      photoUrl: json[KEY_PHOTO_URL],
      messageType: json[KEY_MESSAGE_TYPE],
      createdAt: json[KEY_FIREBASE_CREATED_AT],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data[KEY_ID] = this.id;
    data[KEY_FIREBASE_CREATED_AT] = this.createdAt;
    data[KEY_MESSAGE] = this.message;
    data[KEY_SENDER_ID] = this.senderId;
    data[KEY_IS_MESSAGE_READ] = this.isMessageRead;
    data[KEY_RECEIVER_ID] = this.receiverId;
    data[KEY_PHOTO_URL] = this.photoUrl;
    data[KEY_MESSAGE_TYPE] = this.messageType;
    return data;
  }
}
