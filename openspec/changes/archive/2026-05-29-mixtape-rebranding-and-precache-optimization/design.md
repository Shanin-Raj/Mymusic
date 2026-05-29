## Context

- Renaming an app in Flutter requires updating the native launcher definitions (`AndroidManifest.xml`), core metadata tags (`main.dart`), and background notification session tags (`player_provider.dart`).
- Standard launch icons must be generated in multiple pixel-density folders (`mipmap-hdpi`, `mipmap-xhdpi`, etc.) to support different hardware sizes cleanly. Adaptive launcher configurations are needed for borderless vector backgrounds on newer Android systems.
- In Flutter, dynamic futures passed to `FutureBuilder` inside `build()` trigger resets. Caching the Future object itself in-memory (using a synchronous future return) forces reference equality checks, stopping rebuild flickering.
- Android 13+ foreground services require stenciled vector notification icons. These resources must be protected from compiler tree-shaking via a specific XML keep manifest (`keep.xml`).
- Instantly pre-caching upcoming tracks when playback begins (via the player index change stream) gives the backend a full track duration head start, ensuring seamless, zero-latency transitions.

## Decisions

- **Use `flutter_launcher_icons`**: Simplifies adaptive icon building, creating all density mipmaps from the high-res jpeg.
- **Set `ios: false`**: Avoids path compilation errors on Android-only codebases.
- **Implement Future Caching**: Caches the `Future<List<dynamic>>` reference in `ApiService`. This provides a global fix for flickering lists across all screens in just one file.
- **Implement `keep.xml` Resource Protection**: Tells the resource shrinker (R8) to protect dynamically referenced notification mask drawables.
- **Immediate Index Pre-Caching**: Leverages `_player.currentIndexStream` to pre-cache upcoming songs immediately upon track change, purging position polling logic.
