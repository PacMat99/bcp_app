import 'package:flutter/material.dart';

class AppTheme {
  // PALETTE "PRECISION ENGINEERING"
  // Ispirata alla strumentazione tecnica (Garmin, Strumenti di misura)
  
  // 1. Primary: Slate Blue (Struttura, Testi importanti)
  static const Color slateDark = Color(0xFF263238); 
  
  // 2. Action: Tech Blue (Interazione, Bottoni, Slider attivi)
  static const Color techBlue = Color(0xFF0277BD); 
  
  // 3. Accent: Safety Orange (Focus, Dati critici, Selection)
  static const Color safetyOrange = Color(0xFFEF6C00);
  
  // 4. Backgrounds
  static const Color background = Color(0xFFFFFFFF); // Bianco puro per visibilità outdoor
  static const Color surface = Color(0xFFF5F7FA);   // Grigio ghiaccio per le aree contenitore
  
  // 5. Semantic
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      
      // Definisce la palette globale
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: slateDark,
        onPrimary: Colors.white,
        secondary: techBlue,
        onSecondary: Colors.white,
        tertiary: safetyOrange,
        onTertiary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: slateDark,
        surfaceContainerHighest: Color(0xFFECEFF1), // Per elementi disattivati o sfondi alternativi
      ),

      // AppBar tecnica e pulita
      appBarTheme: const AppBarTheme(
        backgroundColor: slateDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w600, 
          letterSpacing: 0.5,
          fontFamily: 'Roboto', // O il tuo font preferito
        ),
      ),

      // Card: Stile "Blocco Dati"
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0, // Flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Angoli meno stondati = più tecnico
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1), // Bordo sottile
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: Color(0xFF546E7A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: techBlue, width: 2),
        ),
        prefixIconColor: techBlue,
      ),

      // Bottoni
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: techBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),

      // Segmented Buttons (Molto usati nei tuoi config)
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return techBlue;
            return null;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return Colors.white;
            return slateDark;
          }),
          side: MaterialStateProperty.all(const BorderSide(color: techBlue)),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: techBlue,
        inactiveTrackColor: const Color(0xFFCFD8DC),
        thumbColor: safetyOrange, // Il "cursore" arancione aumenta la visibilità
        overlayColor: safetyOrange,
        trackHeight: 4,
      ),
      
      // Icone
      iconTheme: const IconThemeData(
        color: techBlue,
      ),
    );
  }
}