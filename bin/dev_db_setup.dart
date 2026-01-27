// bin/dev_db_setup.dart
import 'dart:io';

void main(List<String> args) async {
  final setupPostgres = File(
    Platform.script.resolve('../lib/sql/setup_postgres.sh').toFilePath(),
  );
  final makeDevDb = File(
    Platform.script.resolve('../lib/sql/make_dev_db.sh').toFilePath(),
  );

  if (!setupPostgres.existsSync() || !makeDevDb.existsSync()) {
    stderr.writeln('shell scripts not found');
    exit(1);
  }

  final result1 = await Process.run('bash', [
    setupPostgres.path,
  ], runInShell: true);

  final result2 = await Process.run('bash', [makeDevDb.path], runInShell: true);

  stdout.write(result1.stdout);
  stderr.write(result1.stderr);
  stdout.write(result2.stdout);
  stderr.write(result2.stderr);
}
