import 'dart:async';

import 'package:flutter/material.dart';
import './login_page.dart';
import './powersync.dart';
import './query_widget.dart';
import 'package:faker_dart/faker_dart.dart';
import 'package:powersync/powersync.dart';
import 'package:logging/logging.dart';

void main() async {
  // Log info from PowerSync
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '[${record.loggerName}] ${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print(record.error);
    }
    if (record.stackTrace != null) {
      print(record.stackTrace);
    }
  });

  WidgetsFlutterBinding
      .ensureInitialized(); //required to get sqlite filepath from path_provider before UI has initialized
  await openDatabase();
  final loggedIn = await demoConnector.hasCredentials();
  runApp(MyApp(loggedIn: loggedIn));
}

const defaultQuery =
    'SELECT time(), * FROM assets ORDER BY created_at DESC NULLS FIRST LIMIT 50';

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PowerSync Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: loggedIn
            ? const MyHomePage(title: 'PowerSync Flutter Demo')
            : const LoginPage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SyncStatus _connectionState;
  StreamSubscription<SyncStatus>? _subscription;

  @override
  void initState() {
    _connectionState = db.currentStatus;
    _subscription = db.statusStream.listen((event) {
      setState(() {
        _connectionState = db.currentStatus;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  void _add() async {
    final faker = Faker.instance;

    final userId = await demoConnector.getUserId();

    await db.execute(
        'INSERT INTO assets(id, make, model, serial_number, quantity, customer_id, user_id) VALUES (uuid(), ?, ?, ?, 1, (SELECT id FROM customers ORDER BY RANDOM() LIMIT 1), ?)',
        [
          faker.company.companyName(),
          faker.commerce.product(),
          faker.datatype.hexaDecimal(length: 8).substring(2).toUpperCase(),
          userId
        ]);
  }

  @override
  Widget build(BuildContext context) {
    const connectedIcon = IconButton(
      icon: Icon(Icons.wifi),
      tooltip: 'Connected',
      onPressed: null,
    );
    const disconnectedIcon = IconButton(
      icon: Icon(Icons.wifi_off),
      tooltip: 'Not connected',
      onPressed: null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          _connectionState.connected ? connectedIcon : disconnectedIcon
        ],
      ),
      body: const Center(child: QueryWidget(defaultQuery: defaultQuery)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(''),
            ),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                var navigator = Navigator.of(context);
                await logout();

                navigator.pushReplacement(MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
