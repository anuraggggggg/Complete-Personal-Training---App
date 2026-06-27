// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/string_extensions.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import '../extensions/shared_pref.dart';
import '../extensions/system_utils.dart';
import '../main.dart';
import '../network/rest_api.dart';
import '../utils/app_common.dart';
import '../utils/app_constants.dart';

// final FirebaseAuth _auth = FirebaseAuth.instance;
// final GoogleSignIn googleSignIn = GoogleSignIn();

// Future<User> signInWithGoogle() async {
//   GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

//   if (googleSignInAccount != null) {
//     final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

//     // final AuthCredential credential = GoogleAuthProvider.credential(
//     //   accessToken: googleSignInAuthentication.accessToken,
//     //   idToken: googleSignInAuthentication.idToken,
//     // );

//     // final UserCredential authResult = await _auth.signInWithCredential(credential);
//     // final User user = authResult.user!;

//     // assert(!user.isAnonymous);

//     // final User currentUser = _auth.currentUser!;
//     // assert(user.uid == currentUser.uid);

//     signOutGoogle();

//     String firstName = '';
//     String lastName = '';

//     if (googleSignInAccount != null) {
//       firstName = googleSignInAccount.displayName?.split(' ').first ?? '';
//       lastName = googleSignInAccount.displayName?.split(' ').last ?? '';

//       print("First Name: $firstName");
//       print("Last Name: $lastName");
//     }

//     // await userStore.setUserImage(currentUser.photoURL.validate());

//     Map req = {
//       // "email": currentUser.email,
//       // "username": currentUser.email,
//       // "first_name": firstName,
//       // "last_name": lastName,
//       // "login_type": LoginTypeGoogle,
//       // "user_type": LoginUser,
//       // 'status': statusActive,
//       // 'player_id': getStringAsync(PLAYER_ID).validate(),
//       // "accessToken": googleSignInAuthentication.accessToken,
//       // if (!currentUser.phoneNumber.isEmptyOrNull) "phone_number": currentUser.phoneNumber.validate(),
//     };

//     return await socialLogInApi(req).then((value) async {
//       await userStore.setToken(value.data!.apiToken.validate());
//       await userStore.setUserID(value.data!.id.validate());
//       await userStore.setFirstName(value.data!.firstName.validate());
//       await userStore.setLastName(value.data!.lastName.validate());
//       await userStore.setGender(value.data!.gender.validate());
//       await userStore.setLogin(true);

//       // return currentUser;
//     }).catchError((e) {
//       log("e->" + e);
//       throw e;
//     });
//   } else {
//     throw errorSomethingWentWrong;
//   }
// }

// Future<void> signOutGoogle() async {
//   await googleSignIn.signOut();
// }

Future<void> loginWithOTP(
    BuildContext context, String phoneNumber, String mobileNo) async {
  appStore.setLoading(true);
  // return await _auth.verifyPhoneNumber(
  //   phoneNumber: phoneNumber,
  //   verificationCompleted: (PhoneAuthCredential credential) async {},
  //   verificationFailed: (FirebaseAuthException e) {
  //     appStore.setLoading(false);
  //     if (e.code == 'invalid-phone-number') {
  //       toast('The provided phone number is not valid.');
  //       throw 'The provided phone number is not valid.';
  //     } else {
  //       toast(e.toString());
  //       throw e.toString();
  //     }
  //   },
  //   timeout: Duration(minutes: 1),
  //   codeSent: (String verificationId, int? resendToken) async {
  //     finish(context);
  //     VerifyOTPScreen(
  //       verificationId: verificationId,
  //       isCodeSent: true,
  //       phoneNumber: phoneNumber,
  //       mobileNo: mobileNo,
  //     ).launch(context);
  //   },
  //   codeAutoRetrievalTimeout: (String verificationId) {
  //     //
  //   },
  // );
}

