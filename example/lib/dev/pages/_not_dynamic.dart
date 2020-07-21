import 'package:flutter/material.dart';

class NotDynamicPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = ModalRoute.of(context).settings;
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Dynamic Page'),
      ),
      body: Center(
        child: Text(
          'not dynamic page, url is ${settings.name}',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
