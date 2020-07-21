import 'package:flutter/material.dart';

import 'home.dart';

class MyApp extends StatefulWidget {
  final Map<String, WidgetBuilder> routes;
  final Map<String, WidgetBuilder> authRoutes;
  final List<WidgetBuilder Function(String)> routesDynamic;
  final List<WidgetBuilder Function(String)> authRoutesDynamic;
  const MyApp(
      {Key key,
      this.routes,
      this.authRoutes,
      this.routesDynamic,
      this.authRoutesDynamic})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  String user;

  void _handleChange(dynamic user) {
    setState(() {
      this.user = user as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routes = widget.routes ?? {};
    final authRoutes = widget.authRoutes ?? {};
    final routesDynamic = widget.routesDynamic ?? [];
    final authRoutesDynamic = widget.authRoutesDynamic ?? [];
    return MaterialApp(
      title: 'Routes Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: (RouteSettings settings) {
        print('onGenerateRoute.routes => ${settings.name} ${routes.keys}');
        WidgetBuilder builder = routes[settings.name];
        if (builder == null) {
          print(
              'onGenerateRoute.authRoutes => ${settings.name} ${authRoutes.keys}');
          builder = authRoutes[settings.name];
          if (builder != null && user == null) {
            print('onGenerateRoute.authRoutes.login => ${settings.name}');
            builder = routes['/login'];
            settings = RouteSettings(
              name: '/login',
              arguments: {
                'name': settings.name,
                'arguments': settings.arguments
              },
            );
          }
        }
        if (builder == null) {
          print('onGenerateRoute.routesDynamic => ${settings.name}');
          for (final matcher in routesDynamic) {
            builder = matcher(settings.name);
            if (builder != null) break;
          }
        }
        if (builder == null) {
          print('onGenerateRoute.authRoutesDynamic => ${settings.name}');
          for (final matcher in authRoutesDynamic) {
            builder = matcher(settings.name);
            if (builder != null) {
              if (user == null) {
                builder = routes['/login'];
                settings = RouteSettings(
                  name: '/login',
                  arguments: {
                    'name': settings.name,
                    'arguments': settings.arguments
                  },
                );
              }
              break;
            }
          }
        }
        if (builder == null) return null;
        Map arguments = settings.arguments ?? {};
        print('MaterialPageRoute => ${settings.name} ${settings.arguments}');
        arguments['user'] = user;
        arguments['changeUser'] = _handleChange;
        return MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
            arguments: arguments,
          ),
          builder: builder,
        );
      },
      home: MyHomePage(
        user: user,
        changeUser: _handleChange,
      ),
    );
  }
}
