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
                      value: selectedType,
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
                        onPressed: () async {
                          if (descriptionController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Describe brevemente qué ocurrió.')),
                            );
                            return;
                          }

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

  Future<void> _openCompleteDeliverySheet() async {
    final package = _package!;
    final nameController = TextEditingController();
    final idDocController = TextEditingController();
    final phoneController = TextEditingController();
    String confirmationMethod = 'cedula';
    File? photo;

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
                      controller: idDocController,
                      decoration: const InputDecoration(labelText: 'Cédula de quien recibe', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: confirmationMethod,
                      decoration: const InputDecoration(labelText: 'Método de confirmación', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'cedula', child: Text('Verificación de cédula')),
                        DropdownMenuItem(value: 'firma', child: Text('Firma')),
                        DropdownMenuItem(value: 'foto', child: Text('Foto de evidencia')),
                      ],
                      onChanged: (value) => setSheetState(() => confirmationMethod = value!),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );
                        if (picked != null) {
                          setSheetState(() => photo = File(picked.path));
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(photo == null ? 'Tomar foto de evidencia (opcional)' : 'Foto capturada ✓'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty || idDocController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Nombre y cédula del receptor son obligatorios.')),
                            );
                            return;
                          }

                          Navigator.of(sheetContext).pop();

                          try {
                            final updated = await context.read<DriverProvider>().completeDelivery(
                                  packageId: package.id,
                                  receiverName: nameController.text.trim(),
                                  receiverIdDoc: idDocController.text.trim(),
                                  receiverPhone: phoneController.text.trim(),
                                  confirmationMethod: confirmationMethod,
                                  photo: photo,
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

  Future<void> _collectCod() async {
    try {
      final updated = await context.read<DriverProvider>().collectCod(_package!.id);
      setState(() => _package = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobro COD registrado correctamente.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
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
                                    color: incident.isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                                            color: incident.isResolved ? const Color(0xFF16A34A) : const Color(0xFFB45309),
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

                      if (_package!.requiresDelivery &&
                          _package!.currentStatus == 'EN_TRANSITO_NACIONAL')
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
                              onPressed: _collectCod,
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
