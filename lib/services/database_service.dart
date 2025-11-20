import 'mysql_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  late MySQLService _mysqlService;
  
  DatabaseService._internal() {
    _mysqlService = MySQLService.instance;
  }
  
  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }
  
  MySQLService get mysql => _mysqlService;
  
  // Initialize database
  Future<bool> initialize() async {
    try {
      print('🔄 Initializing MySQL database connection...');
      await _mysqlService.connect();
      print('✅ MySQL connected successfully');
      return true;
    } catch (e) {
      print('❌ Database initialization error: $e');
      return false;
    }
  }

  
  // Close all connections
  Future<void> close() async {
    await _mysqlService.close();
    print('✅ All database connections closed');
  }
}
