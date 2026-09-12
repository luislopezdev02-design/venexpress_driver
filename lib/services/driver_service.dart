import 'dart:io';
import '../models/driver_model.dart';
import '../models/package_model.dart';
import 'api_client.dart';

class ScanResult {
  final String message;
  final bool securityWarning;
  final PackageModel package;

  ScanResult({
    required this.message,
    required this.securityWarning,
    required this.package,
  });
}

class PackagesPage {
  final List<PackageModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  PackagesPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class CommissionsPage {
  final List<DriverPaymentModel> items;
  final double pendingUsd;
  final double paidUsd;

  CommissionsPage({
    required this.items,
    required this.pendingUsd,
    required this.paidUsd,
  });
}

class DriverService {
  final ApiClient _client = ApiClient();

  Future<DashboardSummary> getDashboard() async {
    final response = await _client.get('/driver/dashboard');
    return DashboardSummary.fromJson(response);
  }

  Future<PackagesPage> getPackages({String status = 'all', String search = '', int page = 1}) async {
    final response = await _client.get('/driver/packages', query: {
      'status': status,
      if (search.isNotEmpty) 'search': search,
      'page': page,
    });

    final data = (response['data'] as List)
        .map((e) => PackageModel.fromJson(e))
        .toList();

    final meta = response['meta'] ?? {};

    return PackagesPage(
      items: data,
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? data.length,
    );
  }

  Future<PackageModel> getPackageDetail(int id) async {
    final response = await _client.get('/driver/packages/$id');
    return PackageModel.fromJson(response['package']);
  }

  /// Escanea una guía por su número de tracking (viene del contenido
  /// del QR, ya decodificado por mobile_scanner).
  Future<ScanResult> scan(String trackingNumber) async {
    final response = await _client.post('/driver/scan', body: {
      'tracking_number': trackingNumber,
    });

    return ScanResult(
      message: response['message'] ?? '',
      securityWarning: response['security_warning'] ?? false,
      package: PackageModel.fromJson(response['package']),
    );
  }

  Future<PackageModel> completeDelivery({
    required int packageId,
    required String receiverName,
    required String receiverIdDoc,
    String? receiverPhone,
    required String confirmationMethod,
    File? photo,
  }) async {
    final response = await _client.postMultipart(
      '/driver/packages/$packageId/complete-delivery',
      fields: {
        'receiver_name': receiverName,
        'receiver_id_doc': receiverIdDoc,
        if (receiverPhone != null && receiverPhone.isNotEmpty) 'receiver_phone': receiverPhone,
        'delivery_confirmation_method': confirmationMethod,
      },
      file: photo,
    );

    return PackageModel.fromJson(response['package']);
  }

  Future<PackageModel> collectCod(int packageId) async {
    final response = await _client.post('/driver/packages/$packageId/collect-cod');
    return PackageModel.fromJson(response['package']);
  }

  Future<CommissionsPage> getCommissions({int page = 1}) async {
    final response = await _client.get('/driver/commissions', query: {'page': page});

    final data = (response['data'] as List)
        .map((e) => DriverPaymentModel.fromJson(e))
        .toList();

    final totals = response['totals'] ?? {};

    return CommissionsPage(
      items: data,
      pendingUsd: (totals['pending_usd'] as num?)?.toDouble() ?? 0,
      paidUsd: (totals['paid_usd'] as num?)?.toDouble() ?? 0,
    );
  }
}
