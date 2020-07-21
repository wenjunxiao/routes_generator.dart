import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<LoginPage> {
  String user;
  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Input the username',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  user = value;
                });
              },
            ),
            OutlineButton(
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                if (user == null || user.isEmpty) return;
                final fn = args['changeUser'] as ValueChanged;
                fn(user);
                if (args.containsKey('name')) {
                  Navigator.of(context).popAndPushNamed(
                    args['name'],
                    result: user,
                    arguments: args['arguments'],
                  );
                } else {
                  Navigator.of(context).pop(user);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
