# SME Cashflow Documentation

SME Cashflow is a Flutter client for recording and reviewing small-business cash flow. It uses a Django-style HTTP API for authentication and data storage, and is designed to run on the web or Android.

## Project Map

### Application entry points

- `lib/main.dart` starts Flutter, creates the shared `AuthProvider`, and begins session initialization.
- `lib/app.dart` defines the Material 3 theme, authentication gate, responsive navigation, and the main application shell.
- `lib/config/app_config.dart` selects the API URL. A build-time `API_BASE_URL` overrides the default deployed API URL.

### Configuration and service layer

- `pubspec.yaml` declares the Flutter SDK and the main dependencies: `dio` for HTTP, `provider` for state management, `shared_preferences` for tokens, and `intl` for currency/date formatting.
- `lib/services/api_service.dart` owns HTTP requests, authentication headers, token persistence, token refresh, and API error conversion.
- `lib/widgets/feedback_widgets.dart` contains shared loading, empty-state, and error-state widgets.

### Data models

- `lib/models/account.dart` represents a money account, including its name, type, balance, and active state.
- `lib/models/category.dart` represents an income or expense category.
- `lib/models/transaction.dart` represents a transaction linked to an account and category, with a type, amount, description, and date.
- `lib/models/dashboard_summary.dart` represents dashboard totals and recent data.
- `lib/models/report_data.dart` represents report responses.

### Providers

Providers coordinate API calls, loading state, errors, and UI updates:

- `lib/providers/auth_provider.dart` handles registration, login, logout, current-user loading, and session expiry.
- `lib/providers/accounts_provider.dart` loads and manages money accounts.
- `lib/providers/categories_provider.dart` loads and manages categories.
- `lib/providers/transactions_provider.dart` loads transactions together with their accounts and categories, applies income/expense filters, and manages transaction CRUD operations.
- `lib/providers/dashboard_provider.dart` loads the dashboard summary.
- `lib/providers/reports_provider.dart` loads cash-flow, category, and account reports.

### Screens

- `lib/screens/splash_screen.dart` is shown while the saved session is checked.
- `lib/screens/login_screen.dart` signs an existing user in and links to registration.
- `lib/screens/register_screen.dart` creates a user and business account.
- `lib/screens/dashboard_screen.dart` shows balance, income, expenses, net cash flow, recent transactions, and accounts.
- `lib/screens/accounts_screen.dart` lists, creates, edits, deactivates, and deletes money accounts.
- `lib/screens/categories_screen.dart` lists income and expense categories and supports category CRUD operations.
- `lib/screens/transactions_screen.dart` lists, filters, creates, edits, and deletes transactions.
- `lib/screens/transaction_form_screen.dart` collects the fields needed to create or edit a transaction.
- `lib/screens/transaction_details.dart` displays the details of one transaction.
- `lib/screens/reports_screen.dart` displays available cash-flow reports.
- `lib/screens/settings_screen.dart` contains application settings.

### Platform and tests

- `android/` contains the Android Gradle project, manifests, Kotlin host entry point, launch resources, and launcher icons.
- `web/` contains the web bootstrap page, manifest, and web icons.
- `test/` contains provider, API, authentication, transaction/category, responsive-layout, settings, checkpoint, and widget tests.
- `analysis_options.yaml` and `devtools_options.yaml` configure analysis and developer tooling.
- `build/` is generated Flutter output and should not be treated as application source.

## Running the Project

Install Flutter, then run:

```powershell
flutter pub get
flutter run -d chrome
```

For Android, start an emulator and run `flutter run -d <device-id>`.

The API defaults are:

- Web development: `http://localhost:8000/api/`
- Android emulator development: `http://10.0.2.2:8000/api/`
- Otherwise, the configured deployed API URL is used.

