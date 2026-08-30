import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// RAWNQ's visual identity.
///
/// The palette is taken from the shop's own assets: `brand_color` is
/// `#7c3918` on the live `tenants` record, and the cream ground and terracotta
/// mid-tone are sampled from the official logo artwork.
class RawnqColors {
  const RawnqColors._();

  static const Color brown = Color(0xFF7C3918);
  static const Color brownDark = Color(0xFF5A2810);
  static const Color terracotta = Color(0xFFB5623C);
  static const Color cream = Color(0xFFF3EBE1);
  static const Color creamDeep = Color(0xFFE8DBCC);
  static const Color sand = Color(0xFFFDF9F4);
  static const Color ink = Color(0xFF3A2A1F);
  static const Color inkSoft = Color(0xFF7A6659);
  static const Color line = Color(0xFFE4D8C9);
  static const Color sale = Color(0xFFA83232);
  static const Color success = Color(0xFF4F7A55);
  static const Color surface = Color(0xFFFFFFFF);
}

/// Spacing and radius scale, so screens stay visually consistent.
class RawnqSpace {
  const RawnqSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
}

/// Soft, warm elevation — the brief asks for subtle shadows, not drop shadows.
const List<BoxShadow> kCardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x147C3918), blurRadius: 18, offset: Offset(0, 6)),
];

ThemeData buildRawnqTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: RawnqColors.brown,
    onPrimary: Colors.white,
    primaryContainer: RawnqColors.cream,
    onPrimaryContainer: RawnqColors.brownDark,
    secondary: RawnqColors.terracotta,
    onSecondary: Colors.white,
    secondaryContainer: RawnqColors.creamDeep,
    onSecondaryContainer: RawnqColors.brownDark,
    error: RawnqColors.sale,
    onError: Colors.white,
    surface: RawnqColors.surface,
    onSurface: RawnqColors.ink,
    surfaceContainerHighest: RawnqColors.cream,
    onSurfaceVariant: RawnqColors.inkSoft,
    outline: RawnqColors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Tajawal',
    scaffoldBackgroundColor: RawnqColors.sand,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: RawnqColors.sand,
      foregroundColor: RawnqColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: RawnqColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: RawnqColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RawnqColors.cream,
      selectedColor: RawnqColors.brown,
      labelStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w500,
      ),
      side: const BorderSide(color: RawnqColors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusLg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RawnqColors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RawnqColors.brown,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: RawnqColors.brown, width: 1.4),
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RawnqColors.brown,
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RawnqColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: RawnqSpace.lg,
        vertical: RawnqSpace.lg,
      ),
      hintStyle: const TextStyle(color: RawnqColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        borderSide: const BorderSide(color: RawnqColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        borderSide: const BorderSide(color: RawnqColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        borderSide: const BorderSide(color: RawnqColors.brown, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        borderSide: const BorderSide(color: RawnqColors.sale, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        borderSide: const BorderSide(color: RawnqColors.sale, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RawnqColors.surface,
      indicatorColor: RawnqColors.cream,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? RawnqColors.brown
              : RawnqColors.inkSoft,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? RawnqColors.brown
              : RawnqColors.inkSoft,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: RawnqColors.line,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: RawnqColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'Tajawal',
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: RawnqColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RawnqSpace.radiusLg),
        ),
      ),
    ),
  );
}

TextTheme _textTheme(TextTheme base) => base.copyWith(
  displaySmall: base.displaySmall?.copyWith(
    fontWeight: FontWeight.w800,
    color: RawnqColors.ink,
    height: 1.3,
  ),
  headlineSmall: base.headlineSmall?.copyWith(
    fontWeight: FontWeight.w700,
    color: RawnqColors.ink,
    height: 1.35,
  ),
  titleLarge: base.titleLarge?.copyWith(
    fontWeight: FontWeight.w700,
    color: RawnqColors.ink,
    height: 1.4,
  ),
  titleMedium: base.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
    color: RawnqColors.ink,
    height: 1.45,
  ),
  bodyLarge: base.bodyLarge?.copyWith(color: RawnqColors.ink, height: 1.6),
  bodyMedium: base.bodyMedium?.copyWith(color: RawnqColors.ink, height: 1.7),
  bodySmall: base.bodySmall?.copyWith(color: RawnqColors.inkSoft, height: 1.6),
  labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
);
