[English](https://github.com/wenjunxiao/routes_generator.dart/blob/master/README.md) | [中文简体](https://github.com/wenjunxiao/routes_generator.dart/blob/master/README-ZH.md)

# routes_generator

Provides [source_gen](https://github.com/dart-lang/source_gen) `Generator` to generator `routes` for `MaterialApp` of `flutter`.

Non-intrusive, convention over configuration, only need to install and build.

## Convention

* The `routes.dart` file used to export routes and related functions to `MaterialApp`.
* The `pages` directory relatived to `routes.dart` contains your app views and routes,
  each file contains only one routing page, generator reads all `.dart` files inside
  this directory and generate routes map into `routes.map.dart`.
* The above two conventions apply to any directory of the project.

## Usage

### Basic Routes

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

### Group Routes
  In addition to putting all routes in one Map, sometimes it is necessary to
  put some routes into a separate Map for special processing,
  such as detecting login before routing.

  You need to add a private class named `_RoutesGroup` and 
  define the supported group annotation instances, such as
```dart
class _RoutesGroup {
  final String name;
  const _RoutesGroup(this.name);
}
const authRequired = _RoutesGroup('authRoutes');
```
  Add corresponding annotations on the routing page where required
```dart
@authRequired
class MySetting extends StatelessWidget {
  Widget build(BuildContext context) {
    // ...
  }
}
```
  Conventional annotations are private class instances.The reason for not providing 
  annotation classes is that routing needs to be used and managed, and random group
  names are not allowed when grouping is specified on the page.

### Parameterized

  If the page widget is parameterized, the generator will automatically inject parameters.
```dart
class ParameterizedPage extends StatelessWidget {
  final String arg1;
  final String arg2;
  ParameterizedPage(this.arg1, {this.arg2});
}
```
  The generated routes looks like this
```dart
Map<String, WidgetBuilder> routes = {
  '/parameterized': (context) {
    final Map args = ModalRoute.of(context).settings?.arguments ?? {};
    return ParameterizedPage(args['arg1'], arg2: args['arg2']);
  },
};
```

### Dynamic Routes

  If the path of the page contains a directory or file name starting with an underscore (`_`),
  then the directory or file name will be used as a variable. 
  such as `/dynamic/_name/_id.dart`, there are two variable in the path, `name` and `id`.
```dart
class DynamicPage extends StatelessWidget {
  final String name;
  final String id;
  DynamicPage(this.name, {this.id});
}
```
  The generated routing table is an list, which variable name ends with `Dynamic`
```dart
List<WidgetBuilder Function(String)> routesDynamic = [
  (path) {
    final reg = RegExp(r'^/dynamic/(?<name>[^\/]+)$/(?<id>[^\/]+)$');
    final match = reg.firstMatch(path);
    if (match == null) return null;
    return (context) => DynamicPage(match.namedGroup('name'), id: match.namedGroup('id'));
  },
];
```
  That should be used in `onGenerateRoute`
```dart
onGenerateRoute: (RouteSettings settings) {
  WidgetBuilder builder = routes[settings.name];
  if (builder == null) {
    for (final matcher in routesDynamic) {
      builder = matcher(settings.name);
      if (builder != null) {
        break;
      }
    }
  }
  if (builder == null) return null;
  return MaterialPageRoute(settings: settings, builder: builder);
}
```

## Configuration

  If your project structure does not conform to the convention,
  or want to split the route according to the environment, such as,
  the development app provides more pages and features, 
  which is very useful when switching between multiple development environments. Configuration is also provided.

### Basic

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
  Already meet basic directory split requirements.
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
  Change or add the configuration to fit you situation. For example,
  the route directory is `views` instead of `pages`.
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
              pages: "../views" # change pages location
            dev/my_routes.dart:
              name: "devRoutes"
              pages: "views"
```
### Group

  If you have defined routing grouping in the project, 
  you can also modify the default grouping parameters `group`.
  The `group` need to specify the class name and grouped field name.

```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          group: "MyPageRoutes.group" # change with class name and it's field name
```
  The annotation is defined as follows.
```dart
class MyPageRoutes {
  final String group;
  const MyPageRoutes(this.group);
}

@MyPageRoutes(group: 'authRoutes')
class FirstPage extends StatelessWidget {
}
```

### Ignores

  If there are non-routing page files or directories in the `pages` directory,
  they can be ignored by configuration

```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ignores: "**/widgets/**" # ignore all `widgets` directory in `pages`
```
  Or configure multiple
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ignores:
            - "**/widgets/**" # ignore all `widgets` directory in `pages`
            - "**.g.dart" # ignore all generated files
```
