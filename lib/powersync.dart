//This file performs setup of the PowerSync database
import 'package:powersync/powersync.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

const _credentialsKey = 'app_credentials';

/// Override DevConnector to provide store credentials in persistent storage.
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

/// Global reference to the database
late PowerSyncDatabase db;

Future<String> getDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  return join(dir.path, 'powersync-demo.db');
}

Future<void> openDatabase() async {
  // Open the local database
  db = PowerSyncDatabase(schema: schema, path: await getDatabasePath());

  if (await demoConnector.hasCredentials()) {
    // If the user is already logged in, connect immediately.
    // Otherwise, connect once logged in.
    db.connect(connector: demoConnector);
  }
}

/// Log in and connect to the PowerSync service.
Future<void> login(
    {required String endpoint,
    required String user,
    required String password}) async {
  await demoConnector.devLogin(
      endpoint: endpoint, user: user, password: password);
  db.connect(connector: demoConnector);
}

/// Clear database and lg out
Future<void> logout() async {
  await db.disconnectedAndClear();
  await demoConnector.clearDevToken();
}
