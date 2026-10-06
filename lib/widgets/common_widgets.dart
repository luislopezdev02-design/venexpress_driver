import 'package:flutter/material.dart';
import '../models/package_model.dart';

// Paleta alineada a la marca web (tailwind.config.js del portal):
// blanco / amarillo / negro. kPrimaryDark, kBackground, kBorder y
// kMuted son los mismos hex que #111111 / #F7F7F4 / #E5E5E0 / #6B6B66
// usados en resources/views/layouts/driver.blade.php. kAccent es el
// amarillo de marca (amber-400), el mismo de x-primary-button.blade.php.
const kPrimaryDark = Color(0xFF111111);
const kBackground = Color(0xFFF7F7F4);
const kBorder = Color(0xFFE5E5E0);
const kMuted = Color(0xFF6B6B66);
const kAccent = Color(0xFFF7FF00);

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
    if (package.isDelivered) return const Color(0xFF047857);
    if (package.currentStatus == 'RECIBIDO_AGENCIA') return const Color(0xFF8C9100);
    if (package.isOutForDelivery) return const Color(0xFF1D4ED8);
    if (package.currentStatus == 'ENTREGA_FALLIDA') return const Color(0xFFDC2626);
    return const Color(0xFF4A4A45);
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
                          color: Color(0xFF8C9100),
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
                    child: Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
