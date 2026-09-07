import 'package:flutter/material.dart';

/// User-facing brand. Dart package name stays `petal_press`.
abstract final class AppDisplay {
  static const name = 'Cute Zine Maker';
  static const shortName = 'Cute Zine';
  static const tagline = 'Pocket zines, kept on this device.';
}

abstract final class PetalColors {
  static const cream = Color(0xFFFFF8F0);
  static const paper = Color(0xFFFFFBF7);
  static const blush = Color(0xFFFFD6E0);
  static const rose = Color(0xFFE88AA8);
  static const roseDeep = Color(0xFFC45D7E);
  static const lavender = Color(0xFFD9C6F0);
  static const mint = Color(0xFFB8E8D4);
  static const peach = Color(0xFFFFD4B8);
  static const lemon = Color(0xFFF7E6A1);
  static const sky = Color(0xFFB8D8F8);
  static const ink = Color(0xFF4A3A52);
  static const muted = Color(0xFF8A7A90);

  /// Soft scrapbook rainbow — chrome only, not the zine page.
  static const rainbow = <Color>[
    blush,
    peach,
    lemon,
    mint,
    sky,
    lavender,
  ];

  static const chromeGradient = <Color>[
    Color(0xFFFFF0F4),
    Color(0xFFFFF3E8),
    Color(0xFFFFF8DC),
    Color(0xFFEEF8F2),
    Color(0xFFEEF4FC),
    Color(0xFFF4EEF8),
  ];

  static Color accentAt(int index) => rainbow[index % rainbow.length];
}

abstract final class PetalPalette {
  static const pens = <Color>[
    Color(0xFF3A2A32),
    Color(0xFFE88AA8),
    Color(0xFFFF7A9C),
    Color(0xFFC9A0DC),
    Color(0xFF7EC8A3),
    Color(0xFFF4A261),
    Color(0xFFF2C94C),
    Color(0xFF6DB4E0),
    Color(0xFFFFB5E8),
    Color(0xFFFFFFFF),
    Color(0xFF8D6E63),
    Color(0xFFB388EB),
  ];

  static const papers = <Color>[
    Color(0xFFFFF6EE),
    Color(0xFFFFF0F4),
    Color(0xFFF4FFF8),
    Color(0xFFF4F4FF),
    Color(0xFFFFF8E8),
    Color(0xFFE8F4FF),
    Color(0xFFFFE4D6),
    Color(0xFFF0E8FF),
    Color(0xFFFFFFFF),
  ];
}

ThemeData buildPetalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Fredoka',
    scaffoldBackgroundColor: PetalColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PetalColors.sky,
      brightness: Brightness.light,
      primary: PetalColors.sky,
      onPrimary: PetalColors.ink,
      secondary: PetalColors.lavender,
      tertiary: PetalColors.mint,
      surface: PetalColors.paper,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: PetalColors.ink,
      displayColor: PetalColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: PetalColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: PetalColors.ink,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: PetalColors.sky,
      thumbColor: PetalColors.lavender,
      inactiveTrackColor: PetalColors.peach.withValues(alpha: 0.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PetalColors.ink,
      contentTextStyle: const TextStyle(fontFamily: 'Fredoka', color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: PetalColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PetalColors.mint,
      foregroundColor: PetalColors.ink,
    ),
  );
}

class RainbowTitle extends StatelessWidget {
  const RainbowTitle({
    super.key,
    this.text = AppDisplay.name,
    this.fontSize = 32,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: PetalColors.rainbow,
      ).createShader(rect),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
