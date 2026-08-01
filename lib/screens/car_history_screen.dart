import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/car_trip.dart';

class CarHistoryScreen extends StatelessWidget {
  const CarHistoryScreen({super.key});

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final trips = List<CarTrip>.from(provider.carTrips)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: const Color(0xFF080914),
      appBar: AppBar(
        title: const Text('Vehicle Trip History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080914), Color(0xFF0E111F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: trips.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: Colors.white24),
                    SizedBox(height: 16),
                    Text(
                      'No GPS trips recorded yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (ctx, idx) {
                  final trip = trips[idx];
                  final tripDate = DateTime.tryParse(trip.date) ?? DateTime.now();

                  return Card(
                    color: Colors.white.withValues(alpha: 0.03),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Header: Date and Delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy | hh:mm a').format(tripDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (confirmCtx) => AlertDialog(
                                      backgroundColor: const Color(0xFF131524),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Delete Trip Log', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        'Are you sure you want to delete this trip record? This action will sync to the database.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(confirmCtx),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                          onPressed: () {
                                            if (trip.id != null) {
                                              provider.deleteCarTrip(trip.id!);
                                            }
                                            Navigator.pop(confirmCtx);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          // Telemetry Metrics Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem(
                                label: 'DISTANCE',
                                value: '${trip.distanceTravelled.toStringAsFixed(2)} km',
                                icon: Icons.straighten_rounded,
                              ),
                              _buildMetricItem(
                                label: 'DURATION',
                                value: _formatDuration(trip.durationSeconds),
                                icon: Icons.timer_outlined,
                              ),
                              _buildMetricItem(
                                label: 'ODOMETER SPAN',
                                value: '${trip.startOdometer.toStringAsFixed(0)} → ${trip.endOdometer.toStringAsFixed(0)}',
                                icon: Icons.speed_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Path GPS Coordinates indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS Track Log: ${_decodeGpsPointsCount(trip.gpsPath)} points recorded',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  int _decodeGpsPointsCount(String jsonPath) {
    try {
      // jsonPath is a JSON string of a list of coordinates
      // Let's decode it safely
      if (jsonPath.isEmpty || jsonPath == '[]') return 0;
      final list = RegExp(r'\[.*?\]').allMatches(jsonPath).length - 1; // simple fast count
      return list > 0 ? list : 0;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildMetricItem({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
