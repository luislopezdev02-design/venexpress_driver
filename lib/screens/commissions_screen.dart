import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/common_widgets.dart';

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadCommissions();
    });
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pagada' => 'Pagada',
      'cancelada' => 'Cancelada',
      _ => 'Pendiente',
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pagada' => const Color(0xFF16A34A),
      'cancelada' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Mis Comisiones'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverProvider>().loadCommissions(),
        child: provider.isLoadingCommissions
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Pendiente de pago',
                          value: '\$${provider.commissionsPendingUsd.toStringAsFixed(2)}',
                          icon: Icons.hourglass_bottom,
                          accentColor: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'Total pagado',
                          value: '\$${provider.commissionsPaidUsd.toStringAsFixed(2)}',
                          icon: Icons.check_circle_outline,
                          accentColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Historial',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (provider.commissions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Todavía no tienes comisiones registradas.', style: TextStyle(color: kMuted)),
                      ),
                    )
                  else
                    ...provider.commissions.map((payment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payment.trackingNumber ?? 'Guía #${payment.packageId}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _statusLabel(payment.status),
                                  style: TextStyle(fontSize: 12, color: _statusColor(payment.status)),
                                ),
                              ],
                            ),
                            Text(
                              '\$${payment.amountUsd.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
