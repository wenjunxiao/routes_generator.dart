import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.user, this.changeUser}) : super(key: key);
  final String user;
  final ValueChanged changeUser;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
