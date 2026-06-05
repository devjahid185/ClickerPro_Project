# Clicker Pro

[![Flutter CI](../../actions/workflows/flutter-ci.yml/badge.svg)](../../actions/workflows/flutter-ci.yml)
[![codecov](https://codecov.io/gh/OWNER/REPO/branch/main/graph/badge.svg?flag=flutter)](https://codecov.io/gh/OWNER/REPO)

Flutter app for photography & event management — bookings, calendar,
assignments, payments, deliveries, and more. Offline-first with a
local Drift database and an outbox-based sync layer over the
companion Node + Express backend.

## Quick start

```bash
flutter pub get
flutter run            # picks the first available device
```

## Verify

```bash
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --coverage   # writes coverage/lcov.info
dart run tool/check_coverage.dart --min=20
```

The smoke-test suite includes 73+ widget tests and finishes in under
a minute on a typical laptop. CI runs analyze + test + coverage gate
on every push.

### Coverage gate

`tool/check_coverage.dart` parses `coverage/lcov.info`, excludes
generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`), and
fails CI if the line-hit ratio drops below the minimum. Bump `--min`
in `.github/workflows/flutter-ci.yml` as coverage grows.

### Codecov

CI uploads `coverage/lcov.info` to Codecov via
`codecov/codecov-action@v4`. Project-level threshold sits at 22%
(local gate is 20%, with a 1% breathing room); diff patch-level
threshold is 50%. See `codecov.yml` for the full config.

To enable PR comments and the badge above:

1. Sign in at <https://codecov.io> with the GitHub account that owns
   the repo and grant access.
2. For private repos, set `CODECOV_TOKEN` as a repo secret. Public
   repos can skip this.
3. Replace `OWNER/REPO` in the badge URL with the actual GitHub slug.

## Build

```bash
flutter build apk --debug      # ~180 MB
flutter build apk --release    # ~65 MB
```

### Release signing (Android)

The android Gradle config (`android/app/build.gradle.kts`) reads
`android/key.properties` if present and falls back to the debug
keystore when absent. To wire up real signing:

1. Generate a keystore (one-time):
   ```bash
   keytool -genkey -v \
     -keystore ~/keystores/clicker_pro.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias clickerpro
   ```
2. Copy `android/key.properties.example` to `android/key.properties`
   and fill in the values. The real `key.properties` is gitignored.
3. `flutter build apk --release` now uses the production keystore.

### CI release pipeline

The `release-apk` job in `.github/workflows/flutter-ci.yml` only
fires on git tag pushes (`v*`) or manual workflow dispatch. When the
following secrets are set in repo settings it builds + signs an
`app-release.apk` and `app-release.aab` and attaches them to the
GitHub Release page automatically:

| Secret                       | Purpose                                |
| ---------------------------- | -------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`    | base64 of `clicker_pro.jks`            |
| `ANDROID_KEYSTORE_PASSWORD`  | keystore password                      |
| `ANDROID_KEY_ALIAS`          | key alias (e.g. `clickerpro`)          |
| `ANDROID_KEY_PASSWORD`       | key password                           |

To prep the base64:
```bash
base64 -w 0 ~/keystores/clicker_pro.jks | pbcopy   # macOS
base64 -w 0 ~/keystores/clicker_pro.jks | wl-copy  # Linux Wayland
```

## Layout

```
clicker_pro/
├── lib/
│   ├── core/                  # api client, db, sync, l10n, theme
│   └── features/
│       ├── auth/              # signup / login / role / session
│       ├── bookings/          # list, detail, edit, calendar, public flow
│       ├── clients/
│       ├── payments/
│       ├── deliveries/
│       └── ...
├── test/                      # 73+ smoke + widget tests
├── assets/
└── l10n.yaml + lib/l10n/      # ARB files (en + bn)
```

## Companion services

The app talks to a Node + Express + Prisma backend in the sibling
`backend/` folder. See `backend/README.md` for setup.
