import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonic_vault_flutter/providers/theme_provider.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: theme.primaryColor,
            ),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          ListTile(
            title: const Text('Sleep Timer'),
            subtitle: const Text('Automatically stop playback'),
            trailing: const Icon(Icons.timer_outlined),
            onTap: () => _showSleepTimerPicker(context),
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

  void _showSleepTimerPicker(BuildContext context) {
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
          _timerOption(context, '5 minutes', 5),
          _timerOption(context, '15 minutes', 15),
          _timerOption(context, '30 minutes', 30),
          _timerOption(context, '1 hour', 60),
          _timerOption(context, 'Off', 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _timerOption(BuildContext context, String label, int minutes) {
    return ListTile(
      title: Text(label),
      trailing: context.watch<PlayerProvider>().sleepTimerMinutes == minutes ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        context.read<PlayerProvider>().setSleepTimer(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(minutes > 0 ? 'Sleep timer set for $label' : 'Sleep timer turned off')));
      },
    );
  }
}
