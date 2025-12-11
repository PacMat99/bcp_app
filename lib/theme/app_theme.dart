import 'package:flutter/material.dart';

class AppTheme {
  // PALETTE "ELECTRIC VELOCITY"
  // Look moderno, sportivo e ad alto contrasto per l'outdoor.
  
  // 1. Primary: Midnight Blue
  // Sostituisce il grigio ardesia. È scuro abbastanza per il testo su bianco,
  // ma ha una tonalità blu che lo rende più "tech".
  static const Color primaryDark = Color(0xFF0D1B2A); 
  
  // 2. Action: Vivid Blue
  // Un blu più saturo e luminoso rispetto al vecchio "Tech Blue".
  // Cattura l'occhio sotto il sole.
  static const Color actionBlue = Color(0xFF2962FF); 
  
  // 3. Accent: Electric Cyan
  // Per dettagli che devono "poppare" fuori.
  static const Color accentCyan = Color(0xFF00B0FF);
  
  // 4. Sfondi
  static const Color background = Color(0xFFFFFFFF); // Bianco Puro (Indispensabile outdoor)
  static const Color surface = Color(0xFFF0F2F5);   // Grigio ghiaccio chiarissimo (moderno)
  
  // 5. Semantic Colors (Più vivaci)
  static const Color error = Color(0xFFD50000); // Rosso acceso
  static const Color success = Color(0xFF00C853); // Verde traffico

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      
      // Definisce la palette globale
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        
        // Colori Principali
        primary: primaryDark,
        onPrimary: Colors.white,
        
        // Colori Secondari (Azioni)
        secondary: actionBlue,
        onSecondary: Colors.white,
        
        // Colori Terziari (Accent)
        tertiary: accentCyan,
        onTertiary: Colors.black, // Testo nero sul ciano per leggibilità
        
        // Stati
        error: error,
        onError: Colors.white,
        
        // Superfici
        surface: surface,
        onSurface: primaryDark,
        
        // Colore per sfondi alternativi (es. header box)
        primaryContainer: primaryDark, 
        onPrimaryContainer: Colors.white,
        
        // Container secondari (es. selezione bike type)
        secondaryContainer: Color(0xFFE3F2FD), // Azzurro chiarissimo
        onSecondaryContainer: actionBlue,
        
        // Bordi e linee
        outline: Color(0xFFB0BEC5),
        surfaceContainerHighest: Color(0xFFE0E0E0), // Grigio medio per i box non attivi
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: background, // AppBar bianca per look "Clean"
        foregroundColor: primaryDark, // Titolo scuro
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 22, 
          fontWeight: FontWeight.w700, // Più grassetto = più moderno
          letterSpacing: -0.5,
          fontFamily: 'Roboto', 
        ),
        iconTheme: IconThemeData(color: primaryDark),
      ),

      // Card: Più definite
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2, // Leggera ombra per staccare dal fondo "ghiaccio"
        shadowColor: Colors.black.withOpacity(0.1), // Ombra morbida
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Arrotondamento moderno
          side: BorderSide.none, // Niente bordo, usiamo l'ombra
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF607D8B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: actionBlue, width: 2),
        ),
        prefixIconColor: actionBlue,
      ),

      // Bottoni
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: Colors.white,
          elevation: 4, // Bottone "floating" che invita al click
          shadowColor: actionBlue.withOpacity(0.4), // Ombra colorata (molto moderno)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      // Segmented Buttons
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return actionBlue;
            return Colors.white;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) return Colors.white;
            return primaryDark;
          }),
          side: MaterialStateProperty.all(const BorderSide(color: Color(0xFFCFD8DC))), // Bordo grigio chiaro
          elevation: MaterialStateProperty.resolveWith<double>((states) {
             if (states.contains(MaterialState.selected)) return 2;
             return 0;
          }),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: actionBlue,
        inactiveTrackColor: const Color(0xFFE0E0E0),
        thumbColor: primaryDark, // Cursore scuro per contrasto
        overlayColor: actionBlue.withOpacity(0.1),
        trackHeight: 6,
      ),
      
      // Icone generali
      iconTheme: const IconThemeData(
        color: actionBlue,
      ),
      
      // Floating Action Button (se lo userai)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: actionBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}