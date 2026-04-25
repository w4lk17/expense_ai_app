# Expense AI 2.0

Expense AI is an offline-first personal finance app built with Flutter. Version 2.0 turns the project from a simple CRUD expense tracker into a calmer financial companion focused on clarity, pacing, and practical next steps.

## What changed in 2.0

- A redesigned 4-tab experience: `Home`, `Activity`, `Plan`, `Profile`
- A premium calm visual language with cleaner hierarchy and softer finance-focused colors
- `Safe to spend` as the primary monthly metric
- Searchable, filterable activity history with grouping by recency
- A planning space for budgets, recurring bills, and monthly pacing
- Embedded AI assistance for category suggestion and concise monthly insight
- Runtime secret loading through `.env` instead of hardcoded credentials

## Core experience

### Home
- Monthly snapshot with income, expenses, budget usage, and days left
- Safe-to-spend hero card
- Quick actions for adding expense or income
- AI-generated monthly insight
- Top categories, upcoming recurring bills, and spending trend overview

### Activity
- Search and quick filters for date, category, type, and sync state
- Transactions grouped into `Today`, `Yesterday`, `This week`, and `Earlier`
- Swipe actions for duplicate and delete
- Fast edit flow from the transaction list

### Plan
- Category budget monitoring
- Recurring obligations view
- Safe-to-spend planning summary
- Budget editing flow for the current month

### Profile
- Sync status and account overview
- Theme switching
- AI provider selection
- CSV export

## Product highlights

- Offline-first local storage with Drift and SQLite
- Supabase authentication and cloud sync support
- Budget tracking by category and month
- Recurring expense handling
- Income and expense tracking in the same flow
- CSV export for sharing or backup
- Optional AI assistance that does not block core usage

## Tech stack

| Area | Technology |
| --- | --- |
| App framework | Flutter |
| Language | Dart |
| State management | Riverpod |
| Local database | Drift + SQLite |
| Backend | Supabase |
| Charts | FL Chart |
| Local config | flutter_dotenv |

## Project structure

```text
lib/
├── core/          # Shared theme, config, providers, database connection
├── features/
│   ├── auth/      # Login and session management
│   ├── expense/   # Home, activity, planning, budget, transaction flows
│   └── ai_advisor/# AI services and provider settings
└── main.dart
```

## Setup

1. Clone the repository.

   ```bash
   git clone <repo-url>
   cd expense_ai_app
   ```

2. Install dependencies.

   ```bash
   flutter pub get
   ```

3. Create your local environment file from the example.

   ```bash
   cp .env.example .env
   ```

4. Fill `.env` with your runtime values.

   Required keys:

   ```env
   SUPABASE_URL=
   SUPABASE_ANON_KEY=
   GEMINI_API_KEY=
   GLM_API_KEY=
   GLM_BASE_URL=
   GLM_MODEL=
   ```

5. Generate Drift files if needed.

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. Run the app.

   ```bash
   flutter run
   ```

## Environment and secrets

- `.env` is required for local development
- `.env.example` documents the expected keys
- `.env` is intentionally ignored by git
- Supabase and AI secrets should never be committed to Dart source files

If secrets were previously committed, rotate them before production use.

## Notes for contributors

- The app initializes dotenv before Supabase and AI services are used
- Core flows should continue to work offline, even when AI is unavailable
- AI is assistive and optional, not a hard dependency for expense entry

## Current focus

Expense AI 2.0 is the first release aligned with the redesigned product direction. The next iterations can build on this foundation with deeper forecasting, notifications, smarter capture, and stronger release tooling.
