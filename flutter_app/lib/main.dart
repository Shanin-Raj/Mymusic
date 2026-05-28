import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sonic_vault_flutter/audio_handler.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/providers/theme_provider.dart';
import 'package:sonic_vault_flutter/providers/playlist_provider.dart';
import 'package:sonic_vault_flutter/screens/main_screen.dart';

late MyAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.sonic_vault_flutter.dev.channel.audio_v4',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationIcon: 'drawable/ic_notification',
      androidStopForegroundOnPause: false,
      androidNotificationOngoing: false,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(_audioHandler)),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: const SonicVaultApp(),
    ),
  );
}

class SonicVaultApp extends StatelessWidget {
  const SonicVaultApp({super.key});

  // Montserrat — closest free Google Font to Spotify's "Spotify Mix" typeface
  static TextTheme _buildTextTheme(Color baseColor) => GoogleFonts.montserratTextTheme(
    TextTheme(
      displayLarge:  TextStyle(color: baseColor, fontWeight: FontWeight.w800, letterSpacing: -1.0),
      displayMedium: TextStyle(color: baseColor, fontWeight: FontWeight.w700, letterSpacing: -0.8),
      displaySmall:  TextStyle(color: baseColor, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: TextStyle(color: baseColor, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium:TextStyle(color: baseColor, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: baseColor, fontWeight: FontWeight.w700),
      titleLarge:    TextStyle(color: baseColor, fontWeight: FontWeight.w700),
      titleMedium:   TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      titleSmall:    TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      bodyLarge:     TextStyle(color: baseColor, fontWeight: FontWeight.w500),
      bodyMedium:    TextStyle(color: baseColor, fontWeight: FontWeight.w400),
      bodySmall:     TextStyle(color: baseColor.withValues(alpha: 0.7), fontWeight: FontWeight.w400),
      labelLarge:    TextStyle(color: baseColor, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelMedium:   TextStyle(color: baseColor, fontWeight: FontWeight.w500),
      labelSmall:    TextStyle(color: baseColor.withValues(alpha: 0.7), fontWeight: FontWeight.w400),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonic Vault',
      debugShowCheckedModeBanner: false,

      // ── LIGHT THEME (off-white, #F5F5F7 bg) ─────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        primaryColor: const Color(0xFF1DB954),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          brightness: Brightness.light,
          primary:    const Color(0xFF1DB954),
          surface:    const Color(0xFFFFFFFF),
          onSurface:  const Color(0xFF111111),
        ),
        textTheme:        _buildTextTheme(const Color(0xFF111111)),
        primaryTextTheme: _buildTextTheme(const Color(0xFF111111)),
        sliderTheme: const SliderThemeData(
          activeTrackColor:   Color(0xFF1DB954),
          inactiveTrackColor: Color(0xFFDDDDDD),
          thumbColor:         Color(0xFF1DB954),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF282828),
          contentTextStyle: GoogleFonts.montserrat(color: Colors.white),
        ),
      ),

      // ── DARK THEME (#121212 bg) ──────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1ED760),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF1ED760),
          surface:   Color(0xFF121212),
          onSurface: Colors.white,
        ),
        textTheme:        _buildTextTheme(Colors.white),
        primaryTextTheme: _buildTextTheme(Colors.white),
        sliderTheme: const SliderThemeData(
          activeTrackColor:   Color(0xFF1ED760),
          inactiveTrackColor: Color(0xFF535353),
          thumbColor:         Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF282828),
          contentTextStyle: GoogleFonts.montserrat(color: Colors.white),
        ),
      ),

      themeMode: context.watch<ThemeProvider>().themeMode,
      home: const MainScreen(),
    );
  }
}
