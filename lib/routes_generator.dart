import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

Builder routesBuilder([BuilderOptions options]) {
  /**
   * 根据约定的规则生成路由，配置文件的key是路由文件所在的目录，比如默认的`routes.dart`
   * `name` 生成的路由变量的名称（用于`key`对应的文件或其他页面引用）
   * `pages` 包含路由文件的路径，可以是绝对路径，默认是相对于`key`对应的文件的路径
   */
  final config = Map<String, dynamic>.from(options?.config ?? {});
  final routes = Map<String, dynamic>.from(config['routes'] ?? {});
  routes.putIfAbsent('routes.dart',
      () => <String, dynamic>{'name': 'routes', 'pages': './pages/'});
  return LibraryBuilder(RoutesGenerator(routes: routes),
      generatedExtension: config['ext'] ?? '.map.dart');
}

/// 判断`key`是否是`inputId`的叶子路径，每级目录必须完全匹配
/// 比如 `bb/cc` 能够匹配 `/aa/bb/cc`
/// 但是 `b/cc` 不能匹配 `/aa/bb/cc`
bool isMatched(String inputId, String key) {
  if (!inputId.endsWith(key)) return false;
  // 完全匹配
  if (inputId.length == key.length) return true;
  final c = inputId[inputId.length - key.length - 1];
  // 检测匹配之前的一个字符是否是非路径字符
  return c == '/' || c == '\\' || c == '|' || c == ':';
}

class RoutesGenerator implements Generator {
  final Map<String, dynamic> _routes;

  const RoutesGenerator({Map<String, dynamic> routes})
      : _routes = routes ?? const {};

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    final inputId = buildStep.inputId.toString();
    final keys = _routes.keys.toList();
    /**
     * 按照key的长度进行降序排序，以便优先匹配长的，越长匹配度越高
     */
    keys.sort((a, b) => b.length - a.length);
    for (final key in keys) {
      if (isMatched(inputId, key)) {
        Map<String, dynamic> opts = Map<String, dynamic>.from(_routes[key]);
        final buf = StringBuffer();
        buffer.writeln("import 'package:flutter/widgets.dart';");
        buf.writeln(
            "Map<String, WidgetBuilder> ${opts['name'] ?? 'routes'} = {");
        // 获取路由文件的目录，用于计算pages目录
        final base = p.dirname(buildStep.inputId.path);
        final pages = p.normalize(p.join(base, opts['pages'] ?? 'pages'));
        final pattern = p.join(pages, '**.dart');
        log.fine('match rule [$key], pattern=$pattern');
        // 查找pages目录及其子目录所有dart文件
        final assetIds = await buildStep.findAssets(Glob(pattern)).toList()
          ..sort();
        for (final assetId in assetIds) {
          final lib = await buildStep.resolver.libraryFor(assetId);
          // 查找文件中的属于页面的类名
          final name = findPageName(lib);
          if (name != null) {
            buffer.writeln("import '${p.relative(assetId.path, from: base)}';");
            buf.writeln(
                "  '/${p.relative(assetId.changeExtension('').path, from: pages)}': (context) => $name(),");
          }
        }
        buf.writeln("};");
        buffer.writeln();
        buffer.writeln(buf.toString());
        break;
      }
    }
    return buffer.toString();
  }
}

bool isWidget(ClassElement element) {
  if (element.allSupertypes.length == 0) return false;
  for (final type in element.allSupertypes) {
    if (type.getDisplayString() == 'Widget') {
      return true;
    }
  }
  return false;
}

/// 根据注解检测是否强制指定为路由组件
bool isRoutesWidget(Element element) {
  if (element.metadata.length == 0) return false;
  for (final ea in element.metadata) {
    final annotation = ConstantReader(ea.computeConstantValue());
    if (annotation.read('name').stringValue?.toLowerCase() == 'routes') {
      return true;
    }
  }
  return false;
}

String findPageName(LibraryElement lib) {
  if (lib.topLevelElements.length == 0) return null;
  List<String> names = [];
  for (var element in lib.topLevelElements) {
    // 查找公共的继承自Widget的组件，过滤标记为已过期的组件
    if (element.isPublic && !element.hasDeprecated && isWidget(element)) {
      // 如果使用注解`@pragma('routes')`指定了某个组件，直接返回该组件
      if (isRoutesWidget(element)) {
        return element.name;
      }
      names.add(element.name);
    }
  }
  // 优先使用第一个符合规则的组件
  return names[0];
}
