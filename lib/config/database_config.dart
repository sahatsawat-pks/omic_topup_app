class DatabaseConfig {
  // MySQL Database Configuration
  // Use '10.0.2.2' for Android emulator (maps to host's localhost)
  // Use '127.0.0.1' for iOS simulator
  // Use your machine's IP address for physical devices
  static const String host = '10.0.2.2';
  static const int port = 3306;
  static const String database = 'omic_web';
  static const String username = ''; // Update your username here
  static const String password = ''; // Update with your MySQL password
  
  // Connection timeout in seconds (reduced for mobile)
  static const int connectionTimeout = 5;
  
  // Max retry attempts
  static const int maxRetryAttempts = 3;
}
