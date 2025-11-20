import 'package:mysql1/mysql1.dart';
import '../config/database_config.dart';

class MySQLService {
  static MySQLService? _instance;
  MySqlConnection? _connection;
  
  MySQLService._internal();
  
  static MySQLService get instance {
    _instance ??= MySQLService._internal();
    return _instance!;
  }
  
  // Connect to MySQL database
  Future<MySqlConnection> connect() async {
    if (_connection != null) {
      return _connection!;
    }
    
    try {
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.username,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: Duration(seconds: DatabaseConfig.connectionTimeout),
      );
      
      _connection = await MySqlConnection.connect(settings);
      print('✅ MySQL connection established successfully');
      return _connection!;
    } catch (e) {
      print('❌ MySQL connection error: $e');
      rethrow;
    }
  }
  
  // Execute a query
  Future<Results> query(String sql, [List<Object?>? values]) async {
    try {
      final conn = await connect();
      final results = await conn.query(sql, values);
      return results;
    } catch (e) {
      print('❌ Query execution error: $e');
      rethrow;
    }
  }
  
  // Execute multiple queries in a transaction
  Future<void> transaction(List<String> queries, [List<List<Object?>?>? values]) async {
    MySqlConnection? conn;
    try {
      conn = await connect();
      await conn.query('START TRANSACTION');
      
      for (int i = 0; i < queries.length; i++) {
        await conn.query(
          queries[i],
          values != null && i < values.length ? values[i] : null,
        );
      }
      
      await conn.query('COMMIT');
      print('✅ Transaction completed successfully');
    } catch (e) {
      if (conn != null) {
        await conn.query('ROLLBACK');
      }
      print('❌ Transaction error (rolled back): $e');
      rethrow;
    }
  }
  
  // Close connection
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('✅ MySQL connection closed');
    }
  }
  
  // Test connection
  Future<bool> testConnection() async {
    try {
      await connect();
      final results = await query('SELECT 1');
      return results.isNotEmpty;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
