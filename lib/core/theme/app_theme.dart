import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shadcn_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ShadcnColors.background,
      colorScheme: const ColorScheme.dark(
        surface: ShadcnColors.background,
        onSurface: ShadcnColors.foreground,
        primary: ShadcnColors.primary,
        onPrimary: ShadcnColors.primaryForeground,
        secondary: ShadcnColors.secondary,
        onSecondary: ShadcnColors.secondaryForeground,
        error: ShadcnColors.destructive,
        onError: ShadcnColors.destructiveForeground,
        outline: ShadcnColors.border,
        surfaceContainerHighest: ShadcnColors.muted,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: ShadcnColors.foreground,
      displayColor: ShadcnColors.foreground,
    );

    final mono = GoogleFonts.jetBrainsMonoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ShadcnColors.panelHeader,
        foregroundColor: ShadcnColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: ShadcnColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ShadcnColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ShadcnColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShadcnColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: ShadcnColors.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: ShadcnColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: ShadcnColors.ring, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: ShadcnColors.mutedForeground,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShadcnColors.primary,
          foregroundColor: ShadcnColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShadcnColors.foreground,
          side: const BorderSide(color: ShadcnColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShadcnColors.foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ShadcnColors.secondary,
        labelStyle: textTheme.labelSmall!,
        side: const BorderSide(color: ShadcnColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ShadcnColors.popover,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ShadcnColors.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: ShadcnColors.popoverForeground),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ShadcnColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ShadcnColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ShadcnColors.secondary,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.all(ShadcnColors.mutedForeground.withValues(alpha: 0.4)),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        iconColor: ShadcnColors.mutedForeground,
        textColor: ShadcnColors.foreground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ShadcnColors.primary,
        linearTrackColor: ShadcnColors.secondary,
      ),
      // expose mono for terminal via extension-like access
      extensions: [
        AppThemeExtras(mono: mono.bodyMedium ?? const TextStyle(fontFamily: 'monospace')),
      ],
    );
  }
}

@immutable
class AppThemeExtras extends ThemeExtension<AppThemeExtras> {
  const AppThemeExtras({required this.mono});
  final TextStyle mono;

  @override
  AppThemeExtras copyWith({TextStyle? mono}) => AppThemeExtras(mono: mono ?? this.mono);

  @override
  AppThemeExtras lerp(ThemeExtension<AppThemeExtras>? other, double t) {
    if (other is! AppThemeExtras) return this;
    return AppThemeExtras(mono: TextStyle.lerp(mono, other.mono, t) ?? mono);
  }
}
