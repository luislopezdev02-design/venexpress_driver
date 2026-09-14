import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/package_model.dart';
import '../providers/driver_provider.dart';
import '../services/api_client.dart';
import '../services/hub_scan_service.dart';
import '../widgets/common_widgets.dart';

/// Escáner del repartidor de HUB (driver_type = 'hub'), para rutas
/// hub_transfer (recolección en aliado + recepción en HUB) y
/// hub_distribution (salida de HUB + llegada a almacén destino).
///
/// Replica el flujo de dos pasos de Livewire\Driver\Scanner del portal
/// web: ESCANEAR -> IDENTIFICAR (lookup, de solo lectura) -> MOSTRAR
/// OPERACIÓN -> CONFIRMAR -> EJECUTAR. Un escaneo nunca ejecuta una
/// transición de estado por sí solo; siempre requiere que el
/// repartidor confirme explícitamente qué operación quiere registrar.
class HubScannerScreen extends StatefulWidget {
  const HubScannerScreen({super.key});

  @override
  State<HubScannerScreen> createState() => _HubScannerScreenState();
}

class _HubScannerScreenState extends State<HubScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  int _processedCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    await _handleTrackingNumber(code);
  }

  Future<void> _handleTrackingNumber(String trackingNumber) async {
    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;

    final provider = context.read<DriverProvider>();
    final activeRoute = provider.activeRoute;

    if (activeRoute == null || !activeRoute.isInProgress) {
      await _showBlockingDialog(
        'Necesitas una ruta en curso',
        'No tienes una ruta en curso. Inicia una ruta antes de escanear paquetes.',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    try {
      // Paso 1 y 2: ESCANEAR -> IDENTIFICAR (solo lectura).
      final package = await provider.lookupPackage(trackingNumber);

      final resolution = resolveHubOperation(
        activeRouteType: activeRoute.routeType,
        packageCurrentStatus: package.currentStatus,
        packageStatusLabel: package.statusLabel,
      );

      if (!resolution.isEligible) {
        await _showBlockingDialog('No se puede procesar', resolution.blockedReason!);
        _resumeScanning();
        return;
      }

      if (!mounted) return;

      // Paso 3 y 4: MOSTRAR OPERACIÓN -> CONFIRMAR.
      final confirmed = await _showConfirmDialog(package, resolution.operation!);

      if (confirmed != true) {
        _resumeScanning();
        return;
      }

      // Paso 5: EJECUTAR.
      final result = await provider.executeHubOperation(resolution.operation!.key, trackingNumber);

      setState(() => _processedCount++);

      if (!mounted) return;
      await _showSuccessDialog(result.message);
      _resumeScanning();
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 404) {
        await _showBlockingDialog('No encontrada', e.message);
      } else {
        await _showBlockingDialog('No se pudo procesar', e.message);
      }

      _resumeScanning();
    } catch (e) {
      if (!mounted) return;
      await _showBlockingDialog('Error de conexión', 'Verifica tu conexión a internet e intenta de nuevo.');
      _resumeScanning();
    }
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _controller.start();
  }

  Future<bool?> _showConfirmDialog(PackageModel package, HubOperation operation) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(operation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(package.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(operation.hint),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryDark, foregroundColor: Colors.white),
            child: Text(operation.cta),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('✅ Escaneo exitoso'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Seguir escaneando')),
        ],
      ),
    );
  }

  Future<void> _showBlockingDialog(String title, String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Future<void> _enterManually() async {
    final controller = TextEditingController();

    final trackingNumber = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Introducir número de guía'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'VEN-20260910-000123'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );

    if (trackingNumber != null && trackingNumber.isNotEmpty) {
      await _handleTrackingNumber(trackingNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = context.watch<DriverProvider>().activeRoute;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(activeRoute?.routeTypeLabel ?? 'Escanear Guía'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Introducir manualmente',
            onPressed: _enterManually,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Apunta la cámara al código QR de la guía',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (_processedCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$_processedCount procesado(s) en esta sesión',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
