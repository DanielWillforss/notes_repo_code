import 'package:notes_repo_core/util/exceptions.dart';
import 'package:notes_repo_core/classes/note_repository.dart';
import 'test_util.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

Future<void> main() async {
  late Connection conn;
  late NoteRepository notesRepo;

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    notesRepo = NoteRepository(conn, "notes");
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  group('insert', () {
    test('inserts a note and returns persisted data', () async {
      final note = await notesRepo.insert(title: 'Test', body: 'Body');

      expect(note.id, isA<int>());
      expect(note.title, equals('Test'));
      expect(note.body, equals('Body'));
      expect(note.parentId, isNull);
      expect(note.createdAt, isA<DateTime>());
      expect(note.updatedAt, isA<DateTime>());
    });

    test('defaults null title and body to empty strings', () async {
      final note = await notesRepo.insert();

      expect(note.title, equals(''));
      expect(note.body, equals(''));
    });
  });

  group('findAll', () {
    test('returns empty list when no notes exist', () async {
      final notes = await notesRepo.findAll();
      expect(notes, isEmpty);
    });

    test('returns all inserted notes', () async {
      await notesRepo.insert(title: 'A', body: 'A');
      await notesRepo.insert(title: 'B', body: 'B');

      final notes = await notesRepo.findAll();
      expect(notes.length, equals(2));
    });
  });

  group('findById', () {
    test('returns correct note', () async {
      final inserted = await notesRepo.insert(title: 'One', body: 'Body');
      final fetched = await notesRepo.findById(inserted.id);

      expect(fetched.id, equals(inserted.id));
      expect(fetched.title, equals('One'));
      expect(fetched.body, equals('Body'));
      expect(fetched.updatedAt, equals(inserted.updatedAt));
    });

    test('throws IdNotFoundException for missing id', () async {
      expect(
        () => notesRepo.findById(99999),
        throwsA(isA<IdNotFoundException>()),
      );
    });
  });

  group('updateTitle', () {
    test('updates only the title', () async {
      final original = await notesRepo.insert(title: 'Old', body: 'Body');

      final updated = await notesRepo.updateTitle(
        id: original.id,
        title: 'New',
      );

      expect(updated.title, equals('New'));
      expect(updated.body, equals('Body'));
      expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
    });

    test('throws IdNotFoundException for missing id', () async {
      expect(
        () => notesRepo.updateTitle(id: 999, title: 'Fail'),
        throwsA(isA<IdNotFoundException>()),
      );
    });
  });

  group('updateBody', () {
    test('updates only the body', () async {
      final original = await notesRepo.insert(title: 'Title', body: 'Old');

      final updated = await notesRepo.updateBody(id: original.id, body: 'New');

      expect(updated.title, equals('Title'));
      expect(updated.body, equals('New'));
      expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
    });

    test('throws IdNotFoundException for missing id', () async {
      expect(
        () => notesRepo.updateBody(id: 999, body: 'Fail'),
        throwsA(isA<IdNotFoundException>()),
      );
    });
  });

  group('updateParent', () {
    test('sets parent_id to another note', () async {
      final parent = await notesRepo.insert(title: 'Parent');
      final child = await notesRepo.insert(title: 'Child');

      final updated = await notesRepo.updateParent(
        id: child.id,
        parentId: parent.id,
      );

      expect(updated.parentId, equals(parent.id));
    });

    test('sets parent_id to null', () async {
      final parent = await notesRepo.insert(title: 'Parent');
      final child = await notesRepo.insert(title: 'Child');

      await notesRepo.updateParent(id: child.id, parentId: parent.id);

      final updated = await notesRepo.updateParent(
        id: child.id,
        parentId: null,
      );

      expect(updated.parentId, isNull);
    });

    test('throws IdNotFoundException for missing id', () async {
      expect(
        () => notesRepo.updateParent(id: 999, parentId: null),
        throwsA(isA<IdNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('removes the specified note only', () async {
      final a = await notesRepo.insert(title: 'A');
      final b = await notesRepo.insert(title: 'B');

      await notesRepo.delete(a.id);

      final notes = await notesRepo.findAll();
      expect(notes.length, equals(1));
      expect(notes.single.id, equals(b.id));
    });

    test('throws IdNotFoundException for missing id', () async {
      expect(() => notesRepo.delete(999), throwsA(isA<IdNotFoundException>()));
    });
  });
}
