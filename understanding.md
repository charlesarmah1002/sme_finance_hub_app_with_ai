# SME Cashflow: Application Understanding

## 1. What This App Is

SME Cashflow is a Flutter Material 3 client for small-business cash-flow management. It talks to a Django-style JSON API and provides:

- JWT-style login, registration, session restoration, and token refresh.
- Dashboard totals and recent activity.
- Account CRUD plus account deactivation.
- Income and expense category CRUD.
- Transaction CRUD with local filtering by income or expense.
- Three generic report views.
- A profile/settings view with logout.

The application is a client only. There is no backend implementation in this repository. The API is expected to provide trailing-slash endpoints and JSON responses.

## 2. Technology and Project Shape

- Framework: Flutter/Dart.
- State management: `provider` and `ChangeNotifier`.
- HTTP: `dio`.
- Local persistence: `shared_preferences` for access and refresh tokens.
- Formatting: `intl` for currency and dates.
- UI: Material 3 with Material icons.
- Supported SDK constraints: Dart `>=3.0.0 <4.0.0`, Flutter `>=3.10.0`.
- Android build target uses Java/Kotlin 17.

Important directories:

```text
lib/
  main.dart                 Application entry point
  app.dart                  Theme, auth gate, navigation shell
  config/                   Runtime configuration
  models/                   JSON-to-domain parsing
  providers/                ChangeNotifier state and API orchestration
  screens/                  Authentication and feature screens
  services/                 API client and auth interceptor
  widgets/                  Shared loading, error, and empty states
test/                       Unit, provider, widget, and responsive tests
android/                    Android host/build configuration
web/                        Flutter web host files
```

## 3. Startup and Authentication Flow

The entry point is `lib/main.dart`:

1. Construct an `ApiService`.
2. Construct the root `AuthProvider` with that service.
3. Call `AuthProvider.initialize()` immediately.
4. Provide the auth provider above `CashflowApp`.

`CashflowApp` installs the Material 3 theme and renders `_AuthGate`. The gate watches `AuthProvider.status`:

- `loading`: `SplashScreen`, which is only a centered progress indicator.
- `authenticated`: `AppShell`.
- `unauthenticated`: `LoginScreen`.

`AuthProvider.initialize()` checks `SharedPreferences` for an access token. If there is no token, the user is unauthenticated. If one exists, it calls `GET auth/me/`. If that fails, it attempts a refresh using the stored refresh token and retries `auth/me/`; if that also fails, both tokens are cleared and the user is logged out.

Login and registration set the provider to loading, call the API, require both `access` and `refresh` response fields, persist the tokens, optionally store the returned `user` object, and switch to authenticated. API errors are exposed through `errorMessage` and leave the provider unauthenticated.

Logout clears both token keys, clears `currentUser`, and switches to unauthenticated. A failed authenticated request can also trigger the service's `onSessionExpired` callback, which is wired to the auth provider.

## 4. Navigation and Responsive Behavior

There is no named-route table. Screen navigation uses `Navigator.push` and `MaterialPageRoute`.

`AppShell` has six destinations:

1. Dashboard
2. Transactions
3. Accounts
4. Categories
5. Reports
6. Settings

At widths of 800 pixels or more, the shell uses a `NavigationRail` and shows all six destinations. At smaller widths it uses a bottom `NavigationBar` for Dashboard, Transactions, Accounts, and Reports. Categories, Settings, and Logout are available through the AppBar overflow menu.

The selected destination is held locally by `AppShell`. Each feature screen creates its own provider in `initState`, loads data immediately, and disposes that provider when the screen is disposed. Consequently, navigating away from a feature discards its in-memory state; returning to it creates a fresh provider and reloads the API data.

The dashboard summary grid uses four columns at widths of at least 700 pixels and two columns below that. Authentication forms are scrollable and constrained to a maximum width of 420 pixels.

## 5. API Client and Runtime Configuration

`lib/services/api_service.dart` wraps Dio and sets:

- A normalized base URL with a trailing slash.
- JSON request content type.
- JSON response type.
- An auth interceptor on the main Dio client.

The public service methods map to these endpoints:

| Feature | Endpoint | Methods / payload |
| --- | --- | --- |
| Register | `auth/register/` | `POST {business_name, name, email, password}` |
| Login | `auth/login/` | `POST {email, password}` |
| Current user | `auth/me/` | `GET` |
| Refresh | `auth/refresh/` | `POST {refresh}`; expects `{access}` |
| Dashboard | `dashboard/summary/` | `GET` |
| Accounts | `accounts/` and `accounts/{id}/` | `GET`, `POST`, `PUT`, `PATCH`, `DELETE` |
| Categories | `categories/` and `categories/{id}/` | `GET`, `POST`, `PUT`, `DELETE` |
| Transactions | `transactions/` and `transactions/{id}/` | `GET`, `POST`, `PUT`, `PATCH`, `DELETE` |
| Cash-flow report | `reports/cashflow/` | `GET` |
| Category report | `reports/by-category/` | `GET` |
| Account report | `reports/by-account/` | `GET` |

