import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../services/api_client.dart';
import 'my_route_screen.dart';
import 'package_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;

    try {
      final result = await context.read<DriverProvider>().scan(code);

      if (!mounted) return;

      if (result.securityWarning) {
        await _showWarningDialog(
          '⚠️ Alerta de seguridad',
          'Los datos de esta guía no coinciden con su código de seguridad original. '
              'Verifica manualmente antes de continuar.\n\n${result.message}',
        );
      } else {
        await _showSuccessDialog(result.message);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PackageDetailScreen(packageId: result.package.id),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      final isRouteError = e.message.contains('ruta en curso') || e.message.contains('ruta asignada');

      if (isRouteError) {
        await _showRouteRequiredDialog(e.message);
      } else {
        await _showWarningDialog('No se pudo procesar', e.message);
      }

      setState(() => _isProcessing = false);
      _controller.start();
    } catch (e) {
      if (!mounted) return;
      await _showWarningDialog('Error de conexión', 'Verifica tu conexión a internet e intenta de nuevo.');
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  Future<void> _showSuccessDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('✅ Escaneo exitoso'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continuar')),
        ],
      ),
    );
  }

  Future<void> _showRouteRequiredDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Necesitas iniciar tu ruta'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyRouteScreen()),
              );
            },
            child: const Text('Ir a Mi Ruta'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWarningDialog(String title, String message) {
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
      await _onDetect(BarcodeCapture(barcodes: [Barcode(rawValue: trackingNumber)]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear Guía'),
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
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Apunta la cámara al código QR de la guía',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
