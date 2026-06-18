import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import '../../providers/audio_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: theme.primaryColor,
            ),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          ListTile(
            title: const Text('Sleep Timer'),
            subtitle: const Text('Automatically stop playback'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (audioProvider.sleepTimerMinutes > 0)
                  Text(
                    '${audioProvider.sleepTimerMinutes}m active',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.timer_outlined),
              ],
            ),
            onTap: () => _showSleepTimerPicker(context, audioProvider),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0-dev', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerPicker(BuildContext context, AudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Stop audio in...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _timerOption(context, audioProvider, '5 minutes', 5),
          _timerOption(context, audioProvider, '15 minutes', 15),
          _timerOption(context, audioProvider, '30 minutes', 30),
          _timerOption(context, audioProvider, '1 hour', 60),
          _timerOption(context, audioProvider, 'Off', 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _timerOption(BuildContext context, AudioProvider audioProvider, String label, int minutes) {
    final isSelected = audioProvider.sleepTimerMinutes == minutes;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        audioProvider.setSleepTimer(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(minutes > 0 ? 'Sleep timer set for $label' : 'Sleep timer turned off'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
