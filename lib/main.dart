import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart'; // Importa il nuovo tema

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'MTB Telemetry',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}