# Mobile Client Security Audit — Mixtape (Flutter / Android)
**Target:** Mixtape Flutter Client + Android TWA Shell  
**Scope:** Secret Storage · AndroidManifest · Network Security · State Manipulation  
**Date:** June 18, 2026  
**Status:** DRAFT — Pending Remediation

---

## 1. Executive Summary

The Mixtape client is a Flutter-based Android audio streaming application. It communicates exclusively with a Node.js/Express backend via HTTP REST APIs and Server-Sent Events (SSE). All data persistence is handled through `shared_preferences` (plaintext XML on disk) and a file-based audio cache in the application documents directory.

The audit identified **seven vulnerabilities** across four focus areas. The most critical findings are: cleartext HTTP traffic is explicitly permitted at the Android platform level, all write/delete API calls are sent without any authentication token, the `AudioService` and `MediaButtonReceiver` are exported without permission guards, and the release APK is signed with debug keys — making it trivially re-signable and modifiable.

---

## 2. Vulnerability Report

### 🔴 CRITICAL — V1: Cleartext Traffic Explicitly Enabled (`usesCleartextTraffic="true"`)

**File:** [AndroidManifest.xml:13](file:///d:/music/flutter_app/android/app/src/main/AndroidManifest.xml#L13)

```xml
<application
    android:label="MixTape"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
```

The `android:usesCleartextTraffic="true"` flag allows the app to make **unencrypted HTTP connections** to any host. On Android 9+ (API 28+), this is `false` by default, which is a critical defense-in-depth measure. By setting it to `true`, the app permits:

- **Man-in-the-middle (MITM) attacks** on any network the user connects to (coffee shop Wi-Fi, compromised routers).
- **Passive eavesdropping** on all API traffic — including song metadata, playlist structures, room states, and (if auth tokens are ever added) authentication credentials.
- **Response tampering** — an attacker could inject malicious audio stream URLs or alter the song library.

While the current `baseUrl` uses `https://`, nothing in the Dart code enforces this. A server-side misconfiguration or DNS hijack could downgrade to HTTP, and the app would silently allow it.

**Remediation — Step 1:** Set `usesCleartextTraffic` to `false` and add a `networkSecurityConfig` for fine-grained control:

```xml
<!-- AndroidManifest.xml -->
<application
    android:label="MixTape"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">
```

**Remediation — Step 2:** Create the network security config file:

Create file: `flutter_app/android/app/src/main/res/xml/network_security_config.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Block cleartext (HTTP) traffic globally -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- Optional: Allow cleartext only for localhost during development -->
    <!-- Remove this block before shipping to production -->
    <!--
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">localhost</domain>
        <domain includeSubdomains="false">10.0.2.2</domain>
    </domain-config>
    -->
</network-security-config>
```

---

### 🔴 CRITICAL — V2: All Mutating API Calls Sent Without Authentication

**File:** [api_service.dart](file:///d:/music/flutter_app/lib/services/api_service.dart) · [room_service.dart](file:///d:/music/flutter_app/lib/services/room_service.dart)

Every single API call — including destructive operations like `deleteSong`, `deletePlaylist`, and `addSong` — is sent with **zero authentication headers**:

```dart
// api_service.dart line 86 — DELETE with no auth
static Future<bool> deleteSong(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/songs/$id'));
    // ...
}

// api_service.dart line 74 — POST (triggers yt-dlp download) with no auth
static Future<Map<String, dynamic>> addSong(String? url, String? name, String? artist) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/add-song'),
      headers: {'Content-Type': 'application/json'},  // No Authorization header
      body: json.encode({'url': url, 'name': name, 'artist': artist}),
    );
    // ...
}
```

Anyone who discovers the backend URL (which is hardcoded in plain text at line 7) can issue these requests directly — deleting the entire song library, creating rooms, or triggering expensive download operations.

**Impact:** Complete unauthorized access to all write/delete operations. Combined with V1, an on-path attacker can also observe the `baseUrl` and replay/forge requests.

**Remediation:** Store a shared API key securely and inject it into all mutating requests. Use `flutter_secure_storage` (backed by Android Keystore) instead of the plaintext `shared_preferences`:

**Step 1:** Add dependency to `pubspec.yaml`:
```yaml
dependencies:
  flutter_secure_storage: ^9.2.4
```

**Step 2:** Create a secure config service:

Create file: `flutter_app/lib/services/secure_config_service.dart`
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfigService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _apiKeyKey = 'api_auth_token';

  /// Read the API key from secure storage.
  /// Returns null if not set (first launch — prompt user to configure).
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  /// Save the API key to secure storage (set during onboarding or settings).
  static Future<void> setApiKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key);
  }

  /// Delete the API key (logout / reset).
  static Future<void> clearApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
