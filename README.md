# SmartBondhu Admin Panel

Internal admin dashboard — opens directly to the dashboard with no login screen.

## Setup

```bash
cd admin_panel
npm install
cp .env.example .env
npm run dev
```

Open http://localhost:5173 — the dashboard loads immediately.

## Backend

Start the SmartBandhu API first:

```bash
cd ../backend
source .venv/bin/activate
PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Ensure `CORS_ORIGINS` in backend `.env` includes `http://localhost:5173`.

## Features

- Dashboard with KPIs (users, bookings, revenue)
- Revenue and booking charts (30-day)
- Bookings list with status updates + push notifications
- Users list with activate/deactivate

## Environment

| Variable | Description |
|----------|-------------|
| `VITE_API_BASE_URL` | Backend API base URL (default: `http://localhost:8000/api/v1`) |

## Production build

```bash
npm run build
npm run preview
```
