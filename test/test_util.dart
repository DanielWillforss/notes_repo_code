import 'package:postgres/postgres.dart';

class TestDatabaseConnection {
  static Future<Connection> _get() async {
    return await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'test_db',
        username: 'admin',
        password: 'admin',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  static Future<Connection> setUpTest() async {
    final conn = await _get();
    await conn.execute('BEGIN');

    return conn;
  }

  static Future<void> tearDownTest(Connection conn) async {
    await conn.execute('ROLLBACK');
    await conn.close();
  }
}
