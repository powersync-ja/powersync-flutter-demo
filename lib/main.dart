import 'package:flutter/material.dart';
import './login_page.dart';
import './powersync.dart';
import './query_widget.dart';
import 'package:faker_dart/faker_dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(child: QueryWidget(defaultQuery: defaultQuery)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
