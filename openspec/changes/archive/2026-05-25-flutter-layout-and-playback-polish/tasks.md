## 1. Layout Refinement

- [x] 1.1 Wrap the root application `Scaffold` or main container in a `SafeArea` to respect system bars.
- [x] 1.2 Use `AnnotatedRegion<SystemUiOverlayStyle>` to set status and navigation bar colors/brightness.
- [x] 1.3 Audit all screens for hardcoded paddings that might interfere with the new `SafeArea` implementation.

## 2. Now Playing Screen Polish

- [x] 2.1 Identify the seek bar widget and ensure it is connected to the `AudioHandler` position and duration streams.
- [x] 2.2 Implement the `onChanged` and `onChangedEnd` callbacks for the seek bar to trigger seeking in the `AudioHandler`.
- [x] 2.3 Verify and fix the `ThemeData` usage in the Now Playing screen to ensure dark mode is applied to the background, text, and icons.

## 3. Background Playback and Track Progression

- [x] 3.1 Update the `AudioHandler` to listen for the `processingState.completed` event from the audio player.
- [x] 3.2 Implement automatic track skipping to the next item in the queue upon current track completion.
- [x] 3.3 Ensure the `AudioHandler` is correctly configured to show the Android system notification with track metadata and media controls.
- [x] 3.4 Verify that background playback continues uninterrupted when the screen is locked or the app is minimized.

## 4. Verification and Testing

- [x] 4.1 Verify layout on different emulated screen sizes and aspect ratios.
- [x] 4.2 Test seek bar functionality (manual seeking and automatic updates).
- [x] 4.3 Confirm dark mode visibility and consistency across the 'Now Playing' screen.
- [x] 4.4 Validate background playback continuity and system notification behavior.
