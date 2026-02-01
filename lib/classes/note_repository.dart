import 'package:notes_repo_core/util/exceptions.dart';
import 'package:notes_repo_core/classes/note_model.dart';
import 'package:postgres/postgres.dart';

class NoteRepository {
  final Connection conn;
  final String tablePath;

  NoteRepository(this.conn, this.tablePath);

  // Get all as List of Notes
  Future<List<Note>> findAll() async {
    // TODO: error wrong path
    final result = await conn.execute(
      Sql.named('SELECT * FROM $tablePath ORDER BY created_at DESC'),
    );

    return result.map((row) => Note.fromSql(row.toColumnMap())).toList();
  }

  // returns Note by id
  // throws IdNotFoundException for non-existant id
  Future<Note> findById(int id) async {
    final result = await conn.execute(
      Sql.named('SELECT * FROM $tablePath WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) throw IdNotFoundException(id);
    return Note.fromSql(result.first.toColumnMap());
  }

  /// Adds new note
  /// Sets title and content to '' if null or not sent as parameters
  /// Sets createdAt and updatedAt to now()
  /// Returns updated Note
  Future<Note> insert({String? title, String? body}) async {
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO $tablePath (title, body)
        VALUES (@title, @body)
        RETURNING *
        '''),
      parameters: {'title': title ?? '', 'body': body ?? ''},
    );

    return Note.fromSql(result.first.toColumnMap());
  }

  /// Update title and/or content of a note
  /// Sets updatedAt to clock_timestamp()
  /// throws IdNotFoundException for non-existant id
  /// throws NullUpdateExeption if nothing is updated
  /// Returns updated Note
  Future<Note> update({required int id, String? title, String? body}) async {
    // Collect fields to update
    final fields = <String>[];
    final parameters = <String, dynamic>{'id': id};

    if (title != null) {
      fields.add('title = @title');
      parameters['title'] = title;
    }

    if (body != null) {
      fields.add('body = @body');
      parameters['body'] = body;
    }

    if (fields.isEmpty) {
      throw NullUpdateException();
    }

    // Always update the timestamp
    fields.add('updated_at = clock_timestamp()');

    final sql =
        '''
      UPDATE $tablePath
      SET ${fields.join(', ')}
      WHERE id = @id
      RETURNING *
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: parameters);

    if (result.isEmpty) {
      throw IdNotFoundException(id);
    }

    return Note.fromSql(result.first.toColumnMap());
  }

  Future<Note> updateTitle({required int id, required String title}) async {
    final result = await conn.execute(
      Sql.named('''
      UPDATE $tablePath
      SET title = @title, 'updated_at = clock_timestamp()'
      WHERE id = @id
      RETURNING *
    '''),
      parameters: {'title': title},
    );

    if (result.isEmpty) {
      throw IdNotFoundException(id);
    }

    return Note.fromSql(result.first.toColumnMap());
  }

  Future<Note> updateBody({required int id, required String body}) async {
    final result = await conn.execute(
      Sql.named('''
      UPDATE $tablePath
      SET body = @body, 'updated_at = clock_timestamp()'
      WHERE id = @id
      RETURNING *
    '''),
      parameters: {'body': body},
    );

    if (result.isEmpty) {
      throw IdNotFoundException(id);
    }

    return Note.fromSql(result.first.toColumnMap());
  }

  Future<Note> updateParent({required int id, int? parentId}) async {
    final result = await conn.execute(
      Sql.named('''
      UPDATE $tablePath
      SET parent_id = @parentId, 'updated_at = clock_timestamp()'
      WHERE id = @id
      RETURNING *
    '''),
      parameters: {'parentId': parentId},
    );

    if (result.isEmpty) {
      throw IdNotFoundException(id);
    }

    return Note.fromSql(result.first.toColumnMap());
  }

  // Delete a note
  // throws IdNotFoundException for non-existant id
  Future<void> delete(int id) async {
    final result = await conn.execute(
      Sql.named('DELETE FROM $tablePath WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.affectedRows == 0) {
      throw IdNotFoundException(id);
    }
  }
}
