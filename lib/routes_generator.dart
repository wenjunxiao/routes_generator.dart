import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

/// Routes Generator Builder Factory
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
        ignores: _ensureList(config['ignores']),
        ext: config['ext'] ?? '.map.dart',
        dynamicSuffix: _ensureString(config['dynamic'] ?? 'Dynamic'),
      ),
      generatedExtension: config['ext'] ?? '.map.dart');
}

// 确保是字符串
String _ensureString(value) {
  if (value == false) return '';
  return value as String;
}

/// 确保值是List类型
List _ensureList(value) {
  if (value == false) return [];
  if (value is List) return value;
  if (value == null) return [];
  return [value];
}

/// 判断`key`是否是`inputId`的叶子路径，每级目录必须完全匹配
/// 比如 `bb/cc` 能够匹配 `/aa/bb/cc`
/// 但是 `b/cc` 不能匹配 `/aa/bb/cc`
bool _isMatched(String inputId, String key) {
  if (!inputId.endsWith(key)) return false;
  // 完全匹配
  if (inputId.length == key.length) return true;
  final c = inputId[inputId.length - key.length - 1];
  // 检测匹配之前的一个字符是否是非路径字符
  return c == '/' || c == '\\' || c == '|' || c == ':';
}

/// 解析分组设置，['分组注解类名', '分组信息所在属性名']
List _parseGroup(String group) {
  if (group == null) return [''];
  if (group.isEmpty) return [''];
  final gs = group.split('.');
  if (gs.length == 1) {
    gs.add('name');
  }
  return gs;
}

/// Routes Generator
class RoutesGenerator implements Generator {
  final Map<String, dynamic> _routes;
  final String _group;
  final _ignores;
  final List<String> keys;
  final String _ext;
  final String _dynamicSuffix;

