import 'package:flutter/material.dart';
import '../../../routes.dart';

@authRequired
class DynamicProtectedPage extends StatelessWidget {
  final String name;
  final String id;
  final String user;

  const DynamicProtectedPage({Key key, this.name, this.id, this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DynamicProtectedPage($user)'),
      ),
      body: Center(
        child: Text(
          'This is dynamic name and dynamic id page, name is $name and id is $id',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
