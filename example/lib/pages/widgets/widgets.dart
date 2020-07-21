import 'package:flutter/material.dart';

class WidgetsComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Text(
        'This is just a widget component and cannot be used for routing',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
