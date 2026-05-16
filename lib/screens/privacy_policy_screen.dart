import 'package:flutter/material.dart';
import 'package:mighty_fitness/extensions/extension_util/string_extensions.dart';
import 'package:mighty_fitness/extensions/extension_util/widget_extensions.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:flutter/services.dart';

import '../components/HtmlWidget.dart';
import '../main.dart';
import '../network/network_utils.dart';
import '../utils/app_constants.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final Future<String> _privacyFuture;

  @override
  void initState() {
    super.initState();
    _privacyFuture = _loadPrivacyContent();
  }

  String _cachedPrivacyContent() {
    final cached = userStore.privacyPolicy.validate();
    return cached.startsWith('http://') || cached.startsWith('https://')
        ? ''
        : cached;
  }

  Future<String> _loadPrivacyContent() async {
    try {
      final decoded = await handleResponse(
        await buildHttpResponse(PRIVACY_POLICY_URL, method: HttpMethod.GET),
      );

      final data = decoded is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>?
          : null;
      final content = data?['content']?.toString().validate() ?? '';

      if (content.isNotEmpty) {
        await userStore.setPrivacyPolicy(content, isInitialization: true);
        return content;
      }
    } catch (e, s) {
      debugPrint('Failed to load privacy content => $e');
      debugPrint('$s');
    }

    return _cachedPrivacyContent();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          languages.lblPrivacyPolicy,
          style: boldTextStyle(color: titleColor, size: 20),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: FutureBuilder<String>(
        future: _privacyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final content = snapshot.data.validate();
          if (content.isEmpty) {
            return Center(
              child: Text(
                'Unable to load privacy policy right now.',
                style: primaryTextStyle(),
              ),
            );
          }

          return SingleChildScrollView(
            child: HtmlWidget(postContent: content)
                .paddingSymmetric(horizontal: 8)
                .paddingOnly(bottom: 20),
          );
        },
      ),
    );
  }
}
