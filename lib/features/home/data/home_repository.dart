import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import 'models/cook.dart';
import 'models/menu_item.dart';

class HomeRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /menu/items — liste paginée de plats avec filtres optionnels
  Future<PaginatedResult<MenuItem>> getMenuItems({
    String? quarterId,
    String? category,
    String? search,
    bool? isDailySpecial,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.menuItems,
        queryParameters: {
          'quarterId': quarterId,
          'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'isDailySpecial': isDailySpecial,
          'page': page,
          'limit': limit,
        }..removeWhere((_, v) => v == null),
      );
      return _parseMenuItemsResponse(response.data);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// GET /cooks — liste paginée de cuisinières
  Future<PaginatedResult<Cook>> getCooks({
    String? quarterId,
    String? city,
    String? sort,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cooks,
        queryParameters: {
          'quarterId': quarterId,
          'city': city,
          'sort': sort,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        }..removeWhere((_, v) => v == null),
      );
      return _parseCooksResponse(response.data);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// GET /cooks/:id — détail d'une cuisinière avec ses plats
  Future<Cook> getCookDetail(String id) async {
    try {
      final response = await _dio.get(ApiConstants.cookById(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Cook.fromJson(data);
      }
      throw const ApiException(message: 'Format de réponse inattendu');
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  PaginatedResult<MenuItem> _parseMenuItemsResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        data: list,
        total: (data['total'] as num?)?.toInt() ?? list.length,
        page: (data['page'] as num?)?.toInt() ?? 1,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      );
    }
    if (data is List) {
      final list =
          data.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
      return PaginatedResult(data: list, total: list.length, page: 1, totalPages: 1);
    }
    return const PaginatedResult(data: [], total: 0, page: 1, totalPages: 1);
  }

  PaginatedResult<Cook> _parseCooksResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Cook.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        data: list,
        total: (data['total'] as num?)?.toInt() ?? list.length,
        page: (data['page'] as num?)?.toInt() ?? 1,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      );
    }
    if (data is List) {
      final list =
          data.map((e) => Cook.fromJson(e as Map<String, dynamic>)).toList();
      return PaginatedResult(data: list, total: list.length, page: 1, totalPages: 1);
    }
    return const PaginatedResult(data: [], total: 0, page: 1, totalPages: 1);
  }
}
