import 'package:flutter/material.dart';

/// Design tokens for the Safety app.
///
/// The product is a public-safety tool, so the palette is deliberately
/// institutional rather than playful: a deep navy carries authority, surfaces
/// are near-neutral so that status colour is the only thing that shouts, and
/// nothing is a gradient. Status meaning is carried by colour *and* by an icon
/// so it never depends on colour perception alone.
class AppColors extends ThemeExtension<AppColors> {
  /// Child missing, wanted person, or an alert awaiting review.
  final Color urgent;

  /// An alert that has been reviewed and is actively broadcast.
  final Color verified;

  /// Submitted but not yet reviewed by an authority.
  final Color pending;

  /// The person has been found; the case is closed.
  final Color resolved;

  /// Missing adult, distinguished from a missing child.
  final Color adultMissing;

  /// Text on top of [urgent] / [verified] / [pending] / [resolved].
  final Color onStatus;

  /// Hairline used to separate surfaces instead of heavy shadows.
  final Color borderSubtle;

  /// Flat fill for grouped or secondary content.
  final Color surfaceMuted;

  /// Translucent flat scrim over imagery, used where a gradient used to be.
  final Color imageScrim;

  const AppColors({
    required this.urgent,
    required this.verified,
    required this.pending,
    required this.resolved,
    required this.adultMissing,
    required this.onStatus,
    required this.borderSubtle,
    required this.surfaceMuted,
    required this.imageScrim,
  });

  static const AppColors light = AppColors(
    urgent: Color(0xFFB3261E),
    verified: Color(0xFF1B6B3A),
    pending: Color(0xFF8A5A00),
    resolved: Color(0xFF00696E),
    adultMissing: Color(0xFF5B4BA8),
    onStatus: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFDDE1E6),
    surfaceMuted: Color(0xFFF2F4F7),
    imageScrim: Color(0xCC10161F),
  );

  static const AppColors dark = AppColors(
    urgent: Color(0xFFF2B8B5),
    verified: Color(0xFF7FD1A0),
    pending: Color(0xFFF0C36D),
    resolved: Color(0xFF7FD6DB),
    adultMissing: Color(0xFFC3B9F5),
    onStatus: Color(0xFF10202A),
    borderSubtle: Color(0xFF333B45),
    surfaceMuted: Color(0xFF1B212A),
    imageScrim: Color(0xD910161F),
  );

  @override
  AppColors copyWith({
    Color? urgent,
    Color? verified,
    Color? pending,
    Color? resolved,
    Color? adultMissing,
    Color? onStatus,
    Color? borderSubtle,
    Color? surfaceMuted,
    Color? imageScrim,
  }) {
    return AppColors(
      urgent: urgent ?? this.urgent,
      verified: verified ?? this.verified,
      pending: pending ?? this.pending,
      resolved: resolved ?? this.resolved,
      adultMissing: adultMissing ?? this.adultMissing,
      onStatus: onStatus ?? this.onStatus,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      imageScrim: imageScrim ?? this.imageScrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      urgent: Color.lerp(urgent, other.urgent, t)!,
      verified: Color.lerp(verified, other.verified, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      resolved: Color.lerp(resolved, other.resolved, t)!,
      adultMissing: Color.lerp(adultMissing, other.adultMissing, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
    );
  }
}

/// Corner radii. Kept in one place so cards, sheets and fields agree.
class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  const AppRadii._();
}

/// Spacing scale (4pt grid).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  const AppSpacing._();
}

class AppTheme {
  /// Deep navy: reads as institutional and keeps status colours dominant.
  static const Color _seed = Color(0xFF1E3A5F);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness).copyWith(
          // Flat surfaces: the tonal tints from fromSeed read as a gradient once
          // stacked, so the top levels are pinned to a single value.
          surface: isDark ? const Color(0xFF12171E) : const Color(0xFFFFFFFF),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFFFFFFF),
          surfaceContainerLow: isDark
              ? const Color(0xFF171D25)
              : const Color(0xFFF7F9FB),
          surfaceContainer: isDark
              ? const Color(0xFF1B212A)
              : const Color(0xFFF2F4F7),
          surfaceContainerHigh: isDark
              ? const Color(0xFF222933)
              : const Color(0xFFEDF0F4),
          outlineVariant: colors.borderSubtle,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: [colors],
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        side: BorderSide(color: colors.borderSubtle),
        labelStyle: base.textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colors.borderSubtle),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _fieldBorder(colors.borderSubtle),
        enabledBorder: _fieldBorder(colors.borderSubtle),
        focusedBorder: _fieldBorder(scheme.primary, width: 2),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return base.textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: colors.surfaceMuted,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Tight, high-contrast type. Headlines get negative tracking and heavier
  /// weights so the hierarchy survives on small screens; labels get positive
  /// tracking so they read as metadata.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        letterSpacing: 0.6,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Convenience accessor for the semantic palette.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
