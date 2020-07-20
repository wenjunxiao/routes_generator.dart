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
  return LibraryBuilder(
      RoutesGenerator(
        routes: routes,
        group: config['group'],
        ignores: ensureList(config['ignores']),
      ),
      generatedExtension: config['ext'] ?? '.map.dart');
}

List ensureList(value) {
  if (value is List) return value;
  if (value == null) return [];
  return [value];
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

List parseGroup(String group) {
  if (group == null) return [''];
  if (group.isEmpty) return [''];
  final gs = group.split('.');
  if (gs.length == 1) {
    gs.add('name');
  }
  return gs;
}

class RoutesGenerator implements Generator {
  final Map<String, dynamic> _routes;
  final String _group;
  final _ignores;

  const RoutesGenerator({
    Map<String, dynamic> routes,
    String group,
    dynamic ignores,
  })  : _routes = routes ?? const {},
        _group = group,
        _ignores = ignores;

  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    try {
      return await _generate(library, buildStep);
    } catch (e, stacktrace) {
      log.severe('generate routes error =>', e, stacktrace);
      rethrow;
    }
  }

  StringBuffer _initRoutesBuffer(String name) {
    final buf = StringBuffer();
    buf.writeln("Map<String, WidgetBuilder> $name = {");
    return buf;
  }

  FutureOr<String> _generate(LibraryReader library, BuildStep buildStep) async {
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
        final group = parseGroup(opts['group'] ?? _group);
        buffer.writeln("import 'package:flutter/widgets.dart';");
        final groupBuffers = <String, StringBuffer>{};
        String defGroup = opts['name'] ?? 'routes';
        // 获取路由文件的目录，用于计算pages目录
        final base = p.normalize(p.dirname(buildStep.inputId.path));
        final pages = p.normalize(p.join(base, opts['pages'] ?? 'pages'));
        final ignores = ensureList(opts['ignores'] ?? _ignores);
        final pattern = p.join(pages, '**.dart');
        log.fine('match rule [$key], pattern=$pattern');
        // 查找pages目录及其子目录所有dart文件
        final assetIds = await buildStep.findAssets(Glob(pattern)).toList()
          ..sort();
        final ignoreIds = <String, bool>{};
        for (final ignore in ignores) {
          final pattern = p.join(base, ignore);
          await buildStep.findAssets(Glob(pattern)).forEach((id) {
            ignoreIds[id.path] = true;
          });
        }
        print('assetIds====$assetIds');
        log.fine('ignores => $ignoreIds');
        for (final assetId in assetIds) {
          final lib = await buildStep.resolver.libraryFor(assetId);
          if (ignoreIds.containsKey(assetId.path)) continue;
          // 查找文件中的属于页面的类名
          final page = findPageElement(lib, group);
          final builder = genPageBuilder(page);
          if (builder != null) {
            final groupName = findPageGroupName(page, group) ?? defGroup;
            if (groupName.isEmpty) continue;
            if (!groupBuffers.containsKey(groupName)) {
              groupBuffers[groupName] = _initRoutesBuffer(groupName);
            }
            final buf = groupBuffers[groupName];
            buffer.writeln("import '${p.relative(assetId.path, from: base)}';");
            buf.writeln(
                "  '/${p.relative(assetId.changeExtension('').path, from: pages)}': $builder,");
          }
        }
        for (final buf in groupBuffers.values) {
          buf.writeln("};");
          buffer.writeln();
          buffer.writeln(buf.toString());
        }
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
bool isRoutesWidget(Element element, List group) {
  if (element.metadata.length == 0) return false;
  for (final ea in element.metadata) {
    final name = ea.element.name;
    // 使用注解`@protected` 或 `@deprecated`
    if (name == 'protected' || name == 'deprecated') return null;
    final annotation = ConstantReader(ea.computeConstantValue());
    // 如果使用注解`@pragma('build:routes')`指定了某个组件，直接返回该组件
    if (isBuildRoutes(annotation)) {
      return true;
    } else if (ea.element is ConstructorElement) {
      ConstructorElement element = ea.element as ConstructorElement;
      final name = element.returnType.element.name;
      if (name != null && name.isNotEmpty && name == group[0]) {
        return true;
      }
    } else if (ea.element is PropertyAccessorElement) {
      PropertyAccessorElement element = ea.element;
      final name = element.variable.type?.element?.name;
      return name == group[0];
    }
  }
  return false;
}

ClassElement findPageElement(LibraryElement lib, List group) {
  if (lib.topLevelElements.length == 0) return null;
  List<ClassElement> names = [];
  for (var element in lib.topLevelElements) {
    // 查找公共的继承自Widget的组件，过滤标记为已过期的组件
    if (element.isPublic &&
        !element.hasDeprecated &&
        element is ClassElement &&
        isWidget(element)) {
      bool isRouter = isRoutesWidget(element, group);
      if (isRouter == null) continue;
      if (isRouter) {
        return element;
      }
      names.add(element);
    }
  }
  // 优先使用第一个符合规则的组件
  if (names.length == 0) return null;
  return names[0];
}

String genPageBuilder(ClassElement element) {
  if (element == null) return null;
  if (element.constructors.length == 0) return null;
  final constructors = [];
  for (var constructor in element.constructors) {
    if (constructor.isDefaultConstructor) {
      constructors.add(constructor);
    }
  }
  constructors.add(element.constructors[0]);
  ConstructorElement constructor = constructors[0];
  if (constructor.parameters.length == 0) {
    return '(context) => ${element.name}()';
  }
  final args = constructor.parameters.map((ParameterElement e) {
    if (e.isNamed) return '${e.name}: args[\'${e.name}\']';
    return 'args[\'${e.name}\']';
  });
  return '''(context){
    final Map args = ModalRoute.of(context).settings?.arguments ?? {};
    return ${element.name}(${args.join(',')});
  }''';
}

isBuildRoutes(ConstantReader annotation) {
  final cr = annotation.peek('name');
  if (cr == null) return false;
  if (cr.isString && cr.stringValue == 'build:routes') return true;
  return false;
}

String findPageGroupName(ClassElement element, List group) {
  if (element.metadata.length > 0) {
    for (final ea in element.metadata) {
      if (ea.element is ConstructorElement) {
        ConstructorElement element = ea.element as ConstructorElement;
        final name = element.returnType.element.name;
        final cr = ConstantReader(ea.computeConstantValue());
        // 如果使用注解`@pragma('build:routes', ['login'])`指定了某个分组
        final opts = cr.peek('options');
        if (isBuildRoutes(cr) && opts != null && opts.isList) {
          if (opts.listValue.length > 0) {
            return opts.listValue[0].toStringValue();
          }
        }
        if (name != null && name.isNotEmpty && name == group[0]) {
          return cr.peek(group[1])?.stringValue;
        }
      } else if (ea.element is PropertyAccessorElement) {
        PropertyAccessorElement element = ea.element;
        final name = element.variable.type?.element?.name;
        if (name == group[0]) {
          final cr = ConstantReader(element.variable.computeConstantValue());
          return cr.peek(group[1])?.stringValue;
        }
      }
    }
  }
  return null;
}
