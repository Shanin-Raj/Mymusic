## 1. Kotlin MainActivity Update

- [x] 1.1 Open `d:\music\flutter_app\android\app\src\main\kotlin\com\example\sonic_vault_flutter\dev\MainActivity.kt`.
- [x] 1.2 Add the following imports:
```kotlin
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServicePlugin
```
- [x] 1.3 Modify the `MainActivity` class to override `provideFlutterEngine`:
```kotlin
class MainActivity: FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }
}
```

## 2. Code Cleanup

- [x] 2.1 Revert `main.dart` if you added any `try-catch` blocks previously, returning it to the standard startup flow. (Since we now know the exact error).

## 3. Verification

- [x] 3.1 Rebuild the release APK using `flutter build apk --release`.
- [x] 3.2 Install and verify the app now launches successfully past the splash screen without crashing.
