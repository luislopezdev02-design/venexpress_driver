import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../models/package_model.dart';
import '../models/route_model.dart';
import '../services/driver_service.dart';
import '../services/driver_route_service.dart';
import '../services/api_client.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();
  final DriverRouteService _routeService = DriverRouteService();

  RouteModel? activeRoute;
  bool isLoadingRoute = false;
  String? routeError;

  Future<void> loadActiveRoute() async {
    isLoadingRoute = true;
    routeError = null;
    notifyListeners();

    try {
      activeRoute = await _routeService.getActiveRoute();
    } on ApiException catch (e) {
      routeError = e.message;
    } catch (e) {
      routeError = 'No se pudo cargar tu ruta.';
    } finally {
      isLoadingRoute = false;
      notifyListeners();
    }
  }

  Future<void> startRoute() async {
    activeRoute = await _routeService.startRoute();
    notifyListeners();
  }

  DashboardSummary? dashboard;
  bool isLoadingDashboard = false;
  String? dashboardError;

  List<PackageModel> packages = [];
  bool isLoadingPackages = false;
  String packagesFilter = 'all';
  String? packagesError;

  List<DriverPaymentModel> commissions = [];
  double commissionsPendingUsd = 0;
  double commissionsPaidUsd = 0;
  bool isLoadingCommissions = false;

  Future<void> loadDashboard() async {
    isLoadingDashboard = true;
    dashboardError = null;
    notifyListeners();

    try {
      dashboard = await _service.getDashboard();
    } on ApiException catch (e) {
      dashboardError = e.message;
    } catch (e) {
      dashboardError = 'No se pudo cargar el resumen.';
    } finally {
      isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadPackages({String? status, String search = ''}) async {
    if (status != null) packagesFilter = status;

    isLoadingPackages = true;
    packagesError = null;
    notifyListeners();

    try {
      final page = await _service.getPackages(status: packagesFilter, search: search);
      packages = page.items;
    } on ApiException catch (e) {
      packagesError = e.message;
    } catch (e) {
      packagesError = 'No se pudo cargar la lista de pedidos.';
    } finally {
      isLoadingPackages = false;
      notifyListeners();
    }
  }

  Future<ScanResult> scan(String trackingNumber) async {
    final result = await _service.scan(trackingNumber);
    // Refrescamos en segundo plano para que el dashboard/lista
    // reflejen el nuevo pedido sin que el usuario tenga que hacerlo.
    loadDashboard();
    return result;
  }

  Future<PackageModel> getPackageDetail(int id) => _service.getPackageDetail(id);

  Future<PackageModel> completeDelivery({
    required int packageId,
    required String receiverName,
    required String receiverIdDoc,
    String? receiverPhone,
    required String confirmationMethod,
    File? photo,
  }) async {
    final updated = await _service.completeDelivery(
      packageId: packageId,
      receiverName: receiverName,
      receiverIdDoc: receiverIdDoc,
      receiverPhone: receiverPhone,
      confirmationMethod: confirmationMethod,
      photo: photo,
    );

    loadDashboard();
    return updated;
  }

  Future<PackageModel> collectCod(int packageId) async {
    final updated = await _service.collectCod(packageId);
    loadDashboard();
    return updated;
  }

  Future<void> loadCommissions() async {
    isLoadingCommissions = true;
    notifyListeners();

    try {
      final page = await _service.getCommissions();
      commissions = page.items;
      commissionsPendingUsd = page.pendingUsd;
      commissionsPaidUsd = page.paidUsd;
    } catch (_) {
      // El resumen ya se ve en el dashboard; si esto falla, dejamos
      // la lista vacía sin bloquear el resto de la app.
    } finally {
      isLoadingCommissions = false;
      notifyListeners();
    }
  }
}
