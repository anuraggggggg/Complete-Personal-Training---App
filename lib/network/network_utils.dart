import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import '../../extensions/extension_util/int_extensions.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/system_utils.dart';
import '../main.dart';
import '../utils/app_config.dart';


// ==============================
// HEADERS
// ==============================
Map<String, String> buildHeaderTokens() {
  final Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
  };

  final token = userStore.token;

  if (token.isNotEmpty) {
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';
  }

  log(jsonEncode(header));
  return header;
}

// ==============================
// BASE URL
// ==============================
Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) {
    url = Uri.parse('$mBaseUrl$endPoint');
  }

  log('URL: $url');
  return url;
}

// ==============================
// HTTP CALL
// ==============================
Future<Response> buildHttpResponse(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map? request,
}) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }

  final headers = buildHeaderTokens();
  final url = buildBaseUrl(endPoint);

  late Response response;

  if (method == HttpMethod.POST) {
    log('Request: $request');
    response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(request),
    );
  } else if (method == HttpMethod.PUT) {
    response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(request),
    );
  } else if (method == HttpMethod.DELETE) {
    response = await http.delete(url, headers: headers);
  } else {
    response = await http.get(url, headers: headers);
  }

  log('Response ($method): ${response.statusCode} ${response.body}');
  return response;
}

// ==============================
// RESPONSE HANDLER (🔥 FIXED)
// ==============================
Future handleResponse(Response response) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }

  // ✅ SUCCESS
  if (response.statusCode.isSuccessful()) {
    return jsonDecode(response.body);
  }

  // 🔐 401 → DO NOT LOGOUT
  if (response.statusCode == 401) {
    log("⚠️ Unauthenticated – handled safely");
    return null; // IMPORTANT
  }

  // ❌ OTHER ERRORS
  final message = await isJsonValid(response.body);
  if (message != null && message.isNotEmpty) {
    throw message;
  }

  throw 'Please try again later';
}

// ==============================
// ENUM
// ==============================
enum HttpMethod { GET, POST, DELETE, PUT }

// ==============================
// JSON VALIDATOR
// ==============================
Future<String?> isJsonValid(dynamic json) async {
  try {
    final Map<String, dynamic> data = jsonDecode(json);
    return data['message'];
  } catch (_) {
    return '';
  }
}

// ==============================
// MULTIPART
// ==============================
Future<MultipartRequest> getMultiPartRequest(
  String endPoint, {
  String? baseUrl,
}) async {
  final url = baseUrl ?? buildBaseUrl(endPoint).toString();
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future<void> sendMultiPartRequest(
  MultipartRequest request, {
  Function(dynamic)? onSuccess,
  Function(dynamic)? onError,
}) async {
  final response =
      await http.Response.fromStream(await request.send());

  log("Multipart Result: ${response.body}");

  if (response.statusCode.isSuccessful()) {
    onSuccess?.call(response.body);
  } else {
    onError?.call(errorSomethingWentWrong);
  }
}
