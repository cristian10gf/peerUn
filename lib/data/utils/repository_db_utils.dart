import 'package:example/data/services/database/database_service.dart';

Future<bool> tableExists(DatabaseService db, String tableName) async {
  try {
    await db.robleRead(tableName);
    return true;
  } catch (_) {
    return false;
  }
}
