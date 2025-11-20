import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/debug_test_screen.dart';
import 'screens/games_screen.dart';
import 'screens/membership_screen.dart';
import 'screens/history_screen.dart';
import 'screens/policy_screen.dart';
import 'screens/support_screen.dart';
import 'screens/about_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/manage_products_screen.dart';
import 'screens/manage_orders_screen.dart';
import 'screens/manage_users_screen.dart';
import 'screens/settings_screen.dart';
import 'services/mysql_service.dart';
import 'package:omic_topup_app/providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MySQL connection FIRST before starting app
  print('🚀 Starting app initialization...');
  try {
    print('🔄 Connecting to MySQL database...');
    await MySQLService.instance.connect();
    print('✅ MySQL database connected successfully');
  } catch (error) {
    print('❌ MySQL connection failed: $error');
    print('⚠️ App will start but data may not load');
  }
  
  print('🎯 Starting Flutter app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          // Load products after provider is created
          if (productProvider.products.isEmpty && !productProvider.isLoading) {
            Future.microtask(() => productProvider.loadProducts());
          }
          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MaterialApp(
            title: 'OMiC Games',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/user/profile': (context) => const ProfileScreen(),
              '/user/games': (context) => const GamesScreen(),
              '/user/membership': (context) => const MembershipScreen(),
              '/user/history': (context) => const HistoryScreen(),
              '/policy': (context) => const PolicyScreen(),
              '/support': (context) => const SupportScreen(),
              '/about': (context) => const AboutScreen(),
              '/admin/dashboard': (context) => const AdminDashboardScreen(),
              '/admin/products': (context) => const ManageProductsScreen(),
              '/admin/orders': (context) => const ManageOrdersScreen(),
              '/admin/users': (context) => const ManageUsersScreen(),

              '/admin/settings': (context) => const SettingsScreen(),
              '/debug': (context) => const DebugTestScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle dynamic routes like /product/:id
              if (settings.name != null && settings.name!.startsWith('/product/')) {
                final productId = settings.name!.substring('/product/'.length);
                return MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(productId: productId),
                );
              }
              return null;
            },
          );
            },
          );
        },
      ),
    );
  }
}

// Splash Screen for loading
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This page is under construction',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
