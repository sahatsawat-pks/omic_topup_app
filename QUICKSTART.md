# Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Install Dependencies
```bash
cd omic_topup_app
flutter pub get
```

### Step 2: Configure API
Open `lib/config/api_constants.dart` and update the base URL:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3300/api';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:3300/api';
```

**For Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3300/api';
```

### Step 3: Run the App
```bash
# Start the backend first
cd ../sec02_gr01_ws_src
npm start

# In a new terminal, run the Flutter app
cd ../omic_topup_app
flutter run
```

## 📱 Available Features

### Without Login
- ✅ Browse products
- ✅ View news
- ✅ Create account
- ✅ Login

### With Login
- ✅ View/Edit profile
- ✅ Change password
- ✅ Upload avatar
- ✅ Access member features

## 🎨 App Screens

1. **Home** - Product grid + News carousel
2. **Login** - Username/password authentication
3. **Register** - New user registration
4. **Profile** - Edit user information
5. **Drawer Menu** - Navigation to all features

## 🔧 Common Issues

### Cannot connect to API
- ✅ Check backend is running on port 3300
- ✅ Use correct IP for your environment
- ✅ Check firewall settings

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Missing packages
```bash
flutter pub upgrade
```

## 📖 More Info

See `README.md` for detailed documentation
See `IMPLEMENTATION_SUMMARY.md` for what was built
