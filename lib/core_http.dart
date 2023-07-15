library core_http;

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'core/error_handling/exceptions.dart';
import 'core/extension.dart';

export 'core/extension.dart';

enum MethodName { get, post, put, delete, path }

const String authorizationKey = 'authorizationKey';

abstract class CoreHttp {
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });
  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });
  Future<dynamic> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });
  Future<dynamic> patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });
  Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<dynamic> method(
    String url,
    MethodName method, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<dynamic> postWithFile(
    String url,
    Map<String, dynamic> body,
    List<File> files, {
    Map<String, String>? headers,
    String fileKey = 'file',
    int timeOut = 0,
  });

  Future<File?> downloadWithHttpClient(String url, savePath);

  Future<String?> download(String url, savePath,
      {void Function(int count, int total)? callBack});

  Future<File?> downloadWithParam(String url,
      {required Map<String, dynamic> body,
      required String filePath,
      void Function(int count, int total)? callBack});

  Future<dynamic> postUploadFile(
    String url, {
    required List<File> files,
    Map<String, String>? headers,
    Function(double percent)? callbackProcess,
    String? key = 'files',
  });

  Future<File?> downloadFromFtp(
    String url, {
    required Map<String, dynamic> body,
    required String filePath,
    Function(int, int)? callBack,
  });
}

class CoreHttpImplement implements CoreHttp {
  final Duration _timeOut = const Duration(milliseconds: 30000); //30 s
  late Dio _dio;

  late final GetStorage _storage;

  CoreHttpImplement({required String appName}) {
    _storage = GetStorage(appName);
    final BaseOptions options = BaseOptions(
      connectTimeout: _timeOut,
      receiveTimeout: _timeOut,
      validateStatus: (status) => true,
      contentType: ContentType.json.value,
      responseType: ResponseType.plain,
    );
    _dio = Dio(options);

// customization
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  @override
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      // if (kDebugMode) {
      log('getAsync _ $e');
      // }
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(headers: headers),
        queryParameters: queryParameters,
      );
      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('postAsync _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final response = await _dio.delete(
        url,
        options: Options(headers: headers),
        queryParameters: queryParameters,
      );
      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('delete _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future<File?> downloadWithHttpClient(String url, savePath) async {
    try {
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        final Uint8List bytes =
            await consolidateHttpClientResponseBytes(response);
        final File newFile = File(savePath);
        return await newFile.writeAsBytes(bytes);
      }
      return null;
    } catch (e) {
      log('download _ $e');
      return null;
    }
  }

  @override
  Future<String?> download(String url, savePath,
      {void Function(int count, int total)? callBack}) async {
    final CancelToken cancelToken = CancelToken();
    try {
      await _dio.download(url, savePath,
          onReceiveProgress: callBack, cancelToken: cancelToken);
      return savePath;
    } catch (e) {
      log('download$e');
      return null;
    }
  }

  @override
  Future<File?> downloadWithParam(String url,
      {required Map<String, dynamic> body,
      required String filePath,
      void Function(int count, int total)? callBack}) async {
    try {
      final Response response = await _dio.post(
        url,
        data: jsonEncode(body),
        onReceiveProgress: callBack,
        options:
            Options(responseType: ResponseType.bytes, followRedirects: false),
      );
      final File file = File(filePath);
      file.createSync(recursive: true);
      final raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();
      return file;
    } catch (e) {
      return null;
    }
  }

  @override
  Future postUploadFile(
    String url, {
    required List<File> files,
    Map<String, String>? headers,
    Function(double percent)? callbackProcess,
    String? key = 'files',
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final List<MapEntry<String, MultipartFile>> uploadData = files
          .map((e) => MapEntry(
              key!,
              MultipartFile.fromFileSync(e.path,
                  filename: e.path.split('/').last)))
          .toList();

      final Response response = await _dio.post(
        url,
        data: FormData()..files.addAll(uploadData),
        options: Options(
          headers: headers,
        ),
        onSendProgress: (int sent, int total) {
          final double percent = (sent / total);
          callbackProcess?.call(percent);
        },
      );

      if (response.statusCode == 200) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('postUploadFile _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future<File?> downloadFromFtp(String url,
      {required Map<String, dynamic> body,
      required String filePath,
      Function(int, int)? callBack}) async {
    try {
      final String jso = jsonEncode(body);
      final Response response = await _dio.post(
        url, data: jso,
        onReceiveProgress: callBack,
        //Received data with List<int>
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      if (response.statusCode == 200) {
        final File file = File(filePath);
        file.createSync(recursive: true);
        final raf = file.openSync(mode: FileMode.write);
        raf.writeFromSync(response.data);
        await raf.close();
        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<dynamic> postWithFile(
      String url, Map<String, dynamic> body, List<File> files,
      {Map<String, String>? headers,
      String fileKey = 'file',
      int timeOut = 0}) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final List<MapEntry<String, MultipartFile>> uploadData = files
          .map((e) => MapEntry(
              fileKey,
              MultipartFile.fromFileSync(e.path,
                  filename: e.path.split('/').last)))
          .toList();

      final Response response = await _dio.post(
        url,
        data: FormData()
          ..files.addAll(uploadData)
          ..fields.addAll(
              body.entries.map((e) => MapEntry(e.key, e.value.toString()))),
        options: Options(headers: headers),
        // onSendProgress: (int sent, int total) {
        //   final double _percent = (sent / total);
        //   callbackProcess?.call(_percent);
        // },
      );

      if (response.statusCode == 200) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('postUploadFile _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future<dynamic> patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final response = await _dio.patch(
        url,
        data: jsonEncode(body),
        options: Options(headers: headers),
        queryParameters: queryParameters,
      );
      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('patchAsync _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future<dynamic> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      final response = await _dio.put(
        url,
        queryParameters: queryParameters,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );
      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('putAsync _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }

  @override
  Future method(
    String url,
    MethodName method, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var token = await (_storage.read<String?>(authorizationKey))?.unHash();
      headers ??= {'Authorization': token ?? ''};

      late final Response<dynamic> response;

      switch (method) {
        case MethodName.get:
          // TODO: Handle this case.
          response = await _dio.get(
            url,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          break;
        case MethodName.post:
          // TODO: Handle this case.
          response = await _dio.post(
            url,
            data: jsonEncode(body),
            options: Options(headers: headers),
            queryParameters: queryParameters,
          );
          break;
        case MethodName.put:
          // TODO: Handle this case.
          response = await _dio.put(
            url,
            queryParameters: queryParameters,
            data: jsonEncode(body),
            options: Options(headers: headers),
          );
          break;
        case MethodName.delete:
          // TODO: Handle this case.
          response = await _dio.delete(
            url,
            options: Options(headers: headers),
            queryParameters: queryParameters,
          );
          break;
        case MethodName.path:
          // TODO: Handle this case.
          response = await _dio.patch(
            url,
            data: jsonEncode(body),
            options: Options(headers: headers),
            queryParameters: queryParameters,
          );
          break;
      }

      if ([200, 404].contains(response.statusCode)) {
        //log(response.data);
        return jsonDecode(response.data);
      }
      throw ServerException();
    } catch (e) {
      log('patchAsync _ $e');
      if (e is ServerException) {
        rethrow;
      } else {
        throw NoConnectionException();
      }
    }
  }
}
