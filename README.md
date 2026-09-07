# SME Cashflow

Flutter client for the SME Cashflow application.

## API configuration

Development defaults are selected automatically:

- Web: `http://localhost:8000/api/`
- Android emulator: `http://10.0.2.2:8000/api/`

Production builds receive the Django URL at build time. The URL is not stored in source control:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api/
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api/
```

Replace the example URL with the deployed Django API URL. Do not put credentials or other secrets in `--dart-define` values.

## Run locally

```powershell
flutter pub get
flutter run -d chrome
```

For Android, start an emulator and run `flutter run -d <device-id>`.
