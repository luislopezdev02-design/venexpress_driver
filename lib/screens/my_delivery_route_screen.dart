import 'package:flutter/material.dart';
import '../models/delivery_stop_model.dart';
import '../services/api_client.dart';
import '../services/driver_delivery_service.dart';
import '../services/location_service.dart';
import '../widgets/common_widgets.dart';
import 'package_detail_screen.dart';

class MyDeliveryRouteScreen extends StatefulWidget {
  const MyDeliveryRouteScreen({super.key});

  @override
  State<MyDeliveryRouteScreen> createState() => _MyDeliveryRouteScreenState();
}

class _MyDeliveryRouteScreenState extends State<MyDeliveryRouteScreen> {
  final _deliveryService = DriverDeliveryService();
  final _locationService = LocationService();

  List<DeliveryStop> _stops = [];
  List<String> _pendingLocation = [];
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
      final position = await _locationService.getCurrentPosition();
      final result = await _deliveryService.getRouteOrder(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _stops = result.stops;
        _pendingLocation = result.pendingLocation;
      });
    } on LocationException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'No se pudo calcular tu ruta.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Mi Ruta de Entrega'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 60),
                      const Icon(Icons.location_off_outlined, size: 48, color: kMuted),
                      const SizedBox(height: 12),
                      Center(child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kMuted))),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(onPressed: _load, child: const Text('Reintentar')),
                      ),
                    ],
                  )
                : _stops.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 60),
                          Icon(Icons.route_outlined, size: 48, color: kMuted),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No tienes pedidos reclamados todavía. Ve a "Pedidos Disponibles" para tomar uno.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kPrimaryDark,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Orden sugerido: de más lejos a más cerca. Entrega el #1 primero.',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_pendingLocation.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hourglass_bottom, color: Color(0xFFB45309), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${_pendingLocation.length} pedido(s) aún ubicándose en el mapa. Reintenta en unos segundos.',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ..._stops.map((stop) {
                            return InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PackageDetailScreen(packageId: stop.package.id),
                                ),
                              ),
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
                                    Container(
                                      width: 32, height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: kPrimaryDark.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text('${stop.order}', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.package.recipient.name ?? stop.package.trackingNumber,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryDark),
                                          ),
                                          if (stop.package.deliveryAddress != null)
                                            Text(
                                              stop.package.deliveryAddress!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: kMuted),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${stop.distanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
      ),
    );
  }
}
