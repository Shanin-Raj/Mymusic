import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'features/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final audioProvider = AudioProvider();
  await audioProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: audioProvider),
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
      home: const MainNavigation(),
    );
  }
}
