import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import 'settings_controller.dart';
import 'dart:async';
import '../services/llm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  StreamSubscription? _batterySubscription;
  BrilliantConnectionState _connectionState = BrilliantConnectionState.disconnected;
  BrilliantScannedDevice? _connectedDevice;
  int? _batteryLevel;
  LLMService? _llmService;
  Timer? _logsRefreshTimer;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBluetooth();
    _initializeLLMService();
    // Refresh logs every 5 seconds
    _logsRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshLogs();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScan();
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _batterySubscription?.cancel();
    _bluetoothService.dispose();
    _logsRefreshTimer?.cancel();
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
      setState(() {
        _isScanning = false;
        _scanTimeLeft = 0;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
            _devices.removeWhere((d) => d.deviceName == device.deviceName);
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
      _scanTimer?.cancel();
      await _bluetoothService.stopScan();
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanTimeLeft = 0;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  Future<void> _connectToDevice(BrilliantScannedDevice device) async {
    try {
      _connectionSubscription?.cancel();
      _batterySubscription?.cancel();

      // Listen for battery updates
      _batterySubscription = _bluetoothService.batteryLevel.listen((level) {
        if (mounted) {
          setState(() {
            _batteryLevel = level;
          });
        }
      });

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
                SnackBar(content: Text('Connected to ${device.deviceName}')),
              );
              break;
            case BrilliantConnectionState.dfuConnected:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to ${device.deviceName} in DFU mode')),
              );
              break;
            case BrilliantConnectionState.disconnected:
              setState(() {
                _connectedDevice = null;
                _batteryLevel = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Disconnected from ${device.deviceName}')),
              );
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _connectionState = BrilliantConnectionState.disconnected;
            _connectedDevice = null;
            _batteryLevel = null;
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
        _batteryLevel = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${e.toString()}')),
      );
    }
  }

  Future<void> _initializeLLMService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('openrouter_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        setState(() {
          _llmService = LLMService(apiKey: apiKey);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshLogs() async {
    if (_llmService != null) {
      final logs = await _llmService!.getLogs();
      setState(() {
        _logs = logs;
      });
    }
  }

  Future<void> _clearLogs() async {
    if (_llmService != null) {
      await _llmService!.clearLogs();
      await _refreshLogs();
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
          const Divider(),
          _buildLogsSection(),
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
                              _connectedDevice!.deviceName,
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
                            _batteryLevel = null;
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_batteryLevel != null) ...[
                        Icon(
                          _batteryLevel! > 80 ? Icons.battery_full :
                          _batteryLevel! > 60 ? Icons.battery_6_bar :
                          _batteryLevel! > 40 ? Icons.battery_4_bar :
                          _batteryLevel! > 20 ? Icons.battery_2_bar :
                          Icons.battery_alert,
                          color: _batteryLevel! <= 20 ? Theme.of(context).colorScheme.error : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Battery: $_batteryLevel%',
                          style: TextStyle(
                            color: _batteryLevel! <= 20 ? Theme.of(context).colorScheme.error : null,
                            fontWeight: _batteryLevel! <= 20 ? FontWeight.bold : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (_connectionState == BrilliantConnectionState.connected) ...[
                        const Icon(Icons.signal_cellular_alt),
                        const SizedBox(width: 8),
                        Text('Signal: ${_connectedDevice!.rssi} dBm'),
                      ],
                    ],
                  ),
                  const Divider(height: 24),
                  // Device Details Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  icon: Icons.bluetooth,
                                  label: 'Device Name',
                                  value: _connectedDevice!.deviceName,
                                ),
                                const SizedBox(height: 4),
                                _buildDetailRow(
                                  icon: Icons.signal_cellular_alt,
                                  label: 'Signal Strength',
                                  value: '${_connectedDevice!.rssi} dBm',
                                ),
                                const SizedBox(height: 4),
                                _buildDetailRow(
                                  icon: Icons.battery_std,
                                  label: 'Battery Level',
                                  value: _batteryLevel != null ? '$_batteryLevel%' : 'Unknown',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  icon: Icons.link,
                                  label: 'Connection Status',
                                  value: _connectionState == BrilliantConnectionState.dfuConnected
                                      ? 'DFU Mode'
                                      : 'Connected',
                                ),
                                const SizedBox(height: 4),
                                _buildDetailRow(
                                  icon: Icons.watch_later_outlined,
                                  label: 'Connected Since',
                                  value: DateTime.now().toString().split('.')[0],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
              if (_connectedDevice?.deviceName == device.deviceName) {
                return const SizedBox.shrink();
              }
              return ListTile(
                title: Text(device.deviceName),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'API Logs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
              onPressed: _clearLogs,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(8),
            child: _logs.isEmpty
                ? const Center(
                    child: Text('No logs available'),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final timestamp = DateTime.parse(log['timestamp'] as String).toLocal();
                      final isError = log['isError'] as bool;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${timestamp.hour}:${timestamp.minute}:${timestamp.second}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log['message'] as String,
                                style: TextStyle(
                                  color: isError 
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
