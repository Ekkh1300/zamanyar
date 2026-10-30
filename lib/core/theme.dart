import 'package:flutter/material.dart';

/// Design tokens. Two palettes share one structure so screens can read
/// [AppColors] from the theme and stay in sync when the user flips theme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.mint,
    required this.amber,
    required this.coral,
    required this.blue,
    required this.pink,
    required this.nav,
  });

  final Color bg;
  final Color bgAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primarySoft;
  final Color mint;
  final Color amber;
  final Color coral;
  final Color blue;
  final Color pink;
  final Color nav;

  static const dark = AppColors(
    bg: Color(0xFF070A12),
    bgAlt: Color(0xFF0C1120),
    surface: Color(0xFF111826),
    surfaceAlt: Color(0xFF182033),
    border: Color(0x14FFFFFF),
    text: Color(0xFFEDF1FC),
    muted: Color(0xFF8C95AD),
    primary: Color(0xFF7C6CFF),
    primarySoft: Color(0xFFA996FF),
    mint: Color(0xFF2FE3B4),
    amber: Color(0xFFFFC15E),
    coral: Color(0xFFFF7091),
    blue: Color(0xFF5AA9FF),
    pink: Color(0xFFFF7CD6),
    nav: Color(0xFF10151F),
  );

  static const light = AppColors(
    bg: Color(0xFFF3F4FB),
    bgAlt: Color(0xFFE9ECF8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F4FC),
    border: Color(0x14101933),
    text: Color(0xFF12172B),
    muted: Color(0xFF6B7390),
    primary: Color(0xFF5B49E8),
    primarySoft: Color(0xFF7C6CFF),
    mint: Color(0xFF0CA47C),
    amber: Color(0xFFC9820B),
    coral: Color(0xFFE0455F),
    blue: Color(0xFF2E7FE0),
    pink: Color(0xFFC948B0),
    nav: Color(0xFFFFFFFF),
  );

  bool get isDark => bg.computeLuminance() < 0.3;

  static const subjectPalette = <Color>[
    Color(0xFF7C6CFF),
    Color(0xFF2FE3B4),
    Color(0xFF5AA9FF),
    Color(0xFFFFC15E),
    Color(0xFFFF7091),
    Color(0xFFFF7CD6),
    Color(0xFF59E0FF),
    Color(0xFFFF9F6B),
  ];

  @override
  AppColors copyWith({
    Color? bg,
    Color? bgAlt,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? text,
    Color? muted,
    Color? primary,
    Color? primarySoft,
    Color? mint,
    Color? amber,
    Color? coral,
    Color? blue,
    Color? pink,
    Color? nav,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bgAlt: bgAlt ?? this.bgAlt,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      mint: mint ?? this.mint,
      amber: amber ?? this.amber,
      coral: coral ?? this.coral,
      blue: blue ?? this.blue,
      pink: pink ?? this.pink,
      nav: nav ?? this.nav,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      bgAlt: l(bgAlt, other.bgAlt),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      primary: l(primary, other.primary),
      primarySoft: l(primarySoft, other.primarySoft),
      mint: l(mint, other.mint),
      amber: l(amber, other.amber),
      coral: l(coral, other.coral),
      blue: l(blue, other.blue),
      pink: l(pink, other.pink),
      nav: l(nav, other.nav),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static ThemeData build(Brightness brightness) {
    final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      secondary: c.mint,
      surface: c.surface,
      onSurface: c.text,
      error: c.coral,
    );

    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: c.text,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: c.text,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: c.text,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        height: 1.35,
        color: c.text,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: c.text,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: c.text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: c.text,
      ),
      titleSmall: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: c.text,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.75,
        color: c.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: c.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: c.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: c.text,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: c.muted,
      ),
      labelSmall: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: c.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Vazirmatn',
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      extensions: [c],
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c.coral),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceAlt,
        contentTextStyle: textTheme.titleSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: Color(0x99000000),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.28),
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
