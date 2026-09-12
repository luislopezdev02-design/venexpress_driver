import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/package_model.dart';
import '../services/api_client.dart';
import '../services/driver_delivery_service.dart';

class DeliveryClaimScannerScreen extends StatefulWidget {
  const DeliveryClaimScannerScreen({super.key});

  @override
  State<DeliveryClaimScannerScreen> createState() => _DeliveryClaimScannerScreenState();
}

class _DeliveryClaimScannerScreenState extends State<DeliveryClaimScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _service = DriverDeliveryService();
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

    try {
      final claimed = await _service.claimByScan(code);
      if (!mounted) return;
      Navigator.of(context).pop<PackageModel>(claimed);
    } on ApiException catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se pudo reclamar'),
          content: Text(e.message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
          ],
        ),
      );
      setState(() => _isProcessing = false);
      _controller.start();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear para Reclamar'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
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
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              'Escanea el QR del paquete en el almacén para reclamarlo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
