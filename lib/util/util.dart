import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Returns the request as a map if possible
/// Returns null if not possible
/// Returns null if the request contains keys not mentioned in allowedKeys
Future<Map<String, dynamic>?> decodeRequest(
  Request req, {
  Set<String>? allowedKeys,
}) async {
  final body = await req.readAsString();
  Map<String, dynamic>? decoded;
  try {
    decoded = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
  if (allowedKeys != null &&
      decoded.keys.any((k) => !allowedKeys.contains(k))) {
    return null;
  }

  return decoded;
}

Response jsonResponse(Object body) {
  return Response.ok(
    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}

/// returns string as int if possible
/// returns badRequest('Invalid id') otherwise
ParseResult<int> parseId(String rawId) {
  final parsed = int.tryParse(rawId);

  if (parsed == null) return ParseResult.badRequest('Invalid id');

  return ParseResult.ok(parsed);
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
