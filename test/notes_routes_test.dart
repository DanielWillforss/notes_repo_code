import 'dart:convert';

import 'package:notes_repo_core/classes/note_routing.dart';
import 'test_util.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

void main() async {
  late Router router;
  late Connection conn;

  void register(Router router) {
    final routing = NotesRouting(conn, "notes");

    // GET /notes
    router.get('/notes', routing.getAll);

    // GET /notes/<id>
    router.get('/notes/<id>', routing.getById);

    // POST /notes
    router.post('/notes', routing.create);

    // PUT /notes/<id>
    router.put('/notes/<id>', routing.update);

    // DELETE /notes/<id>
    router.delete('/notes/<id>', routing.delete);
  }

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    router = Router();
    register(router);
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  Future<Response> createNote({required String title, required String body}) {
    return router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/notes'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'title': title, 'body': body}),
      ),
    );
  }

  group('GET /notes', () {
    test('returns empty list when database is empty', () async {
      final request = Request('GET', Uri.parse('http://localhost/notes'));
      final response = await router.call(request);
      final body = await response.readAsString();

      expect(response.statusCode, 200);
      expect(jsonDecode(body), isList);
      expect(jsonDecode(body), isEmpty);
    });

    test('returns all notes', () async {
      await createNote(title: 'Note 1', body: 'body 1');
      await createNote(title: 'Note 2', body: 'body 2');

      final request = Request('GET', Uri.parse('http://localhost/notes'));
      final response = await router.call(request);
      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.length, 2);
    });
  });

  group('POST /notes', () {
    test('creates a note', () async {
      final response = await createNote(
        title: 'Test note',
        body: 'This is a test note',
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['title'], 'Test note');
      expect(body['body'], 'This is a test note');
    });
  });

  group('GET /notes/<id>', () {
    test('returns note by id', () async {
      await createNote(title: 'Find me', body: 'Here I am');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/notes')),
      );
      final notes = jsonDecode(await getAll.readAsString());
      final id = notes.first['id'];

      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/notes/$id')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['id'], id);
    });

    test('returns bad request for invalid id', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/notes/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing note', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/notes/9999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'not_found');
    });
  });

  group('PUT /notes/<id>', () {
    test('updates a note', () async {
      await createNote(title: 'Old', body: 'Old body');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/notes')),
      );
      final id = jsonDecode(await getAll.readAsString()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'New'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['id'], id);
      expect(body['title'], 'New');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/abc'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'New'}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('fails when title and body are missing', () async {
      await createNote(title: 'Test', body: 'Test');

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/1'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'null_update');
    });

    test('returns not_found when note does not exist', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/999'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'New'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });

  group('DELETE /notes/<id>', () {
    test('deletes a note', () async {
      await createNote(title: 'Delete me', body: 'Bye');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/notes')),
      );
      final id = jsonDecode(await getAll.readAsString()).first['id'];

      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/$id')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'deleted');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing note', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });
}
