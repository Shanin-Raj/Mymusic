import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../core/constants.dart';

class RoomBottomSheet extends StatefulWidget {
  const RoomBottomSheet({super.key});

  @override
  State<RoomBottomSheet> createState() => _RoomBottomSheetState();
}

class _RoomBottomSheetState extends State<RoomBottomSheet> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? MyColors.blackColor : MyColors.offWhite;
    final textColor = isDark ? Colors.white : MyColors.darkText;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Listening Room',
            style: AppTextStyles.sectionHeader(color: textColor).copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (audioProvider.activeRoomId != null) ...[
            Text(
              'Connected to Room:',
              style: AppTextStyles.bodyRegular(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              audioProvider.activeRoomId!,
              style: AppTextStyles.greeting(color: MyColors.greenColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                audioProvider.leaveRoom();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Leave Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () async {
                try {
                  await audioProvider.createRoom();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.greenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Create New Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter 5-character Room Code',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: textColor),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final code = _codeController.text.trim().toUpperCase();
                if (code.length != 5) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code must be 5 characters')));
                  return;
                }
                try {
                  await audioProvider.joinRoom(code);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                foregroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Join Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
