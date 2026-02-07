import 'package:notes_repo_core/util/exceptions.dart';
import 'package:notes_repo_core/classes/note_model.dart';
import 'package:postgres/postgres.dart';

class NoteRepository {
  final Connection conn;
  final String tablePath;

  NoteRepository(this.conn, this.tablePath);

  // Get all as List of Notes
  Future<List<Note>> findAll() async {
    final result = await conn.execute(
      Sql.named('SELECT * FROM $tablePath ORDER BY created_at DESC'),
    );

    return [for (final row in result) Note.fromMap(row.toColumnMap())];
  }

  // returns Note by id
  // throws IdNotFoundException for non-existant id
  Future<Note> findById(int id) async {
    return _oneOrThrow(
      'SELECT * FROM $tablePath WHERE id = @id',
      params: {'id': id},
      idForError: id,
    );
  }

  /// Adds new note
  /// Sets title and content to '' if null or not sent as parameters
  /// Sets parent_id to null
  /// Sets createdAt and updatedAt to now()
  /// Returns updated Note
  Future<Note> insert({String? title, String? body}) {
    return _oneOrThrow(
      '''
    INSERT INTO $tablePath (title, body)
    VALUES (@title, @body)
    RETURNING *
    ''',
      params: {'title': title ?? '', 'body': body ?? ''},
    );
  }

  /// Update the title of a note
  /// Sets updatedAt to clock_timestamp()
  /// throws IdNotFoundException for non-existant id
  /// Returns updated Note
  Future<Note> updateTitle({required int id, required String title}) async {
    return _update(id, 'title = @title', {'title': title});
  }

  /// Update the body of a note
  /// Sets updatedAt to clock_timestamp()
  /// throws IdNotFoundException for non-existant id
  /// Returns updated Note
  Future<Note> updateBody({required int id, required String body}) async {
    return _update(id, 'body = @body', {'body': body});
  }

  /// Update the parent_id of a note
  /// Sets updatedAt to clock_timestamp()
  /// throws IdNotFoundException for non-existant id
  /// Returns updated Note
  Future<Note> updateParent({required int id, int? parentId}) async {
    return _update(id, 'parent_id = @parentId', {'parentId': parentId});
  }

  // Delete a note
  // throws IdNotFoundException for non-existant id
  Future<void> delete(int id) async {
    await _oneOrThrow(
      'DELETE FROM $tablePath WHERE id = @id RETURNING *',
      params: {'id': id},
      idForError: id,
    );
  }

  Future<Note> _update(int id, String setClause, Map<String, Object?> params) {
    return _oneOrThrow(
      '''
    UPDATE $tablePath
    SET $setClause, updated_at = clock_timestamp()
    WHERE id = @id
    RETURNING *
    ''',
      params: {...params, 'id': id},
      idForError: id,
    );
  }

  Future<Note> _oneOrThrow(
    String sql, {
    required Map<String, Object?> params,
    int? idForError,
  }) async {
    final result = await conn.execute(Sql.named(sql), parameters: params);

    if (result.isEmpty && idForError != null) {
      throw IdNotFoundException(idForError);
    }

    return Note.fromMap(result.first.toColumnMap());
  }
}
