import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/incident_model.dart';
import '../models/package_model.dart';
import '../providers/driver_provider.dart';
import '../services/api_client.dart';
import '../services/incident_service.dart';
import '../widgets/common_widgets.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final _incidentService = IncidentService();

  PackageModel? _package;
  List<IncidentModel> _incidents = [];
  bool _isLoading = true;
  bool _isCollectingCod = false;
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
      final package = await context.read<DriverProvider>().getPackageDetail(widget.packageId);
      final incidents = await _incidentService.listFor(widget.packageId);
      setState(() {
        _package = package;
        _incidents = incidents;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'No se pudo cargar el pedido.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openReportIncidentSheet() async {
    String selectedType = IncidentType.clienteAusente;
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Reportar incidencia',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
                      items: IncidentType.labels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setSheetState(() => selectedType = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Cuéntanos qué pasó...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.report_problem_outlined),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (descriptionController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Describe brevemente qué ocurrió.')),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);
                                Navigator.of(sheetContext).pop();

                                try {
                                  final incident = await _incidentService.report(
                                    packageId: widget.packageId,
                                    type: selectedType,
                                    description: descriptionController.text.trim(),
                                  );

                                  if (!mounted) return;
                                  setState(() => _incidents = [incident, ..._incidents]);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Incidencia reportada correctamente.')),
                                  );
                                } on ApiException catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                }
                              },
                        label: const Text('Reportar incidencia'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Formas de pago que dejan un número de referencia: es obligatorio
  /// registrarlo (mismo criterio que Package::PAYMENT_METHODS_REQUIRING_REFERENCE).
  static const Set<String> _methodsRequiringReference = {'pago_movil', 'transferencia', 'zelle'};

  bool _isCashMethod(String? method) => method == 'efectivo_usd' || method == 'efectivo_ves';

  Future<File?> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      // Limita la resolución máxima para que la foto no sea un archivo
      // pesado en una cámara de alta resolución: evita subidas lentas
      // o que agoten el timeout de ApiConfig en conexiones débiles.
      maxWidth: 1600,
      maxHeight: 1600,
    );

    return picked != null ? File(picked.path) : null;
  }

  Future<void> _openCompleteDeliverySheet() async {
    final package = _package!;
    final nameController = TextEditingController();
    final idDocController = TextEditingController();
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    final referenceController = TextEditingController();
    bool withoutPin = !package.hasDeliveryPin;
    String? codPaymentMethod;
    File? photo;
    File? codPaymentProof;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final usesPin = package.hasDeliveryPin && !withoutPin;
            final needsReference = _methodsRequiringReference.contains(codPaymentMethod);

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Confirmar entrega',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre de quien recibe', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    if (package.hasDeliveryPin)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('El destinatario no tiene el PIN', style: TextStyle(fontSize: 14)),
                        value: withoutPin,
                        onChanged: (value) => setSheetState(() => withoutPin = value),
                      ),
                    if (usesPin) ...[
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'PIN de entrega',
                          helperText: package.deliveryPinAttemptsLeft != null
                              ? 'Pídeselo al destinatario. Intentos disponibles: ${package.deliveryPinAttemptsLeft}'
                              : 'Pídeselo al destinatario.',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Sin PIN: verifica la cédula del destinatario y toma una foto de la entrega. '
                          'Solo el destinatario puede recibir el paquete.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: idDocController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula del destinatario',
                          hintText: 'V-12345678',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _pickImage(ImageSource.camera);
                          if (picked != null) setSheetState(() => photo = picked);
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(photo == null ? 'Tomar foto de la entrega' : 'Foto capturada ✓'),
                      ),
                    ],
                    if (package.isCod && !package.codPendingAtDelivery) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'Este pedido contra entrega ya figura como pagado: no cobres al entregar.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                        ),
                      ),
                    ],
                    if (package.codPendingAtDelivery) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDBA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFFC70)),
                        ),
                        child: Text(
                          'Este pedido es contra entrega (COD): US\$${package.codAmountUsd?.toStringAsFixed(2) ?? '0.00'}. '
                          'No lo entregues sin registrar el pago.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666B00)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: codPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Forma de pago del cobro',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Selecciona cómo te cancelaron...'),
                        items: _paymentMethodLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setSheetState(() => codPaymentMethod = value),
                      ),
                      if (codPaymentMethod != null && !_isCashMethod(codPaymentMethod)) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: referenceController,
                          decoration: InputDecoration(
                            labelText: needsReference ? 'Número de referencia' : 'Número de referencia (opcional)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await _pickImage(ImageSource.gallery);
                            if (picked != null) setSheetState(() => codPaymentProof = picked);
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: Text(
                            codPaymentProof == null ? 'Adjuntar comprobante (opcional)' : 'Comprobante adjunto ✓',
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          String? problem;

                          if (nameController.text.trim().isEmpty) {
                            problem = 'Indica el nombre de quien recibe.';
                          } else if (usesPin && !RegExp(r'^\d{6}$').hasMatch(pinController.text.trim())) {
                            problem = 'El PIN de entrega tiene 6 dígitos.';
                          } else if (!usesPin && idDocController.text.trim().isEmpty) {
                            problem = 'Sin PIN, indica la cédula del destinatario.';
                          } else if (!usesPin && photo == null) {
                            problem = 'Sin PIN, toma una foto de la entrega.';
                          } else if (package.codPendingAtDelivery && codPaymentMethod == null) {
                            problem = 'Indica la forma de pago con la que te cancelaron el COD.';
                          } else if (package.codPendingAtDelivery &&
                              needsReference &&
                              referenceController.text.trim().isEmpty) {
                            problem = 'Indica el número de referencia del pago.';
                          }

                          if (problem != null) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(problem)));
                            return;
                          }

                          setSheetState(() => isSubmitting = true);
                          Navigator.of(sheetContext).pop();

                          try {
                            final updated = await context.read<DriverProvider>().completeDelivery(
                                  packageId: package.id,
                                  receiverName: nameController.text.trim(),
                                  receiverIdDoc: usesPin ? null : idDocController.text.trim(),
                                  receiverPhone: phoneController.text.trim(),
                                  deliveryPin: usesPin ? pinController.text.trim() : null,
                                  photo: usesPin ? null : photo,
                                  codPaymentMethod: package.codPendingAtDelivery ? codPaymentMethod : null,
                                  codPaymentReference: package.codPendingAtDelivery && !_isCashMethod(codPaymentMethod)
                                      ? referenceController.text.trim()
                                      : null,
                                  codPaymentProof: package.codPendingAtDelivery && !_isCashMethod(codPaymentMethod)
                                      ? codPaymentProof
                                      : null,
                                );

                            if (!mounted) return;
                            setState(() => _package = updated);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Entrega confirmada correctamente.')),
                            );
                          } on ApiException catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                            // Un PIN incorrecto se cuenta en el servidor:
                            // recarga para mostrar los intentos que quedan.
                            _load();
                          }
                        },
                        child: const Text('Confirmar entrega'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const Map<String, String> _paymentMethodLabels = {
    'efectivo_usd': 'Efectivo (USD)',
    'efectivo_ves': 'Efectivo (VES)',
    'pago_movil': 'Pago móvil',
    'transferencia': 'Transferencia',
    'punto_venta': 'Punto de venta',
    'zelle': 'Zelle',
  };

  String _paymentMethodLabel(String method) => _paymentMethodLabels[method] ?? method;

  Future<void> _collectCod() async {
    setState(() => _isCollectingCod = true);

    try {
      final updated = await context.read<DriverProvider>().collectCod(_package!.id);
      if (!mounted) return;
      setState(() => _package = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro COD registrado correctamente.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isCollectingCod = false);
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: kMuted, fontSize: 13))),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '—',
              style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(_package?.trackingNumber ?? 'Detalle del pedido'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: kMuted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_package!.securityWarning)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Los datos de esta guía no coinciden con su código de seguridad original.',
                                  style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PackageStatusBadge(package: _package!),
                          if (_package!.isFragile)
                            const Text('⚠️ Frágil', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionCard(
                        title: 'Remitente',
                        children: [
                          _infoRow('Nombre', _package!.sender.name),
                          _infoRow('Cédula/RIF', _package!.sender.idDoc),
                          _infoRow('Teléfono', _package!.sender.phone),
                        ],
                      ),

                      _sectionCard(
                        title: 'Destinatario',
                        children: [
                          _infoRow('Nombre', _package!.recipient.name),
                          _infoRow('Cédula/RIF', _package!.recipient.idDoc),
                          _infoRow('Teléfono', _package!.recipient.phone),
                          _infoRow('Ciudad', _package!.destinationCity),
                          if (_package!.requiresDelivery) ...[
                            _infoRow('Dirección', _package!.deliveryAddress),
                            _infoRow('Sector', _package!.deliverySector),
                            _infoRow('Referencia', _package!.deliveryReference),
                          ],
                        ],
                      ),

                      if (_package!.isCod)
                        _sectionCard(
                          title: 'Pago contra entrega (COD)',
                          children: [
                            _infoRow('Monto', '\$${_package!.codAmountUsd?.toStringAsFixed(2) ?? '0.00'}'),
                            _infoRow('Estado', _package!.codStatus == 'liquidado' ? 'Liquidado' : 'Pendiente'),
                            _infoRow('Cobrado', _package!.codCollectedAt != null ? 'Sí' : 'No'),
                            if (_package!.codPaymentMethod != null)
                              _infoRow('Forma de pago', _paymentMethodLabel(_package!.codPaymentMethod!)),
                            if (_package!.codPaymentReference != null)
                              _infoRow('Referencia', _package!.codPaymentReference),
                          ],
                        ),

                      if (_package!.driverRemunerationUsd != null)
                        _sectionCard(
                          title: 'Tu comisión por este pedido',
                          children: [
                            _infoRow('Monto', '\$${_package!.driverRemunerationUsd!.toStringAsFixed(2)}'),
                            _infoRow(
                              'Estado',
                              _package!.driverRemunerationStatus == 'pagada' ? 'Pagada' : 'Pendiente de pago',
                            ),
                          ],
                        ),

                      if (_incidents.isNotEmpty)
                        _sectionCard(
                          title: 'Incidencias reportadas',
                          children: _incidents.map((incident) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    incident.isResolved ? Icons.check_circle : Icons.error_outline,
                                    size: 16,
                                    color: incident.isResolved ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          IncidentType.labels[incident.type] ?? incident.type,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kPrimaryDark),
                                        ),
                                        Text(
                                          incident.description,
                                          style: const TextStyle(fontSize: 12, color: kMuted),
                                        ),
                                        Text(
                                          incident.isResolved ? 'Resuelta' : 'En revisión',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: incident.isResolved ? const Color(0xFF047857) : const Color(0xFF8C9100),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 8),

                      if (_package!.requiresDelivery && _package!.isOutForDelivery)
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openCompleteDeliverySheet,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Confirmar entrega'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                      if (_package!.codPendingCollection)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _isCollectingCod ? null : _collectCod,
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Registrar cobro COD'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryDark,
                                side: const BorderSide(color: kPrimaryDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),

                      if (!_package!.isDelivered)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _openReportIncidentSheet,
                              icon: const Icon(Icons.report_problem_outlined),
                              label: const Text('Reportar incidencia'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFDC2626)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
