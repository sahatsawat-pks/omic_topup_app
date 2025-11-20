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
│   ├── database_config.dart   # Database configuration
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
- MySQL Server running

### Backend Setup

1. Make sure your backend server is running:
   ```bash
   cd ../service
   npm install
   npm start
   ```

2. The backend should be configured to read from its own `.env` file for database and API settings.

### Flutter App Setup

1. **Create `.env` file** in the root directory of the Flutter project:
   ```bash
   cp .env.example .env
   ```

2. **Configure your `.env` file** with your settings:
   ```dotenv
   # Database Configuration
   DB_HOST=10.0.2.2
   DB_PORT=3306
   DB_NAME=omic_web
   DB_USERNAME=your_username_here
   DB_PASSWORD=your_password_here
   DB_CONNECTION_TIMEOUT=5
   DB_MAX_RETRY_ATTEMPTS=3

   # API Configuration
   API_BASE_URL=http://10.0.2.2:3300/api
   API_CONNECTION_TIMEOUT=30
   API_RECEIVE_TIMEOUT=30

   # API Endpoints
   API_LOGIN=/auth/login
   API_REGISTER=/auth/register
   API_PRODUCTS=/products
   API_PRODUCT_BY_ID=/products/
   API_PACKAGES=/packages
   API_PACKAGES_BY_PRODUCT_ID=/packages/product/
   API_ORDERS=/orders
   API_LATEST_ORDER_ID=/orders/latest
   API_UPDATE_PROFILE=/profile/update
   API_UPDATE_PASSWORD=/profile/password

   # Storage Keys
   STORAGE_ACCESS_TOKEN_KEY=accessToken
   STORAGE_USER_KEY=authUser
   ```

   **Important API Base URL configurations:**
   - For Android emulator: `http://10.0.2.2:3300/api`
   - For iOS simulator: `http://localhost:3300/api`
   - For physical devices: `http://YOUR_COMPUTER_IP:3300/api` (e.g., `http://192.168.1.100:3300/api`)

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Environment Variables

This app uses environment variables for configuration. All sensitive data and configuration should be stored in the `.env` file.

### Creating .env file

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your actual values
3. **Never commit `.env` to version control** (it's in `.gitignore`)

### Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | Database host address | `10.0.2.2` for Android emulator |
| `DB_PORT` | Database port | `3306` |
| `DB_NAME` | Database name | `omic_web` |
| `DB_USERNAME` | Database username | `root` |
| `DB_PASSWORD` | Database password | `your_password` |
| `DB_CONNECTION_TIMEOUT` | DB connection timeout (seconds) | `5` |
| `DB_MAX_RETRY_ATTEMPTS` | Max retry attempts | `3` |
| `API_BASE_URL` | Backend API base URL | `http://10.0.2.2:3300/api` |
| `API_CONNECTION_TIMEOUT` | API timeout (seconds) | `30` |
| `API_RECEIVE_TIMEOUT` | API receive timeout (seconds) | `30` |

## Configuration Files

### API Constants

The `lib/config/api_constants.dart` file now reads from environment variables using `flutter_dotenv`. All API endpoints and timeouts are configured through the `.env` file.

### Database Config

The `lib/config/database_config.dart` file reads database settings from environment variables. Configure your database connection in the `.env` file.

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
- Make sure backend server is running on the correct port
- Check `.env` file for correct `API_BASE_URL`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical devices, use your computer's local IP address
- Ensure your device/emulator can reach the backend server

### Environment Variable Issues
- Make sure `.env` file exists in the project root
- Verify `.env` is listed in `pubspec.yaml` under assets
- Run `flutter clean` and `flutter pub get` after changing `.env`
- Restart the app after modifying environment variables

### Package Issues
```bash
flutter clean
flutter pub get
```

### Database Connection Issues
- Verify MySQL server is running
- Check database credentials in `.env`
- Ensure the database `omic_web` exists
- For Android emulator, use `10.0.2.2` as `DB_HOST`

## Security Notes

- **Never commit `.env` file** to version control
- Keep `.env.example` updated with all required variables (without actual values)
- Use different `.env` files for development, staging, and production
- Rotate sensitive credentials regularly
- Use strong passwords for database access

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
- `flutter_dotenv`: Environment variable management
- `image_picker`: Avatar upload

## Team Setup

For team members setting up the project:

1. Clone the repository
2. Copy `.env.example` to `.env`
3. Ask team lead for the correct environment values
4. Run `flutter pub get`
5. Ensure backend server is running
6. Run the app with `flutter run`