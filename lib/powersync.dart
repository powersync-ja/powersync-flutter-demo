// This file performs setup of the PowerSync database
import 'package:powersync/powersync.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:convert';

/// Override DevConnector to provide store credentials in persistent storage.
class DemoConnector extends DevConnector {
  PowerSyncDatabase db;

  DemoConnector(this.db);

  @override
  Future<DevCredentials?> loadDevCredentials() async {
    final row = await db.getOptional(
        'SELECT data FROM credentials WHERE id = ?', ['dev_credentials']);
    if (row == null) {
      return null;
    }
    return DevCredentials.fromString(row['data']);
  }

  @override
  Future<void> storeDevCredentials(DevCredentials credentials) async {
    await db.execute(
        'INSERT OR REPLACE INTO credentials(id, data) VALUES(?, ?)',
        ['dev_credentials', jsonEncode(credentials)]);
  }
}

late final DemoConnector demoConnector;

const schema = Schema(([
  Table('assets', [
    Column.text('created_at'),
    Column.text('make'),
    Column.text('model'),
    Column.text('serial_number'),
    Column.integer('quantity'),
    Column.text('user_id'),
    Column.text('customer_id'),
  ], indexes: [
    Index('makemodel', [IndexedColumn('make'), IndexedColumn('model')])
  ]),
  Table('customers', [Column.text('name'), Column.text('email')]),

  // Local-only table to store session credentials.
  // Note: This stores the credentials in plaintext, used for simplicity in the demo.
  // flutter_secure_storage may be a better option for storing sensitive credentials.
  Table.localOnly(
    'credentials',
    [Column.text('data')],
  )
]));

/// Global reference to the database
late final PowerSyncDatabase db;

Future<String> getDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  return join(dir.path, 'powersync-demo.db');
}

Future<void> openDatabase() async {
  // Open the local database
  db = PowerSyncDatabase(schema: schema, path: await getDatabasePath());
  await db.initialize();

  demoConnector = DemoConnector(db);

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

/// Clear database and log out
Future<void> logout() async {
  await demoConnector.clearDevToken();
  await db.disconnectedAndClear();
}