  RoutesGenerator(
      {Map<String, dynamic> routes,
      String group,
      dynamic ignores,
      String ext,
      String dynamicSuffix,
      bool matcher})
      : _routes = routes ?? const {},
        _group = group ?? '_RoutesGroup.name',
        _ignores = ignores,
        _ext = ext,
        _dynamicSuffix = dynamicSuffix ?? 'Dynamic',
        keys = routes?.keys?.toList() ?? [] {
    /**
     * 按照key的长度进行降序排序，以便优先匹配长的，越长匹配度越高
     */
    keys.sort((a, b) => b.length - a.length);
  }

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    try {
      return await _generate(library, buildStep);
    } catch (e, stacktrace) {
      log.severe('generate routes error =>', e, stacktrace);
      rethrow;
    }
  }

  /// 初始化buffer
  StringBuffer _initBuf(String name, bool parameterized) {
    final buf = StringBuffer();
    if (parameterized) {
      buf.writeln('List<WidgetBuilder Function(String)> $name = [');
    } else {
      buf.writeln('Map<String, WidgetBuilder> $name = {');
    }
    return buf;
  }

  FutureOr<String> _generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    final inputId = buildStep.inputId.toString();
    for (final key in keys) {
      if (_isMatched(inputId, key)) {
        final outputId = buildStep.inputId.changeExtension(_ext).uri.toString();
        final outputName = p.basename(outputId);
        final curName = p.join('.', outputName);
        final outputMatched = (uri) {
          return uri == outputName || uri == outputId || uri == curName;
        };
        // 只有在 routes.dart 中 导入或者导出 routes.map.dart 才是符合生成要求
        if (!(library.element.imports.any((e) => outputMatched(e.uri)) ||
            library.element.exports.any((e) => outputMatched(e.uri)))) {
          continue;
        }
        final opts = Map<String, dynamic>.from(_routes[key]);
        final _dynamic = _ensureString(opts['dynamic'] ?? _dynamicSuffix);
        final group = _parseGroup(opts['group'] ?? _group);
        buffer.writeln("import 'package:flutter/widgets.dart';");
        final _buffers = <String, StringBuffer>{};
        String defGroup = opts['name'] ?? 'routes';
        _buffers[defGroup] = _initBuf(defGroup, false);
        if (_dynamic.isNotEmpty) {
          final dynamicGroup = defGroup + _dynamic;
          _buffers[dynamicGroup] = _initBuf(dynamicGroup, true);
        }
        for (final name in _findRoutesGroups(library, group)) {
          _buffers[name] = _initBuf(name, false);
          if (_dynamic.isNotEmpty) {
            final dynamicGroup = name + _dynamic;
            _buffers[dynamicGroup] = _initBuf(dynamicGroup, true);
          }
        }
        // 获取路由文件的目录，用于计算pages目录
        final base = p.normalize(p.dirname(buildStep.inputId.path));
        final pages = p.normalize(p.join(base, opts['pages'] ?? 'pages'));
        final ignores = _ensureList(opts['ignores'] ?? _ignores);
        final pattern = p.join(pages, '**.dart');
        log.fine('match rule [$key], pattern=$pattern');
        // 查找pages目录及其子目录所有dart文件
        final assetIds = await buildStep.findAssets(Glob(pattern)).toList()
          ..sort();
        final ignoreIds = <String, bool>{};
        final groupMap = <String, Map<String, String>>{};
        for (final ignore in ignores) {
          final pattern = p.join(base, ignore);
          await buildStep.findAssets(Glob(pattern)).forEach((id) {
            ignoreIds[id.path] = true;
          });
        }
        log.fine('ignores => $ignoreIds');
        final paramReg = RegExp(r'/_(\w+)');
        for (final assetId in assetIds) {
          final lib = await buildStep.resolver.libraryFor(assetId);
          if (ignoreIds.containsKey(assetId.path)) continue;
          var url = assetId.changeExtension('').path;
          final origUrl = '/${p.relative(url, from: pages)}';
          var parameterized = false;
          final params = <String, String>{};
          if (_dynamic.isNotEmpty) {
            url = origUrl.replaceAllMapped(paramReg, (match) {
              parameterized = true;
              // hasParameterized = true;
              params[match[1]] = match[1];
              return '/(?<${match[1]}>[^\\/]+)';
            });
          } else {
            url = origUrl;
          }
          // 查找文件中的属于页面的类名
          final page = _findPageElement(lib, group);
          final builder = _genPageBuilder(page, parameterized, params);
          if (builder != null) {
            var groupName = _findPageGroupName(page, group) ?? defGroup;
            if (groupName.isEmpty) continue;
            buffer.writeln("import '${p.relative(assetId.path, from: base)}';");
            if (parameterized) {
              groupName = groupName + _dynamic;
            }
            if (!_buffers.containsKey(groupName)) {
              _buffers[groupName] = _initBuf(groupName, parameterized);
            }
            final buf = _buffers[groupName];
            if (parameterized) {
              /// 正则表达式匹配列表需要排序，同一个位置是正则的需要排在后面
              /// 保证正则和非正则可以同时存在，并且非正则优先匹配
              /// 以下把正则位置替换成最小的字符'\0'，方便进行排序
              final key = origUrl.replaceAllMapped(paramReg, (match) {
                return '/\0';
              });
              groupMap[groupName] = groupMap[groupName] ?? <String, String>{};
              groupMap[groupName][key] = '''
              (path) {
                final reg = RegExp(r'^$url\$');
                final match = reg.firstMatch(path);
                if (match == null) return null;
                return $builder;
              },''';
            } else {
              buf.writeln("  '${url}': $builder,");
            }
          }
        }
        for (final entry in _buffers.entries) {
          final map = groupMap[entry.key];
          if (map != null) {
            final urls = map.keys.toList();
            urls.sort((a, b) {
              return b.compareTo(a);
            });
            for (final url in urls) {
              entry.value.writeln(map[url]);
            }
          }
          final bs = entry.value.toString();
          buffer.writeln();
          buffer.writeln(bs);
          if (bs.startsWith('List')) {
            buffer.writeln('];');
          } else {
            buffer.writeln('};');
          }
        }
        break;
      }
    }
    return buffer.toString();
  }
}

/// 判断是否是 Widget组件
bool _isWidget(ClassElement element) {
  if (element.allSupertypes.isEmpty) return false;
  for (final type in element.allSupertypes) {
    if (type.getDisplayString() == 'Widget') {
      return true;
    }
  }
  return false;
}

