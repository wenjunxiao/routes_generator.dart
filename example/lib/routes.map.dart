// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: Instance of 'RoutesGenerator'
// **************************************************************************

import 'package:flutter/widgets.dart';
import 'pages/_name/_id.dart';
import 'pages/_name/home.dart';
import 'pages/_name/protected/_id.dart';
import 'pages/_name/public/_id.dart';
import 'pages/login.dart';
import 'pages/protected.dart';
import 'pages/public.dart';

Map<String, WidgetBuilder> routes = {
  '/login': (context) => LoginPage(),
  '/public': (context) => PublicPage(),
};

List<WidgetBuilder Function(String)> routesDynamic = [
  (path) {
    final reg = RegExp(r'^/(?<name>[^\/]+)/public/(?<id>[^\/]+)$');
    final match = reg.firstMatch(path);
    if (match == null) return null;
    return (context) {
      final Map args = ModalRoute.of(context).settings?.arguments ?? {};
      return DynamicPublicPage(
          key: args['key'],
          name: match.namedGroup('name'),
          id: match.namedGroup('id'));
    };
  },
  (path) {
    final reg = RegExp(r'^/(?<name>[^\/]+)/home$');
    final match = reg.firstMatch(path);
    if (match == null) return null;
    return (context) {
      final Map args = ModalRoute.of(context).settings?.arguments ?? {};
      return DynamicPage(key: args['key'], name: match.namedGroup('name'));
    };
  },
  (path) {
    final reg = RegExp(r'^/(?<name>[^\/]+)/(?<id>[^\/]+)$');
    final match = reg.firstMatch(path);
    if (match == null) return null;
    return (context) {
      final Map args = ModalRoute.of(context).settings?.arguments ?? {};
      return DynamicIdPage(
          key: args['key'],
          name: match.namedGroup('name'),
          id: match.namedGroup('id'));
    };
  },
];

Map<String, WidgetBuilder> authRoutes = {
  '/protected': (context) {
    final Map args = ModalRoute.of(context).settings?.arguments ?? {};
    return ProtectedPage(key: args['key'], user: args['user']);
  },
};

List<WidgetBuilder Function(String)> authRoutesDynamic = [
  (path) {
    final reg = RegExp(r'^/(?<name>[^\/]+)/protected/(?<id>[^\/]+)$');
    final match = reg.firstMatch(path);
    if (match == null) return null;
    return (context) {
      final Map args = ModalRoute.of(context).settings?.arguments ?? {};
      return DynamicProtectedPage(
          key: args['key'],
          name: match.namedGroup('name'),
          id: match.namedGroup('id'),
          user: args['user']);
    };
  },
];
