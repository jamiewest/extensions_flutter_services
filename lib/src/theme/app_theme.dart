// import 'package:flutter/material.dart';

// /// Defines the app's color schemes and themes.
// ///
// /// This class provides light and dark themes based on Material Design 3.
// /// You can customize these themes to match your app's design requirements.
// class AppTheme {
//   // Prevent instantiation
//   AppTheme._();

//   // Color seeds for generating color schemes
//   static const Color _primarySeedColor = Colors.blue;

//   /// The light theme for the app.
//   ///
//   /// Uses Material Design 3 with a light color scheme generated from
//   /// the primary seed color.
//   static ThemeData get lightTheme {
//     final colorScheme = ColorScheme.fromSeed(
//       seedColor: _primarySeedColor,
//       brightness: Brightness.light,
//     );

//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: colorScheme,
//       brightness: Brightness.light,

//       // AppBar theme
//       appBarTheme: AppBarTheme(
//         centerTitle: false,
//         elevation: 0,
//         backgroundColor: colorScheme.surface,
//         foregroundColor: colorScheme.onSurface,
//       ),

//       // Card theme
//       cardTheme: CardThemeData(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),

//       // Input decoration theme
//       inputDecorationTheme: InputDecorationTheme(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         filled: true,
//       ),

//       // Floating Action Button theme
//       floatingActionButtonTheme: FloatingActionButtonThemeData(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }

//   /// The dark theme for the app.
//   ///
//   /// Uses Material Design 3 with a dark color scheme generated from
//   /// the primary seed color.
//   static ThemeData get darkTheme {
//     final colorScheme = ColorScheme.fromSeed(
//       seedColor: _primarySeedColor,
//       brightness: Brightness.dark,
//     );

//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: colorScheme,
//       brightness: Brightness.dark,

//       // AppBar theme
//       appBarTheme: AppBarTheme(
//         centerTitle: false,
//         elevation: 0,
//         backgroundColor: colorScheme.surface,
//         foregroundColor: colorScheme.onSurface,
//       ),

//       // Card theme
//       cardTheme: CardThemeData(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),

//       // Input decoration theme
//       inputDecorationTheme: InputDecorationTheme(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         filled: true,
//       ),

//       // Floating Action Button theme
//       floatingActionButtonTheme: FloatingActionButtonThemeData(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }

//   /// Returns the appropriate text theme color based on brightness.
//   ///
//   /// Useful for custom widgets that need to adapt to the current theme.
//   static Color getTextColor(BuildContext context) {
//     return Theme.of(context).brightness == Brightness.light
//         ? Colors.black87
//         : Colors.white;
//   }

//   /// Returns true if the current theme is dark.
//   static bool isDark(BuildContext context) {
//     return Theme.of(context).brightness == Brightness.dark;
//   }
// }
