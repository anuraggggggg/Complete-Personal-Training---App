import 'dart:async';
import 'dart:developer';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// 🔵 Bluetooth Service (Heart Rate Enabled)
class MyBluetoothService {
  // ================= SINGLETON =================
  static final MyBluetoothService _instance = MyBluetoothService._internal();
  factory MyBluetoothService() => _instance;
  MyBluetoothService._internal();

  // ================= STATE =================
  fbp.BluetoothDevice? connectedDevice;
  fbp.BluetoothCharacteristic? _heartRateChar;

  StreamSubscription<List<int>>? _notifySub;
  final StreamController<int> _heartRateController =
      StreamController<int>.broadcast();

  // ================= PUBLIC STREAM =================
  Stream<int> get heartRateStream => _heartRateController.stream;

  // =====================================================
  // INIT
  // =====================================================
  void initBluetooth() {
    fbp.FlutterBluePlus.adapterState.listen((state) {
      log("Bluetooth Adapter: $state");
      if (state != fbp.BluetoothAdapterState.on) {
        disconnect();
      }
    });
  }

  // =====================================================
  // SCAN
  // =====================================================
  Stream<List<fbp.ScanResult>> scanDevices() {
    if (!fbp.FlutterBluePlus.isScanningNow) {
      fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
    }
    return fbp.FlutterBluePlus.scanResults;
  }

  // =====================================================
  // CONNECT
  // =====================================================
  Future<void> connect(fbp.BluetoothDevice device) async {
    await disconnect();

    log("Connecting to ${device.platformName}");

    await device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );

    connectedDevice = device;
    await _discoverHeartRate(device);

    log("Connected & Heart Rate ready");
  }

  // =====================================================
  // DISCOVER HEART RATE SERVICE
  // =====================================================
  Future<void> _discoverHeartRate(fbp.BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      // ❤️ Heart Rate Service UUID
      if (service.uuid.toString().toLowerCase().contains("180d")) {
        for (final char in service.characteristics) {
          // ❤️ Heart Rate Measurement UUID
          if (char.uuid.toString().toLowerCase().contains("2a37")) {
            _heartRateChar = char;

            await char.setNotifyValue(true);

            _notifySub = char.lastValueStream.listen((data) {
              if (data.isNotEmpty) {
                final bpm = _parseHeartRate(data);
                _heartRateController.add(bpm);
              }
            });

            return;
          }
        }
      }
    }

    log("❌ Heart Rate characteristic not found");
  }

  // =====================================================
  // PARSE BPM
  // =====================================================
  int _parseHeartRate(List<int> data) {
    final flags = data[0];
    final is16Bit = flags & 0x01 == 1;

    if (is16Bit && data.length >= 3) {
      return (data[2] << 8) + data[1];
    } else {
      return data[1];
    }
  }

  // =====================================================
  // DISCONNECT
  // =====================================================
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;

    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }

    connectedDevice = null;
    _heartRateChar = null;
  }

  void dispose() {
    _heartRateController.close();
  }
}
