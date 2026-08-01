import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Speedometer
  double _currentSpeed = 0.0;
  StreamSubscription<Position>? _positionSubscription;

  // Configuration and Data
  double _odometer = 0.0;
  double _mileage = 15.0;
  String _userName = '';
  Map<String, dynamic>? _activeTrip;
  List<Map<String, dynamic>> _completedTrips = [];

  // Dialog controllers
  final _odoController = TextEditingController();
  final _mileageController = TextEditingController();

  Timer? _dbRefreshTimer;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
    _startSpeedTracking();
    _startDbRefreshLoop();

    // Auto-sync after 10 seconds (giving network time to connect)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _silentSyncData();
    });

    // Auto-sync every 5 minutes
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _silentSyncData();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _dbRefreshTimer?.cancel();
    _autoSyncTimer?.cancel();
    _odoController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialConfig() async {
    final dbHelper = DatabaseHelper.instance;
    
    // Load config values
    final odoStr = await dbHelper.getConfig('currentOdometer', defaultValue: '0.0');
    final mileageStr = await dbHelper.getConfig('mileage', defaultValue: '15.0');
    final name = await dbHelper.getConfig('user_name', defaultValue: 'Driver');

    setState(() {
      _odometer = double.tryParse(odoStr) ?? 0.0;
      _mileage = double.tryParse(mileageStr) ?? 15.0;
      _userName = name;
    });

    _refreshDbData();
  }

  void _startDbRefreshLoop() {
    // Refresh DB metrics and trips every 4 seconds to sync with background service
    _dbRefreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _refreshDbData();
    });
  }

  Future<void> _refreshDbData() async {
    final dbHelper = DatabaseHelper.instance;
    final active = await dbHelper.getActiveTrip();
    final completed = await dbHelper.getCompletedTrips();
    final odoStr = await dbHelper.getConfig('currentOdometer', defaultValue: '0.0');

    setState(() {
      _activeTrip = active;
      _completedTrips = completed;
      _odometer = double.tryParse(odoStr) ?? 0.0;
    });
  }

  Future<void> _startSpeedTracking() async {
    // Request location permissions if not already granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            // position.speed is in meters/sec, convert to km/h
            _currentSpeed = position.speed * 3.6;
            if (_currentSpeed < 1.0) _currentSpeed = 0.0; // Filter static noise
          });
        }
      });
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      // Sync trips and odometer to API Gateway
      final syncedCount = await SyncService.syncTripsToServer();
      await SyncService.syncOdometerToServer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronization complete. Synced $syncedCount trips.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _refreshDbData();
      }
    }
  }

  Future<void> _silentSyncData() async {
    try {
      await SyncService.syncTripsToServer();
      await SyncService.syncOdometerToServer();
      if (mounted) {
        _refreshDbData();
      }
    } catch (_) {
      // Fail silently in background
    }
  }

  void _showSettingsDialog() {
    _odoController.text = _odometer.toStringAsFixed(1);
    _mileageController.text = _mileage.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121422),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text(
          'Vehicle Configuration',
          style: GoogleFonts.outfit(
            textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _odoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Odometer (km)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mileageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Average Mileage (km/L)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newOdo = double.tryParse(_odoController.text) ?? _odometer;
              final newMil = double.tryParse(_mileageController.text) ?? _mileage;

              final dbHelper = DatabaseHelper.instance;
              await dbHelper.setConfig('currentOdometer', newOdo.toString());
              await dbHelper.setConfig('mileage', newMil.toString());

              setState(() {
                _odometer = newOdo;
                _mileage = newMil;
              });

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration saved locally.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.setConfig('is_authenticated', '0');
    await dbHelper.setConfig('user_id', '');
    await dbHelper.setConfig('user_name', '');
    await dbHelper.clearAllTrips();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  String _formatTimeString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark Futuristic Styling
    const primaryBg = Color(0xFF080914);
    const cardColor = Color(0xFF121422);
    const accentIndigo = Color(0xFF6366F1);
    const accentGreen = Color(0xFF10B981);

    final isTripActive = _activeTrip != null;
    final activeDistance = isTripActive ? ((_activeTrip!['distanceTravelled'] as num?)?.toDouble() ?? 0.0) : 0.0;
    final activeDuration = isTripActive ? ((_activeTrip!['durationSeconds'] as num?)?.toInt() ?? 0) : 0;
    final activeFuel = _mileage > 0 ? activeDistance / _mileage : 0.0;

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.directions_car_rounded, color: accentIndigo),
            const SizedBox(width: 10),
            Text(
              'CAR STEREO DRIVER INTERFACE',
              style: GoogleFonts.outfit(
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1),
              ),
            ),
          ],
        ),
        backgroundColor: cardColor.withOpacity(0.5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Config Settings',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: 'Sync Database',
            onPressed: _isSyncing ? null : _syncData,
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Side: Speedometer & Telemetry stats
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // Speedometer Gauge
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0E1120),
                          boxShadow: [
                            BoxShadow(
                              color: (isTripActive ? accentGreen : accentIndigo).withOpacity(0.12),
                              blurRadius: 30,
                              spreadRadius: 2,
                            )
                          ],
                          border: Border.all(
                            color: isTripActive ? accentGreen.withOpacity(0.4) : Colors.white12,
                            width: 8,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentSpeed.toStringAsFixed(0),
                              style: GoogleFonts.outfit(
                                textStyle: const TextStyle(
                                  fontSize: 82,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const Text(
                              'km/h',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isTripActive ? accentGreen : Colors.orangeAccent).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isTripActive ? 'TRACKING TRIP' : 'STANDBY',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isTripActive ? accentGreen : Colors.orangeAccent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Telemetry Grid
                  Expanded(
                    flex: 4,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          title: 'VEHICLE ODOMETER',
                          value: '${_odometer.toStringAsFixed(1)} km',
                          sub: 'Total run distance',
                          icon: Icons.speed_rounded,
                          color: Colors.white70,
                        ),
                        _buildMetricCard(
                          title: 'VEHICLE MILEAGE',
                          value: '${_mileage.toStringAsFixed(1)} km/L',
                          sub: 'Configured rating',
                          icon: Icons.local_gas_station_rounded,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Side: Active Trip & Historical logs
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Trip Card / Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTripActive ? accentGreen.withOpacity(0.08) : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTripActive ? accentGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: isTripActive
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.sensors_rounded, color: accentGreen, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ACTIVE TRIP DETECTED',
                                        style: GoogleFonts.outfit(
                                          textStyle: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Started ${_formatTimeString(_activeTrip!['startTime'])}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildActiveDetail('Distance', '${activeDistance.toStringAsFixed(2)} km'),
                                  _buildActiveDetail('Duration', _formatDuration(activeDuration)),
                                  _buildActiveDetail('Fuel Used', '${activeFuel.toStringAsFixed(2)} L'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Start: ${_activeTrip!['startLocation'] ?? 'Detecting location...'}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.white30, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                'Automated Background Tracking Active',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  textStyle: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Trip starts automatically when vehicle speed exceeds 5 km/h. Concludes when stopped for >30 minutes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Historical Trips Title
                  Text(
                    'COMPLETED RECENT TRIPS',
                    style: GoogleFonts.outfit(
                      textStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Completed Trips List
                  Expanded(
                    child: _completedTrips.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, color: Colors.white24, size: 40),
                                  SizedBox(height: 8),
                                  Text('No trips recorded yet.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _completedTrips.length,
                            itemBuilder: (ctx, index) {
                              final trip = _completedTrips[index];
                              final dist = (trip['distanceTravelled'] as num?)?.toDouble() ?? 0.0;
                              final duration = (trip['durationSeconds'] as num?)?.toInt() ?? 0;
                              final fuel = (trip['fuelUsed'] as num?)?.toDouble() ?? 0.0;
                              final trMileage = (trip['mileage'] as num?)?.toDouble() ?? _mileage;

                              return Card(
                                color: Colors.white.withOpacity(0.02),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Header: Date, Start & End Time
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 12, color: accentIndigo),
                                              const SizedBox(width: 6),
                                              Text(
                                                _formatDateString(trip['date']),
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${_formatTimeString(trip['startTime'])} - ${_formatTimeString(trip['endTime'])}',
                                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Colors.white10, height: 16),
                                      // Telemetry row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildDetailItem('Distance', '${dist.toStringAsFixed(2)} km'),
                                          _buildDetailItem('Total Time', _formatDuration(duration)),
                                          _buildDetailItem('Fuel Used', '${fuel.toStringAsFixed(2)} L'),
                                          _buildDetailItem('Milage', '${trMileage.toStringAsFixed(1)} km/L'),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Locations
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 12, color: Colors.orangeAccent),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Start: ${trip['startLocation'] ?? 'Unknown'}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.flag_rounded, size: 12, color: accentGreen),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'End: ${trip['endLocation'] ?? 'Unknown'}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDetail(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
