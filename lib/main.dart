import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9C27B0), // Viola principale
            brightness: Brightness.dark,
            primary: const Color(0xFF9C27B0),
            secondary: const Color(0xFFE040FB),
            tertiary: const Color(0xFF00BCD4),
            surface: const Color(0xFF1A1625),
            surfaceContainerHighest: const Color(0xFF2D2538),
          ).copyWith(
            // Colori aggiuntivi per contrasto
            primaryContainer: const Color(0xFF6A1B9A),
            secondaryContainer: const Color(0xFF4A148C),
            tertiaryContainer: const Color(0xFF006064),
            error: const Color(0xFFCF6679),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFFE8DEF8),
            onSurfaceVariant: const Color(0xFFCAC4D0),
          ),
          useMaterial3: true,
          
          // Personalizzazioni aggiuntive
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF2D2538),
          ),
          
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF1A1625),
          ),
          
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFFE040FB),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Grafici e indicatori
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFE040FB),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
