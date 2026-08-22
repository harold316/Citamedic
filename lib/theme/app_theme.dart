import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
  });

  static const Color primary = Color(0xFF0D9B8A);
  static const Color primaryDark = Color(0xFF0A7A6D);
  static const Color star = Color(0xFFFFC107);
  static const Color danger = Color(0xFFE05A5A);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color location = Color(0xFF2563EB);
  static const Color accent = Color(0xFF6366F1);

  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;

  static const light = AppColors(
    primarySoft: Color(0xFFE6F6F3),
    background: Color.fromARGB(255, 162, 236, 218),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1E2A32),
    muted: Color(0xFF6B7C85),
    border: Color(0xFFE3EEEC),
  );

  static const dark = AppColors(
    primarySoft: Color(0xFF163F3A),
    background: Color(0xFF101618),
    surface: Color(0xFF1A2327),
    text: Color(0xFFF3F7F8),
    muted: Color(0xFF9AADB6),
    border: Color(0xFF2C3A3E),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? light;
  }

  @override
  AppColors copyWith({
    Color? primarySoft,
    Color? background,
    Color? surface,
    Color? text,
    Color? muted,
    Color? border,
  }) {
    return AppColors(
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    const radius = BorderRadius.all(Radius.circular(24));
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      extensions: [colors],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        surface: colors.surface,
      ),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      cardColor: colors.surface,
      dividerColor: colors.border,
      iconTheme: const IconThemeData(color: AppColors.primary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actionsIconTheme: const IconThemeData(color: AppColors.primary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: colors.muted,
        indicatorColor: AppColors.primary,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: colors.text),
        bodyLarge: TextStyle(color: colors.text),
        titleMedium: TextStyle(color: colors.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.muted),
        labelStyle: TextStyle(color: colors.muted),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: colors.text),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primarySoft,
        disabledColor: colors.surface,
        labelStyle: TextStyle(color: colors.text),
        secondaryLabelStyle: TextStyle(color: colors.text),
        side: BorderSide(color: colors.border),
        checkmarkColor: AppColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(color: colors.muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surface : const Color(0xFF1E2A32),
        contentTextStyle: TextStyle(color: isDark ? colors.text : Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return colors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primarySoft;
          }
          return colors.border;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: colors.text,
      ),
      dividerTheme: DividerThemeData(color: colors.border),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: colors.muted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
