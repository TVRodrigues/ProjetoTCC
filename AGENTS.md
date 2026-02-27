# AGENTS.md

## Cursor Cloud specific instructions

### Project overview
This is **Marcador RA** — a Flutter mobile app combining document scanning (Google ML Kit) with Augmented Reality (ARCore). The project is in `projetotcc/`. There is no backend server; cloud processing is simulated with a `Future.delayed`.

### Prerequisites (installed by VM snapshot)
- **Flutter 3.41.2** at `/opt/flutter/bin` (Dart 3.11.0)
- **Android SDK** at `/opt/android-sdk` (platform 36, build-tools 36.0.0, NDK 28.2)
- **JDK 17** at `/usr/lib/jvm/java-17-openjdk-amd64` (required by `ar_flutter_plugin_plus` Gradle build)
- **Linux toolchain**: clang, cmake, ninja-build, libgtk-3-dev

### Environment variables
These are set in `~/.bashrc`:
```
export PATH="/opt/flutter/bin:$PATH"
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

### Key commands (run from `projetotcc/`)
| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint/analyze | `flutter analyze` |
| Tests | `flutter test` (no test dir exists yet) |
| Build web | `flutter build web` |
| Build APK | `flutter build apk --debug` |
| Run web (dev) | `flutter run -d chrome` |
| Serve built web | `python3 -m http.server 8080 --directory build/web` |

### Gotchas
- **JDK version**: The Android build requires JDK 17 specifically. JDK 21 (default Ubuntu) will fail the Gradle build for `ar_flutter_plugin_plus` with a toolchain error. Flutter must be configured with `flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk-amd64`.
- **`flutter analyze` info**: There is 1 info-level lint about `vector_math` being a transitive (not direct) dependency. This is not an error.
- **AR/Camera features**: Document scanning and AR require a physical Android device with ARCore. In the Cloud VM, use web or Linux desktop builds for UI testing. Core AR/camera flows cannot be tested without a device.
- **No test directory**: The project has no `test/` directory or automated tests yet. `flutter test` will exit with "Test directory not found".
