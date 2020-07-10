# routes_generator

Provides [source_gen](https://github.com/dart-lang/source_gen) `Generator` to generator `routes` for `MaterialApp` of `flutter`.

Non-intrusive, convention over configuration, only need to install and build.

## Convention

* The `routes.dart` file used to export routes and related functions to `MaterialApp`.
* The `pages` directory relatived to `routes.dart` contains your app views and routes,
 generator reads all `.dart` files inside this directory and generate routes map into
 `routes.map.dart`
* The above two conventions apply to any directory of the project.

## Usage

  Add `dev_dependencies`.
```yaml
dev_dependencies:
  routes_generator: any
```

  Run code generation.
```bash
$ flutter pub run build_runner build
```

  Import through `routes.dart` or direct import `routes.map.dart`.
```dart
// routes.dart
import 'package:flutter/widgets.dart';
import 'routes.map.dart' as p;

Map<String, WidgetBuilder> routes = p.routes;
```

  If there are multiple `routes.map.dart`, they need to be merged and used.
```dart
import 'routes.map.dart' as p;
import 'dev/routes.map.dart' as d;

class MyApp extends StatelessWidget {

  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{...p.routes, ...d.routes}
    );
  }
}
```


## Configuration

  If your project structure does not conform to the convention,
  or want to split the route according to the environment, such as,
  the development app provides more pages and features, 
  which is very useful when switching between multiple development environments. Configuration is also provided.

 The following structure is typical and conforms to the convention.
```bash
├── lib
│   ├── dev
│   │   ├── drawer.dart
│   │   ├── pages
│   │   │   └── hosts.dart
│   │   ├── routes.dart
│   │   └── routes.map.dart
│   ├── main.dart
│   ├── main_dev.dart
│   ├── pages
│   │   ├── home.dart
│   │   ├── user
│   │   │   └── settings.dart
│   │   └── setting.dart
│   ├── routes.dart
│   ├── routes.map.dart
│   └── screen
│       ├── app.dart
│       └── home.dart
```

  Configure it in `build.yaml`. The following configuration is in accordance with the convention.
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ext: ".map.dart" # generated file extension
          routes:
            routes.dart: # routes.dart 
              name: "routes" # generated variable name
              pages: "pages" # pages directory, relative to `routes.dart`
```
  Change or add the configuration to fit you situation.
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ext: ".my.dart" # change generated file extension
          routes:
            my_routes.dart: # change routes file
              name: "myRoutes" # change the variable name 
              pages: "../pages" # change pages location
            dev/my_routes.dart:
              name: "devRoutes"
              pages: "views"
```
