import 'dart:async';
import 'package:frame_sdk/frame_sdk.dart';
import 'package:frame_sdk/bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';

class BrilliantBluetoothException implements Exception {
  final String msg;
  const BrilliantBluetoothException(this.msg);
  @override
  String toString() => 'BrilliantBluetoothException: $msg';
}

enum BrilliantConnectionState {
  connected,
  dfuConnected,
  disconnected,
}

class BrilliantScannedDevice {
  final Frame frame;
  final int rssi;
  final String deviceName;

  BrilliantScannedDevice({
    required this.frame,
    required this.rssi,
    required this.deviceName,
  });
}

class BluetoothService {
  Frame? _frame;
  final _messageController = StreamController<String>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  StreamSubscription? _connectionSubscription;
  
  Stream<String> get messages => _messageController.stream;
  Stream<int> get batteryLevel => _batteryController.stream;
  bool get isConnected => _frame?.isConnected ?? false;

  Future<void> initialize() async {
    try {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await BrilliantBluetooth.requestPermission();
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Stream<BrilliantScannedDevice> scanForDevices() async* {
    try {
      await for (final device in BrilliantBluetooth.scan()) {
        final name = device.toString().toLowerCase();
        if (name.contains('frame') || 
            name.contains('monocle') || 
            name.contains('dfutarg')) {
          final frame = Frame();
          yield BrilliantScannedDevice(
            frame: frame,
            rssi: -60, // Default RSSI since it's not available in this version
            deviceName: device.toString(),
          );
        }
      }
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<void> stopScan() async {
    try {
      await BrilliantBluetooth.stopScan();
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Stream<BrilliantConnectionState> connectToDevice(BrilliantScannedDevice device) async* {
    try {
      _frame = device.frame;
      await _frame!.connect();

      // Start battery monitoring
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!isConnected) {
          timer.cancel();
          return;
        }
        try {
          final level = await _frame!.getBatteryLevel();
          _batteryController.add(level);
        } catch (e) {
          // Ignore battery read errors
        }
      });

      yield BrilliantConnectionState.connected;

      // Monitor connection state using isConnected
      while (isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        yield BrilliantConnectionState.connected;
      }
      yield BrilliantConnectionState.disconnected;

    } catch (error) {
      await disconnect();
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<void> disconnect() async {
    if (_frame != null) {
      await _frame!.disconnect();
      _frame = null;
    }
    _connectionSubscription?.cancel();
  }

  Future<void> sendString(String message) async {
    try {
      if (_frame == null) {
        throw "Not connected to device";
      }
      await _frame!.runLua(message);
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  void dispose() {
    _messageController.close();
    _batteryController.close();
    _connectionSubscription?.cancel();
    disconnect();
  }
} 