import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mighty_fitness/screens/bluetooth/bluetooth_service.dart';

import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/text_styles.dart';
import '../../utils/app_colors.dart';

class WatchSearchScreen extends StatefulWidget {
  const WatchSearchScreen({Key? key}) : super(key: key);

  @override
  State<WatchSearchScreen> createState() => _WatchSearchScreenState();
}

class _WatchSearchScreenState extends State<WatchSearchScreen>
    with SingleTickerProviderStateMixin {
  final MyBluetoothService bluetoothService = MyBluetoothService();
  StreamSubscription<List<ScanResult>>? _scanSub;

  List<ScanResult> devices = [];
  bool isScanning = true;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    _scanSub = bluetoothService.scanDevices().listen((results) {
      setState(() {
        devices = results
            .where((e) => e.device.platformName.isNotEmpty)
            .toList();
        isScanning = false;
      });
    });
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await bluetoothService.connect(device);
      Navigator.pop(context);
      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      Navigator.pop(context, false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor, // ✅ FIX
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: BackButton(color: Colors.white),
        title: Text(
          "Connect Watch",
          style: boldTextStyle(color: Colors.white),
        ),
    
      ),
      body: Column(
        children: [
          _header(),
          Expanded(child: _deviceList()),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.05).animate(
              CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
            ),
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(0.4),
                    primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: const Icon(
                Icons.watch,
                size: 52,
                color: Colors.white,
              ),
            ),
          ),
          20.height,
          Text(
            "Searching for nearby devices",
            style: boldTextStyle(size: 18),
          ),
          6.height,
          Text(
            "Make sure your watch is powered on",
            style: secondaryTextStyle(),
          ),
        ],
      ),
    );
  }

  // ================= DEVICE LIST =================
  Widget _deviceList() {
    if (isScanning && devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isScanning && devices.isEmpty) {
      return _emptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final d = devices[index].device;

        return GestureDetector(
          onTap: () => _connectDevice(d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
            
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.15),
                  ),
                  child: Icon(Icons.watch, color: primaryColor),
                ),
                14.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.platformName, style: boldTextStyle()),
                      4.height,
                      Text(
                        d.remoteId.toString(),
                        style: secondaryTextStyle(size: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: primaryColor),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= EMPTY STATE =================
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled,
                size: 60, color: primaryColor.withOpacity(0.6)),
            16.height,
            Text("No devices found", style: boldTextStyle()),
            8.height,
            Text(
              "Turn on Bluetooth & keep watch nearby",
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
