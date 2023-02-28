import 'dart:io';

import 'package:flutter/material.dart';
import 'package:powersync_flutter_demo/main.dart';

import './powersync.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _MyLoginPageState();
}

const Map<String, String> users = {
  '10000000-0000-0000-a1a1-000000000001': 'User 1',
  '20000000-0000-0000-a1a1-000000000002': 'User 2',
  '30000000-0000-0000-a1a1-000000000003': 'User 3'
};

class _MyLoginPageState extends State<LoginPage> {
  late String _username = users.keys.first;
  late TextEditingController _passwordController;
  late TextEditingController _endpointController;
  String? _error;
  late bool _busy;

  @override
  void initState() {
    super.initState();

    _busy = false;
    _username = users.keys.first;
    _passwordController = TextEditingController(text: '');
    _endpointController = TextEditingController(text: '');

    demoConnector.getEndpoint().then((endpoint) {
      setState(() {
        if (endpoint != null && _endpointController.text == '') {
          _endpointController.text = endpoint;
        }
      });
    }, onError: (_) {});
  }

  void _login(BuildContext context) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await login(
          endpoint: _endpointController.text,
          user: _username,
          password: _passwordController.text);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              const MyHomePage(title: 'PowerSync Flutter Demo'),
        ));
      }
    } on HttpException catch (e) {
      _error = e.message;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      _error = e.toString();
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("PowerSync Flutter Demo"),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Demo Login'),
                      const SizedBox(height: 35),
                      TextFormField(
                        controller: _endpointController,
                        decoration:
                            const InputDecoration(labelText: "Demo Endpoint"),
                        enabled: !_busy,
                        onFieldSubmitted: _busy
                            ? null
                            : (String value) {
                                _login(context);
                              },
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        value: _username,
                        onChanged: _busy
                            ? null
                            : (String? value) {
                                setState(() {
                                  _username = value!;
                                });
                              },
                        underline: Container(
                          height: 1,
                          color: Colors.grey,
                        ),
                        items: users.entries.map((var value) {
                          return DropdownMenuItem<String>(
                            value: value.key,
                            child: Text(value.value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelText: "Password", errorText: _error),
                        enabled: !_busy,
                        onFieldSubmitted: _busy
                            ? null
                            : (String value) {
                                _login(context);
                              },
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _login(context);
                              },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
