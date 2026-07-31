import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Receipt Scan View — OCR scanner viewport, camera picker, itemized preview.
class ReceiptScanView extends StatelessWidget {
  const ReceiptScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scanner Viewport
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.4), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppTheme.primaryTeal),
                    SizedBox(height: 12),
                    Text('Align Receipt inside Frame', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Auto OCR will extract merchant, total & items', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Capture Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Upload Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
