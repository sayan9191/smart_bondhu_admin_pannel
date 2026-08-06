# SmartBondhu Admin (Flutter)

Internal admin mobile/desktop app — **no login screen**. Opens directly to the dashboard.

## Features

- Dashboard KPIs (revenue, bookings, users, vendors)
- Revenue & booking charts (30 days)
- Bookings list with status updates (sends push to customer)
- Users list with activate/deactivate

## Setup

```bash
cd admin_panel
flutter pub get
flutter run
```

## Backend

Start the SmartBandhu API first:

```bash
cd ../backend
source .venv/bin/activate
PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## API URL

Default targets `localhost:8000`. For Android:

| Device | Command |
|--------|---------|
| Emulator | `flutter run` (uses `10.0.2.2`) |
| Physical device (Wi‑Fi) | `flutter run --dart-define=DEV_LAN_IP=192.168.1.83` |
| USB + adb reverse | `adb reverse tcp:8000 tcp:8000` then `flutter run` |

Override fully:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.83:8000/api/v1
```

## Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# macOS
flutter run -d macos
```

## Repo

https://github.com/sayan9191/smart_bondhu_admin_pannel.git
