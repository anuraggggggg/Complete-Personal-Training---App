import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/network/network_utils.dart';
import 'package:mighty_fitness/screens/complete_profile_screen.dart';
import 'package:mighty_fitness/screens/dashboard_screen.dart';
import 'package:mighty_fitness/utils/app_constants.dart';

class GoogleAuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final GoogleSignIn _google = GoogleSignIn.instance;

  static const String _googleAuthApi = 'google-auth';
  static const String _serverClientId =
      '570223930504-ge2d3ss60jhf2eenukek9isg8fa7n0l0.apps.googleusercontent.com';
  // static const String _serverClientId =
  //     '325854241528-s145hlrheger3fcf5hus1sr7igkqlppr.apps.googleusercontent.com';

  @override
  void onInit() {
    super.onInit();
    _google.initialize(serverClientId: _serverClientId);
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      await _google.signOut();

      final googleUser = await _google.authenticate();
      final auth = googleUser.authentication;

      if (auth.idToken == null) {
        throw Exception('Google ID token missing. Check SHA-1/client ID config.');
      }

      final displayName = googleUser.displayName ?? '';
      final parts = displayName.trim().split(' ');

      final request = {
        'email': googleUser.email,
        'provider_id': googleUser.id,
        'login_type': 'google',
        'first_name': parts.isNotEmpty ? parts.first : '',
        'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'id_token': auth.idToken,
      };

      debugPrint('GOOGLE LOGIN REQUEST => $request');

      final result = await _googleLoginApi(request);
      final String action = result['action'];

      if (action == 'register') {
        Get.offAll(() => const CompleteProfileScreen());
      } else {
        Get.offAll(() => DashboardScreen());
      }
    } catch (e, s) {
      debugPrint('Google Sign-In Error => $e');
      debugPrint('$s');

      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('sign_in_failed')) {
        return;
      }

      Get.snackbar(
        'Login Failed',
        'Google sign-in failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _googleLoginApi(
      Map<String, dynamic> request) async {
    final response = await buildHttpResponse(
      _googleAuthApi,
      request: request,
      method: HttpMethod.POST,
    );

    if (!response.statusCode.isSuccessful()) {
      throw Exception('Google auth API failed');
    }

    final decoded = jsonDecode(response.body);
    final String action = decoded['action'];
    final Map<String, dynamic> data = decoded['data'];

    if (action == 'login') {
      if (data['api_token'] == null) {
        throw Exception('Invalid login response');
      }
      await _saveAuthData(data);
      await _updateUserFromAuth(data);
    } else {
      await setValue('TEMP_EMAIL', data['email']);
      await setValue('TEMP_FIRST_NAME', data['first_name']);
      await setValue('TEMP_LAST_NAME', data['last_name']);
      await setValue('TEMP_LOGIN_TYPE', 'google');
    }

    return {
      'action': action,
      'data': data,
    };
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await setValue(TOKEN, data['api_token']);
    await setValue(USER_ID, data['id']);
    await setValue(IS_LOGIN, true);
    await setValue(IS_SOCIAL, true);

    await userStore.setToken(data['api_token']);
    await userStore.setUserID(data['id']);
    await userStore.setLogin(true);
  }

  Future<void> _updateUserFromAuth(Map<String, dynamic> data) async {
    await userStore.setUserEmail(data['email'] ?? '');
    await userStore.setFirstName(data['first_name'] ?? '');
    await userStore.setLastName(data['last_name'] ?? '');
    await userStore.setDisplayName(data['display_name'] ?? '');
    await userStore.setUserImage(data['profile_image'] ?? '');
    await userStore.setSubscribe(data['is_subscribe'] ?? 0);

    final profile = data['user_profile_data'];
    if (profile != null) {
      await userStore.setAge(profile['age']?.toString() ?? '');
      await userStore.setWeight(profile['weight']?.toString() ?? '');
      await userStore.setHeight(profile['height']?.toString() ?? '');
      await userStore.setWeightUnit(profile['weight_unit'] ?? 'kg');
      await userStore.setHeightUnit(profile['height_unit'] ?? 'cm');
    }
  }

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await clearSharedPref();
    userStore.clearUserData();
    Get.offAllNamed('/login');
  }
}
