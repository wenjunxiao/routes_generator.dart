import 'package:flutter/material.dart';

import '../routes.dart';

@authRequired
class ProtectedPage extends StatelessWidget {
  final String user;

  const ProtectedPage({Key key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: user == null
            ? Text('ProtectedPage(Unauthorized access)')
            : Text('ProtectedPage($user)'),
      ),
      body: Center(
        child: Text('This is protected page, you must log in to access'),
      ),
    );
  }
}
