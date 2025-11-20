import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseConfig {
  static String get host => dotenv.env['DB_HOST'] ?? '10.0.2.2';
  static int get port => int.parse(dotenv.env['DB_PORT'] ?? '3306');
  static String get database => dotenv.env['DB_NAME'] ?? 'omic_web';
  static String get username => dotenv.env['DB_USERNAME'] ?? 'root';
  static String get password => dotenv.env['DB_PASSWORD'] ?? '';
  static int get connectionTimeout => int.parse(dotenv.env['DB_CONNECTION_TIMEOUT'] ?? '5');
  static int get maxRetryAttempts => int.parse(dotenv.env['DB_MAX_RETRY_ATTEMPTS'] ?? '3');
}