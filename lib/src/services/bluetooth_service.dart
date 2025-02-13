import 'dart:async';
import 'dart:typed_data';
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
  final _tapController = StreamController<void>.broadcast();
  StreamSubscription? _connectionSubscription;
  Timer? _keepAliveTimer;
  Timer? _batteryCheckTimer;
  
  Stream<String> get messages => _messageController.stream;
  Stream<int> get batteryLevel => _batteryController.stream;
  Stream<void> get onTap => _tapController.stream;
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
      print('Starting Bluetooth scan...');
      await for (final device in BrilliantBluetooth.scan()) {
        final name = device.toString().toLowerCase();
        print('Found device: $name');
        
        // Check for various possible Frame device names
        if (name.contains('frame') || 
            name.contains('monocle') || 
            name.contains('dfutarg') ||
            name.contains('brilliant') ||
            name.contains('aeye')) {
          print('Detected potential Frame device: $name');
          final frame = Frame();
          
          yield BrilliantScannedDevice(
            frame: frame,
            rssi: -60, // Default RSSI value
            deviceName: device.toString(),
          );
        }
      }
    } catch (error) {
      print('Scan error: $error');
      throw BrilliantBluetoothException('Failed to scan for devices: $error');
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

      // Set up tap gesture handling
      await setupTapGesture();

      // Start keep-alive mechanism
      _startKeepAlive();

      // Start battery monitoring
      _batteryCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
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

  Future<void> _startKeepAlive() async {
    // Cancel any existing keep-alive timer
    _keepAliveTimer?.cancel();
    
    // Start a new keep-alive timer that runs every 10 seconds
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      
      try {
        // Send a minimal Lua command to keep the connection active
        await _frame?.runLua('-- keep-alive');
      } catch (e) {
        print('Keep-alive error: $e');
        // Don't throw here as we want to keep trying
      }
    });
  }

  Future<void> disconnect() async {
    // Cancel timers first
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _batteryCheckTimer?.cancel();
    _batteryCheckTimer = null;

    if (_frame != null) {
      await _frame!.disconnect();
      _frame = null;
    }
    _connectionSubscription?.cancel();
  }

  Future<void> sendString(String message) async {
    if (_frame == null) {
      throw const BrilliantBluetoothException("Not connected to device");
    }

    try {
      await _frame!.runLua(message);
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<void> setupTapGesture() async {
    if (_frame == null) {
      throw const BrilliantBluetoothException("Not connected to device");
    }

    try {
      // Set up tap detection on the Frame
      await _frame!.runLua('''
        function onTap()
          print("tapped")
        end
        frame.motion.onTap(onTap)
      ''');

      // Listen for tap messages
      _messageController.stream.listen((message) {
        if (message.trim() == 'tapped') {
          _tapController.add(null);
        }
      });
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<Uint8List?> takePhoto() async {
    if (_frame == null) {
      throw const BrilliantBluetoothException("Not connected to device");
    }

    try {
      final photo = await _frame!.camera.takePhoto();
      return photo;
    } catch (e) {
      throw BrilliantBluetoothException('Error taking photo: $e');
    }
  }

  Future<void> displayText(String text) async {
    if (_frame == null) {
      throw const BrilliantBluetoothException("Not connected to device");
    }

    try {
      await _frame!.display.showText(text);
    } catch (e) {
      throw BrilliantBluetoothException('Error displaying text: $e');
    }
  }

  Future<void> scrollText(String text) async {
    if (_frame == null) {
      throw const BrilliantBluetoothException("Not connected to device");
    }

    try {
      await _frame!.display.scrollText(text);
    } catch (e) {
      throw BrilliantBluetoothException('Error scrolling text: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _batteryController.close();
    _tapController.close();
    _connectionSubscription?.cancel();
    _keepAliveTimer?.cancel();
    _batteryCheckTimer?.cancel();
    disconnect();
  }
} 