Future<bool> appleLogIn() async {
  if (!await TheAppleSignIn.isAvailable()) {
    toast('Apple SignIn is not available for your device');
    return false;
  }

  try {
    final AuthorizationResult result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    switch (result.status) {
      case AuthorizationStatus.authorized:
        log("Result: $result");

        final authorizationCode = result.credential?.authorizationCode;
        final String accessToken = authorizationCode == null
            ? ''
            : String.fromCharCodes(authorizationCode).trim();

        if (accessToken.isEmpty) {
          toast('Unable to complete Apple Sign-In. Please try again.');
          return false;
        }

        final String email = result.credential?.email?.trim() ?? '';
        if (email.isEmpty) {
          return await saveAppleDataWithoutEmail(
            result,
            accessToken,
          );
        }

        return await saveAppleData(result);
      case AuthorizationStatus.error:
        final String message =
            result.error?.localizedDescription?.trim().isNotEmpty == true
                ? result.error!.localizedDescription!
                : 'Apple Sign-In failed. Please try again.';
        log("Sign in failed: $message");
        toast(message);
        return false;
      case AuthorizationStatus.cancelled:
        log('User cancelled');
        return false;
    }
  } catch (e) {
    log("Apple Sign-In error: $e");
    toast('Unable to complete Apple Sign-In. Please try again.');
    return false;
  }
}

String _appleFallbackEmail(AuthorizationResult result) {
  final String savedEmail = getStringAsync('appleEmail').trim();
  if (savedEmail.isNotEmpty) return savedEmail;

  final String rawUserId = result.credential?.user?.trim() ?? '';
  final String sanitizedUserId =
      rawUserId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

  if (sanitizedUserId.isNotEmpty) {
    return 'apple_$sanitizedUserId@cpt.apple';
  }

  return '';
}

String _appleFirstName(AuthorizationResult result) {
  final String currentFirstName =
      result.credential?.fullName?.givenName?.trim() ?? '';
  if (currentFirstName.isNotEmpty) return currentFirstName;

  final String savedFirstName = getStringAsync('appleGivenName').trim();
  if (savedFirstName.isNotEmpty) return savedFirstName;

  return 'Apple';
}

String _appleLastName(AuthorizationResult result) {
  final String currentLastName =
      result.credential?.fullName?.familyName?.trim() ?? '';
  if (currentLastName.isNotEmpty) return currentLastName;

  final String savedLastName = getStringAsync('appleFamilyName').trim();
  if (savedLastName.isNotEmpty) return savedLastName;

  return 'User';
}

Future<bool> saveAppleData(
  AuthorizationResult result,
) async {
  final String email = result.credential?.email?.trim() ?? '';
  final String firstName = _appleFirstName(result);
  final String lastName = _appleLastName(result);
  final String authorizationCode = result.credential?.authorizationCode == null
      ? ''
      : String.fromCharCodes(result.credential!.authorizationCode!).trim();
  final String identityToken = result.credential?.identityToken == null
      ? ''
      : String.fromCharCodes(result.credential!.identityToken!).trim();

  if (email.isEmpty || authorizationCode.isEmpty) {
    toast('Unable to complete Apple Sign-In. Please try again.');
    return false;
  }

  await setValue('appleEmail', email);
  await setValue('appleGivenName', firstName);
  await setValue('appleFamilyName', lastName);

  log('Email:- ${getStringAsync('appleEmail')}');
  log('appleGivenName:- ${getStringAsync('appleGivenName')}');
  log('appleFamilyName:- ${getStringAsync('appleFamilyName')}');

  var req = {
    'email': email.validate(),
    "username": email.validate(),
    'first_name': firstName.validate(),
    'last_name': lastName.validate(),
    "user_type": LoginUser,
    'status': statusActive,
    'player_id': getStringAsync(PLAYER_ID).toString().validate(),
    'accessToken': authorizationCode,
    'id_token': identityToken,
    // 'photoURL': '',
    'login_type': LoginTypeApple,
  };
  return socialLogin(req);
}

