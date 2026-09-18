import 'package:flutter/material.dart';

/// Navigator key global de la app, asignado a MaterialApp en main.dart.
///
/// Permite navegar desde código que no tiene un BuildContext propio
/// (ej. AuthProvider, un ChangeNotifier) — en particular, para volver
/// al login limpiando todo el stack de pantallas cuando el backend
/// revoca la sesión (401), igual que ya hace el botón manual de
/// "Cerrar sesión" con su propio context.
final navigatorKey = GlobalKey<NavigatorState>();
