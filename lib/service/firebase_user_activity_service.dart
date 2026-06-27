import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../extensions/extension_util/string_extensions.dart';
import '../models/login_response.dart' as login_model;
import '../models/social_login_response.dart' as social_model;

class FirebaseUserActivityService {
  FirebaseUserActivityService._();

  static const bool _firestoreUserMirrorEnabled = bool.fromEnvironment(
    'FIREBASE_USER_MIRROR_ENABLED',
    defaultValue: false,
  );

  static final FirebaseUserActivityService instance =
      FirebaseUserActivityService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> trackEmailLogin({
    required login_model.UserModel user,
    required Map request,
  }) async {
    await _trackSafely(
      eventName: 'login',
      method: 'email',
      user: _userMapFromLoginModel(user),
      password: request['password']?.toString(),
      isRegistration: false,
    );
  }

  Future<void> trackRegistration({
    required login_model.UserModel user,
    required Map request,
  }) async {
    await _trackSafely(
      eventName: 'sign_up',
      method:
          request['login_type']?.toString().validate(value: 'email') ?? 'email',
      user: _userMapFromLoginModel(user),
      password: request['password']?.toString(),
      isRegistration: true,
    );
  }

  Future<void> trackSocialLogin({
    required social_model.Data user,
    required Map request,
  }) async {
    await _trackSafely(
      eventName: 'login',
      method: request['login_type']?.toString().validate(value: 'social') ??
          'social',
      user: _userMapFromSocialModel(user),
      idToken: request['id_token']?.toString(),
      accessToken: request['accessToken']?.toString(),
      isRegistration: false,
    );
  }

  Future<void> trackGoogleAuth({
    required Map<String, dynamic> user,
    required Map<String, dynamic> request,
    required String action,
  }) async {
    await _trackSafely(
      eventName: action == 'register' ? 'sign_up' : 'login',
      method: 'google',
      user: user,
      idToken: request['id_token']?.toString(),
      accessToken: request['access_token']?.toString().isNotEmpty == true
          ? request['access_token']?.toString()
          : request['accessToken']?.toString(),
      isRegistration: action == 'register',
    );
  }

  Future<void> _trackSafely({
    required String eventName,
    required String method,
    required Map<String, dynamic> user,
    String? password,
    String? idToken,
    String? accessToken,
    required bool isRegistration,
  }) async {
    try {
      if (user.isEmpty) return;

      final firebaseUser = await _ensureFirebaseUser(
        user: user,
        method: method,
        password: password,
        idToken: idToken,
        accessToken: accessToken,
        isRegistration: isRegistration,
      );

      final firebaseUid = firebaseUser?.uid ?? _fallbackDocumentId(user);

      await _analytics.setUserId(id: firebaseUid);
      await _analytics.setUserProperty(name: 'login_type', value: method);
      await _logRecommendedAuthEvent(
        eventName: eventName,
        method: method,
      );

      if (!_firestoreUserMirrorEnabled) return;

      final userDoc = _firestore.collection('users').doc(firebaseUid);
      final now = FieldValue.serverTimestamp();
      final apiUserId = user['id']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';
      final firstName = user['first_name']?.toString() ?? '';
      final lastName = user['last_name']?.toString() ?? '';
      final displayName = user['display_name']?.toString().isNotEmpty == true
          ? user['display_name'].toString()
          : '$firstName $lastName'.trim();

      await userDoc.set(
        {
          'firebaseUid': firebaseUid,
          'apiUserId': apiUserId,
          'name': displayName,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': user['phone_number']?.toString() ?? '',
          'provider': method,
          'loginType': method,
          'profileImage': user['profile_image']?.toString() ?? '',
          'subscriptionStatus': user['is_subscribe'],
          'updatedAt': now,
          'lastLoginAt': now,
          if (isRegistration) 'createdAt': now,
          if (firebaseUser != null) 'firebaseAuthLinked': true,
        },
        SetOptions(merge: true),
      );

      await userDoc.collection('login_logs').add({
        'firebaseUid': firebaseUid,
        'apiUserId': apiUserId,
        'email': email,
        'provider': method,
        'event': eventName,
        'loginAt': now,
        'platform': defaultTargetPlatform.name,
      });
    } catch (error, stack) {
      debugPrint('Firebase activity tracking failed: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _logRecommendedAuthEvent({
    required String eventName,
    required String method,
  }) async {
    if (eventName == 'sign_up') {
      await _analytics.logSignUp(signUpMethod: method);
      return;
    }

    if (eventName == 'login') {
      await _analytics.logLogin(loginMethod: method);
      return;
    }

    await _analytics.logEvent(
      name: eventName,
      parameters: {'method': method},
    );
  }

  Future<User?> _ensureFirebaseUser({
    required Map<String, dynamic> user,
    required String method,
    String? password,
    String? idToken,
    String? accessToken,
    required bool isRegistration,
  }) async {
    try {
      if (method == 'google' && idToken.validate().isNotEmpty) {
        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken.validate().isNotEmpty ? accessToken : null,
        );
        return (await _auth.signInWithCredential(credential)).user;
      }

      if (method == 'apple' && idToken.validate().isNotEmpty) {
        final provider = OAuthProvider('apple.com');
        final credential = provider.credential(
          idToken: idToken,
          accessToken: accessToken.validate().isNotEmpty ? accessToken : null,
        );
        return (await _auth.signInWithCredential(credential)).user;
      }

      final email = user['email']?.toString().trim() ?? '';
      if (email.isEmpty || password.validate().isEmpty) {
        return _matchingCurrentUser(email);
      }

      if (isRegistration) {
        try {
          return (await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password!,
          ))
              .user;
        } on FirebaseAuthException catch (error) {
          if (error.code != 'email-already-in-use') rethrow;
        }
      }

      return (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password!,
      ))
          .user;
    } on PlatformException catch (error) {
      debugPrint('Firebase Auth unavailable: ${error.message}');
      return _matchingCurrentUser(user['email']?.toString().trim() ?? '');
    } on FirebaseAuthException catch (error) {
      debugPrint('Firebase Auth skipped: ${error.code}');
      return _matchingCurrentUser(user['email']?.toString().trim() ?? '');
    } catch (error) {
      debugPrint('Firebase Auth skipped: $error');
      return _matchingCurrentUser(user['email']?.toString().trim() ?? '');
    }
  }

  User? _matchingCurrentUser(String email) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    if (email.isEmpty) return currentUser;
    return currentUser.email?.trim().toLowerCase() == email.toLowerCase()
        ? currentUser
        : null;
  }

  Map<String, dynamic> _userMapFromLoginModel(login_model.UserModel user) {
    return {
      'id': user.id,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'display_name': user.displayName,
      'profile_image': user.profileImage,
      'is_subscribe': user.isSubscribe,
    };
  }

  Map<String, dynamic> _userMapFromSocialModel(social_model.Data user) {
    return {
      'id': user.id,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'display_name': user.displayName,
      'profile_image': user.profileImage,
    };
  }

  String _fallbackDocumentId(Map<String, dynamic> user) {
    final rawId = user['id']?.toString() ?? '';
    if (rawId.isNotEmpty) return 'api_$rawId';

    final email = user['email']?.toString().trim().toLowerCase() ?? '';
    if (email.isNotEmpty) {
      return 'email_${sha256.convert(utf8.encode(email))}';
    }

    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }
}
