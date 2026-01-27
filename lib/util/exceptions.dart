class IdNotFoundException implements Exception {
  final int id;

  IdNotFoundException(this.id);

  @override
  String toString() => 'Entry with id $id not found';
}

class NullUpdateException implements Exception {
  @override
  String toString() => 'Empty update not allowed';
}
