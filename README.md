# SmartBondhu Admin Panel

React admin dashboard for managing bookings, users, and revenue analytics.

## Setup

```bash
cd admin_panel
npm install
cp .env.example .env
npm run dev
```

Open http://localhost:5173

## Login

Use the seeded admin account:

- **Email:** `admin@smartbandhu.com`
- **Password:** `Admin@123`

## Backend

The admin panel connects to the SmartBondhu FastAPI backend. Start it first:

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
