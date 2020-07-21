import 'package:flutter/material.dart';

class WidgetsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WidgetsPage'),
      ),
      body: Center(
        child: Text(
          'This is a page for wigets',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
