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

  // Test: insert
  test('insert and retrieve a note', () async {
    // Arrange: the note data to insert
    const title = 'Test Note';
    const body = 'This is a test note body.';

    // Act: insert the note into the test database
    await notesRepo.insert(title: title, body: body);

    // Retrieve all notes
    final notes = await notesRepo.findAll();

    // Assert: There should be exactly 1 note
    expect(notes.length, equals(1));
    final note = notes.single;

    expect(note.title, equals(title));
    expect(note.body, equals(body));

    // Optional: check that id and timestamps are set
    expect(note.id, isA<int>());
    expect(note.createdAt, isA<DateTime>());
    expect(note.updatedAt, isA<DateTime>());
  });

  // Test: findAll
  test('findAll returns all notes', () async {
    // Arrange: insert multiple notes
    await notesRepo.insert(title: 'Note 1', body: 'body 1');
    await notesRepo.insert(title: 'Note 2', body: 'body 2');

    // Act: retrieve all notes
    final notes = await notesRepo.findAll();

    // Assert: we should get exactly 2 notes
    expect(notes.length, equals(2));
    final titles = notes.map((n) => n.title).toSet();
    expect(titles, containsAll(['Note 1', 'Note 2']));
  });

  // Test: findById returns correct note
  test('findById returns note by id', () async {
    // Arrange: insert a note
    await notesRepo.insert(title: 'Single Note', body: 'Single body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Act: retrieve the note by its id
    final fetchedNote = await notesRepo.findById(note.id);

    // Assert: the fetched note matches the inserted note
    expect(fetchedNote.id, equals(note.id));
    expect(fetchedNote.title, equals(note.title));
    expect(fetchedNote.body, equals(note.body));
  });

  // Test: findById throws for non-existent id
  test('findById throws exception for non-existent id', () async {
    // Act: try to fetch a note that doesn't exist
    expect(() => notesRepo.findById(9999), throwsA(isA<IdNotFoundException>()));
  });

  // Test: update note successfully
  test('update modifies existing note', () async {
    // Arrange: insert a note
    await notesRepo.insert(title: 'Old Title', body: 'Old body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Act: update the note
    final updatedNote = await notesRepo.update(
      id: note.id,
      title: 'Updated Title',
      body: 'Updated body',
    );

    // Retrieve updated note
    //final updatedNote = await notesRepo.findById(conn, note.id);

    // Assert: the note fields have been updated
    expect(updatedNote.title, equals('Updated Title'));
    expect(updatedNote.body, equals('Updated body'));
    expect(updatedNote.updatedAt.isAfter(note.updatedAt), isTrue);
  });

  // Test: update throws for non-existent note
  test('update throws exception for non-existent note', () async {
    // Act & Assert: should throw 'Note not found'
    expect(
      () => notesRepo.update(id: 9999, title: 'Title', body: 'body'),
      throwsA(predicate((e) => e is IdNotFoundException)),
    );
  });

  // Test: delete note successfully
  test('delete removes a note', () async {
    // Arrange: insert a note
    await notesRepo.insert(title: 'To Delete', body: 'Some body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Act: delete the note
    await notesRepo.delete(note.id);

    // Assert: note should no longer exist
    expect(
      () => notesRepo.findById(note.id),
      throwsA(isA<IdNotFoundException>()),
    );
  });

  // Test: delete throws for non-existent note
  test('delete throws exception for non-existent note', () async {
    // Act & Assert: should throw 'Note not found'
    expect(
      () => notesRepo.delete(9999),
      throwsA(predicate((e) => e is IdNotFoundException)),
    );
  });

  // Test: insert a note with empty title and body
  test('insert allows empty title and body', () async {
    // Arrange: empty strings
    const title = '';
    const body = '';

    // Act: insert note
    await notesRepo.insert(title: title, body: body);

    // Retrieve inserted note
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Assert: values match what we inserted
    expect(note.title, equals(title));
    expect(note.body, equals(body));
    expect(note.id, isA<int>());
    expect(note.createdAt, isA<DateTime>());
    expect(note.updatedAt, isA<DateTime>());
  });

  // Test: insert a note with very long title and body
  test('insert handles very long title and body', () async {
    // Arrange: create long strings
    final title = 'A' * 1000; // 1000 chars
    final body = 'B' * 5000; // 5000 chars

    // Act: insert note
    await notesRepo.insert(title: title, body: body);

    // Retrieve inserted note
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Assert: values match what we inserted
    expect(note.title, equals(title));
    expect(note.body, equals(body));
  });

  // Test: insert multiple notes quickly and retrieve
  test('insert multiple notes quickly and verify all are present', () async {
    // Arrange & Act: insert 5 notes
    for (int i = 1; i <= 5; i++) {
      await notesRepo.insert(title: 'Title $i', body: 'body $i');
    }

    // Retrieve all notes
    final notes = await notesRepo.findAll();

    // Assert: all notes are present in correct order
    expect(notes.length, equals(5));
    for (int i = 0; i < 5; i++) {
      expect(notes[i].title, equals('Title ${i + 1}'));
      expect(notes[i].body, equals('body ${i + 1}'));
    }
  });

  // Test: update a note with empty title and body
  test('update allows setting empty title and body', () async {
    // Arrange: insert a note
    await notesRepo.insert(title: 'Original', body: 'Original body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    // Act: update with empty strings
    await notesRepo.update(id: note.id, title: '', body: '');

    // Retrieve updated note
    final updatedNote = await notesRepo.findById(note.id);

    // Assert: note fields updated
    expect(updatedNote, isNotNull);
    expect(updatedNote.title, equals(''));
    expect(updatedNote.body, equals(''));
  });

  // Test: update only title
  test('updates only the title when body is null', () async {
    await notesRepo.insert(title: 'Original Title', body: 'Original body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;
    await notesRepo.update(id: note.id, title: 'New Title');

    final updatedNote = await notesRepo.findById(note.id);
    expect(updatedNote, isNotNull);
    expect(updatedNote.title, equals('New Title'));
    expect(updatedNote.body, equals('Original body')); // body stays the same
    expect(updatedNote.updatedAt.isAfter(note.updatedAt), isTrue);
  });

  // Test: update only body
  test('updates only the body when title is null', () async {
    await notesRepo.insert(title: 'Original Title', body: 'Original body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;
    await notesRepo.update(id: note.id, body: 'New body');

    final updatedNote = await notesRepo.findById(note.id);
    expect(updatedNote, isNotNull);
    expect(updatedNote.title, equals('Original Title')); // title stays the same
    expect(updatedNote.body, equals('New body'));
    expect(updatedNote.updatedAt.isAfter(note.updatedAt), isTrue);
  });

  // Test: updating nothing
  test('does nothing if both title and body are null', () async {
    await notesRepo.insert(title: 'Original Title', body: 'Original body');
    final notes = await notesRepo.findAll();
    expect(notes.length, equals(1));
    final note = notes.single;

    expect(
      () => notesRepo.update(id: note.id),
      throwsA(predicate((e) => e is NullUpdateException)),
    );

    final updatedNote = await notesRepo.findById(note.id);
    expect(updatedNote, isNotNull);
    expect(updatedNote.title, equals('Original Title'));
    expect(updatedNote.body, equals('Original body'));
  });

  // Test: delete all notes in sequence
  test('delete all notes one by one', () async {
    // Arrange: insert 3 notes
    for (int i = 1; i <= 3; i++) {
      await notesRepo.insert(title: 'Note $i', body: 'body $i');
    }
    var notes = await notesRepo.findAll();
    expect(notes.length, equals(3));

    // Act & Assert: delete notes one by one
    for (final note in notes) {
      await notesRepo.delete(note.id);
    }

    // Final check: no notes should remain
    final remainingNotes = await notesRepo.findAll();
    expect(remainingNotes, isEmpty);
  });

  test('insert defaults null title and body to empty strings', () async {
    await notesRepo.insert();

    final note = (await notesRepo.findAll()).single;

    expect(note.title, equals(''));
    expect(note.body, equals(''));
  });

  test('update returns the persisted updated note', () async {
    await notesRepo.insert(title: 'Old', body: 'Old body');
    final original = (await notesRepo.findAll()).single;

    final returned = await notesRepo.update(id: original.id, title: 'New');

    final fetched = await notesRepo.findById(original.id);

    expect(returned.id, equals(fetched.id));
    expect(returned.title, equals(fetched.title));
    expect(returned.body, equals(fetched.body));
    expect(returned.updatedAt, equals(fetched.updatedAt));
  });

  test('findById does not modify updatedAt', () async {
    await notesRepo.insert(title: 'Note', body: 'Body');
    final note = (await notesRepo.findAll()).single;

    final fetched = await notesRepo.findById(note.id);

    expect(fetched.updatedAt, equals(note.updatedAt));
  });

  test('delete removes only the specified note', () async {
    await notesRepo.insert(title: 'A', body: 'A');
    await notesRepo.insert(title: 'B', body: 'B');

    final notes = await notesRepo.findAll();
    final toDelete = notes.first;
    final toKeep = notes.last;

    await notesRepo.delete(toDelete.id);

    final remaining = await notesRepo.findAll();
    expect(remaining.length, equals(1));
    expect(remaining.single.id, equals(toKeep.id));
  });

  test('update with identical values still updates updatedAt', () async {
    await notesRepo.insert(title: 'Same', body: 'Same');
    final note = (await notesRepo.findAll()).single;

    final updated = await notesRepo.update(
      id: note.id,
      title: 'Same',
      body: 'Same',
    );

    expect(updated.updatedAt.isAfter(note.updatedAt), isTrue);
  });
}
