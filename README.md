# OMiC Top-Up App (Flutter)

A Flutter mobile application for game top-ups, based on the OMiC Games web application.

## Features

- **User Authentication**: Login and registration with JWT token management
- **Product Browsing**: View available game products and packages
- **User Profile**: Edit profile information, update avatar, and change password
- **News Feed**: Latest gaming news and updates
- **Theme Support**: Light and dark mode matching the web app design system
- **Navigation Drawer**: Easy access to all app sections

## Project Structure

```
lib/
├── config/
│   ├── api_constants.dart     # API endpoints and configuration
│   └── app_theme.dart          # Theme configuration (colors, styles)
├── models/
│   ├── user.dart               # User data model
│   ├── product.dart            # Product data model
│   └── news_item.dart          # News item data model
├── providers/
│   └── auth_provider.dart      # Authentication state management
├── screens/
│   ├── home_screen.dart        # Home page with products and news
│   ├── login_screen.dart       # Login page
│   ├── register_screen.dart    # Registration page
│   └── profile_screen.dart     # User profile page
├── services/
│   ├── api_service.dart        # HTTP client and API calls
│   └── auth_service.dart       # Authentication and data services
├── widgets/
│   └── app_drawer.dart         # Navigation drawer widget
└── main.dart                   # App entry point
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode for emulators
- VS Code with Flutter extension (recommended)

### Backend Setup

1. Make sure your backend server is running:
   ```bash
   cd ../service
   npm install
   npm start
   ```

2. Update the API base URL in `lib/config/api_constants.dart` if needed:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:3300/api';
   ```
   - For Android emulator: Use `http://10.0.2.2:3300/api`
   - For iOS simulator: Use `http://localhost:3300/api`
   - For physical devices: Use your computer's IP address

### Flutter App Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Configuration

### API Constants

Edit `lib/config/api_constants.dart` to configure:
- Base URL for your backend API
- API endpoints
- Timeout settings
- Storage keys

### Database Config

Edit your database configuration in the `.env` file, in your backend's config file (such as `service/.env` or `service/database_config.js`), or in the Flutter app's `lib/config/database_config.dart` if you use a local database or need to reference database settings in Dart code.
Typical settings include:
- DB_HOST: Database host
- DB_PORT: Database port
- DB_USER: Database username
- DB_PASS: Database password
- DB_NAME: Database name

Example for `.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_USER=youruser
DB_PASS=yourpassword
DB_NAME=omic_topup
```

For Flutter, you can create or edit `lib/config/database_config.dart` to read these values using a package like `flutter_dotenv`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseConfig {
   static String get host => dotenv.env['DB_HOST'] ?? '';
   static String get port => dotenv.env['DB_PORT'] ?? '';
   static String get user => dotenv.env['DB_USER'] ?? '';
   static String get password => dotenv.env['DB_PASS'] ?? '';
   static String get dbName => dotenv.env['DB_NAME'] ?? '';
}
```

Make sure your backend and app read these values and connect to the correct database.

### Theme

Edit `lib/config/app_theme.dart` to customize:
- Color scheme (matching web app)
- Typography
- Button styles
- Input field styles
- Card styles

## Available Screens

### Public Screens
- **Home Screen**: Product grid and news carousel
- **Login Screen**: User authentication
- **Register Screen**: New user registration

### Authenticated Screens
- **Profile Screen**: View and edit user profile
- **Games Screen**: Browse available games (placeholder)
- **Membership Screen**: Membership information (placeholder)
- **History Screen**: Transaction history (placeholder)

### Admin Screens
- **Admin Dashboard**: Admin panel (placeholder)

## Design System

The app follows the web application's design system:

### Colors
- Primary: `#1A1A1A` (Dark gray)
- Secondary: `#F7F7F7` (Light gray)
- Accent: `#14B8A6` (Teal)
- Background: `#FFFFFF` (White)
- Error: `#DC2626` (Red)

## Running Tests

```bash
flutter test
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## Troubleshooting

### Connection Issues
- Make sure backend server is running
- Check API base URL configuration
- For Android emulator, use `10.0.2.2` instead of `localhost`

### Package Issues
```bash
flutter clean
flutter pub get
```

## Next Steps

To complete the implementation:

1. **Add Product Details Screen**: Show package options and pricing
2. **Implement Order Flow**: Shopping cart and checkout process
3. **Add Payment Integration**: Payment gateway integration
4. **Implement History Screen**: Transaction and order history
5. **Add Push Notifications**: Order status updates

## Dependencies

Key packages used:
- `provider`: State management
- `http`: HTTP requests
- `shared_preferences`: Local storage
- `flutter_secure_storage`: Secure token storage
- `image_picker`: Avatar upload

