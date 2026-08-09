# SmartBondhu Admin (Flutter)

Internal admin app — dashboard, catalog, bookings, users, and control (maintenance, force update, broadcast notifications).

## Setup

```bash
git clone https://github.com/sayan9191/smart_bondhu_admin_pannel.git
cd smart_bondhu_admin_pannel
flutter pub get
```

Start the [backend](https://github.com/sayan9191/smart_bondhu_backend) first.

## Features

- Dashboard KPIs with date filters and CSV export
- **Catalog** — categories, sub-categories, services with prices (add new items)
- Bookings list with status updates (sends push to customer)
- Users list with activate/deactivate
- Control tab — maintenance mode, force update, broadcast notifications

## Run (development)

| Device | Command |
|--------|---------|
| Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` |
| Physical device (USB) | `adb reverse tcp:8000 tcp:8000` then `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` |
| Physical device (Wi‑Fi) | `flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_IP:8000/api/v1` |

## Production build

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

## Backend deploy

See backend [DEPLOYMENT.md](https://github.com/sayan9191/smart_bondhu_backend/blob/main/DEPLOYMENT.md) for AWS setup.

## Related repos

- Backend: https://github.com/sayan9191/smart_bondhu_backend
- Customer app: https://github.com/sayan9191/smart_bondhu_frontend
