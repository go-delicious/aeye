import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'settings_controller.dart';
import 'dart:async';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with WidgetsBindingObserver {
  final BluetoothService _bluetoothService = BluetoothService();
  final List<BrilliantScannedDevice> _devices = [];
  bool _isScanning = false;
  String? _error;
  int _scanTimeLeft = 0;
  Timer? _scanTimer;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  BrilliantConnectionState _connectionState = BrilliantConnectionState.disconnected;
  BrilliantScannedDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBluetooth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScan();
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopScan();
    }
  }

  @override
  void deactivate() {
    _stopScan();
    super.deactivate();
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _bluetoothService.initialize();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) {
      await _stopScan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan cancelled'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _devices.clear();
      _isScanning = true;
      _error = null;
      _scanTimeLeft = 15;
    });

    // Show persistent scanning snackbar
    if (!mounted) return;
    
    StateSetter? snackBarSetState;
    final scanningBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: StatefulBuilder(
          builder: (BuildContext context, setState) {
            snackBarSetState = setState;
            return Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Scanning... $_scanTimeLeft seconds remaining',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        duration: const Duration(days: 1), // Effectively infinite
      ),
    );

    // Start countdown timer after snackBarSetState is initialized
    _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isScanning) {
        timer.cancel();
        return;
      }
      setState(() {
        _scanTimeLeft--;
      });
      // Update the snackbar text only if snackBarSetState is initialized
      snackBarSetState?.call(() {});
      if (_scanTimeLeft <= 0) {
        timer.cancel();
        await _stopScan();
        scanningBar.close();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_devices.isEmpty ? 'No devices found' : 'Scan complete: ${_devices.length} devices found'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });

    try {
      _scanSubscription = _bluetoothService.scanForDevices().listen(
        (device) {
          if (!mounted) return;
          setState(() {
            // Remove old entry if exists
            _devices.removeWhere((d) => d.device.remoteId == device.device.remoteId);
            // Add new entry
            _devices.add(device);
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString();
            _isScanning = false;
            _scanTimeLeft = 0;
          });
          _scanTimer?.cancel();
          scanningBar.close();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan failed: ${e.toString()}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _scanTimeLeft = 0;
          });
          _scanTimer?.cancel();
          scanningBar.close();
          if (mounted && _devices.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No devices found'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isScanning = false;
        _scanTimeLeft = 0;
      });
      _scanTimer?.cancel();
      scanningBar.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopScan() async {
    try {
      _scanSubscription?.cancel();
      await _bluetoothService.stopScan();
    } finally {
      _scanTimer?.cancel();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanTimeLeft = 0;
        });
      }
    }
  }

  Future<void> _connectToDevice(BrilliantScannedDevice device) async {
    try {
      _connectionSubscription?.cancel();
      _connectionSubscription = _bluetoothService.connectToDevice(device).listen(
        (state) {
          if (!mounted) return;
          setState(() {
            _connectionState = state;
            _connectedDevice = device;
          });
          switch (state) {
            case BrilliantConnectionState.connected:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to ${device.device.platformName}')),
              );
              break;
            case BrilliantConnectionState.dfuConnected:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to ${device.device.platformName} in DFU mode')),
              );
              break;
            case BrilliantConnectionState.disconnected:
              setState(() {
                _connectedDevice = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Disconnected from ${device.device.platformName}')),
              );
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _connectionState = BrilliantConnectionState.disconnected;
            _connectedDevice = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: ${e.toString()}')),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionState = BrilliantConnectionState.disconnected;
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(),
          const Divider(),
          _buildBluetoothSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButton<ThemeMode>(
          value: widget.controller.themeMode,
          onChanged: widget.controller.updateThemeMode,
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light Theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark Theme'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBluetoothSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frame Glasses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop Scan' : 'Scan for Devices'),
            ),
          ],
        ),
        if (_connectionState != BrilliantConnectionState.disconnected && _connectedDevice != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _connectedDevice!.device.platformName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _connectionState == BrilliantConnectionState.dfuConnected
                                  ? 'Connected (DFU Mode)'
                                  : 'Connected',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _bluetoothService.disconnect();
                          setState(() {
                            _connectionState = BrilliantConnectionState.disconnected;
                            _connectedDevice = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                  if (_connectionState == BrilliantConnectionState.connected) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Signal Strength: ${_connectedDevice!.rssi} dBm',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (_devices.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              // Don't show the connected device in the list
              if (_connectedDevice?.device.remoteId == device.device.remoteId) {
                return const SizedBox.shrink();
              }
              return ListTile(
                title: Text(device.device.platformName),
                subtitle: Text('RSSI: ${device.rssi}'),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  child: const Text('Connect'),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
