import 'package:flutter/material.dart';

import 'screen/app.dart';
import 'routes.dart';
import 'dev/routes.dart' as d;

void main() {
  runApp(MyApp(
    routes: {...routes, ...d.devRoutes},
    authRoutes: {...authRoutes, ...d.authRoutes},
    routesDynamic: [...routesDynamic],
    authRoutesDynamic: [...authRoutesDynamic],
  ));
}
