[English](https://github.com/wenjunxiao/routes_generator.dart/blob/master/README.md) | [中文简体](https://github.com/wenjunxiao/routes_generator.dart/blob/master/README-ZH.md)

# routes_generator

提供基于[source_gen](https://github.com/dart-lang/source_gen)的代码生成器`Generator`，
用于生成`flutter`中`MaterialApp`的`routes`或`onGenerateRoute`相关的路由代码。

非侵入式，约定优于配置，只需要安装和构建即可。

## 约定

* `routes.dart`文件中导出路由及其相关功能给`MaterialApp`使用，并且`routes.dart`文件中必须导入`routes.map.dart` 
* `pages`目录(相对于`routes.dart`)包含所有路由页面，每个文件只包含一个路由页面，
  生成器会读取该目录中所有的`.dart`文件，并在`routes.map.dart`文件中生成对应的路由表
* 以上两条规则适用于项目中的任意子目录

## 使用

### 基本路由

  添加到`dev_dependencies`中
```yaml
dev_dependencies:
  routes_generator: any
```
  
  在`routes.dart`文件（如果不存在则新增）导入`routes.map.dart`，无需新增`routes.map.dart`文件，会自动生成。
```dart
// routes.dart
import 'package:flutter/widgets.dart';
import 'routes.map.dart' as p;

Map<String, WidgetBuilder> routes = p.routes;
```

  执行代码生成命令
```bash
$ flutter pub run build_runner build
```

  如果有多个`routes.map.dart`，那么在使用之前需要进行对应的合并
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

### 分组路由

  除了把所有路由放在一个Map中，有时需要将某些路由放入单独的Map，以便进行特殊处理，比如路由之前检测登录。
  需要添加一个名为`_RoutesGroup`的私有类，并定义好支持的分组注解实例，比如
```dart
class _RoutesGroup {
  final String name;
  const _RoutesGroup(this.name);
}
const authRequired = _RoutesGroup('authRoutes');
```
  在需要进行登录的路由页面加入对应的注解
```dart
@authRequired
class MySetting extends StatelessWidget {
  Widget build(BuildContext context) {
    // ...
  }
}
```
  约定注解是私有类实例，而不提供注解类的原因是路由需要被使用和管理，在页面规定分组时不允许随意的分组名。

### 参数化

  如果路由的参数化页面，生成器会自动注入对应的参数
```dart
class ParameterizedPage extends StatelessWidget {
  final String arg1;
  final String arg2;
  ParameterizedPage(this.arg1, {this.arg2});
}
```
  生成的路由表如下
```dart
Map<String, WidgetBuilder> routes = {
  '/parameterized': (context) {
    final Map args = ModalRoute.of(context).settings?.arguments ?? {};
    return ParameterizedPage(args['arg1'], arg2: args['arg2']);
  },
};
```

### 动态路由

  如果页面的路径中包含以下划线`_`开头的目录或者文件，那么对应的目录或文件名将会作为变量。
  比如`/dynamic/_name/_id.dart`路径中有两个变量`name`和`id`
```dart
class DynamicPage extends StatelessWidget {
  final String name;
  final String id;
  DynamicPage(this.name, {this.id});
}
```
  生成的路由表是一个数组, 其变量名以`Dynamic`结尾
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
  这应该在`onGenerateRoute`中使用，如下所示
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

## 配置

  如果项目结构不满足约定的要求，或者需要根据环境或者其他因素拆分页面到不同的目录，
  比如，开发环境将要包含更多的页面和功能，这在多开发环境中进行切换时非常有用。
  也可以通过个性化配置达到目的。

### 基本配置

  以下是符合约定的典型目录结构。
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

  在`build.yaml`文件中进行配置。以下配置是基于约定的默认配置，已经满足基本的目录拆分需求
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ext: ".map.dart" # 定义生成文件的后缀名
          routes:
            routes.dart: # routes.dart
              name: "routes" # 生成路由的变量名
              pages: "pages" # 路由页面所在目录，相对于`routes.dart`文件
```
  可以添加或修改以满足对应的场景。比如，路由的目录是`views`而不是`pages`
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ext: ".my.dart" # 修改后缀名
          prefix: "/app" # 给路由URL添加默认的前缀
          routes:
            my_routes.dart: # 修改路由标识的文件名
              name: "myRoutes" # 修改生成的变量名
              pages: "../view" # 修改路由页面的名称和相对位置
            dev/my_routes.dart: # 增加一个dev的路由配置
              prefix: "/dev" # 给dev路由URL添加统一的前缀，覆盖默认的前缀/app
              name: "devRoutes" # dev路由表的变量名
              pages: "views" # 相对于`dev`目录中`my_routes.dart`的路由页面目录
```

### 分组配置

  如果在项目中已经定义好了路由分组相关，也可以修改默认的约定分组参数`group`。
  `group`需要指定类名和分组的字段名
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          group: "MyPageRoutes.group" # 修改分组注解的类名和属性名
```
  注解的定义如下
```dart
class MyPageRoutes{
  final String group;
  const MyPageRoutes(this.group);
}

@MyPageRoutes(group: 'authRoutes')
class FirstPage extends StatelessWidget{
}
```
  此选项可以也可以在任何`routes`的子节点中，它将覆盖上述默认的配置
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          group: "MyPageRoutes.group"
          routes:
            routes.dart:
              group: "SubPageRoutes.group"
```

### 忽略文件

  如果在`pages`目录存在非路由页面文件或目录，可以通过配置排除
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ignores: "**/widgets/**" # 忽略所有`widgets`目录
```
  或者配置多条
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ignores:
            - "**/widgets/**" # 忽略所有`widgets`目录
            - "**.g.dart" # 忽略所有生成的文件
```
  此选项可以也可以在任何`routes`的子节点中，它将覆盖上述默认的配置。
  也可以设置`false`来禁用此选项。
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          ignores: "**.g.dart"
          routes:
            routes.dart:
              ignores: "**/widgets/**"
            dev/routes.dart:
              ignores: false # disable ignore any files
```

### 动态路由

  可以配置动态路由变量的后缀名。同样可以设置`false`来禁止生成动态路由。
```yaml
targets:
  $default:
    builders:
      routes_generator:
        options:
          dynamic: 'Dynamic'
          routes:
            routes.dart:
              dynamic: 'Dynamic'
            dev/routes.dart:
              dynamic: false # disable dynamic routes
```