```

**Step 3:** Update `ApiService` to attach the `Authorization` header:
```dart
// api_service.dart — add auth header helper
static Future<Map<String, String>> _authHeaders() async {
    final apiKey = await SecureConfigService.getApiKey();
    return {
      'Content-Type': 'application/json',
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
    };
}

// Example: secured addSong
static Future<Map<String, dynamic>> addSong(String? url, String? name, String? artist) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/add-song'),
      headers: await _authHeaders(),
      body: json.encode({'url': url, 'name': name, 'artist': artist}),
    );
    _cachedSongs = null;
    _songsFuture = null;
    return json.decode(response.body);
}

// Apply the same pattern to: deleteSong, createPlaylist, addSongToPlaylist,
// deletePlaylist, removeSongFromPlaylist, createRoom, updateRoomState
```

---

### 🟠 HIGH — V3: Backend URL Hardcoded in Plain Dart Source

**File:** [api_service.dart:7](file:///d:/music/flutter_app/lib/services/api_service.dart#L7)

```dart
static String baseUrl = 'https://mymusic-ibgr.onrender.com'; // Default for local testing
```

The production backend URL is hardcoded as a mutable `static String` directly in the compiled Dart source. This is problematic because:

1. **Reverse engineering:** The URL is trivially extractable from the APK via `strings` or any Dart decompiler (e.g., `darter`, `Doldrums`). An attacker now has the exact API endpoint for all attacks identified in the SAST and Cloud Security reports.
2. **No environment separation:** The same URL is used for development and production. There is no mechanism to switch between staging and production backends without modifying source code.
3. **Mutable static field:** Being a non-final `static String`, it could theoretically be overwritten at runtime by injected code or a compromised plugin.

**Remediation:** Use Dart's compile-time `--dart-define` flag to inject the base URL at build time, keeping it out of version-controlled source code:

```dart
// api_service.dart
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mymusic-ibgr.onrender.com',
  );
  // ... rest of the class
```

Build with:
```bash
flutter build apk --dart-define=API_BASE_URL=https://your-production-url.com
```

> **Note:** While this won't prevent extraction from the binary, it cleanly separates environments and removes the URL from source control. True protection of the endpoint requires backend-side authentication (V2) — the URL being known should not be a vulnerability if the API is properly authenticated.

---

### 🟠 HIGH — V4: Release APK Signed with Debug Keystore

**File:** [build.gradle.kts:28-33](file:///d:/music/flutter_app/android/app/build.gradle.kts#L28-L33)

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

The release build type uses the **shared Android debug keystore** (`~/.android/debug.keystore`). This keystore:

1. **Has a well-known password** (`android` / `androiddebugkey`) — any developer can extract the signing key.
2. **Allows APK re-signing** — an attacker can decompile the APK, inject malicious code (e.g., a keylogger for the API key from V2's remediation, or a modified `baseUrl` pointing to their proxy), re-sign with the same debug key, and redistribute.
3. **Breaks Google Play integrity checks** — the Play Store and SafetyNet/Play Integrity API will flag debug-signed APKs.
4. **Voids TWA trust** — the [assetlinks.json](file:///d:/music/backend/server.js#L86-L88) handshake relies on SHA-256 fingerprint matching. A debug-signed APK will fail Digital Asset Links verification on production.

**Remediation:** Generate a release keystore and configure it properly:

```bash
# Generate a release keystore (do this once, keep it SECURE)
keytool -genkey -v -keystore mixtape-release.keystore \
  -alias mixtape -keyalg RSA -keysize 2048 -validity 10000
```

Create `flutter_app/android/key.properties` (add to `.gitignore`!):
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=mixtape
storeFile=../mixtape-release.keystore
```

Update `build.gradle.kts`:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

### 🟠 HIGH — V5: Exported `AudioService` and `MediaButtonReceiver` Without Permission Guards

