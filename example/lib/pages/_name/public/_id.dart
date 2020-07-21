import 'package:flutter/material.dart';

class DynamicPublicPage extends StatelessWidget {
  final String name;
  final String id;

  const DynamicPublicPage({Key key, this.name, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DynamicPublicPage'),
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
