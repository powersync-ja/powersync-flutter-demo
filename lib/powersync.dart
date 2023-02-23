import 'package:powersync/powersync.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

const _credentialsKey = 'app_credentials';

class DemoConnector extends DevConnector {
  @override
  Future<DevCredentials?> loadDevCredentials() async {
    return DevCredentials.fromOptionalString(
        await _storage.read(key: _credentialsKey));
  }

  @override
  Future<void> storeDevCredentials(DevCredentials credentials) async {
    await _storage.write(key: _credentialsKey, value: jsonEncode(credentials));
  }
}

final demoConnector = DemoConnector();

const schema = Schema([
  Table('assets', [
    Column.text('created_at'),
    Column.text('make'),
    Column.text('model'),
    Column.text('serial_number'),
    Column.integer('quantity'),
    Column.text('user_id'),
    Column.text('customer_id'),
  ]),
  Table('customers', [Column.text('name'), Column.text('email')])
]);

late PowerSyncDatabase db;

Future<String> getDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  return join(dir.path, 'powersync-demo.db');
}

Future<void> openDatabase() async {
  db = PowerSyncDatabase(schema: schema, path: await getDatabasePath());
  db.connect(connector: demoConnector);
}
