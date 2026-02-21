import 'dart:developer';
import 'dart:io';

import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/models/login_response.dart';
import 'package:path/path.dart';

import '../../main.dart';
import '../Chat/model/chat_message_model.dart';
import '../Chat/model/contact_model.dart';
import '../utils/app_constants.dart';
import 'base_service.dart';

class ChatMessageService extends BaseService {

  ChatMessageService();

  // For local or API-based chat messages (Firestore removed)
  Future<void> addMessageToDbLocal(ChatMessageModel data, UserModel sender, UserModel? user,
      {File? image}) async {
    String imageUrl = '';

    if (image != null) {
      String fileName = basename(image.path);
      // Example: local file path handling instead of Firebase Storage
      imageUrl = "local_path/${sender.uid}/$fileName";
      log("Image saved locally at $imageUrl");
    }

    // Here you can implement local storage or API call to save chat message
    log("Message saved locally: ${data.toJson()} with imageUrl: $imageUrl");
  }

  // Local method to simulate adding contacts
  Future<void> addToContactsLocal({String? senderId, String? receiverId}) async {
    log("Add to contacts locally: senderId=$senderId, receiverId=$receiverId");
    // Implement local DB or API logic here if needed
  }

  // Example local fetch for unread count
  // int fetchForMessageCountLocal(String currentUserId) {
  //   userStore.chatNotificationCount = 0;
  //   log("Fetching message count locally for $currentUserId");
  //   return userStore.chatNotificationCount;
  // }

  // Placeholder for getting user by id
  Future<UserModel> getUserByIdLocal({String? uid}) async {
    log("Fetching user locally: $uid");
    // Return dummy or API-fetched user
    return UserModel(
      firstName: "Demo",
      profileImage: "",
      uid: uid ?? "",
      playerId: "",
    );
  }

  // You can add more methods here to simulate Firestore behavior using local storage or APIs
}
