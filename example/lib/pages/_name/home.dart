import 'package:flutter/material.dart';

class DynamicPage extends StatelessWidget {
  final String name;
  const DynamicPage({Key key, this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DynamicPage'),
      ),
      body: Center(
        child: Text(
          'This is dynamic name page, name is $name.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
