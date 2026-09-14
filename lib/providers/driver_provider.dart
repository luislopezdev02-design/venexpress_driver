import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../models/package_model.dart';
import '../models/route_model.dart';
import '../services/driver_service.dart';
import '../services/driver_route_service.dart';
import '../services/hub_scan_service.dart';
import '../services/api_client.dart';

class DriverProvider extends ChangeNotifier {
  final DriverService _service = DriverService();
  final DriverRouteService _routeService = DriverRouteService();
  final HubScanService _hubScanService = HubScanService();

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

  Future<void> completeRoute() async {
    activeRoute = await _routeService.completeRoute();
    notifyListeners();
  }

  List<RouteModel> availableRoutes = [];
  bool isLoadingAvailableRoutes = false;
  String? availableRoutesError;

  /// Rutas hub_transfer/hub_distribution disponibles para el
  /// repartidor de HUB autenticado (equivalente a la pestaña
  /// "Rutas disponibles" del dashboard web).
  Future<void> loadAvailableRoutes() async {
    isLoadingAvailableRoutes = true;
    availableRoutesError = null;
    notifyListeners();

    try {
      availableRoutes = await _routeService.getAvailableRoutes();
    } on ApiException catch (e) {
      availableRoutesError = e.message;
    } catch (e) {
      availableRoutesError = 'No se pudieron cargar las rutas disponibles.';
    } finally {
      isLoadingAvailableRoutes = false;
      notifyListeners();
    }
  }

  /// "Primero en tomar, primero en repartir": si el backend rechaza
  /// la toma (otro repartidor la tomó primero), propaga la
  /// ApiException tal cual para que la pantalla muestre el mensaje.
  Future<void> claimRoute(int routeId) async {
    activeRoute = await _routeService.claimRoute(routeId);
    notifyListeners();
  }

  /// Identifica una guía sin ejecutar ningún movimiento (paso 1 del
  /// escaneo de HUB: ESCANEAR -> IDENTIFICAR).
  Future<PackageModel> lookupPackage(String trackingNumber) => _hubScanService.lookup(trackingNumber);

  /// Ejecuta la operación de HUB ya confirmada por el repartidor
  /// (paso 2: EJECUTAR). La clave debe venir de
  /// [resolveHubOperation], calculada sobre la misma guía identificada
  /// en [lookupPackage].
  Future<HubScanResult> executeHubOperation(String operationKey, String trackingNumber) async {
    final HubScanResult result;

    switch (operationKey) {
      case 'collection':
        result = await _hubScanService.scanCollection(trackingNumber);
        break;
      case 'hub_reception':
        result = await _hubScanService.scanHubReception(trackingNumber);
        break;
      case 'hub_departure':
        result = await _hubScanService.scanHubDispatch(trackingNumber);
        break;
      case 'hub_arrival':
        result = await _hubScanService.scanHubArrival(trackingNumber);
        break;
      default:
        throw ApiException('Operación de escaneo desconocida.');
    }

    // Refrescamos en segundo plano para que "Mi Ruta" refleje el
    // avance sin que el repartidor tenga que salir de la pantalla.
    loadActiveRoute();

    return result;
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
    String? codPaymentMethod,
  }) async {
    final updated = await _service.completeDelivery(
      packageId: packageId,
      receiverName: receiverName,
      receiverIdDoc: receiverIdDoc,
      receiverPhone: receiverPhone,
      confirmationMethod: confirmationMethod,
      photo: photo,
      codPaymentMethod: codPaymentMethod,
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
