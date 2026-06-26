# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**모운(Moun)** is a personal finance app — Flutter mobile frontend + FastAPI backend. The core concept is budget cycles keyed to a user's salary day, with business-day adjustment for holidays.

## Backend (`backend/`)

**Stack:** FastAPI, SQLAlchemy 2, Alembic, MariaDB, Redis, MinIO. Python ≥ 3.12.

### Setup & Run

```bash
cd backend

# Start infrastructure
docker-compose up -d          # MariaDB :3306, Redis :6379, MinIO :9000/:9001

# Install (editable)
pip install -e .

# Run dev server
uvicorn app.main:app --reload

# Run migrations
alembic upgrade head
```

Config is via `.env` file (see `app/core/config.py` for all keys). Default DB: `mysql+pymysql://moun:moun@localhost:3306/moun`.

### Tests

```bash
cd backend
pytest                        # all tests
pytest tests/test_auth_api.py # single file
```

Tests use SQLite in-memory + `fakeredis` — no Docker needed. Import `app.models` at top of conftest to register all models before fixtures run.

### Architecture

```
app/
  main.py          # FastAPI app, router registration
  core/
    config.py      # Settings (pydantic-settings, reads .env)
    deps.py        # FastAPI dependency injectors (get_db, get_current_user)
    auth.py        # JWT creation/verification
    budget_calculator.py   # Core budget cycle math
    budget_cycle.py        # Cycle boundary helpers
    billing.py             # Fixed-expense billing logic
    schedule_generator.py  # Materializes pending/scheduled income & expense items
  models/          # SQLAlchemy ORM models
  schemas/         # Pydantic request/response schemas
  api/             # Route handlers (one file per domain)
  db/              # Engine, session factory, Redis client
alembic/           # Migration scripts
```

Key domain logic lives in `app/core/` not `app/api/`. The `holidays` package is used for Korean holiday calendar (`holiday_country="KR"`).

## Frontend (`frontend/`)

**Stack:** Flutter/Dart, Riverpod (flutter_riverpod + riverpod_annotation), go_router, Dio.

### Run

```bash
cd frontend
flutter pub get
flutter run               # Android emulator or connected device
flutter test              # unit/widget tests
flutter analyze           # lint
```

`baseUrl` in `lib/core/constants/app_constants.dart` is set to `http://10.0.2.2:8000` (Android emulator → host). Change to `http://localhost:8000` for iOS simulator or macOS.

To toggle the design showcase instead of the real app, set `_showDesignShowcase = true` in `lib/main.dart`.

### Architecture

Feature-first structure under `lib/features/`. Each feature follows a 3-layer pattern:

```
features/<name>/
  data/        # Repository (Dio HTTP calls, token storage)
  domain/      # Models, state sealed classes
  presentation/
    providers/ # Riverpod providers/notifiers
    screens/   # Screen widgets
    widgets/   # Feature-local widgets
```

```
lib/
  main.dart
  core/
    constants/   # appName, baseUrl
    network/     # Dio provider with auth interceptor
    router/      # go_router config, auth redirect logic
    storage/     # SecureTokenStorage (flutter_secure_storage)
    theme/       # AppTheme, AppColors, AppTypography
  features/
    auth/        # Login, register, JWT session restore
    onboarding/  # First-run setup: salary day, budget cycle config
    home/        # Dashboard / budget summary
    budget/      # Budget cycle detail
    transactions/
    categories/
    statistics/
    settings/
    shell/       # Bottom nav shell (StatefulShellRoute)
    _design_showcase/  # Dev-only design system preview
  shared/
    widgets/     # Reusable widgets across features
```

### Design System

Apple Liquid Glass–inspired glassmorphism (iOS 26 style). Bright, refined, not heavy.

- **Font:** Pretendard Variable (`assets/fonts/PretendardVariable.ttf`)
- **Theme:** `AppTheme.light` / `AppTheme.dark` in `lib/core/theme/`
- **Colors:** defined in `AppColors` — key semantic tokens: `primary` (#5B8DEF), `income` (#34C77B), `expense` (#FF6B6B), `expensePending` (#B39DFF)
- **Typography:** `AppTypography` — `amountLarge/Medium/Small` for currency display
- Full spec: [`docs/design-system.md`](docs/design-system.md)

Auth state is a sealed class (`AuthStateAuthenticated`, `AuthStateAuthenticating`, `AuthStateUnauthenticated`) watched by go_router's `refreshListenable` for redirect logic.

Router redirect order: unauthenticated → `/login`; authenticated but `needsOnboarding` → `/onboarding`; otherwise → `/home`.

### Backend API routes

`app/api/` contains one file per domain: `auth`, `budget_cycles`, `cards`, `categories`, `fixed_expenses`, `incomes`, `transactions`. All registered in `app/main.py`.
