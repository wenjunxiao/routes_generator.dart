import 'package:flutter/material.dart';

import 'screen/app.dart';
import 'routes.dart';

void main() {
  runApp(MyApp(
    routes: routes,
    routesDynamic: routesDynamic,
    authRoutes: authRoutes,
    authRoutesDynamic: authRoutesDynamic,
  ));
}
