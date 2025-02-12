import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static const String frameServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String frameTxCharUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String frameRxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  
  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;

  bool get isConnected => _connectedDevice != null;

  Future<void> initialize() async {
    // Request necessary permissions
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    
    // Turn on Bluetooth if it's not already on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> frameDevices = [];
    
    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        withServices: [Guid(frameServiceUuid)],
      );

      // Listen to scan results
      await for (final results in FlutterBluePlus.scanResults) {
        for (ScanResult r in results) {
          if (!frameDevices.contains(r.device)) {
            frameDevices.add(r.device);
          }
        }
      }
    } finally {
      // Stop scanning
      await FlutterBluePlus.stopScan();
    }

    return frameDevices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();
      
      for (final service in services) {
        if (service.serviceUuid.toString() == frameServiceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicUuid.toString() == frameTxCharUuid) {
              _txCharacteristic = characteristic;
            } else if (characteristic.characteristicUuid.toString() == frameRxCharUuid) {
              _rxCharacteristic = characteristic;
              // Set up notification handling
              await characteristic.setNotifyValue(true);
              characteristic.onValueReceived.listen((value) {
                if (value.isNotEmpty) {
                  String message = String.fromCharCodes(value);
                  _messageController.add(message);
                }
              });
            }
          }
        }
      }

      if (_txCharacteristic == null || _rxCharacteristic == null) {
        throw Exception('Required characteristics not found');
      }
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _txCharacteristic = null;
      _rxCharacteristic = null;
    }
  }

  Future<void> sendMessage(String message) async {
    if (_txCharacteristic == null) {
      throw Exception('Not connected to device');
    }

    List<int> bytes = message.codeUnits;
    await _txCharacteristic!.write(bytes);
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }
} 