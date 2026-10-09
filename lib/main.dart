import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'services/tema_service.dart';
import 'views/login_page.dart';
import 'views/usuario_page.dart'; // ⬅️ Asegúrate de importar tus otras pantallas
import 'views/registro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await TemaService.cargar(); // Recupera el tema (claro/oscuro) guardado
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cada vez que cambia el tema, se reconstruye el MaterialApp
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaService.modo,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'Gestión de Usuarios',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: modo,
          // 1. Defines cuál será la ruta con la que arranca la app
          initialRoute: '/login',

          // 2. Mapeas el nombre de cada ruta con su widget correspondiente
          routes: {
            '/login': (context) => const LoginPage(),
            '/registro': (context) => const RegistroPage(),
            '/productos': (context) => const ProductosOnlineScreen(
                  correoUsuario: '', // Pasa los parámetros por defecto si son requeridos
                ),
          },
        );
      },
    );
  }
}

//otefrajav@gmail.com