To provide an API URL explicitly for a release build:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api/
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api/
```

## User Workflow

The records should be created in this order because a transaction references both an account and a category:

1. Create a user account.
2. Create a money account.
3. Create a category.
4. Create a transaction using the money account and category.

### 1. Create a user account

1. Open the app. On the sign-in screen, select **Create an account**.
2. Enter the **Business name**, **Name**, **Email**, and **Password**.
3. Use a valid email address and a password with at least 8 characters.
4. Select **Register**.
5. A successful registration stores the access and refresh tokens and opens the authenticated app shell.

The user can later return through the sign-in screen with the same email and password. On startup, the app checks the saved session and attempts to refresh an expired access token when necessary.

### 2. Create a money account

1. Open **Accounts** from the navigation rail on desktop or the bottom navigation/more menu on smaller screens.
2. Select **Add account**.
3. Enter an account **Name**, such as `Main bank account`.
4. Enter the account **Type** using one of these supported values:
   - `bank`
   - `cash`
   - `mobile_money`
5. Enter the starting **Balance** as a number, such as `1500.00`.
6. Select **Save**.

The account appears in the Accounts list and becomes available in the transaction form. The current client uses a text field for account type, so enter the values exactly as shown. The client validates the name and numeric balance; the API remains responsible for rejecting unsupported type values.

### 3. Create a category

1. Open **Categories**. On a small screen, open the **More** menu first.
2. Select **Add category**.
3. Enter a category **Name**, such as `Office supplies`.
4. Select the category **Type**:
   - **Income** for money received.
   - **Expense** for money spent.
5. Select **Save**.

Create a category whose type matches the transaction you plan to record. For example, an `Office supplies` expense category can be used for an expense transaction, while a `Sales` income category can be used for an income transaction.

### 4. Create a transaction

1. Open **Transactions**.
2. Select **Add transaction**.
3. Choose **Income** or **Expense** as the transaction **Type**.
4. Select the previously created **Account**.
5. Select a **Category** of the same type. Expense transactions only show expense categories, and income transactions only show income categories.
6. Enter an **Amount** greater than zero.
7. Enter an optional **Description**.
8. Select the transaction **Date**.
9. Select **Save transaction**.

The new transaction is sent to the API with the selected account ID, category ID, type, amount, description, and date. It then appears in the transaction list and contributes to dashboard and report totals.

## Using the App After Setup

- **Dashboard** provides a high-level balance, income, expense, and net cash-flow overview.
- **Transactions** supports All, Income, and Expense filters. Select a transaction to view details, or use its menu to edit or delete it.
- **Accounts** supports editing, deactivating, and deleting accounts.
- **Settings** displays the authenticated user's name, email, and business name.
- **Settings** allows the authenticated user to change their password by providing the current password and a new password of at least 8 characters.
- **Categories** separates income and expense categories and supports editing and deleting them.
- **Reports** provides cash-flow, category, and account reports from the API in a compact view. Summary values appear as metric tiles, while detailed rows show only the relevant name or date and its value for easier scanning.
- **Settings** provides the available application settings.
- Use **Logout** from the desktop navigation rail or the mobile More menu to clear the saved session.

Most list screens support pull-to-refresh. API failures are displayed in the relevant screen with an option to retry.

## API Endpoint Summary

The client communicates with these API paths relative to the configured base URL:

- `auth/register/`, `auth/login/`, `auth/me/`, and `auth/refresh/`
- `dashboard/summary/`
- `accounts/`
- `categories/`
- `transactions/`
- `reports/cashflow/`
- `reports/by-category/`
- `reports/by-account/`

Authenticated requests send a bearer access token. Access and refresh tokens are stored locally using `shared_preferences`; credentials and tokens should not be placed in source control or in build configuration values.

The Accounts screen displays each API-provided account balance and a total balance across the accounts returned by the API. When creating an account, the client sends the Django API's `opening_balance` field; the API returns the calculated `balance` used for display. Account deletion is a soft delete, so inactive accounts are excluded from the active list and cannot be used for new transactions.

## Verification

Run the automated checks with:

```powershell
flutter test
flutter analyze
```

The test suite covers API behavior, provider behavior, authentication, transaction/category behavior, responsive layouts, and core widget rendering.