**File:** [AndroidManifest.xml:38-55](file:///d:/music/flutter_app/android/app/src/main/AndroidManifest.xml#L38-L55)

```xml
<service android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"
    tools:ignore="Instantiatable">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</service>

<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true"
    tools:ignore="Instantiatable">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

Both the `AudioService` and `MediaButtonReceiver` are declared `android:exported="true"` with **no `android:permission` attribute**. This means:

- **Any app on the device** can bind to the `MediaBrowserService` and browse/control the media session — skipping tracks, pausing, playing, or reading the currently-playing song metadata.
- **Any app** can send `MEDIA_BUTTON` intents to trigger playback actions.
- A malicious app could spam `MEDIA_BUTTON` intents to disrupt the user experience, or silently monitor what songs are being played.

> **Nuance:** The `audio_service` Flutter plugin **requires** `exported="true"` for `MediaBrowserService` to function with Android system media controls (notification, lock screen, Bluetooth). This is by design and documented. However, the lack of a `permission` attribute means the service is unprotected beyond the standard system binding.

**Remediation:** Add a custom signature-level permission to restrict binding to apps signed with the same key:

```xml
<!-- Add at the top of AndroidManifest.xml, before <application> -->
<permission
    android:name="com.example.flutter_app.MEDIA_SERVICE"
    android:protectionLevel="signature" />

<!-- Update the service declaration -->
<service android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"
    android:permission="com.example.flutter_app.MEDIA_SERVICE"
    tools:ignore="Instantiatable">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</service>
```

> ⚠️ **Caveat:** Adding `android:permission` to the service may break system media controls on some Android skins (e.g., Samsung One UI, MIUI) that don't hold signature-level permissions from your key. Test thoroughly on target devices. If it breaks system integration, the current exported state is **acceptable** as a necessary trade-off — the real protection must come from the backend (authenticated APIs).

---

### 🟡 MEDIUM — V6: Listening Room State Manipulation — No `roomSecret` Sent in Updates

**File:** [room_service.dart:58-71](file:///d:/music/flutter_app/lib/services/room_service.dart#L58-L71) · [api_service.dart:196-216](file:///d:/music/flutter_app/lib/services/api_service.dart#L196-L216)

```dart
// room_service.dart — updateState sends no secret
Future<void> updateState(String roomId, String currentSongId, bool isPlaying, double position) async {
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentSongId': currentSongId,
          'isPlaying': isPlaying,
          'position': position,
          // ❌ Missing: 'secret': roomSecret
        }),
      );
    } catch (e) {
      debugPrint('Error updating room state: $e');
    }
}
```

The Cloud Security Report (V4) recommended adding a `roomSecret` to prevent IDOR attacks on listening rooms. However, the client-side code:
1. Does not **store** the `roomSecret` returned when creating a room.
2. Does not **send** it in update requests.

This means even if the backend is hardened, the client will break — and more importantly, **any user who knows a 5-character room ID** (31^5 ≈ 28.6M combinations — brute-forceable) can hijack the playback state.

**Remediation:** Capture and persist the `roomSecret` on room creation, and include it in all state update requests:

```dart
// room_service.dart — updated with secret management
class RoomState {
  final String roomId;
  final String? roomSecret; // ← ADD: Only available to creator
  final String currentSongId;
  final bool isPlaying;
  final double position;
  final int updatedAt;

