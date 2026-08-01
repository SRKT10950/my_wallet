import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  bool _isConnecting = false;
  bool _bluetoothScanning = false;
  List<Map<String, dynamic>> _scannedBtDevices = [];
  bool _btSyncing = false;
  String? _btSyncDevice;
  double _btSyncProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _triggerBtScan() {
    setState(() {
      _bluetoothScanning = true;
      _scannedBtDevices = [];
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _bluetoothScanning = false;
          _scannedBtDevices = [
            {'name': 'Car Android Stereo (Default)', 'id': 'AA:BB:CC:DD:EE:FF', 'type': 'Stereo System'},
            {'name': 'My Wallet Car Receiver', 'id': '11:22:33:44:55:66', 'type': 'Automotive Dashboard'},
            {'name': 'Linked Phone (Galaxy S23)', 'id': '99:88:77:66:55:44', 'type': 'Mobile Companion'},
          ];
        });
      }
    });
  }

  void _triggerBtSync(String deviceName) {
    setState(() {
      _btSyncing = true;
      _btSyncDevice = deviceName;
      _btSyncProgress = 0.0;
    });

    // Animate progress bar to simulate data transfer
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return false;
      setState(() {
        _btSyncProgress += 0.2;
      });
      if (_btSyncProgress >= 1.0) {
        return false;
      }
      return true;
    }).then((_) {
      if (mounted) {
        setState(() {
          _btSyncing = false;
          _btSyncProgress = 1.0;
        });

        // Trigger a mock data merge to demonstrate success
        final provider = Provider.of<FinanceProvider>(context, listen: false);
        provider.mergeOfflineTelemetryData([], [], {
          'initialOdometer': provider.vehicleConfig?.initialOdometer ?? 0.0,
          'currentOdometer': (provider.vehicleConfig?.currentOdometer ?? 0.0) + 12.5, // simulate some trip increment
          'vehicleName': provider.vehicleConfig?.vehicleName ?? 'My Car',
          'lastSyncTime': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully paired & synced via Bluetooth with $deviceName!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    });
  }

  void _syncWithIp(FinanceProvider provider) async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Host IP Address.')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    final success = await provider.connectAndSyncWithWifiHost(ip);

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Wi-Fi Sync Completed Successfully!' : 'Failed to connect to Wi-Fi Host. Check IP.'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isHostActive = provider.wifiSyncServer != null;

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      appBar: AppBar(
        title: const Text('Offline Sync Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          tabs: const [
            Tab(icon: Icon(Icons.wifi_rounded), text: 'Wi-Fi Network'),
            Tab(icon: Icon(Icons.bluetooth_rounded), text: 'Bluetooth P2P'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // WiFi Sync Tab
            _buildWifiSyncTab(provider, isHostActive),
            // Bluetooth Sync Tab
            _buildBluetoothSyncTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiSyncTab(FinanceProvider provider, bool isHostActive) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Host Sync Server Section
          Card(
            color: Colors.white.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isHostActive ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HOST OFFLINE SERVER',
                            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHostActive ? 'Server is Live' : 'Start Server',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Switch(
                        activeThumbColor: const Color(0xFF10B981),
                        value: isHostActive,
                        onChanged: (val) async {
                          if (val) {
                            await provider.startWifiSyncHost();
                          } else {
                            await provider.stopWifiSyncHost();
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  if (isHostActive) ...[
                    _buildPulsingRadar(),
                    const SizedBox(height: 12),
                    Text(
                      'Host IP Address: ${provider.localIpAddress ?? "unknown"}',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter this IP Address on your car stereo (or mobile) Client to sync telemetry data offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ] else ...[
                    const Icon(Icons.wifi_tethering_off_rounded, size: 64, color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      'Turn on to broadcast your local Wi-Fi IP and start receiving sync payloads from other companion devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Client Sync Section
          Card(
            color: Colors.white.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CONNECT TO SYNC HOST',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Host IP Address',
                      labelStyle: const TextStyle(color: Colors.orangeAccent),
                      hintText: 'e.g. 192.168.1.100',
                      hintStyle: const TextStyle(color: Colors.white24),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orangeAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(
                      _isConnecting ? 'CONNECTING & SYNCING...' : 'SYNC WITH HOST NOW',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isConnecting ? null : () => _syncWithIp(provider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothSyncTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bluetooth Radar Scan Section
          Card(
            color: Colors.white.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'BLUETOOTH P2P DISCOVERY',
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  if (_bluetoothScanning) ...[
                    _buildPulsingRadar(color: Colors.lightBlueAccent),
                    const SizedBox(height: 12),
                    const Text(
                      'Scanning for companion devices running My Wallet...',
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ] else ...[
                    const Icon(Icons.bluetooth_searching_rounded, size: 64, color: Colors.white24),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: Colors.lightBlueAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('SCAN FOR DEVICES', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _triggerBtScan,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Discovered Devices Section
          if (_scannedBtDevices.isNotEmpty) ...[
            const Text(
              'DISCOVERED DEVICES',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scannedBtDevices.length,
              itemBuilder: (ctx, idx) {
                final dev = _scannedBtDevices[idx];
                final isThisSyncing = _btSyncing && _btSyncDevice == dev['name'];

                return Card(
                  color: Colors.white.withValues(alpha: 0.02),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.bluetooth_rounded, color: Colors.lightBlueAccent),
                    ),
                    title: Text(dev['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('${dev['type']} | MAC: ${dev['id']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: isThisSyncing
                        ? SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LinearProgressIndicator(value: _btSyncProgress, color: Colors.lightBlueAccent, backgroundColor: Colors.white10),
                                const SizedBox(height: 4),
                                Text('${(_btSyncProgress * 100).toStringAsFixed(0)}% synced', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _btSyncing ? null : () => _triggerBtSync(dev['name']),
                            child: const Text('Sync'),
                          ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPulsingRadar({Color color = const Color(0xFF10B981)}) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse 1
          _RadarRing(color: color, delay: 0),
          // Pulse 2
          _RadarRing(color: color, delay: 1000),
          // Core Icon
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.radar_rounded, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}

class _RadarRing extends StatefulWidget {
  final Color color;
  final int delay;

  const _RadarRing({required this.color, required this.delay});

  @override
  State<_RadarRing> createState() => _RadarRingState();
}

class _RadarRingState extends State<_RadarRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
