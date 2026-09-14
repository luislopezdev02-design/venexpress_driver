import 'package:flutter/material.dart';
import '../models/package_model.dart';

const kPrimaryDark = Color(0xFF0F172A);
const kBackground = Color(0xFFF3F5F7);
const kBorder = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor ?? kPrimaryDark, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }
}

class PackageStatusBadge extends StatelessWidget {
  final PackageModel package;

  const PackageStatusBadge({super.key, required this.package});

  Color get _color {
    if (package.isDelivered) return const Color(0xFF16A34A);
    if (package.currentStatus == 'RECIBIDO_AGENCIA') return const Color(0xFFF59E0B);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        package.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class PackageListTile extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onTap;

  const PackageListTile({super.key, required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.trackingNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.recipient.name ?? '—',
                    style: const TextStyle(fontSize: 13, color: kMuted),
                  ),
                  if (package.destinationCity != null)
                    Text(
                      package.destinationCity!,
                      style: const TextStyle(fontSize: 12, color: kMuted),
                    ),
                  if (package.isCod)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'COD: \$${package.codAmountUsd?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PackageStatusBadge(package: package),
                if (package.securityWarning)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
