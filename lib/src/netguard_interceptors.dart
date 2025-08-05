import 'package:dio/dio.dart';

/// NetGuard interceptors wrapper around Dio's Interceptors
class NetGuardInterceptors {
  final Interceptors _interceptors;

  /// Create NetGuard interceptors from Dio interceptors
  NetGuardInterceptors(this._interceptors);

  /// Get the underlying Dio interceptors
  Interceptors get interceptors => _interceptors;

  /// Add an interceptor
  void add(Interceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Add all interceptors
  void addAll(Iterable<Interceptor> interceptors) {
    _interceptors.addAll(interceptors);
  }

  /// Insert an interceptor at index
  void insert(int index, Interceptor interceptor) {
    _interceptors.insert(index, interceptor);
  }

  /// Remove an interceptor
  bool remove(Interceptor interceptor) {
    return _interceptors.remove(interceptor);
  }

  /// Remove an interceptor at index
  Interceptor removeAt(int index) {
    return _interceptors.removeAt(index);
  }

  /// Remove last interceptor
  Interceptor removeLast() {
    return _interceptors.removeLast();
  }

  /// Clear all interceptors
  void clear() {
    _interceptors.clear();
  }

  /// Get interceptor at index
  Interceptor operator [](int index) {
    return _interceptors[index];
  }

  /// Set interceptor at index
  void operator []=(int index, Interceptor interceptor) {
    _interceptors[index] = interceptor;
  }

  /// Get length of interceptors
  int get length => _interceptors.length;

  /// Check if empty
  bool get isEmpty => _interceptors.isEmpty;

  /// Check if not empty
  bool get isNotEmpty => _interceptors.isNotEmpty;

  /// Get first interceptor
  Interceptor get first => _interceptors.first;

  /// Get last interceptor
  Interceptor get last => _interceptors.last;

  /// Get iterator
  Iterator<Interceptor> get iterator => _interceptors.iterator;

  /// Contains check
  bool contains(Object? element) => _interceptors.contains(element);

  /// Index of interceptor
  int indexOf(Interceptor element, [int start = 0]) {
    return _interceptors.indexOf(element, start);
  }

  /// Last index of interceptor
  int lastIndexOf(Interceptor element, [int? start]) {
    return _interceptors.lastIndexOf(element, start);
  }

  /// For each interceptor
  void forEach(void Function(Interceptor element) action) {
    _interceptors.forEach(action);
  }

  /// Map interceptors
  Iterable<T> map<T>(T Function(Interceptor e) toElement) {
    return _interceptors.map(toElement);
  }

  /// Where interceptors
  Iterable<Interceptor> where(bool Function(Interceptor element) test) {
    return _interceptors.where(test);
  }

  /// Expand interceptors
  Iterable<T> expand<T>(Iterable<T> Function(Interceptor element) toElements) {
    return _interceptors.expand(toElements);
  }

  /// Any interceptor
  bool any(bool Function(Interceptor element) test) {
    return _interceptors.any(test);
  }

  /// Every interceptor
  bool every(bool Function(Interceptor element) test) {
    return _interceptors.every(test);
  }

  /// To list
  List<Interceptor> toList({bool growable = true}) {
    return _interceptors.toList(growable: growable);
  }

  /// To set
  Set<Interceptor> toSet() {
    return _interceptors.toSet();
  }
}