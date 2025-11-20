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
│   ├── home_screen.dart        # Home page with products
│   ├── login_screen.dart       # Login page
│   ├── register_screen.dart    # Registration page
│   └── profile_screen.dart     # User profile page
├── services/
│   ├── api_service.dart        # HTTP client and API calls
│   └── auth_service.dart       # Authentication and data services
├── widgets/
│   └── app_drawer.dart         # Navigation drawer widget
└── main.dart                   # App entry point

service/
├── Controller/                 # All controller for backend handling
└── server.js                   # Main backend code

sql/
└── omic_web.sql                # Database schema and mock data
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode for emulators
- VS Code with Flutter extension (recommended)
- MySQL Server (8.0 or higher)
- Node.js (for backend service)

### Database Setup

1. **Start MySQL Server** and ensure it's running on port 3306

2. **Create the database** using the provided SQL file:
   ```bash
   mysql -u root -p < sql/omic_web.sql
   ```
   Or manually:
   - Open MySQL Workbench or command line
   - Run the `sql/omic_web.sql` script
   - This will create the `omic_web` database with all tables and mock data

3. **Verify database creation**:
   ```sql
   USE omic_web;
   SHOW TABLES;
   SELECT * FROM Product;
   ```

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd service
   ```

2. **Create `.env` file** for backend:
   ```bash
   cp .env.example .env
   ```

3. **Configure backend `.env`**:
   ```dotenv
   # Database Configuration
   DB_HOST=localhost
   DB_USER=root
   DB_PASS=your_mysql_password
   DB_NAME=omic_web
   DB_PORT=3306

   # Server Configuration
   PORT=3300
   ```

4. **Install dependencies and start server**:
   ```bash
   npm install
   npm start
   ```

5. **Verify backend is running**:
   - Server should start on `http://localhost:3300`
   - Test endpoint: `http://localhost:3300/api/products`

### Flutter App Setup

1. **Navigate to Flutter project root**

2. **Create `.env` file** for Flutter app:
   ```bash
   cp .env.example .env
   ```

3. **Configure Flutter `.env`** with your settings:
   ```dotenv
   # Database Configuration (if direct connection needed)
   DB_HOST=10.0.2.2
   DB_PORT=3306
   DB_NAME=omic_web
   DB_USERNAME=root
   DB_PASSWORD=your_mysql_password
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

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

## Database Schema

The `omic_web` database includes the following tables:

### Core Tables
- **User**: User accounts (Admin, Customer, Developer)
- **Login_Data**: Authentication credentials
- **Login_Log**: Login attempt history
- **Membership**: User membership tiers and points

### Product Tables
- **Product**: Game products available for top-up
- **Product_Category**: Product categorization
- **Product_Package**: Package options for products
- **Server**: Game server regions
- **Product_Server**: Product-server relationships

### Transaction Tables
- **Order_Record**: Customer orders
- **Order_Item**: Individual items in orders
- **Payment_Record**: Payment information
- **Discount**: Discount codes and promotions
- **Review**: Product reviews

### Mock Data Available
- 10 Users (Admins and Customers)
- 10 Game Products (Free Fire, Genshin Impact, PUBG, Valorant, etc.)
- 11 Server Regions
- 5 Discount Codes
- Sample Orders and Payments
- Product Packages with pricing

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

## Test Accounts

Use these accounts from the mock data to test the application:

### Admin Accounts
- Username: `admin1` | Password: `admin123`
- Username: `charlie_admin` | Password: `admin123`

### Customer Accounts
- Username: `alice123` | Password: `password123`
- Username: `bob_the_builder` | Password: `password123`
- Username: `sophia_m` | Password: `password123`

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

### Database Issues
- Verify MySQL server is running: `mysql -u root -p`
- Check database exists: `SHOW DATABASES;`
- Verify tables created: `USE omic_web; SHOW TABLES;`
- Check backend `.env` has correct database credentials
- For Android emulator connecting directly to DB, use `10.0.2.2` as `DB_HOST`

### Environment Variable Issues
- Make sure `.env` file exists in the project root
- Verify `.env` is listed in `pubspec.yaml` under assets
- Run `flutter clean` and `flutter pub get` after changing `.env`
- Restart the app after modifying environment variables

### Backend Connection Issues
- Check if backend is running: `curl http://localhost:3300/api/products`
- Verify backend port matches `API_BASE_URL` in Flutter `.env`
- Check backend logs for errors
- Ensure MySQL connection from backend is working

### Package Issues
```bash
flutter clean
flutter pub get
```

## Security Notes

- **Never commit `.env` files** to version control
- Keep `.env.example` updated with all required variables (without actual values)
- Use different `.env` files for development, staging, and production
- Rotate sensitive credentials regularly
- Use strong passwords for database and user accounts
- Mock data passwords are hashed with bcrypt

## Next Steps

To complete the implementation:

1. **Add Product Details Screen**: Show package options and pricing
2. **Implement Order Flow**: Shopping cart and checkout process
3. **Add Payment Integration**: Payment gateway integration
4. **Implement History Screen**: Transaction and order history
5. **Add Push Notifications**: Order status updates
6. **Implement Review System**: Allow users to review products
7. **Add Discount Code Feature**: Apply discount codes at checkout

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
2. Set up MySQL database using `sql/omic_web.sql`
3. Set up backend:
   - Navigate to `service` directory
   - Copy `.env.example` to `.env`
   - Configure database credentials
   - Run `npm install` and `npm start`
4. Set up Flutter app:
   - Copy `.env.example` to `.env`
   - Configure API base URL for your environment
   - Run `flutter pub get`
   - Run `flutter run`
5. Test with provided mock user accounts