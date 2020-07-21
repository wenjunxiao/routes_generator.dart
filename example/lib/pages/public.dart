import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PublicPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: args['user'] == null
            ? Text('PublicPage')
            : Text('PublicPage(${args['user']})'),
      ),
      body: Center(
        child: Text('This is public page, you can visit at will'),
      ),
    );
  }
}
