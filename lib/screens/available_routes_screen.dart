import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/driver_provider.dart';
import '../services/api_client.dart';
import '../widgets/common_widgets.dart';
import 'my_route_screen.dart';

/// Rutas hub_transfer/hub_distribution disponibles para que un
/// repartidor de HUB las tome. Equivalente móvil de la lista de rutas
/// disponibles del dashboard web (RouteService::availableRoutesFor()).
class AvailableRoutesScreen extends StatefulWidget {
  const AvailableRoutesScreen({super.key});

  @override
  State<AvailableRoutesScreen> createState() => _AvailableRoutesScreenState();
}

class _AvailableRoutesScreenState extends State<AvailableRoutesScreen> {
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadAvailableRoutes();
    });
  }

  Future<void> _claim(RouteModel route) async {
    setState(() => _isClaiming = true);

    try {
      await context.read<DriverProvider>().claimRoute(route.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Ruta tomada! Ya puedes iniciarla cuando estés listo.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyRouteScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      context.read<DriverProvider>().loadAvailableRoutes();
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Rutas Disponibles'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverProvider>().loadAvailableRoutes(),
        child: provider.isLoadingAvailableRoutes && provider.availableRoutes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.availableRoutesError != null && provider.availableRoutes.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(provider.availableRoutesError!, style: const TextStyle(color: kMuted)),
                      ),
                    ],
                  )
                : provider.availableRoutes.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Icon(Icons.alt_route, size: 48, color: kMuted),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No hay rutas disponibles por el momento. Desliza hacia abajo para refrescar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.availableRoutes.length,
                        itemBuilder: (context, index) {
                          final route = provider.availableRoutes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.name ?? 'Ruta #${route.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryDark),
                                ),
                                const SizedBox(height: 4),
                                Text(route.routeTypeLabel, style: const TextStyle(fontSize: 12, color: kMuted)),
                                if (route.city != null)
                                  Text(route.city!, style: const TextStyle(fontSize: 12, color: kMuted)),
                                const SizedBox(height: 8),
                                Text(
                                  '${route.totalStops} parada(s)',
                                  style: const TextStyle(fontSize: 12, color: kMuted),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isClaiming ? null : () => _claim(route),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryDark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Tomar ruta'),
                                  ),
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
