import 'package:notes_repo_core/classes/note_routing.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Future<void> main() async {
  final conn = await DatabaseConnection.get();
  final router = Router();
  final routing = NotesRouting(conn, "notes");

  // GET /notes
  router.get('/notes/', routing.getAll);

  // POST /notes
  router.post('/notes/', routing.create);

  // PUT /notes/<id>
  router.put('/notes/<id>/', routing.update);

  // DELETE /notes/<id>
  router.delete('/notes/<id>/', routing.delete);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await io.serve(handler, '127.0.0.1', 5000);
  print('Server running on http://${server.address.host}:${server.port}');
}

class DatabaseConnection {
  static Connection? _conn;

  static Future<Connection> get() async {
    _conn ??= await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'dev_db',
        username: 'admin',
        password: 'admin',
      ),
    );

    return _conn!;
  }

  //TODO: what if connection fails or is lost?
  // Consistent error message thrown by repository?
  //TODO: not hardcoded endpoint
}
