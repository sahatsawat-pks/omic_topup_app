import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/product_repository.dart';

class DebugTestScreen extends StatefulWidget {
  const DebugTestScreen({super.key});

  @override
  State<DebugTestScreen> createState() => _DebugTestScreenState();
}

class _DebugTestScreenState extends State<DebugTestScreen> {
  final _dbService = DatabaseService.instance;
  final _userRepo = UserRepository();
  final _productRepo = ProductRepository();
  
  String _testResults = 'Tap buttons to run tests';
  bool _isLoading = false;

  Future<void> _testMySQLConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing MySQL connection...';
    });

    try {
      final conn = await _dbService.mysql.connect();
      final results = await conn.query('SELECT DATABASE() as db, VERSION() as version');
      
      if (results.isNotEmpty) {
        final row = results.first;
        setState(() {
          _testResults = '✅ MySQL Connected!\n'
              'Database: ${row['db']}\n'
              'Version: ${row['version']}';
        });
      }
    } catch (e) {
      setState(() {
        _testResults = '❌ MySQL Connection Failed:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testProductQuery() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing product query...';
    });

    try {
      final products = await _productRepo.getAllProducts();
      
      setState(() {
        _testResults = '✅ Products Query Success!\n'
            'Found ${products.length} products\n\n'
            'Sample products:\n'
            '${products.take(3).map((p) => '- ${p['product_name']}').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Product Query Failed:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUserQuery() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing user query...';
    });

    try {
      final users = await _dbService.mysql.query('SELECT User_ID, Fname, Lname, email FROM User LIMIT 5');
      
      setState(() {
        _testResults = '✅ User Query Success!\n'
            'Found ${users.length} users\n\n'
            'Sample users:\n'
            '${users.map((u) => '- ${u['Fname']} ${u['Lname']} (${u['email']})').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ User Query Failed:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testLoginData() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing login data...';
    });

    try {
      final logins = await _dbService.mysql.query(
        '''SELECT ld.User_ID, ld.username, 
              LEFT(ld.hashed_password, 20) as password_preview,
              u.Fname, u.Lname
           FROM Login_Data ld
           LEFT JOIN User u ON ld.User_ID = u.User_ID
           LIMIT 5'''
      );
      
      setState(() {
        _testResults = '✅ Login Data Query Success!\n'
            'Found ${logins.length} login records\n\n'
            'Sample accounts:\n'
            '${logins.map((l) => '- ${l['username']}: ${l['Fname']} ${l['Lname']}\n  Password: ${l['password_preview']}...').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Login Data Query Failed:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPasswordVerify() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing password verification...';
    });

    try {
      // Test with username 'alice123' and password 'password123'
      final result = await _userRepo.verifyLogin('alice123', 'password123');
      
      setState(() {
        if (result != null) {
          _testResults = '✅ Login Verification Success!\n'
              'User: ${result['Fname']} ${result['Lname']}\n'
              'Email: ${result['email']}\n'
              'Type: ${result['user_type']}';
        } else {
          _testResults = '❌ Login Verification Failed:\n'
              'Invalid username or password\n\n'
              'Try:\n'
              'Username: alice123\n'
              'Password: password123';
        }
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Login Verification Error:\n$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tests'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testMySQLConnection,
              icon: const Icon(Icons.storage),
              label: const Text('Test MySQL Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testProductQuery,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Test Product Query'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testUserQuery,
              icon: const Icon(Icons.people),
              label: const Text('Test User Query'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLoginData,
              icon: const Icon(Icons.login),
              label: const Text('Test Login Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testPasswordVerify,
              icon: const Icon(Icons.lock),
              label: const Text('Test Password Verify (alice123)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