Future<bool> socialLogin(req) async {
  appStore.setLoading(true);
  return await socialLogInApi(req).then((res) async {
    appStore.setLoading(false);
    await userStore.setUserID(res.data!.id.validate());
    await userStore.setFirstName(res.data!.firstName.validate());
    await userStore.setLastName(res.data!.lastName.validate());
    await userStore.setGender(res.data!.gender.validate());
    await userStore.setToken(res.data!.apiToken.validate());
    await userStore.setLogin(true);
    await userStore.setUserEmail(res.data!.email.validate());
    await userStore.setUsername(res.data!.email.validate());
    await userStore.setUserImage(res.data!.profileImage.validate());
    await userStore.setDisplayName(res.data!.displayName.validate());
    await userStore.setPhoneNo(res.data!.phoneNumber.validate());
    return true;
    // getUSerDetail(context, res.data!.id.validate()).then((value) {
    //   DashboardScreen().launch(context, isNewTask: true);
    // }).catchError((e) {
    //   print("error=>" + e.toString());
    // });
  }).catchError((error) {
    appStore.setLoading(false);
    toast(error.toString());
    return false;
  });
}

Future deleteUser() async {
  // if (FirebaseAuth.instance.currentUser != null) {
  //   FirebaseAuth.instance.currentUser!.delete();
  //   await FirebaseAuth.instance.signOut();
  // }
}

Future<bool> saveAppleDataWithoutEmail(
  AuthorizationResult result,
  String? accessToken,
) async {
  final String fallbackEmail = _appleFallbackEmail(result);
  final String firstName = _appleFirstName(result);
  final String lastName = _appleLastName(result);

  if (fallbackEmail.isNotEmpty) {
    await setValue('appleEmail', fallbackEmail);
  }
  await setValue('appleGivenName', firstName);
  await setValue('appleFamilyName', lastName);

  var req = {
    'email': fallbackEmail,
    "username": fallbackEmail,
    'first_name': firstName,
    'last_name': lastName,
    "user_type": LoginUser,
    'status': statusActive,
    'player_id': getStringAsync(PLAYER_ID).validate(),
    'accessToken': accessToken,
    'id_token': result.credential?.identityToken == null
        ? ''
        : String.fromCharCodes(result.credential!.identityToken!).trim(),
    // 'photoURL': '',
    'login_type': LoginTypeApple,
  };

  if (fallbackEmail.isEmpty) {
    toast('Unable to complete Apple Sign-In. Please try again.');
    return false;
  }

  return socialLogin(req);
}

Future deleteUserFirebase() async {
  // if (FirebaseAuth.instance.currentUser != null) {
  //   FirebaseAuth.instance.currentUser?.delete();
  //   await FirebaseAuth.instance.signOut();
  // }
}

Future<void> logout(BuildContext context, {Function? onLogout}) async {
  await removeKey(IS_LOGIN);
  await removeKey(USER_ID);
  await removeKey(FIRSTNAME);
  await removeKey(LASTNAME);
  await removeKey(USER_PROFILE_IMG);
  await removeKey(DISPLAY_NAME);
  await removeKey(PHONE_NUMBER);
  await removeKey(GENDER);
  await removeKey(AGE);
  await removeKey(HEIGHT);
  await removeKey(HEIGHT_UNIT);
  await removeKey(IS_OTP);
  await removeKey(IS_SOCIAL);
  await removeKey(WEIGHT);
  await removeKey(WEIGHT_UNIT);
  userStore.clearUserData();
  if (getBoolAsync(IS_SOCIAL) ||
      !getBoolAsync(IS_REMEMBER) ||
      getBoolAsync(IS_OTP) == true) {
    await removeKey(PASSWORD);
    await removeKey(EMAIL);
  }
  userStore.setLogin(false);
  onLogout?.call();
}
