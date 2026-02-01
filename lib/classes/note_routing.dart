import 'dart:convert';

import 'package:notes_repo_core/util/exceptions.dart';
import 'package:notes_repo_core/classes/note_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class NotesRouting {
  late NoteRepository notesRepo;

  NotesRouting(Connection conn, String tablePath) {
    notesRepo = NoteRepository(conn, tablePath);
  }

  void register(Router router) {
    // GET /notes
    router.get('/notes/', getAll);

    // POST /notes
    router.post('/notes/', create);

    // PUT /notes/<id>
    //router.put('/notes/<id>/', update);

    // PUT /notes/<id>
    router.put('/notes/<id>/title/', updateTitle);

    // PUT /notes/<id>
    router.put('/notes/<id>/body/', updateContent);

    // PUT /notes/<id>
    router.put('/notes/<id>/parent/', updateParentId);

    // DELETE /notes/<id>
    router.delete('/notes/<id>/', delete);
  }

  Response _jsonResponse(Object body) {
    return Response.ok(
      jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// returns string as int if possible
  /// returns badRequest('Invalid id') otherwise
  ParseResult<int> _parseId(String rawId) {
    final parsed = int.tryParse(rawId);

    if (parsed == null) {
      return ParseResult.badRequest('Invalid id');
    }

    return ParseResult.ok(parsed);
  }

  /// Returns the request as a map if possible
  /// Returns null if not possible
  /// Returns null if the request contains keys not mentioned in allowedKeys
  Future<Map<String, dynamic>?> _decodeRequest(
    Request req, {
    Set<String>? allowedKeys,
  }) async {
    late final Map<String, dynamic> payload;
    try {
      final body = await req.readAsString();
      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      payload = decoded;
    } catch (_) {
      return null;
    }

    if (allowedKeys == null) {
      return payload;
    }

    //if allowed keys is used
    final unexpectedKeys = payload.keys.where((k) => !allowedKeys.contains(k));

    if (unexpectedKeys.isNotEmpty) {
      return null;
    }

    return payload;
  }

  /// returns all notes as a list of json with the keys "id", "title", "body", "created_at", "updated_at"
  Future<Response> getAll(Request req) async {
    final notes = await notesRepo.findAll();
    return _jsonResponse(notes.map((n) => n.toJson()).toList());
  }

  /// return the note with the specific id as json with the keys "id", "title", "body", "created_at", "updated_at"
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> getById(Request req, String id) async {
    final parsedId = _parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final note = await notesRepo.findById(parsedId.value!);
      return _jsonResponse(note.toJson());
    } on IdNotFoundException {
      return _jsonResponse({'status': 'not_found'});
    }
  }

  /// returns created note as json
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title and body
  Future<Response> create(Request req) async {
    final payload = await _decodeRequest(req, allowedKeys: {'title'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    await notesRepo.insert(title: payload['title']);
    final notes = await notesRepo.findAll();
    return _jsonResponse(notes.map((n) => n.toJson()).toList());
  }

  /// returns the updated note as json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'null_update'}) if neither title nor body was given
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title and body
  // Future<Response> update(Request req, String id) async {
  //   final parsedId = _parseId(id);
  //   if (!parsedId.isOk) return parsedId.error!;

  //   final payload = await _decodeRequest(req, allowedKeys: {'title', 'body'});
  //   if (payload == null) {
  //     return Response.badRequest(body: 'Request not formatted correctly');
  //   }

  //   try {
  //     await notesRepo.update(
  //       id: parsedId.value!,
  //       title: payload['title'],
  //       body: payload['body'],
  //     );
  //     final notes = await notesRepo.findAll();
  //     return _jsonResponse(notes.map((n) => n.toJson()).toList());
  //   } on IdNotFoundException {
  //     return _jsonResponse({'status': 'not_found'});
  //   } on NullUpdateException {
  //     return _jsonResponse({'status': 'null_update'});
  //   }
  // }

  Future<Response> updateTitle(Request req, String id) async {
    final parsedId = _parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await _decodeRequest(req, allowedKeys: {'title'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    try {
      await notesRepo.updateTitle(id: parsedId.value!, title: payload['title']);
      final notes = await notesRepo.findAll();
      return _jsonResponse(notes.map((n) => n.toJson()).toList());
    } on IdNotFoundException {
      return _jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return _jsonResponse({'status': 'null_update'});
    }
  }

  Future<Response> updateContent(Request req, String id) async {
    final parsedId = _parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await _decodeRequest(req, allowedKeys: {'title', 'body'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    try {
      await notesRepo.updateBody(id: parsedId.value!, body: payload['body']);
      final notes = await notesRepo.findAll();
      return _jsonResponse(notes.map((n) => n.toJson()).toList());
    } on IdNotFoundException {
      return _jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return _jsonResponse({'status': 'null_update'});
    }
  }

  Future<Response> updateParentId(Request req, String id) async {
    final parsedId = _parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await _decodeRequest(req, allowedKeys: {'parentId'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    try {
      await notesRepo.updateParent(
        id: parsedId.value!,
        parentId: payload['parentId'],
      );
      final notes = await notesRepo.findAll();
      return _jsonResponse(notes.map((n) => n.toJson()).toList());
    } on IdNotFoundException {
      return _jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return _jsonResponse({'status': 'null_update'});
    }
  }

  /// returns jsonResponse({'status': 'deleted'})
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> delete(Request req, String id) async {
    final parsedId = _parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      await notesRepo.delete(parsedId.value!);
      final notes = await notesRepo.findAll();
      return _jsonResponse(notes.map((n) => n.toJson()).toList());
    } on IdNotFoundException {
      return _jsonResponse({'status': 'not_found'});
    }
  }
}

class ParseResult<T> {
  final T? value;
  final Response? error;

  const ParseResult._(this.value, this.error);

  bool get isOk => error == null;

  static ParseResult<T> ok<T>(T value) => ParseResult._(value, null);

  static ParseResult<T> badRequest<T>(String message) =>
      ParseResult._(null, Response.badRequest(body: message));
}
