import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mighty_fitness/service/health_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/horizontal_bar_chart.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/text_styles.dart';
import '../network/rest_api.dart';
import '../utils/app_constants.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  final HealthService healthService = HealthService();
  StreamSubscription<int>? _hrSub;

  int liveHeartRate = 0;
  bool isConnected = false;
  bool permissionDenied = false;
  bool isLoading = false;

  String get _healthPlatformName =>
      Platform.isIOS ? "Apple Health (HealthKit)" : "Google Health Connect";

  String get _healthPlatformSummary => Platform.isIOS
      ? "This screen reads your heart-rate data from Apple Health using HealthKit."
      : "This screen reads your heart-rate data from Google Health Connect.";

  String get _connectButtonLabel {
    if (isLoading) return "Connecting...";
    if (isConnected) return "Connected to $_healthPlatformName";
    return Platform.isIOS ? "Connect Apple Health" : "Connect Health Connect";
  }

  // =========================================================
  // INIT / DISPOSE
  // =========================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hrSub?.cancel();
    super.dispose();
  }

  /// 👂 Listen when user comes back from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && permissionDenied) {
      _connectHealth();
    }
  }

  // =========================================================
  // 🔐 CONNECT FLOW (USER DRIVEN)
  // =========================================================
  Future<void> _connectHealth() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      permissionDenied = false;
    });

    final granted = await healthService.requestPermission();

    if (!granted) {
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
      return;
    }

    _hrSub?.cancel();
    _hrSub = healthService.heartRateStream().listen((bpm) {
      if (!mounted) return;
      setState(() {
        liveHeartRate = bpm;
        isConnected = bpm > 0;
        permissionDenied = false;
      });
    });

    setState(() => isLoading = false);
  }

  // =========================================================
  // 🔓 OPEN APP SETTINGS
  // =========================================================
  Future<void> _openSettings() async {
    await openAppSettings();
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permissionDenied) _permissionBanner(),
            _integrationCard(),
            16.height,
            _heroCard(),
            20.height,
            _statsRow(),
            28.height,
            _sectionTitle("Diagnostics"),
            12.height,
            _heartRateCard(),
            20.height,
            _weightChart(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================
  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      title: Text(
        Platform.isIOS ? "Heart Health + HealthKit" : "Heart Health",
        style: boldTextStyle(size: 22, color: Colors.white),
      ),
    );
  }

  // =========================================================
  // 🚨 PERMISSION BANNER (CORRECT UX)
  // =========================================================
  Widget _permissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Colors.redAccent),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Permission Required",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  Platform.isIOS
                      ? "Please allow Apple Health (HealthKit) access to read your heart rate data."
                      : "Please allow Health Connect access to read your heart rate data.",
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openSettings,
            child: const Text(
              "OPEN SETTINGS",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _integrationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_outline, color: Colors.redAccent),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _healthPlatformName,
                  style: boldTextStyle(size: 16, color: Colors.black),
                ),
                6.height,
                Text(
                  _healthPlatformSummary,
                  style: secondaryTextStyle(color: Colors.black54, size: 13),
                ),
                8.height,
                Text(
                  "This feature is informational only and is not emergency or diagnostic care.",
                  style: secondaryTextStyle(color: Colors.black54, size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HERO CARD
  // =========================================================
  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1D8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Platform.isIOS ? "HealthKit" : "Health Connect",
                  style: secondaryTextStyle(color: Colors.black54, size: 13),
                ),
                10.height,
                Text(
                  Platform.isIOS
                      ? "Track your heart\nwith Apple Health"
                      : "Track your heart\nwith Health Connect",
                  style: boldTextStyle(size: 26, color: Colors.black),
                ),
                14.height,
                _connectButton(),
              ],
            ),
          ),
          const Icon(Icons.favorite, size: 72, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _connectButton() {
    return GestureDetector(
      onTap: _connectHealth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _connectButtonLabel,
          style: boldTextStyle(color: Colors.black),
        ),
      ),
    );
  }

  // =========================================================
  // STATS
  // =========================================================
  Widget _statsRow() {
    return Row(
      children: [
        _miniStat("Heart pressure", "123 / 80"),
        14.width,
        _miniStat("Heart rhythm", "$liveHeartRate / min"),
      ],
    );
  }

  Widget _miniStat(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: secondaryTextStyle(color: Colors.black54, size: 12)),
            10.height,
            Text(value, style: boldTextStyle(size: 20, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEART RATE CARD
  // =========================================================
  Widget _heartRateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F3F8),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Icon(Icons.show_chart, size: 40, color: Colors.blue),
          14.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Heartbeat",
                  style: secondaryTextStyle(color: Colors.black54)),
              6.height,
              Text(
                liveHeartRate > 0 ? "$liveHeartRate bpm" : "Waiting for data",
                style: boldTextStyle(size: 24, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WEIGHT
  // =========================================================
  Widget _weightChart() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Weight", style: boldTextStyle(color: Colors.black)),
          16.height,
          SizedBox(
            height: 200,
            child: FutureBuilder(
              future: getProgressApi(METRICS_WEIGHT),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return HorizontalBarChart(snapshot.data!.data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: boldTextStyle(size: 18, color: Colors.black));
  }
}
