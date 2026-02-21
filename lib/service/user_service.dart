import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/service/base_service.dart';

import '../../main.dart';
import '../extensions/constants.dart';
import '../extensions/shared_pref.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';

class UserService extends BaseService {

  UserService();

  Future<void> updateUserStatus(Map data, String id) async {
    // Use SharedPreferences or API call to update user status locally
    // log("Update user status locally for $id: $data");
  }

  Future<UserModel> getUser({String? email}) async {
    // log("Get user by email locally: $email");
    // Replace with API call or local storage logic
    return UserModel(
      firstName: "Demo",
      profileImage: "",
      uid: "demo_uid",
      playerId: "",
    );
  }

  Future<UserModel> getUserById({String? val}) async {
    // log("Get user by ID locally: $val");
    // Replace with API call or local storage logic
    return UserModel(
      firstName: "Demo",
      profileImage: "",
      uid: val ?? "demo_uid",
      playerId: "",
    );
  }

  Stream<List<UserModel>> users({String? searchText}) {
    // log("Get users list locally with searchText: $searchText");
    // Return empty list or fetch from API/local DB
    return Stream.value([]);
  }

  Future<UserModel> userByEmail(String? email) async {
    // log("Get user by email locally: $email");
    return UserModel(
      firstName: "Demo",
      profileImage: "",
      uid: "demo_uid",
      playerId: "",
    );
  }

  Future<UserModel> userByMobileNumber(String? phone) async {
    // log("Get user by phone locally: $phone");
    return UserModel(
      firstName: "Demo",
      profileImage: "",
      uid: "demo_uid",
      playerId: "",
    );
  }

  Future<void> removeDocument(String? id) async {
    // log("Remove document locally: $id");
  }

  Future<String> unBlockUser(Map<String, dynamic> data) async {
    // log("Unblock user locally: $data");
    return "User Unblocked";
  }

  Future<String> blockUser(Map<String, dynamic> data) async {
    // log("Block user locally: $data");
    return "User Blocked";
  }

  Future<bool> isUserBlocked(String uid) async {
    // log("Check if user is blocked locally: $uid");
    return false;
  }

  // User reference placeholder
  String getUserReference({required String uid}) {
    return uid;
  }
}
