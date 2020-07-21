import 'package:flutter/material.dart';
import '../pages/widgets/widgets.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.user, this.changeUser}) : super(key: key);
  final String user;
  final ValueChanged changeUser;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.user == null
            ? Text('Not logged')
            : Text('Welcome ${widget.user}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlineButton(
              child: Text(
                'Protected',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/protected');
              },
            ),
            OutlineButton(
              child: Text(
                'Public',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/public');
              },
            ),
            OutlineButton(
              child: Text(
                'Dynamic',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/dynamic/home');
              },
            ),
            OutlineButton(
              child: Text(
                'DynamicId',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/dynamic/id');
              },
            ),
            OutlineButton(
              child: Text(
                'DynamicPublic',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/dynamic/public/id');
              },
            ),
            OutlineButton(
              child: Text(
                'DynamicProtected',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/dynamic/protected/id');
              },
            ),
            OutlineButton(
              child: Text(
                'DevHosts',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/hosts');
              },
            ),
            OutlineButton(
              child: Text(
                'NotDynamicPage',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/_not_dynamic');
              },
            ),
            OutlineButton(
              child: Text(
                'DevWidgetsPage',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/widgets/widget.g');
              },
            ),
            WidgetsComponent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.user == null) {
            Navigator.of(context).pushNamed('/login');
          } else {
            widget.changeUser(null);
          }
        },
        tooltip: widget.user == null ? 'Login' : 'Logout',
        child: widget.user == null ? Text('Login') : Text('Logout'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
