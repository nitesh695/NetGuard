import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:netguard/netguard.dart';

void main() {
  group('NetGuard Tests', () {
    late NetGuard netGuard;

    setUp(() {
      netGuard = NetGuard();
    });

    tearDown(() {
      netGuard.close();
    });

    test('should create NetGuard from Dio instance', () {
      final dio = Dio();
      dio.options.baseUrl = 'https://test.com';

      final netGuardFromDio = NetGuard.fromDio(dio);

      expect(netGuardFromDio.options.baseUrl, equals('https://test.com'));
      expect(netGuardFromDio.dio, equals(dio));

      netGuardFromDio.close();
    });

    test('should configure options correctly', () {
      netGuard.options.baseUrl = 'https://api.test.com';
      netGuard.options.connectTimeout = const Duration(seconds: 10);
      netGuard.options.receiveTimeout = const Duration(seconds: 15);
      netGuard.options.sendTimeout = const Duration(seconds: 20);

      expect(netGuard.options.baseUrl, equals('https://api.test.com'));
      expect(netGuard.options.connectTimeout, equals(const Duration(seconds: 10)));
      expect(netGuard.options.receiveTimeout, equals(const Duration(seconds: 15)));
      expect(netGuard.options.sendTimeout, equals(const Duration(seconds: 20)));
    });

    test('should add and manage interceptors', () {
      final interceptor1 = InterceptorsWrapper();
      final interceptor2 = InterceptorsWrapper();

      expect(netGuard.interceptors.length, equals(0));

      netGuard.interceptors.add(interceptor1);
      expect(netGuard.interceptors.length, equals(1));

      netGuard.interceptors.add(interceptor2);
      expect(netGuard.interceptors.length, equals(2));

      netGuard.interceptors.remove(interceptor1);
      expect(netGuard.interceptors.length, equals(1));

      netGuard.interceptors.clear();
      expect(netGuard.interceptors.length, equals(0));
    });

    test('should handle headers correctly', () {
      netGuard.options.headers['Authorization'] = 'Bearer token123';
      netGuard.options.headers['Content-Type'] = 'application/json';

      expect(netGuard.options.headers['Authorization'], equals('Bearer token123'));
      expect(netGuard.options.headers['Content-Type'], equals('application/json'));
    });

    test('should copy options with new values', () {
      netGuard.options.baseUrl = 'https://original.com';
      netGuard.options.connectTimeout = const Duration(seconds: 10);

      final copiedOptions = netGuard.options.copyWith(
        baseUrl: 'https://new.com',
        receiveTimeout: const Duration(seconds: 30),
      );

      expect(copiedOptions.baseUrl, equals('https://new.com'));
      expect(copiedOptions.connectTimeout, equals(const Duration(seconds: 10))); // Original value
      expect(copiedOptions.receiveTimeout, equals(const Duration(seconds: 30))); // New value
    });

    group('Static Methods Tests', () {
      setUp(() {
        NetGuard.configure(
          baseUrl: 'https://jsonplaceholder.typicode.com',
          connectTimeout: const Duration(seconds: 10),
        );
      });

      test('should configure default instance', () {
        NetGuard.configure(
          baseUrl: 'https://test-static.com',
          connectTimeout: const Duration(seconds: 15),
          headers: {'X-Test': 'static-test'},
        );

        final instance = NetGuard.instance;
        expect(instance.options.baseUrl, equals('https://test-static.com'));
        expect(instance.options.connectTimeout, equals(const Duration(seconds: 15)));
        expect(instance.options.headers['X-Test'], equals('static-test'));
      });

      test('should use quick setup correctly', () {
        NetGuard.quickSetup(
          baseUrl: 'https://quick-setup.com',
          accessToken: 'test-token',
          timeout: const Duration(seconds: 25),
          allowBadCertificates: true,
        );

        final instance = NetGuard.instance;
        expect(instance.options.baseUrl, equals('https://quick-setup.com'));
        expect(instance.options.connectTimeout, equals(const Duration(seconds: 25)));
        expect(instance.interceptors.length, greaterThan(0));
      });
    });

    group('NetGuardOptions Tests', () {
      test('should create options from BaseOptions', () {
        final baseOptions = BaseOptions(
          baseUrl: 'https://test.com',
          connectTimeout: const Duration(seconds: 5),
        );

        final netGuardOptions = NetGuardOptions.fromBaseOptions(baseOptions);

        expect(netGuardOptions.baseUrl, equals('https://test.com'));
        expect(netGuardOptions.connectTimeout, equals(const Duration(seconds: 5)));
      });

      test('should create options with parameters', () {
        final options = NetGuardOptions(
          baseUrl: 'https://param-test.com',
          connectTimeout: const Duration(seconds: 12),
          headers: {'X-Custom': 'header-value'},
        );

        expect(options.baseUrl, equals('https://param-test.com'));
        expect(options.connectTimeout, equals(const Duration(seconds: 12)));
        expect(options.headers['X-Custom'], equals('header-value'));
      });
    });

    group('NetGuardInterceptors Tests', () {
      late NetGuardInterceptors interceptors;
      late Interceptor testInterceptor1;
      late Interceptor testInterceptor2;

      setUp(() {
        final dioInterceptors = Interceptors();
        interceptors = NetGuardInterceptors(dioInterceptors);
        testInterceptor1 = InterceptorsWrapper();
        testInterceptor2 = InterceptorsWrapper();
      });

      test('should add interceptors', () {
        expect(interceptors.length, equals(0));

        interceptors.add(testInterceptor1);
        expect(interceptors.length, equals(1));
        expect(interceptors.first, equals(testInterceptor1));
      });

      test('should add all interceptors', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);
        expect(interceptors.length, equals(2));
      });

      test('should insert interceptor at index', () {
        interceptors.add(testInterceptor1);
        interceptors.insert(0, testInterceptor2);

        expect(interceptors.length, equals(2));
        expect(interceptors.first, equals(testInterceptor2));
      });

      test('should remove interceptors', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);

        final removed = interceptors.remove(testInterceptor1);
        expect(removed, isTrue);
        expect(interceptors.length, equals(1));
        expect(interceptors.first, equals(testInterceptor2));
      });

      test('should remove interceptor at index', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);

        final removed = interceptors.removeAt(0);
        expect(removed, equals(testInterceptor1));
        expect(interceptors.length, equals(1));
      });

      test('should clear all interceptors', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);

        interceptors.clear();
        expect(interceptors.length, equals(0));
        expect(interceptors.isEmpty, isTrue);
      });

      test('should access interceptors by index', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);

        expect(interceptors[0], equals(testInterceptor1));
        expect(interceptors[1], equals(testInterceptor2));
      });

      test('should set interceptor at index', () {
        interceptors.add(testInterceptor1);
        interceptors[0] = testInterceptor2;

        expect(interceptors[0], equals(testInterceptor2));
      });

      test('should check contains', () {
        interceptors.add(testInterceptor1);

        expect(interceptors.contains(testInterceptor1), isTrue);
        expect(interceptors.contains(testInterceptor2), isFalse);
      });

      test('should find index of interceptor', () {
        interceptors.addAll([testInterceptor1, testInterceptor2]);

        expect(interceptors.indexOf(testInterceptor1), equals(0));
        expect(interceptors.indexOf(testInterceptor2), equals(1));
      });
    });
  });

  group('Response Extensions Tests', () {
    test('should identify successful responses', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: 'success',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.isClientError, isFalse);
      expect(response.isServerError, isFalse);
    });

    test('should identify client error responses', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 404,
        data: 'not found',
      );

      expect(response.isSuccessful, isFalse);
      expect(response.isClientError, isTrue);
      expect(response.isServerError, isFalse);
    });

    test('should identify server error responses', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
        data: 'server error',
      );

      expect(response.isSuccessful, isFalse);
      expect(response.isClientError, isFalse);
      expect(response.isServerError, isTrue);
    });

    test('should identify redirect responses', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 302,
        data: 'redirect',
      );

      expect(response.isSuccessful, isFalse);
      expect(response.isRedirect, isTrue);
    });

    test('should identify content types', () {
      final jsonResponse = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: '{"test": true}',
        headers: Headers.fromMap({'content-type': ['application/json']}),
      );

      expect(jsonResponse.isJson, isTrue);
      expect(jsonResponse.isXml, isFalse);
      expect(jsonResponse.isHtml, isFalse);

      final xmlResponse = Response<String>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: '<test>true</test>',
        headers: Headers.fromMap({'content-type': ['application/xml']}),
      );

      expect(xmlResponse.isJson, isFalse);
      expect(xmlResponse.isXml, isTrue);
      expect(xmlResponse.isHtml, isFalse);
    });
  });

  group('Error Extensions Tests', () {
    test('should identify connection timeout errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(error.isConnectionTimeout, isTrue);
      expect(error.isTimeoutError, isTrue);
      expect(error.isNetworkError, isTrue);
    });

    test('should identify send timeout errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );

      expect(error.isSendTimeout, isTrue);
      expect(error.isTimeoutError, isTrue);
    });

    test('should identify receive timeout errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );

      expect(error.isReceiveTimeout, isTrue);
      expect(error.isTimeoutError, isTrue);
    });

    test('should identify bad certificate errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badCertificate,
      );

      expect(error.isBadCertificate, isTrue);
    });

    test('should identify bad response errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );

      expect(error.isBadResponse, isTrue);
      expect(error.statusCode, equals(404));
      expect(error.isClientError, isTrue);
    });

    test('should identify cancel errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );

      expect(error.isCancelled, isTrue);
    });

    test('should identify connection errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      expect(error.isConnectionError, isTrue);
      expect(error.isNetworkError, isTrue);
    });

    test('should provide user-friendly error messages', () {
      final timeoutError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(timeoutError.userFriendlyMessage,
          contains('Connection timeout'));

      final cancelError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );

      expect(cancelError.userFriendlyMessage,
          contains('Request was cancelled'));
    });
  });
}