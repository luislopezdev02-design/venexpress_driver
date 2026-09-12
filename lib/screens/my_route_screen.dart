import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/driver_provider.dart';
import '../services/api_client.dart';
import '../widgets/common_widgets.dart';

class MyRouteScreen extends StatefulWidget {
  const MyRouteScreen({super.key});

  @override
  State<MyRouteScreen> createState() => _MyRouteScreenState();
}

class _MyRouteScreenState extends State<MyRouteScreen> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadActiveRoute();
    });
  }

  Future<void> _startRoute() async {
    setState(() => _isStarting = true);

    try {
      await context.read<DriverProvider>().startRoute();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta iniciada. Ya puedes escanear paquetes en cada agencia.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Color _stopColor(RouteStopModel stop) {
    return stop.isVisited ? const Color(0xFF94A3B8) : const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final route = provider.activeRoute;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Mi Ruta'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverProvider>().loadActiveRoute(),
        child: provider.isLoadingRoute && route == null
            ? const Center(child: CircularProgressIndicator())
            : route == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 60),
                      const Icon(Icons.map_outlined, size: 48, color: kMuted),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'No tienes una ruta asignada por el momento. Contacta al administrador.',
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  route.name ?? 'Ruta #${route.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryDark),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: route.isInProgress
                                        ? const Color(0xFF16A34A).withOpacity(0.1)
                                        : const Color(0xFFF59E0B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    route.isInProgress ? 'En curso' : 'Por iniciar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: route.isInProgress ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (route.city != null) Text(route.city!, style: const TextStyle(color: kMuted, fontSize: 13)),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: route.totalStops > 0 ? route.visitedStops / route.totalStops : 0,
                              backgroundColor: kBorder,
                              color: kPrimaryDark,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${route.visitedStops} de ${route.totalStops} agencias visitadas',
                              style: const TextStyle(fontSize: 12, color: kMuted),
                            ),
                            if (route.isAssigned) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 46,
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isStarting ? null : _startRoute,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(_isStarting ? 'Iniciando...' : 'Iniciar ruta'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Paradas (agencias a visitar)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      ...route.stops.map((stop) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _stopColor(stop).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${stop.sequence}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: _stopColor(stop)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.ally?.name ?? 'Agencia #${stop.ally?.id ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryDark),
                                    ),
                                    if (stop.ally?.address != null)
                                      Text(stop.ally!.address!, style: const TextStyle(fontSize: 12, color: kMuted)),
                                    if (stop.packagesCollectedCount > 0)
                                      Text(
                                        '${stop.packagesCollectedCount} paquete(s) recolectado(s)',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                                      ),
                                  ],
                                ),
                              ),
                              if (stop.isVisited)
                                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
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
