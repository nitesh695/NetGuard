import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Navigate letsGoto = Navigate();

typedef _RoutePredicate = bool Function(Route<dynamic>);

class Navigate {
  Future<T?> pushNamed<T extends Object?>(
      String routeName, {
        Object? args,
      }) async {
    return Get.toNamed<T>(
      routeName,
      arguments: args,
    );
  }

  Future<T?> push<T extends Object?>(
      Widget Function() page, {
        dynamic arguments,
        bool preventDuplicates = true,
      }) async {
    return Get.to<T>(
      page,
      arguments: arguments,
      preventDuplicates: preventDuplicates,
    );
  }

  Future<T?> pushReplacementNamed<T extends Object?>(
      String routeName, {
        Object? args,
      }) async {
    return Get.offNamed<T>(
      routeName,
      arguments: args,
    );
  }

  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
      String routeName, {
        Object? args,
        _RoutePredicate? predicate,
      }) async {
    return Get.offAllNamed<T>(
      routeName,
      predicate: predicate ?? (_) => false,
      arguments: args,
    );
  }

  Future<T?> pushAndRemoveUntil<T extends Object?>(
      Widget Function() page, {
        _RoutePredicate? predicate,
      }) async {
    return Get.offAll<T>(
      page,
      predicate: predicate ?? (_) => false,
    );
  }

  Future<bool> maybePop<T extends Object?>([T? result]) async {
    return Navigator.maybePop(Get.context!, result);
  }

  bool canPop() => Get.key.currentState!.canPop();

  void goBack<T extends Object?>({T? result}) {
    Get.back<T>(result: result);
  }

  void popUntil(String route) {
    Get.until((route) => Get.currentRoute == route);
  }

  RouteSettings? pageSettings(BuildContext context) {
    return ModalRoute.of<RouteSettings>(context)?.settings;
  }
}
