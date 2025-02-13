import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  BluetoothDevice device;
  int? rssi;

  BrilliantScannedDevice({
    required this.device,
    required this.rssi,
  });
}

class BluetoothService {
  static const String brilliantServiceUuid = '7a230001-5475-a6a4-654c-8431f6ad49c4';
  static const String brilliantTxCharUuid = '7a230002-5475-a6a4-654c-8431f6ad49c4';
  static const String brilliantRxCharUuid = '7a230003-5475-a6a4-654c-8431f6ad49c4';
  static const String dfuServiceUuid = 'fe59';
  static const String dfuControlCharUuid = '8ec90001-f315-4f60-9fb8-838830daea50';
  static const String dfuPacketCharUuid = '8ec90002-f315-4f60-9fb8-838830daea50';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _dfuControl;
  BluetoothCharacteristic? _dfuPacket;
  BrilliantConnectionState _state = BrilliantConnectionState.disconnected;
  
  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;

  bool get isConnected => _state == BrilliantConnectionState.connected;
  int? maxStringLength;
  int? maxDataLength;

  Future<void> initialize() async {
    try {
      // Request necessary permissions
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      
      await FlutterBluePlus.startScan();
      await FlutterBluePlus.stopScan();
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Stream<BrilliantScannedDevice> scanForDevices() async* {
    try {
      await FlutterBluePlus.startScan(
        withServices: [
          Guid(brilliantServiceUuid),
          Guid(dfuServiceUuid),
        ],
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 2),
      );

      await for (final results in FlutterBluePlus.scanResults) {
        if (results.isEmpty) continue;
        
        // Find the device with strongest signal
        ScanResult nearestDevice = results[0];
        for (var result in results) {
          if (result.rssi > nearestDevice.rssi) {
            nearestDevice = result;
          }
        }

        // Filter by name: "Frame", "Frame Update", "Monocle" & "DFUTarg"
        final name = nearestDevice.device.advName.toLowerCase();
        if (name.contains('frame') || 
            name.contains('monocle') || 
            name.contains('dfutarg')) {
          yield BrilliantScannedDevice(
            device: nearestDevice.device,
            rssi: nearestDevice.rssi,
          );
        }
      }
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    } finally {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Stream<BrilliantConnectionState> connectToDevice(BrilliantScannedDevice scanned) async* {
    try {
      await FlutterBluePlus.stopScan();

      await scanned.device.connect(
        autoConnect: Platform.isIOS,
        mtu: null,
      );

      _connectedDevice = scanned.device;

      yield* FlutterBluePlus.events.onConnectionStateChanged
          .where((event) =>
              event.connectionState == BluetoothConnectionState.connected ||
              (event.connectionState == BluetoothConnectionState.disconnected &&
                  event.device.disconnectReason != null &&
                  event.device.disconnectReason!.code != 23789258))
          .asyncMap((event) async {
        if (event.connectionState == BluetoothConnectionState.connected) {
          try {
            final state = await _enableServices(event.device);
            _state = state;
            return state;
          } catch (error) {
            throw BrilliantBluetoothException(error.toString());
          }
        }
        
        if (Platform.isAndroid) {
          event.device.connect(timeout: const Duration(days: 365));
        }
        
        _state = BrilliantConnectionState.disconnected;
        return BrilliantConnectionState.disconnected;
      });

    } catch (error) {
      await disconnect();
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<BrilliantConnectionState> _enableServices(BluetoothDevice device) async {
    if (Platform.isAndroid) {
      await device.requestMtu(512);
    }

    maxStringLength = device.mtuNow - 3;
    maxDataLength = device.mtuNow - 4;

    final services = await device.discoverServices();
    
    for (final service in services) {
      // Check for Brilliant service
      if (service.serviceUuid == Guid(brilliantServiceUuid)) {
        for (final characteristic in service.characteristics) {
          if (characteristic.characteristicUuid == Guid(brilliantTxCharUuid)) {
            _txCharacteristic = characteristic;
          } else if (characteristic.characteristicUuid == Guid(brilliantRxCharUuid)) {
            _rxCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen(_handleIncomingMessage);
          }
        }
      }
      
      // Check for DFU service
      if (service.serviceUuid == Guid(dfuServiceUuid)) {
        for (final characteristic in service.characteristics) {
          if (characteristic.characteristicUuid == Guid(dfuControlCharUuid)) {
            _dfuControl = characteristic;
            await characteristic.setNotifyValue(true);
          } else if (characteristic.characteristicUuid == Guid(dfuPacketCharUuid)) {
            _dfuPacket = characteristic;
          }
        }
      }
    }

    if (_txCharacteristic != null && _rxCharacteristic != null) {
      return BrilliantConnectionState.connected;
    }

    if (_dfuControl != null && _dfuPacket != null) {
      return BrilliantConnectionState.dfuConnected;
    }

    throw "Incomplete set of services found";
  }

  void _handleIncomingMessage(List<int> value) {
    if (value.isEmpty) return;
    
    // Handle data messages (starting with 0x01)
    if (value[0] == 0x01) {
      // final data = value.sublist(1);
      // Handle data message
      return;
    }
    
    // Handle string messages (not starting with 0x01 or 0x02)
    if (value[0] != 0x02) {
      final message = utf8.decode(value);
      _messageController.add(message);
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _txCharacteristic = null;
      _rxCharacteristic = null;
      _dfuControl = null;
      _dfuPacket = null;
      maxStringLength = null;
      maxDataLength = null;
      _state = BrilliantConnectionState.disconnected;
    }
  }

  Future<void> sendString(String message, {bool awaitResponse = true}) async {
    try {
      if (_txCharacteristic == null) {
        throw "Not connected to device";
      }

      if (message.length > (maxStringLength ?? 0)) {
        throw "Message exceeds maximum length of $maxStringLength";
      }

      await _txCharacteristic!.write(utf8.encode(message), withoutResponse: true);

      if (awaitResponse) {
        await _rxCharacteristic!.onValueReceived
            .timeout(const Duration(seconds: 1))
            .first;
      }
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  Future<void> sendData(List<int> data) async {
    try {
      if (_txCharacteristic == null) {
        throw "Not connected to device";
      }

      if (data.length > (maxDataLength ?? 0)) {
        throw "Data exceeds maximum length of $maxDataLength";
      }

      final finalData = [0x01, ...data];
      await _txCharacteristic!.write(finalData, withoutResponse: true);
    } catch (error) {
      throw BrilliantBluetoothException(error.toString());
    }
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }
} 