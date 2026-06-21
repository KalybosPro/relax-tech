# Manage Your Flutter Environment Variables Like a Pro with env_builder_cli

*Type-safe access, AES encryption, embedded assets, and obfuscated builds — all from a single command.*

---

## The problem every Flutter developer knows

You start a new Flutter project. Everything's fine. Then comes the dreaded moment: environment management.

You have one API URL for development, another for production. A test API key, a real API key. A `DEBUG` flag that must be `true` here but absolutely not there. Before long, your code fills up with `const bool kIsProd = false; // ⚠️ DON'T FORGET TO CHANGE BEFORE RELEASE`.

And one day it happens: a production key gets committed to Git. Or worse, your production build ships with `DEBUG=true`.

Existing solutions each have their flaw:

- Reading a `.env` at runtime? You lose type safety, and parsing can fail in production.
- Hardcoding values across multiple files? Unmanageable and dangerous.
- Doing it all by hand with `envied`? Powerful, but repetitive and tedious to maintain across multiple environments.

**env_builder_cli** was built to solve all of this at once.

---

## What is env_builder_cli?

It's a command-line tool, written in Dart, that **automates the creation and maintenance of a type-safe environment package** for your Flutter apps — straight from your plain `.env` files.

In a single command, it:

1. Creates a `packages/env` directory in your project,
2. Copies and encrypts your `.env` files,
3. Generates strongly-typed Dart classes (powered by [`envied`](https://pub.dev/packages/envied)) for compile-time-checked access,
4. Updates your `pubspec.yaml` files and runs `flutter pub get`,
5. Even updates your `.gitignore` with the right rules.

And it doesn't stop there: asset encryption, obfuscated APK/AAB builds, encrypt/decrypt commands… we'll get to those.

---

## Installation

```bash
dart pub global activate env_builder_cli
```

That's it. The `env_builder` command is now available everywhere.

---

## 1. Automated environment package generation

Move to the root of your Flutter project and run:

```bash
# Build from all .env* files found in the current directory
env_builder build

# Or target specific files
env_builder build --env-file=.env.development,.env.production,.env.staging
```

From these files:

```bash
# .env.development
BASE_URL=https://dev-api.example.com
API_KEY=dev_key_123
DEBUG=true

# .env.production
BASE_URL=https://api.example.com
API_KEY=prod_key_456
DEBUG=false
```

…the tool generates type-safe Dart classes:

```dart
@Envied(path: '.env.production')
abstract class EnvProduction {
  @EnviedField(varName: 'BASE_URL')
  static const String baseUrl = _EnvProduction.baseUrl;

  @EnviedField(varName: 'API_KEY', obfuscate: true)
  static final String apiKey = _EnvProduction.apiKey;

  @EnviedField(varName: 'DEBUG')
  static const bool debug = _EnvProduction.debug;
}
```

Notice the automatic typing: `BASE_URL` becomes a `String`, `DEBUG` a `bool`. **No more runtime type errors.**

---

## 2. Built-in AES encryption, by default

Sensitive variables are **automatically AES-encrypted** (`obfuscate: true`). Your keys no longer sit in plain text inside the compiled binary.

Need to disable encryption for a purely public value? One flag does it:

```bash
env_builder build --no-encrypt --env-file=.env
```

---

## 3. Type-safe, elegant access in your app

In your Flutter app, usage becomes clean:

```dart
import 'package:env/env.dart';

// Pick the flavor
final appFlavor = AppFlavor.production();

class ApiService {
  final appBaseUrl = appFlavor.getEnv(Env.baseUrl);
  final apiKey = appFlavor.getEnv(Env.apiKey);
}
```

The compiler protects you: you can't request a variable that doesn't exist.

---

## 4. Multi-environment without the pain

`development`, `staging`, `production`, or your own custom flavors: each `.env.*` file becomes a managed, isolated, and tested environment.

```bash
env_builder build --env-file=.env.development,.env.staging,.env.production
```

The tool also generates **unit tests** to validate that each variable is present and correctly typed. No more runtime surprises.

---

## 5. Automatic Git integration

On every build, your `.gitignore` is updated with the right rules: sensitive `.env` files are excluded, while encrypted `.env.encrypted` versions can be safely committed.

```bash
env_builder encrypt --password=yourSecretKey .env
env_builder decrypt --password=yourSecretKey .env.encrypted
```

Perfect for storing encrypted secrets in your repo or decrypting them in your CI/CD pipeline.

---

## 6. Asset encryption: the bonus feature that changes everything

Here's the part few tools offer. **env_builder_cli can encrypt and embed your images, videos, and SVGs directly into your Dart code.**

```bash
# XOR encryption (fast, lightweight) by default
env_builder assets

# Or AES (more secure)
env_builder assets --encrypt=aes
```

Your assets become embedded `Uint8List` constants in the binary — **zero runtime dependencies, no `pubspec.yaml` changes**. No one can pull your sensitive resources out of the bundle.

And the generated API stays familiar, compatible with `flutter_gen`:

```dart
// Ready-to-use widgets
Assets.images.logo.image();          // an Image widget
Assets.svgs.icon.svg();              // an SvgPicture widget
Assets.videos.intro.videoPlayer();   // a video player
```

Supported formats: PNG, JPG, GIF, WebP for images; MP4, WebM, MOV, AVI, MKV for videos; and SVGs (with automatic minification).

---

## 7. Obfuscated production builds in one command

```bash
# Obfuscated APK
env_builder apk --target=lib/main_production.dart

# Obfuscated Android App Bundle
env_builder aab --target=lib/main_production.dart
```

The tool runs a release build with obfuscation, making it harder to reverse-engineer your app in production.

---

## Why I think you should try it

env_builder_cli answers a real, recurring need — one that's usually hand-rolled project after project:

- ✅ **Type safety** guaranteed at compile time
- 🔐 **AES encryption** of secrets by default
- 🔄 **Multi-environment** handled cleanly
- 🎨 **Encrypted, embedded assets** with no runtime dependency
- 📱 **Obfuscated** APK/AAB builds built in
- 🧪 **Tests generated** automatically
- 📂 **Git integration** with zero effort

All from the plain `.env` files you're already writing.

---

## Getting started

```bash
dart pub global activate env_builder_cli
cd your_flutter_project
env_builder build
flutter run
```

The full documentation, a working example, and the source code are available on the repo:

👉 **https://github.com/KalybosPro/relax-tech/tree/main/packages/env_builder_cli**

And on pub.dev:

👉 **https://pub.dev/packages/env_builder_cli**

---

*Ever struggled with environment management in Flutter? Give env_builder_cli a shot — and let me know in the comments what's been missing for you so far. 💙*

*Made with ❤️ for the Flutter community.*

#Flutter #Dart #DevTools #MobileDev #FlutterDeveloper #Security #CLI