`AppConfig` chooses the base URL as follows:

- Web default: `http://localhost:8000/api/`.
- Android emulator default: `http://10.0.2.2:8000/api/`.
- Any non-empty `API_BASE_URL` compile-time define overrides the defaults and is normalized with a trailing slash.

Example release commands are documented in `README.md`:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api/
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api/
```

The auth interceptor reads the access token before every request and adds `Authorization: Bearer <token>`. A 401 response causes one refresh attempt, then retries the original request once with the new access token. Refresh requests are excluded from this retry path. If refresh fails, tokens are cleared and the session-expired callback is invoked.

`ApiException` converts Dio failures into user-facing messages. For map response bodies it formats entries such as `detail: Invalid credentials`; otherwise it reports either a communication failure or the HTTP status code.

## 6. Models and JSON Contracts

### Account

`lib/models/account.dart` defines:

- `id: int`
- `name: String`
- `type: String?`
- `balance: double?`
- `isActive: bool?`

`account_type` is preferred over `type`. Numeric values can arrive as numbers or parseable strings. List parsing accepts either a raw list or a `{results: [...]}` envelope.

### TransactionCategory

`lib/models/category.dart` defines `CategoryType.income` and `CategoryType.expense`, plus `TransactionCategory` with `id`, `name`, and `type`.

Category list parsing accepts a raw list or `results`, `data`, or `categories` envelopes. The type is lowercased; exactly `income` maps to income, and every other value maps to expense.

### CashflowTransaction

`lib/models/transaction.dart` defines:

- `id`
- `accountId`
- `categoryId`
- `type` (`TransactionType.income` or `TransactionType.expense`)
- `amount: double?`
- `description`
- `date: DateTime?`
- optional `accountName` and `categoryName`

The `account` and `category` JSON fields may be IDs or nested objects. Nested objects also supply display names. Only `type == income` maps to income; all other values map to expense. Transaction lists accept a raw list or `{results: [...]}`.

There are no model `toJson` methods. Request maps are assembled directly by the relevant screen/provider flow.

### DashboardSummary

`lib/models/dashboard_summary.dart` parses either top-level summary fields or a nested `summary` object:

- `total_balance`
- `total_income`
- `total_expenses`
- `net_cash_flow`
- `recent_transactions`
- `accounts`

The last two fields are preserved as generic `List<Map<String, dynamic>>` values. `isEmpty` is true only when all scalar fields are null and both lists are empty.

### ReportData

`lib/models/report_data.dart` preserves a report map as `raw` and extracts generic row maps from `results`, `data`, `items`, or `series`. A raw list becomes rows with an empty raw map. This lets the UI display multiple backend schemas without a strongly typed report model.

## 7. Providers and State Responsibilities

All providers extend `ChangeNotifier`, expose `isLoading` and `errorMessage` where applicable, notify before and after asynchronous work, and catch `ApiException`.

### AuthProvider

Owns `AuthStatus`, `currentUser`, and the authentication error. Public operations are `initialize`, `login`, `register`, and `logout`. It also owns the callback used when the API service detects an expired session.

### AccountsProvider

Owns the account list. Public operations are `load`, `create`, `update`, `deactivate`, and `delete`. Every successful mutation reloads the complete list. Deactivation is a PATCH with `{is_active: false}`.

### CategoriesProvider

Owns the category list. Public operations are `load`, `create`, `update`, and `delete`. Create/update convert the enum to the API string using `type.name`. Successful mutations reload the full list.

### TransactionsProvider

Owns transactions, accounts, categories, the selected `TransactionFilter`, loading, and error state. `load()` requests transactions, accounts, and categories concurrently. `visibleTransactions` filters the already loaded transaction list locally; it does not use the API's optional `?type=` query parameter. Mutations reload all three datasets.

`loadCategories()` is used by the transaction form when categories are missing. The form receives this provider instance so it can use the provider's current accounts and categories.

### DashboardProvider

Owns one `DashboardSummary`. It loads `dashboard/summary/` and retains an existing summary if a later refresh fails, while exposing the new error message.

### ReportsProvider

Owns `cashflow`, `byCategory`, and `byAccount` report data. It requests all three reports concurrently. A failure causes the overall load to expose an error; previously loaded report objects remain in memory.

## 8. User Interface Workflows

### Login and Registration

Login validates an email containing `@` and a non-empty password. Registration validates business name, name, email, and a password of at least eight characters. Provider errors appear below the fields. Successful authentication causes the auth gate to replace the form with the app shell.

### Dashboard

The dashboard loads when entered unless `loadOnStart` is false, which is useful for tests. It renders loading, error/retry, empty, or populated states. Populated data includes four summary cards for balance, income, expenses, and net cash flow. Up to five recent transactions and five accounts are rendered as generic JSON-derived list tiles. Pull-to-refresh calls the provider again.

### Accounts

The accounts screen loads on entry and supports pull-to-refresh. The add/edit dialog accepts name, account type, and numeric balance. Each row shows name, optional type/status, formatted balance, and actions for edit, deactivate, and delete. Successful mutations show SnackBars.

### Categories

Categories are grouped into Income and Expense sections. Add/edit uses a dialog with a name field and income/expense dropdown. Each row has edit and delete icon buttons. Empty sections display `None`; the overall screen has loading, error, and empty states.

### Transactions

The transaction list has All, Income, and Expense segmented filters. Each row shows description, category, account, date, and a signed formatted amount; tapping opens details. Edit/delete actions are available from a popup menu.

The form requires an account, a category matching the selected transaction type, an amount greater than zero, and a date. Description is optional. It submits:

```json
{
  "account": 1,
  "category": 2,
  "type": "expense",
  "amount": "150.00",
  "description": "Office rental",
  "date": "2026-09-04"
}
```

Changing the type clears the category selection and limits the category dropdown to the matching category type.

### Transaction Details

The detail screen is read-only. It displays amount, type, category, account, and formatted date.

### Reports

Reports load all three endpoints on entry and present them in Cash Flow, By Category, and By Account tabs. Scalar fields become value cards; list rows become generic key/value cards. There are currently no charts or domain-specific report visualizations. Pull-to-refresh is available within each tab.

### Settings

Settings displays name, email, and business name from `currentUser`. Business name supports `business_name`, `businessName`, or a nested `business.name`. The page provides logout.

## 9. Shared UI State Widgets

`lib/widgets/feedback_widgets.dart` contains:

- `LoadingWidget`: progress indicator with an optional message.
- `ErrorMessage`: error icon, message, and optional Retry button.
- `EmptyState`: inbox icon, message, and optional action.

Feature screens use these to keep loading, failure, and empty-data presentation consistent.

## 10. Tests and What They Prove

The test suite uses local `HttpServer` instances for provider/API behavior and Flutter widget tests for UI behavior.

- `api_service_test.dart`: API root requests and conversion of HTTP errors to `ApiException`.
- `auth_provider_test.dart`: login, registration, logout, token persistence, startup refresh, and invalid credentials.
- `accounts_provider_test.dart`: account loading and all mutations, including reload after each mutation.
- `categories_provider_test.dart`: category loading, enum-to-API type conversion, and mutation reloads.
- `transactions_provider_test.dart`: combined loading, local filtering, mutation reloads, and request types.
- `dashboard_provider_test.dart`: summary parsing and empty responses.
- `reports_provider_test.dart`: all three report endpoints and scalar/row extraction.
- `transaction_categories_test.dart`: category loading from a `data` envelope.
- `responsive_test.dart`: shell behavior across phone, tablet, and desktop widths, plus phone transaction-form rendering.
- `settings_screen_test.dart`: profile fields and logout/token clearing.
- `widget_test.dart`: desktop navigation and mobile navigation/overflow menu.
- `checkpoint13_test.dart`: login/register validation, transaction amount validation, unauthenticated gate, and transaction JSON parsing.

Current coverage gaps include:

- Direct tests for all model parsers and every supported response envelope.
- Explicit auth-interceptor retry and refresh-failure/session-expiration tests.
- Provider retry/error-state tests and UI interaction tests for CRUD screens.
- Transaction date, account, category, type-switching, and edit-form tests.
- Report/dashboard rendering tests beyond provider parsing.
- Accessibility, text-overflow, and more detailed narrow-tablet layout checks.

## 11. Build and Deployment Notes

Run locally with:

```powershell
flutter pub get
flutter run -d chrome
```

The Android host still uses the template application ID `com.example.sme_cashflow`. Release Android builds currently use the debug signing configuration and need a real signing setup before production distribution. `android/local.properties` must point Gradle at the local Flutter SDK.

The web host is the standard Flutter bootstrap page, with the application title and description set to SME Cashflow. No secrets should be placed in source control or in `--dart-define` values.

## 12. Practical Maintenance Guide

When changing an API response shape, update the corresponding parser in `lib/models/` and its provider tests first. When adding a new authenticated endpoint, add it to `ApiService` so token injection, refresh, and `ApiException` handling remain centralized. When adding a feature screen, follow the existing lifecycle pattern: obtain the shared `ApiService` from `AuthProvider`, create a screen-local provider, load in `initState`, provide it with `ChangeNotifierProvider.value`, and dispose it with the screen.

For a new transaction-related field, update the model, the list/detail/form surfaces, and the request payload together. For a new report schema, prefer extending `ReportData` or introducing a typed report model if the UI needs domain-specific calculations; the current generic renderer is intentionally permissive but cannot provide charts or strong validation.