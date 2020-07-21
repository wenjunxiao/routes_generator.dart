import 'package:flutter/material.dart';

class HostsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HostsState();
  }
}

class _HostsState extends State<HostsPage> {
  String host;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hosts'),
      ),
      body: Center(
          child: Column(
        children: [
          ListTile(
            title: Text(
              'Switch host',
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              'This is hosts page, you can switch host here',
              style: TextStyle(fontSize: 16),
            ),
          ),
          RadioListTile(
            title: Text(
              'Development',
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              'This is environment for developers',
              style: TextStyle(fontSize: 16),
            ),
            value: 'dev',
            onChanged: (value) {
              setState(() {
                host = value;
              });
            },
            groupValue: host,
          ),
          RadioListTile(
            title: Text(
              'Test',
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              'This is environment for tester',
              style: TextStyle(fontSize: 16),
            ),
            value: 'test',
            onChanged: (value) {
              setState(() {
                host = value;
              });
            },
            groupValue: host,
          ),
          RadioListTile(
            title: Text(
              'Beta',
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              'This is beta environment',
              style: TextStyle(fontSize: 16),
            ),
            value: 'beta',
            onChanged: (value) {
              setState(() {
                host = value;
              });
            },
            groupValue: host,
          ),
        ],
      )),
    );
  }
}
