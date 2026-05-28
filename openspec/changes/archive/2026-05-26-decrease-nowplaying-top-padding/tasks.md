## 1. Optimize Full-Screen Player Layout Spacing

- [x] 1.1 In `lib/screens/main_screen.dart`, locate the `FullScreenPlayer` widget's body layout.
- [x] 1.2 Within the `Column` inside the `SafeArea`, replace the `const Spacer(flex: 2)` immediately above the `AspectRatio` containing the album art with a fixed size spacer `const SizedBox(height: 16)` (or a smaller flexible spacer).
- [x] 1.3 Verify that the album art is correctly elevated on the screen and other playback buttons/lyrics preview are more visible, similar to Reference Image 2.
