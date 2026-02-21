import 'package:mighty_fitness/models/login_response.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

/// BaseService without Firestore
abstract class BaseService {
  BaseService();

  /// Dummy method to simulate adding a document
  Future<Map<String, dynamic>> addDocument(Map<String, dynamic> data) async {
    // generate a fake UID
    data[KEY_UID] = DateTime.now().millisecondsSinceEpoch.toString();
    return data;
  }

  /// Dummy method to simulate adding document with custom ID
  Future<Map<String, dynamic>> addDocumentWithCustomId(
      String id, Map<String, dynamic> data) async {
    data[KEY_UID] = id;
    return data;
  }

  /// Dummy update
  Future<void> updateDocument(Map<String, dynamic> data, String? id) async {
    // Implement your local update logic here
    print("Update called for ID $id with data $data");
  }

  /// Dummy remove
  Future<void> removeDocument(String id) async {
    print("Remove called for ID $id");
  }

  /// Dummy get list
  Future<List<Map<String, dynamic>>> getList() async {
    return [];
  }

  /// Dummy users stream
  Stream<List<UserModel>> users({String? searchText}) async* {
    yield [];
  }
}
