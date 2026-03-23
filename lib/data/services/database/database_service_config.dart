import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseServiceConfig {
  static const String _exampleDbName = 'example_db_name';
  final String defaultDbName;

  const DatabaseServiceConfig({required this.defaultDbName});

  String get dbName {
    final envDb = dotenv.isInitialized ? dotenv.env['ROBLE_DB_NAME'] : null;
    if (envDb != null && envDb.isNotEmpty) return envDb;
    final fromDefine = const String.fromEnvironment(
      'ROBLE_DB_NAME',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    if (defaultDbName.isNotEmpty) return defaultDbName;
    return _exampleDbName;
  }

  String get authBase {
    final envUrl =
        dotenv.isInitialized ? dotenv.env['ROBLE_AUTH_BASE_URL'] : null;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'https://roble-api.openlab.uninorte.edu.co/auth';
  }

  String get dataBase {
    final envUrl =
        dotenv.isInitialized ? dotenv.env['ROBLE_DATA_BASE_URL'] : null;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'https://roble-api.openlab.uninorte.edu.co/database';
  }

  String get studentDefaultPassword {
    final envPwd = dotenv.isInitialized
        ? dotenv.env['ROBLE_STUDENT_DEFAULT_PASSWORD']
        : null;
    if (envPwd != null && envPwd.isNotEmpty) return envPwd;
    return const String.fromEnvironment(
      'ROBLE_STUDENT_DEFAULT_PASSWORD',
      defaultValue: 'Password123!',
    );
  }

  String _trimSlashes(String value) =>
      value.trim().replaceAll(RegExp(r'/+$'), '');

  String buildServiceUrl(String rawBase, String segment) {
    final base = _trimSlashes(rawBase);
    final db = dbName.trim();
    final lower = base.toLowerCase();
    final segmentLower = segment.toLowerCase();
    final dbLower = db.toLowerCase();

    final effectiveDb = db.isEmpty ? defaultDbName : db;

    if (lower.endsWith('/$segmentLower/$dbLower') ||
        lower.endsWith('/$segmentLower/${defaultDbName.toLowerCase()}')) {
      return base;
    }

    if (lower.endsWith('/$segmentLower')) {
      return '$base/$effectiveDb';
    }

    return '$base/$segment/$effectiveDb';
  }
}
