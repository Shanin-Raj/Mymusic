import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/download_provider.dart';
import 'services/connectivity_service.dart';
import 'services/audio_controller.dart';
import 'features/main_navigation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Firebase Auth Error: $e');
  }

  await Hive.initFlutter();
  await Hive.openBox('offline_songs');

  final connectivityService = ConnectivityService.instance;
  await connectivityService.init();

  final audioProvider = AudioProvider();
  await audioProvider.init(connectivityService);

  // Wire AudioController to use the main AudioProvider for room playback
  AudioController.instance.setAudioProvider(audioProvider);

  final downloadProvider = DownloadProvider();
  await downloadProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: audioProvider),
        ChangeNotifierProvider.value(value: downloadProvider),
      ],
      child: const MixtapeApp(),
    ),
  );
}

class MixtapeApp extends StatelessWidget {
  const MixtapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Mixtape',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: SonicTheme.lightTheme,
      darkTheme: SonicTheme.darkTheme,
      navigatorKey: navigatorKey,
      home: const MainNavigation(),
    );
  }
}
