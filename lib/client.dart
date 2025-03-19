import 'package:dio/dio.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:todoer/models/task.dart';

class TodoerClient {
  final Dio _dio;
  String? _token;

  TodoerClient(String baseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          followRedirects: false,
          contentType: 'application/json',
        )) {
    _dio.httpClientAdapter = NativeAdapter();
    _dio.interceptors
        .add(PrettyDioLogger(requestBody: true, responseBody: false));
  }

  Future<List<dynamic>> createTask({
    required String title,
    required bool isProject,
    required String? link,
    required int? parentId,
    required List<String> systemTags,
  }) async {
    return await _request(
      'POST',
      '/tasks/',
      queryParams: {"get_list": "1"},
      data: {
        'title': title,
        'is_project': isProject,
        'link': link,
        'system_tags': systemTags,
        'parent': parentId,
      },
    );
  }

  Future<List<dynamic>> getTasksTree() async {
    return await _request<List<dynamic>>('GET', '/tasks/');
  }

  Future<List<dynamic>> updateTask(
    int id, {
    required String title,
    required bool isProject,
    required String? link,
    required List<String> systemTags,
  }) async {
    return await _request(
      'PATCH',
      "/tasks/$id/",
      queryParams: {"get_list": "1"},
      data: {
        'title': title,
        'is_project': isProject,
        'link': link,
        'system_tags': systemTags,
      },
    );
  }

  Future<List<dynamic>> setTaskStatus(int id, String status) async {
    return await _request(
      'PATCH',
      "/tasks/$id/status/",
      data: {'value': status},
    );
  }

  Future<List<dynamic>> moveTask(
    int id,
    int? newParentId,
    int newOrder,
  ) async {
    return await _request(
      'PATCH',
      "/tasks/$id/move/",
      queryParams: {"get_list": "1"},
      data: {
        'parent': newParentId,
        'order': newOrder,
      },
    );
  }

  Future<List<dynamic>> deleteTask(int id) async {
    return await _request(
      'DELETE',
      "/tasks/$id/",
      queryParams: {"get_list": "1"},
    );
  }

  Future<List<dynamic>> deleteAllDoneTasks() async {
    return await _request(
      'DELETE',
      '/tasks/batch/',
      queryParams: {"status": TaskStatus.done.name, "get_list": "1"},
    );
  }

  setToken(String? token) {
    _token = token;
  }

  logoutToken() async {
    await _request('POST', '/auth/tokens/logout/');
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParams,
  }) async {
    assert(_token != null);
    var response = await _dio.request<T>(
      path,
      queryParameters: queryParams,
      data: data,
      options: Options(
        method: method,
        headers: {"Authorization": "Token $_token"},
      ),
    );
    return response.data!;
  }
}
