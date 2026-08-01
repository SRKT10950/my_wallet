import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/fuel_log.dart';
import 'car_history_screen.dart';
import 'fuel_log_screen.dart';
import 'offline_sync_screen.dart';

class CarDashboardScreen extends StatefulWidget {
  const CarDashboardScreen({super.key});

  @override
  State<CarDashboardScreen> createState() => _CarDashboardScreenState();
}

class _CarDashboardScreenState extends State<CarDashboardScreen> {
  final TextEditingController _odoInputController = TextEditingController();

  void _showSetOdometerDialog(BuildContext context, FinanceProvider provider) {
    bool autoStart = provider.vehicleConfig?.autoStartOnBoot ?? true;
    if (provider.vehicleConfig != null) {
      _odoInputController.text = provider.vehicleConfig!.currentOdometer.toStringAsFixed(0);
    } else {
      _odoInputController.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131524),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Configure Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the current physical odometer reading of your vehicle (in km). GPS tracking will increment this value.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _odoInputController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Current Odometer (km)',
                    labelStyle: const TextStyle(color: Colors.orangeAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orangeAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-start tracking', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Start tracking when app/car boots up', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  value: autoStart,
                  activeThumbColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setStateDialog(() {
                      autoStart = val;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                onPressed: () {
                  final val = double.tryParse(_odoInputController.text);
                  if (val != null && val >= 0) {
                    provider.saveVehicleConfig(val, autoStartOnBoot: autoStart);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showQuickFuelLogSheet(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFuelLogSheet(
        fuelLog: FuelLog(
          date: DateTime.now().toIso8601String(),
          odometer: provider.vehicleConfig?.currentOdometer ?? 0.0,
          fuelAmount: 0.0,
          pricePerUnit: 0.0,
          totalCost: 0.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _odoInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Premium styling colors
    const primaryBg = Color(0xFF080914);
    const accentTeal = Color(0xFF10B981);
    const accentRed = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: const Text('Car Stereo Interface', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Set Odometer',
            onPressed: () => _showSetOdometerDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Colors.white),
            tooltip: 'Trip Logs',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const CarHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: isLandscape
            ? Row(
                children: [
                  // Left Side: Speedometer & Big Control Button
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedometer(provider, accentTeal),
                        const SizedBox(height: 16),
                        _buildTrackingButton(provider, accentTeal, accentRed),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Side: Telemetry Metrics & Quick Tools
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTelemetryGrid(provider),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  side: const BorderSide(color: Colors.white10),
                                ),
                                icon: const Icon(Icons.local_gas_station_rounded, color: Colors.orangeAccent),
                                label: const Text('Quick Refuel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                onPressed: () => _showQuickFuelLogSheet(context, provider),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  side: const BorderSide(color: Colors.white10),
                                ),
                                icon: const Icon(Icons.sync_rounded, color: Colors.lightBlueAccent),
                                label: const Text('Offline Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => const OfflineSyncScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSpeedometer(provider, accentTeal),
                  _buildTelemetryGrid(provider),
                  _buildTrackingButton(provider, accentTeal, accentRed),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          icon: const Icon(Icons.local_gas_station_rounded, color: Colors.orangeAccent),
                          label: const Text('Quick Refuel Log', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showQuickFuelLogSheet(context, provider),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          icon: const Icon(Icons.sync_rounded, color: Colors.lightBlueAccent),
                          label: const Text('Offline Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const OfflineSyncScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSpeedometer(FinanceProvider provider, Color accentTeal) {
    final speed = provider.liveSpeed;
    final isTracking = provider.isTrackingTrip;

    return Center(
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0E1120),
          boxShadow: [
            BoxShadow(
              color: (isTracking ? accentTeal : Colors.orangeAccent).withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            )
          ],
          border: Border.all(
            color: isTracking ? accentTeal.withValues(alpha: 0.4) : Colors.white12,
            width: 8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isTracking ? speed.toStringAsFixed(0) : '0',
              style: const TextStyle(
                fontSize: 62,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Outfit',
              ),
            ),
            const Text(
              'km/h',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isTracking) ...[
              const SizedBox(height: 4),
              const Text(
                'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingButton(FinanceProvider provider, Color accentTeal, Color accentRed) {
    final isTracking = provider.isTrackingTrip;

    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isTracking ? accentRed : accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: (isTracking ? accentRed : accentTeal).withValues(alpha: 0.4),
        ),
        onPressed: () async {
          if (isTracking) {
            await provider.stopCarTrip();
          } else {
            if (provider.vehicleConfig == null) {
              _showSetOdometerDialog(context, provider);
            } else {
              final started = await provider.startCarTrip();
              if (!mounted) return;
              if (!started) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enable Location Services and grant GPS permissions.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              isTracking ? 'STOP TRACKING TRIP' : 'START GPS TRIP',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(FinanceProvider provider) {
    final curOdo = provider.vehicleConfig?.currentOdometer ?? 0.0;
    final tripDist = provider.liveTripDistance;
    final isTracking = provider.isTrackingTrip;
    final isTripActive = provider.isTripActive;
    final pathPoints = provider.liveTripPath.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.1,
      children: [
        _buildMetricCard(
          title: 'VEHICLE ODOMETER',
          value: '${curOdo.toStringAsFixed(1)} km',
          sub: 'Total run distance',
          color: Colors.white70,
          icon: Icons.speed_rounded,
        ),
        _buildMetricCard(
          title: 'TRIP DISTANCE',
          value: '${tripDist.toStringAsFixed(2)} km',
          sub: isTracking
              ? (isTripActive
                  ? 'Recording trip...'
                  : 'Standby (waiting for >50m movement)')
              : 'Odometer locked',
          color: isTracking
              ? (isTripActive ? const Color(0xFF10B981) : Colors.amber)
              : Colors.grey,
          icon: Icons.alt_route_rounded,
        ),
        _buildMetricCard(
          title: 'GPS LOG STATUS',
          value: isTracking ? (isTripActive ? 'RECORDING' : 'MONITORING') : 'STANDBY',
          sub: isTracking
              ? (isTripActive
                  ? '$pathPoints coordinates logged'
                  : 'Listening for movement...')
              : 'Set initial odometer',
          color: isTracking
              ? (isTripActive ? const Color(0xFF10B981) : Colors.amber)
              : Colors.orangeAccent,
          icon: isTracking
              ? (isTripActive ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded)
              : Icons.gps_off_rounded,
        ),
        _buildMetricCard(
          title: 'SYNC STATUS',
          value: provider.isAuthenticated ? 'LINKED' : 'UNLINKED',
          sub: provider.isAuthenticated ? 'Syncs via cloud DB' : 'Login to enable mobile sync',
          color: provider.isAuthenticated ? Colors.lightBlueAccent : Colors.grey,
          icon: Icons.sync_rounded,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
