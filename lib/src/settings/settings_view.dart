import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
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

class _SettingsViewState extends State<SettingsView> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  String? _error;
  int _scanTimeLeft = 0;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _bluetoothService.dispose();
    super.dispose();
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
      if (mounted) {
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
      }
    });

    try {
      final devices = await _bluetoothService.scanForDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
      });
      scanningBar.close();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      scanningBar.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
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

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.connectToDevice(device);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );
    } catch (e) {
      if (!mounted) return;
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
        const SizedBox(height: 8),
        const Text(
          'Connect to your Brilliant Labs Frame glasses',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startScan,
                icon: Icon(_isScanning ? Icons.stop : Icons.search),
                label: Text(_isScanning ? 'Cancel Scan' : 'Scan for Devices'),
                style: _isScanning ? ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_devices.isEmpty && !_isScanning)
          const Center(
            child: Text('No devices found'),
          )
        else if (_devices.isNotEmpty)
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isConnected = _bluetoothService.isConnected;
                
                return ListTile(
                  title: Text(device.platformName),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: isConnected
                    ? const Icon(Icons.bluetooth_connected, color: Colors.green)
                    : const Icon(Icons.bluetooth),
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),
      ],
    );
  }
}
