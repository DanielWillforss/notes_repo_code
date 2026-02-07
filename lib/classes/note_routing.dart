import 'package:notes_repo_core/util/exceptions.dart';
import 'package:notes_repo_core/classes/note_repository.dart';
import 'package:notes_repo_core/util/util.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class NotesRouting {
  late NoteRepository notesRepo;

  NotesRouting(Connection conn, String tablePath) {
    notesRepo = NoteRepository(conn, tablePath);
  }

  static String _normalizeBasePath(String path) {
    if (path.isEmpty) return '';
    if (!path.startsWith('/')) path = '/$path';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  void register(Router router, {String basepath = ''}) {
    final notesRouter = Router();

    // GET /notes/
    notesRouter.get('/', getAll);

    // POST /notes/
    notesRouter.post('/', create);

    // PUT /notes/<id>/title/
    notesRouter.put('/<id>/title/', updateTitle);

    // PUT /notes/<id>/body/
    notesRouter.put('/<id>/body/', updateContent);

    // PUT /notes/<id>/parent/
    notesRouter.put('/<id>/parent/', updateParentId);

    // DELETE /notes/<id>/
    notesRouter.delete('/<id>/', delete);

    router.mount('${_normalizeBasePath(basepath)}/notes', notesRouter.call);
  }

  /// returns all notes as a list of json with the keys "id", "title", "body", "parent_id", "created_at", "updated_at"
  Future<Response> getAll(Request req) async {
    return _allNotesResponse();
  }

  /// return the note with the specific id as json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> getById(Request req) async {
    final id = req.params['id'];
    final parsedId = parseId(id!);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final note = await notesRepo.findById(parsedId.value!);
      return jsonResponse(note.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// creates new note with specific title
  /// returns all notes as a list of json
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title
  Future<Response> create(Request req) async {
    final payload = await decodeRequest(req, allowedKeys: {'title'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    await notesRepo.insert(title: payload['title']);
    return _allNotesResponse();
  }

  /// returns all notes as a list of json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns badRequest(body: 'null_update') if title was not given
  /// returns badRequest(body: 'not_found') if the id was not found
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title
  Future<Response> updateTitle(Request req) {
    return _updateField(
      req,
      field: 'title',
      updater: (id, value) => notesRepo.updateTitle(id: id, title: value),
    );
  }

  /// returns all notes as a list of json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns badRequest(body: 'null_update') if body was not given
  /// returns badRequest(body: 'not_found') if the id was not found
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than body
  Future<Response> updateContent(Request req) {
    return _updateField(
      req,
      field: 'body',
      updater: (id, value) => notesRepo.updateBody(id: id, body: value),
    );
  }

  /// returns all notes as a list of json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns badRequest(body: 'null_update') if parentId was not given
  /// returns badRequest(body: 'not_found') if the id was not found
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than parentId
  Future<Response> updateParentId(Request req) {
    return _updateField(
      req,
      field: 'parentId',
      updater: (id, value) => notesRepo.updateParent(id: id, parentId: value),
    );
  }

  /// returns all notes as a list of json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns badRequest(body: 'not_found') if the id was not found
  Future<Response> delete(Request req) async {
    final id = req.params['id'];
    final parsedId = parseId(id!);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      await notesRepo.delete(parsedId.value!);
      return _allNotesResponse();
    } on IdNotFoundException {
      return Response.badRequest(body: 'not_found');
    }
  }

  Future<Response> _allNotesResponse() async {
    final notes = await notesRepo.findAll();
    return jsonResponse(notes.map((n) => n.toJson()).toList());
  }

  Future<Response> _updateField(
    Request req, {
    required String field,
    required Future<void> Function(int id, dynamic value) updater,
  }) async {
    final parsedId = parseId(req.params['id']!);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await decodeRequest(req, allowedKeys: {field});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    final value = payload[field];
    // if (value == null) {
    //   return Response.badRequest(body: 'null_update');
    // }

    try {
      await updater(parsedId.value!, value);
      return _allNotesResponse();
    } on IdNotFoundException {
      return Response.badRequest(body: 'not_found');
    }
  }
}
