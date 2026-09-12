import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../services/api_client.dart';
import '../services/driver_delivery_service.dart';
import '../widgets/common_widgets.dart';
import 'delivery_claim_scanner_screen.dart';
import 'package_detail_screen.dart';

class AvailableDeliveriesScreen extends StatefulWidget {
  const AvailableDeliveriesScreen({super.key});

  @override
  State<AvailableDeliveriesScreen> createState() => _AvailableDeliveriesScreenState();
}

class _AvailableDeliveriesScreenState extends State<AvailableDeliveriesScreen> {
  final _service = DriverDeliveryService();

  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _service.getAvailable();
      setState(() => _packages = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar la lista.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claim(PackageModel package) async {
    try {
      final claimed = await _service.claimById(package.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pedido reclamado! Ya es tuyo para entregar.')),
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PackageDetailScreen(packageId: claimed.id)),
      );

      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _load(); // por si ya lo tomó otro, refrescamos la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Pedidos Disponibles'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear para reclamar'),
        onPressed: () async {
          final claimed = await Navigator.of(context).push<PackageModel>(
            MaterialPageRoute(builder: (_) => const DeliveryClaimScannerScreen()),
          );
          if (claimed != null) _load();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: kMuted)))
                : _packages.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 80),
                          const Icon(Icons.inbox_outlined, size: 48, color: kMuted),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'No hay pedidos disponibles por el momento. Esta lista se actualiza sola — desliza hacia abajo para refrescar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _packages.length,
                        itemBuilder: (context, index) {
                          final package = _packages[index];
                          return Container(
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
                                      Text(package.destinationCity ?? '—', style: const TextStyle(fontSize: 13, color: kMuted)),
                                      if (package.deliveryAddress != null)
                                        Text(
                                          package.deliveryAddress!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: kMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _claim(package),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Reclamar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
