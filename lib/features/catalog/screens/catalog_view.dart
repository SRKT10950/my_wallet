import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Product Catalog View — items, pricing, inventory stock tags.
class CatalogView extends StatelessWidget {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Web Design Service', 'category': 'Services', 'price': '₹ 15,000 / unit', 'stock': 'In Stock'},
      {'name': 'Cloud Hosting Plan', 'category': 'Subscriptions', 'price': '₹ 2,499 / mo', 'stock': 'Available'},
      {'name': 'Consulting Hour', 'category': 'Services', 'price': '₹ 1,500 / hr', 'stock': 'In Stock'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Product & Service Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...products.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.primaryViolet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(p['category'] as String, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(p['price'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(p['stock'] as String, style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
