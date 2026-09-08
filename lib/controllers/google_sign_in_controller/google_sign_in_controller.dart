import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mighty_fitness/extensions/extension_util/int_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/shared_pref.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/network/network_utils.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/complete_profile_screen.dart';
import 'package:mighty_fitness/service/firebase_user_activity_service.dart';
import 'package:mighty_fitness/utils/app_constants.dart';
import 'package:mighty_fitness/utils/subscription_navigation.dart';

class GoogleAuthController extends GetxController {
  static const String _googleWebServerClientId =
      '254180435384-liv5jj2tj8jm7lddc0kgo6sma5t4o3cf.apps.googleusercontent.com';
  static const List<String> _googleScopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  final RxBool isLoading = false.obs;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  static const String _googleAuthApi = 'google-auth';

  int _subscriptionFlagFromValue(dynamic value) {
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toInt();

    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == 'yes') return 1;
    return int.tryParse(text) ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    if (_isGoogleInitialized) return;
    await _google.initialize(serverClientId: _googleWebServerClientId);
    _isGoogleInitialized = true;
  }

  Future<String?> _getAccessToken(GoogleSignInAccount googleUser) async {
    try {
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(
                _googleScopes,
              ) ??
              await googleUser.authorizationClient.authorizeScopes(
                _googleScopes,
              );
      return authorization.accessToken;
    } catch (e, s) {
      debugPrint('Google access token request failed => $e');
      debugPrint('$s');
      return null;
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      await _initializeGoogle();
      await _google.signOut();
      final googleUser = await _google.authenticate();
      final auth = googleUser.authentication;
      final accessToken = await _getAccessToken(googleUser);

      if (auth.idToken == null) {
        throw Exception(
            'Google ID token missing. Check SHA-1/client ID config.');
      }

      final displayName = googleUser.displayName ?? '';
      final parts = displayName.trim().split(' ');

      final request = {
        'email': googleUser.email,
        'username': googleUser.email,
        'provider_id': googleUser.id,
        'login_type': 'google',
        'first_name': parts.isNotEmpty ? parts.first : '',
        'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'user_type': LoginUser,
        'status': statusActive,
        'player_id': getStringAsync(PLAYER_ID).validate(),
        'id_token': auth.idToken,
        'accessToken': accessToken ?? auth.idToken ?? '',
        'access_token': accessToken ?? '',
        'photo_url': googleUser.photoUrl ?? '',
        'accepted_terms': 1,
        'accepted_privacy': 1,
      };
      await setValue('TEMP_EMAIL', googleUser.email);
      await setValue('TEMP_FIRST_NAME', parts.isNotEmpty ? parts.first : '');
      await setValue(
          'TEMP_LAST_NAME', parts.length > 1 ? parts.sublist(1).join(' ') : '');
      await setValue('TEMP_LOGIN_TYPE', 'google');
      await setValue('TEMP_PROVIDER_ID', googleUser.id);
      await setValue('TEMP_ID_TOKEN', auth.idToken ?? '');
      await setValue('TEMP_ACCESS_TOKEN', accessToken ?? '');
      debugPrint('GOOGLE LOGIN REQUEST => $request');
      final result = await _loginWithBackend(request);
      final String action = result['action'];
      if (action == 'register') {
        Get.offAll(() => const CompleteProfileScreen());
      } else {
        openPostAuthDestination(allowFreeAutopayPrompt: false);
      }
    } catch (e, s) {
      debugPrint('Google Sign-In Error => $e');
      debugPrint('$s');

      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
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

  Future<Map<String, dynamic>> _loginWithBackend(
      Map<String, dynamic> request) async {
    try {
      return await _googleLoginApi(request);
    } catch (e, s) {
      debugPrint('google-auth failed, trying social-mail-login => $e');
      debugPrint('$s');
      return _legacyGoogleLoginApi(request);
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
      final Map<String, dynamic>? decodedError = _tryDecodeJson(response.body);
      final message = decodedError?['message']?.toString();
      throw Exception(message ?? 'Google auth API failed');
    }

    final decoded = jsonDecode(response.body);
    final String action = decoded['action']?.toString() ?? '';
    final Map<String, dynamic> data =
        (decoded['data'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    if (action.isEmpty) {
      throw Exception('Invalid auth response: missing action');
    }

    if (action == 'login') {
      if (data['api_token'] == null) {
        throw Exception('Invalid auth response: missing api_token');
      }

      await _saveAuthData(data);
      await _updateUserFromAuth(data);
      await FirebaseUserActivityService.instance.trackGoogleAuth(
        user: data,
        request: request,
        action: action,
      );
    } else {
      if ((data['email']?.toString().isNotEmpty ?? false)) {
        await setValue('TEMP_EMAIL', data['email']);
      }
      if ((data['first_name']?.toString().isNotEmpty ?? false)) {
        await setValue('TEMP_FIRST_NAME', data['first_name']);
      }
      if ((data['last_name']?.toString().isNotEmpty ?? false)) {
        await setValue('TEMP_LAST_NAME', data['last_name']);
      }
      await setValue('TEMP_LOGIN_TYPE', 'google');
    }

    return {
      'action': action,
      'data': data,
    };
  }

  Future<Map<String, dynamic>> _legacyGoogleLoginApi(
      Map<String, dynamic> request) async {
    final response = await socialLogInApi({
      'email': request['email'],
      'username': request['username'],
      'first_name': request['first_name'],
      'last_name': request['last_name'],
      'login_type': request['login_type'],
      'user_type': request['user_type'],
      'status': request['status'],
      'player_id': request['player_id'],
      'accessToken': request['accessToken'] ?? request['access_token'] ?? '',
      'photo_url': request['photo_url'] ?? '',
    });

    final data = response.data?.toJson() ?? <String, dynamic>{};
    final token = response.data?.apiToken?.validate() ?? '';

    if (token.isNotEmpty) {
      data['api_token'] = token;
      await _saveAuthData(data);
      await _updateUserFromAuth(data);
      await FirebaseUserActivityService.instance.trackGoogleAuth(
        user: data,
        request: request,
        action: 'login',
      );
      return {
        'action': 'login',
        'data': data,
      };
    }

    if ((request['email']?.toString().isNotEmpty ?? false)) {
      await setValue('TEMP_EMAIL', request['email']);
    }
    if ((request['first_name']?.toString().isNotEmpty ?? false)) {
      await setValue('TEMP_FIRST_NAME', request['first_name']);
    }
    if ((request['last_name']?.toString().isNotEmpty ?? false)) {
      await setValue('TEMP_LAST_NAME', request['last_name']);
    }
    await setValue('TEMP_LOGIN_TYPE', 'google');

    return {
      'action': 'register',
      'data': data,
    };
  }

  Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await setValue(TOKEN, data['api_token']);
    await setValue(USER_ID, data['id']);
    await setValue(IS_LOGIN, true);
    await setValue(IS_SOCIAL, true);
    await userStore.setToken(data['api_token']);
    await userStore.setUserID(data['id']);
    await refreshCompanyAccessAfterAuth();
    await userStore.setLogin(true);
  }

  Future<void> _updateUserFromAuth(Map<String, dynamic> data) async {
    await userStore.setUserEmail(data['email'] ?? '');
    await userStore.setFirstName(data['first_name'] ?? '');
    await userStore.setLastName(data['last_name'] ?? '');
    await userStore.setDisplayName(data['display_name'] ?? '');
    await userStore.setUserImage(data['profile_image'] ?? '');
    await userStore.setSubscribe(_subscriptionFlagFromValue(
      data['is_subscribe'],
    ));
    final profile = data['user_profile_data'];
    if (profile != null) {
      await userStore.setAge(profile['age']?.toString() ?? '');
      await userStore.setWeight(profile['weight']?.toString() ?? '');
      await userStore.setHeight(profile['height']?.toString() ?? '');
      await userStore.setWeightUnit(profile['weight_unit'] ?? 'kg');
      await userStore.setHeightUnit(profile['height_unit'] ?? 'cm');
      await userStore.setGoal(profile['goal']?.toString() ?? '');
      await userStore.setlevel(profile['workout_level']?.toString() ?? '');

      final workoutMode =
          int.tryParse(profile['workout_mode']?.toString() ?? '');
      if (workoutMode != null && workoutMode > 0) {
        await userStore.setWorkoutLoc(workoutMode.toString());
        await setValue(WORKOUT_MODE, workoutMode);
      }
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
