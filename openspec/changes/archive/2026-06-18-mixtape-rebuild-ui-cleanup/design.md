## Technical Architecture

### 1. Safe Area & Mini Player Docking
Detail screens (`PlaylistDetailScreen`, `AlbumDetailScreen`, `ArtistDetailScreen`) now wrap their `MiniPlayer` containing column with a `SafeArea`:
```dart
bottomNavigationBar: const SafeArea(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MiniPlayer(),
    ],
  ),
)
```

### 2. Collapsible Dynamic Padding
Screens monitor `AudioProvider.currentSong` to adjust bottom scroll paddings dynamically:
```dart
final hasMiniPlayer = audioProvider.currentSong != null;
...
padding: EdgeInsets.only(
  left: 16.0,
  right: 16.0,
  top: 16.0,
  bottom: hasMiniPlayer ? 100.0 : 16.0,
)
```

### 3. Image Selector in Dialog
The `_showCreatePlaylistDialog` in `LibraryScreen` uses `StatefulBuilder` to load available cover images asynchronously:
```dart
ApiService.fetchAvailableImages().then((images) {
  setDialogState(() {
    availableImages = images;
  });
});
```

### 4. Branding Configurations
`pubspec.yaml` was integrated with `flutter_launcher_icons`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/mixtapelogo.jpeg"
```
