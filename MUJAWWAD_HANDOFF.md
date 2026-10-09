# Mujawwad Abdullah Khan — UI (Core) — Handoff

Scope per Technical Architecture Proposal: Dashboard UI, Transaction History UI,
Add Expense/Income modals.

## Files
lib/
├── models/models.dart                       shared models (match DB schema + API shapes)
├── models/formatters.dart                   money/date formatting (users.currency, 'YYYY-MM')
├── providers/transaction_provider.dart      in-memory state; `// SWAP:` markers for repos
├── main_preview.dart                        run UI standalone (delete when main.dart is ready)
└── screens/
    ├── dashboard/dashboard_screen.dart              GET /api/dashboard
    ├── dashboard/transaction_history_screen.dart    GET /api/transactions (filters)
    └── transactions/
        ├── add_transaction_sheet.dart               POST /api/transactions
        ├── transaction_tile.dart
        └── category_style.dart

## pubspec.yaml (Asim) — packages needed
    provider: ^6.1.2
    intl: ^0.20.2        # use the version `flutter pub add intl` resolves

## Run
    flutter pub get
    flutter run -t lib/main_preview.dart

## Integration (Hamza)
Keep `TransactionProvider`'s public API; replace bodies marked `// SWAP:` with
tx_repo / budget_repo calls. UI needs no changes.
Entry point for routing: `DashboardScreen()`; history opens via "See all".