/// 根据注解检测是否强制指定为路由组件
bool _isRoutesWidget(Element element, List group) {
  if (element.metadata.isEmpty) return false;
  for (final ea in element.metadata) {
    final name = ea.element.name;
    // 使用注解`@protected` 或 `@deprecated`
    if (name == 'protected' || name == 'deprecated') return null;
    final annotation = ConstantReader(ea.computeConstantValue());
    // 如果使用注解`@pragma('build:routes')`指定了某个组件，直接返回该组件
    if (_isBuildRoutes(annotation)) {
      return true;
    } else if (ea.element is ConstructorElement) {
      final element = ea.element as ConstructorElement;
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

/// 查找页面Element
ClassElement _findPageElement(LibraryElement lib, List group) {
  if (lib.topLevelElements.isEmpty) return null;
  final names = <ClassElement>[];
  for (var element in lib.topLevelElements) {
    // 查找公共的继承自Widget的组件，过滤标记为已过期的组件
    if (element.isPublic &&
        !element.hasDeprecated &&
        element is ClassElement &&
        _isWidget(element)) {
      final isRouter = _isRoutesWidget(element, group);
      if (isRouter == null) continue;
      if (isRouter) {
        return element;
      }
      names.add(element);
    }
  }
  // 优先使用第一个符合规则的组件
  if (names.isEmpty) return null;
  return names[0];
}

/// 生成页面的构造方法
String _genPageBuilder(ClassElement element, bool parameterized, Map params) {
  if (element == null) return null;
  if (element.constructors.isEmpty) return null;
  final constructors = [];
  for (var constructor in element.constructors) {
    if (constructor.isDefaultConstructor) {
      constructors.add(constructor);
    }
  }
  constructors.add(element.constructors[0]);
  ConstructorElement constructor = constructors[0];
  final builderArgs = 'context';
  if (constructor.parameters.isEmpty) {
    return '($builderArgs) => ${element.name}()';
  }
  var hasArgs = false;
  final args = constructor.parameters.map((ParameterElement e) {
    if (params.containsKey(e.name)) {
      if (e.isNamed) return '${e.name}: match.namedGroup(\'${e.name}\')';
      return 'match.namedGroup(\'${e.name}\')';
    }
    hasArgs = true;
    if (e.isNamed) return '${e.name}: args[\'${e.name}\']';
    return 'args[\'${e.name}\']';
  }).join(',');
  if (!hasArgs) {
    return '''($builderArgs) => ${element.name}(${args})''';
  }
  return '''($builderArgs){
    final Map args = ModalRoute.of(context).settings?.arguments ?? {};
    return ${element.name}(${args});
  }''';
}

/// 判断是否是 @pragma('build:routes') 注解，用于测试
bool _isBuildRoutes(ConstantReader annotation) {
  final cr = annotation.peek('name');
  if (cr == null) return false;
  if (cr.isString && cr.stringValue == 'build:routes') return true;
  return false;
}

/// 检测页面是否指定了路由分组
String _findPageGroupName(ClassElement element, List group) {
  if (element.metadata.isNotEmpty) {
    for (final ea in element.metadata) {
      if (ea.element is ConstructorElement) {
        final element = ea.element as ConstructorElement;
        final name = element.returnType.element.name;
        final cr = ConstantReader(ea.computeConstantValue());
        // 如果使用注解`@pragma('build:routes', ['login'])`指定了某个分组
        final opts = cr.peek('options');
        if (_isBuildRoutes(cr) && opts != null && opts.isList) {
          if (opts.listValue.isNotEmpty) {
            return opts.listValue[0].toStringValue();
          }
        }
        // 使用了注解类 @RoutesGroup('group')
        if (name != null && name.isNotEmpty && name == group[0]) {
          return cr.peek(group[1])?.stringValue;
        }
      } else if (ea.element is PropertyAccessorElement) {
        // 使用了注解实例 @groupedRoutes
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

/// 查找所有支持的路由分组
Iterable<String> _findRoutesGroups(LibraryReader library, List group) sync* {
  // 默认只生成出现过的分组，为了避免初始时没有导致处理时报错，检测所有导入或者导出的分组
  final groupClass = library.element.getType(group[0]); // 当前文件是否就是定义分组的地方
  if (groupClass != null) {
    final groupType = groupClass.runtimeType;
    for (final element in library.element.topLevelElements) {
      if ((element is VariableElement) &&
          element.type?.element?.runtimeType == groupType) {
        final cr = ConstantReader(element.computeConstantValue());
        final gn = cr.peek(group[1])?.stringValue;
        if (gn != null && gn.isNotEmpty) {
          yield gn;
        }
      }
    }
  } else {
    // 在 routes.dart 使用 exports 'path/of/routes_group.dart' show authRequired;
    for (final element in library.element.exports) {
      // 当前文件是否就是定义分组的地方
      final groupClass = element.exportedLibrary?.getType(group[0]);
      if (groupClass != null && element.combinators.isNotEmpty) {
        final groupType = groupClass.thisType;
        for (final combinator in element.combinators) {
          if (combinator is ShowElementCombinator) {
            for (final element in element.exportedLibrary.topLevelElements) {
              if (element is VariableElement &&
                  element.type.element is ClassElement) {
                final typeEl = element.type.element as ClassElement;
                if (typeEl.thisType == groupType &&
                    combinator.shownNames.contains(element.name)) {
                  final cr = ConstantReader(element.computeConstantValue());
                  final gn = cr.peek(group[1])?.stringValue;
                  if (gn != null && gn.isNotEmpty) {
                    yield gn;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
