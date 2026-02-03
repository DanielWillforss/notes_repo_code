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
    final routing = NotesRouting(conn, 'notes');
    routing.register(router);
  }

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    router = Router();
    register(router);
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  Future<Response> createNote({required String title}) {
    return router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/notes/'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'title': title}),
      ),
    );
  }

  Future<List<dynamic>> getAllNotes() async {
    final response = await router.call(
      Request('GET', Uri.parse('http://localhost/notes/')),
    );
    return jsonDecode(await response.readAsString());
  }

  group('GET /notes/', () {
    test('returns empty list when database is empty', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/notes/')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body, isList);
      expect(body, isEmpty);
    });

    test('returns all notes', () async {
      await createNote(title: 'Note 1');
      await createNote(title: 'Note 2');

      final body = await getAllNotes();

      expect(body.length, 2);
    });
  });

  group('POST /notes/', () {
    test('creates a note', () async {
      final response = await createNote(title: 'Test note');
      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.length, 1);
      expect(body.first['title'], 'Test note');
    });

    test('fails when payload contains extra keys', () async {
      final response = await router.call(
        Request(
          'POST',
          Uri.parse('http://localhost/notes/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'Bad', 'body': 'nope'}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('fails when payload is invalid json', () async {
      final response = await router.call(
        Request(
          'POST',
          Uri.parse('http://localhost/notes/'),
          headers: {'content-type': 'application/json'},
          body: '{invalid json}',
        ),
      );

      expect(response.statusCode, 400);
    });
  });

  group('PUT /notes/<id>/title/', () {
    test('updates note title', () async {
      await createNote(title: 'Old');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id/title/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'New'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.first['title'], 'New');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/abc/title/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'title': 'New'}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('fails for null update', () async {
      await createNote(title: 'Test');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id/title/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({}),
        ),
      );

      final body = await response.readAsString();
      expect(body, 'null_update');
    });
  });

  group('PUT /notes/<id>/body/', () {
    test('updates note body', () async {
      await createNote(title: 'Has body');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id/body/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'body': 'Updated body'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.first['body'], 'Updated body');
    });

    test('fails when body is missing', () async {
      await createNote(title: 'Test');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id/body/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({}),
        ),
      );

      final body = await response.readAsString();
      expect(body, 'null_update');
    });
  });

  group('PUT /notes/<id>/parent/', () {
    test('updates parent_id', () async {
      await createNote(title: 'Parent');
      await createNote(title: 'Child');

      final notes = await getAllNotes();
      final parentId = notes.first['id'];
      final childId = notes.last['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$childId/parent/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'parentId': parentId}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.last['parent_id'], parentId);
    });

    test('fails when parentId missing', () async {
      await createNote(title: 'Test');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/notes/$id/parent/'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({}),
        ),
      );

      final body = await response.readAsString();
      expect(body, 'null_update');
    });
  });

  group('DELETE /notes/<id>/', () {
    test('deletes a note', () async {
      await createNote(title: 'Delete me');
      final id = (await getAllNotes()).first['id'];

      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/$id/')),
      );

      expect(response.statusCode, 200);
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/abc/')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing note', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/notes/9999/')),
      );

      final body = await response.readAsString();
      expect(body, 'not_found');
    });
  });
}
