import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema claro/oscuro de toda la app (admin y usuario).
/// Se guarda en SharedPreferences para recordarlo al volver a abrir la app.
class TemaService {
  static const String _clave = 'tema_modo';

  static final ValueNotifier<ThemeMode> modo =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Llamar una vez en main(), antes de runApp().
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      modo.value =
          prefs.getString(_clave) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static Future<void> establecer(ThemeMode nuevo) async {
    modo.value = nuevo;
    await guardar();
  }

  /// Escribe el tema actual en disco. Útil después de prefs.clear(),
  /// que borraría la preferencia al cerrar sesión.
  static Future<void> guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _clave, modo.value == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