  RoomState({
    required this.roomId,
    this.roomSecret,
    required this.currentSongId,
    required this.isPlaying,
    required this.position,
    required this.updatedAt,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      roomId: json['roomId'] ?? '',
      roomSecret: json['roomSecret'],  // ← Capture if present (only on create)
      currentSongId: json['currentSongId'] ?? '',
      isPlaying: json['isPlaying'] ?? false,
      position: (json['position'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'] ?? 0,
    );
  }
}

class RoomService {
  http.Client? _client;
  StreamSubscription? _streamSubscription;
  final _roomStateController = StreamController<RoomState>.broadcast();
  String? _roomSecret;  // ← Store the secret locally

  Stream<RoomState> get roomStream => _roomStateController.stream;

  Future<RoomState> createRoom() async {
    final response = await http.post(Uri.parse('${ApiService.baseUrl}/api/rooms'));
    if (response.statusCode == 200) {
      final state = RoomState.fromJson(json.decode(response.body));
      _roomSecret = state.roomSecret;  // ← Capture secret from creation response
      return state;
    } else {
      throw Exception('Failed to create room');
    }
  }

  Future<RoomState> joinRoom(String roomId) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId'));
    if (response.statusCode == 200) {
      _roomSecret = null;  // ← Joiners don't get the secret (read-only listeners)
      return RoomState.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to join room');
    }
  }

  Future<void> updateState(String roomId, String currentSongId, bool isPlaying, double position) async {
    if (_roomSecret == null) {
      debugPrint('⚠️ Cannot update room state: not the room creator (no secret).');
      return;  // ← Silently refuse — only the creator can update
    }
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentSongId': currentSongId,
          'isPlaying': isPlaying,
          'position': position,
          'secret': _roomSecret,  // ← Include secret for IDOR protection
        }),
      );
    } catch (e) {
      debugPrint('Error updating room state: $e');
    }
  }

  // ... rest of class unchanged
}
```

---

### 🟡 MEDIUM — V7: Sensitive Data Stored in Plaintext `SharedPreferences`

**File:** [storage_service.dart](file:///d:/music/flutter_app/lib/services/storage_service.dart)

```dart
class StorageService {
  static const String _songsCacheKey = 'sv_songs_cache';
  static const String _likedSongsKey = 'sv_liked';
  // ...
  static Future<void> cacheSongs(List<dynamic> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_songsCacheKey, json.encode(songs));
  }
}
```

`SharedPreferences` on Android stores data in **plaintext XML** at:
```
/data/data/com.example.flutter_app/shared_prefs/FlutterSharedPreferences.xml
```

On rooted devices or via ADB backup, this file is trivially readable. The cached song data includes metadata received from the server — and as identified in the Cloud Security Report (V5), the server currently leaks `fileKey` (the B2 object key) in song responses. This means the B2 storage keys are persisted in plaintext on the user's device.

**Current stored data:** Song IDs, names, artists, image URLs, liked songs list, recent searches. This is **low-sensitivity** data on its own, but it becomes a concern if server-side over-fetching (V5 in Cloud Report) is not fixed — `fileKey` values would be cached here.

**Impact:** Low (assuming server-side `fileKey` stripping is implemented). Moderate if not.

**Remediation:** This is acceptable for non-sensitive preference data (likes, recent searches) **after** the backend is fixed to stop leaking `fileKey`. If any sensitive data (API keys, tokens) is ever stored client-side, use `flutter_secure_storage` as shown in V2's remediation. Do **not** store auth tokens in `SharedPreferences`.

---

## 3. Additional Observations

### ✅ No Hardcoded Secrets in Dart Source
A grep scan across all `.dart` files found **no** hardcoded API keys, tokens, passwords, or secrets. The only embedded value is the backend URL (V3), which is a configuration value, not a credential.

### ✅ No Client-Side Firebase SDK
The Flutter app does **not** include `cloud_firestore`, `firebase_core`, or any Firebase client package. All Firestore access goes through the backend. This eliminates an entire class of client-side Firestore security rule bypass attacks.

### ⚠️ Default Application ID
The `applicationId` is `com.example.flutter_app` — the Flutter scaffold default. For production, this should be changed to a unique reverse-domain identifier (e.g., `com.shanin.mixtape`) to:
- Avoid collisions on the Play Store.
- Establish a proper package namespace for the signature-level permission in V5.

### ⚠️ No Code Obfuscation / R8 / ProGuard
The release build has no `isMinifyEnabled = true`, no `isShrinkResources = true`, and no ProGuard/R8 rules. Combined with the debug signing (V4), the release APK can be trivially decompiled with tools like `apktool`, `jadx`, or `darter` (for Dart AOT snapshots).

---

## 4. Summary & Prioritized Remediation Checklist

| Priority | ID | Action | Effort |
|---|---|---|---|
| **P0 — NOW** | 🔴 V1 | Set `usesCleartextTraffic="false"`, add `network_security_config.xml` | 10 min |
| **P0 — NOW** | 🔴 V2 | Add `flutter_secure_storage`, create `SecureConfigService`, inject `Authorization` headers into all mutating API calls | 2 hrs |
| **P1 — This Sprint** | 🟠 V3 | Move `baseUrl` to `String.fromEnvironment` with `--dart-define` | 15 min |
| **P1 — This Sprint** | 🟠 V4 | Generate release keystore, configure `signingConfigs`, enable R8 minification | 30 min |
| **P1 — This Sprint** | 🟠 V5 | Add signature-level `permission` to `AudioService` (test on target devices) | 30 min |
| **P2 — Next Sprint** | 🟡 V6 | Capture `roomSecret` on creation, send in update requests | 1 hr |
| **P2 — Cleanup** | 🟡 V7 | Audit `SharedPreferences` contents after backend `fileKey` stripping is deployed | 15 min |
| **P2 — Cleanup** | ⚠️ | Change `applicationId` from `com.example.flutter_app` to production value | 10 min |
