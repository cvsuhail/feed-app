import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/feed_model.dart';

class HomeApiService {
  static const String _baseUrl = 'https://frijo.noviindus.in/api/';
  static const String _tokenKey = 'access_token';
  
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      validateStatus: (int? status) => true,
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    ),
  );

  HomeApiService() {
    // Add interceptor to automatically include authorization header and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          await _addAuthHeader(options);
          debugPrint('HOME_API_REQUEST: ${options.method} ${options.uri}');
          debugPrint('HOME_API_HEADERS: ${options.headers}');
          debugPrint('HOME_API_QUERY_PARAMS: ${options.queryParameters}');
          handler.next(options);
        },
        onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
          debugPrint('HOME_API_RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          debugPrint('HOME_API_RESPONSE_DATA: ${response.data}');
          handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          debugPrint('HOME_API_ERROR: ${e.response?.statusCode} ${e.requestOptions.uri}');
          debugPrint('HOME_API_ERROR_DATA: ${e.response?.data}');
          handler.next(e);
        },
      ),
    );
  }

  // Cache of category name -> id mapping from last categories fetch
  Map<String, int> _categoryNameToId = <String, int>{};

  /// Gets the stored access token from SharedPreferences
  Future<String?> _getAccessToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString(_tokenKey);
      debugPrint('HOME_API_TOKEN_RETRIEVED: ${token != null ? 'Token exists (${token.length} chars)' : 'No token found'}');
      return token;
    } catch (e) {
      debugPrint('HOME_API_TOKEN_ERROR: $e');
      return null;
    }
  }

  /// Adds authorization header to the request
  Future<void> _addAuthHeader(RequestOptions options) async {
    final String? token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('HOME_API_AUTH_HEADER_ADDED: Bearer token (${token.length} chars)');
    } else {
      debugPrint('HOME_API_NO_AUTH_HEADER: No token available');
    }
  }

  /// Fetches feeds from the home endpoint
  Future<List<FeedModel>> getFeeds({
    String? category,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint('HOME_API_GET_FEEDS_CALLED: category=$category, page=$page, limit=$limit');
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      
      if (category != null && category.isNotEmpty && category != 'Explore') {
        queryParams['category'] = category;
      }
      debugPrint('HOME_API_GET_FEEDS_PARAMS: $queryParams');

      final Response<dynamic> response = await _dio.get(
        'home',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final dynamic data = response.data;
        debugPrint('HOME_API_GET_FEEDS_SUCCESS: Parsing response data (status: ${response.statusCode})');
        
        // Handle different response formats
        List<dynamic> feedsData = [];
        if (data is List) {
          feedsData = data;
          debugPrint('HOME_API_GET_FEEDS_DATA_FORMAT: Direct array (${feedsData.length} items)');
        } else if (data is Map<String, dynamic>) {
          // Updated to match actual API response structure
          feedsData = data['results'] ?? data['data'] ?? data['feeds'] ?? [];
          debugPrint('HOME_API_GET_FEEDS_DATA_FORMAT: Map with results (${feedsData.length} items)');
          debugPrint('HOME_API_GET_FEEDS_RESPONSE_KEYS: ${data.keys.toList()}');
        }

        final List<FeedModel> feeds = feedsData
            .map((feedJson) => FeedModel.fromJson(feedJson as Map<String, dynamic>))
            .toList();
        
        debugPrint('HOME_API_GET_FEEDS_PARSED: ${feeds.length} feeds parsed successfully');
        return feeds;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to access feeds.');
      } else {
        throw Exception('Failed to fetch feeds: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetches categories for filtering
  Future<List<String>> getCategories() async {
    try {
      debugPrint('HOME_API_GET_CATEGORIES_CALLED');
      final Response<dynamic> response = await _dio.get('category_list');
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        final dynamic decoded = response.data;
        debugPrint('HOME_API_GET_CATEGORIES_SUCCESS: Parsing categories data (status: ${response.statusCode})');
        debugPrint('HOME_API_GET_CATEGORIES_RESPONSE: $decoded');
        
        if (decoded is List) {
          final List<String> categories = decoded
              .map((dynamic e) => _extractCategoryName(e))
              .whereType<String>()
              .toList();
          debugPrint('HOME_API_GET_CATEGORIES_PARSED: ${categories.length} categories from direct list');
          return categories;
        }
        if (decoded is Map<String, dynamic>) {
          // Updated to match actual API response structure
          final dynamic data = decoded['categories'] ?? decoded['category_dict'] ?? decoded['data'] ?? decoded['result'];
          debugPrint('HOME_API_GET_CATEGORIES_DATA_SOURCE: ${decoded.keys.toList()}');
          if (data is List) {
            final List<String> categories = <String>[];
            final Map<String, int> nameToId = <String, int>{};
            
            for (final dynamic item in data) {
              if (item is Map<String, dynamic>) {
                final String? title = item['title']?.toString();
                final int? id = item['id'] is int ? item['id'] : int.tryParse(item['id']?.toString() ?? '');
                
                if (title != null && title.isNotEmpty && id != null) {
                  categories.add(title);
                  nameToId[title] = id;
                }
              } else {
                // Fallback to old parsing method
                final String? name = _extractCategoryName(item);
                if (name != null) {
                  categories.add(name);
                }
              }
            }
            
            _categoryNameToId = nameToId;
            debugPrint('HOME_API_GET_CATEGORIES_PARSED: ${categories.length} categories from map with ${_categoryNameToId.length} ID mappings');
            return categories;
          } else if (decoded['category_dict'] is Map<String, dynamic>) {
            // Expecting { "23": "Sports", "24": "Music", ... }
            final Map<String, dynamic> dict = decoded['category_dict'] as Map<String, dynamic>;
            final Map<String, int> nameToId = <String, int>{};
            final List<String> names = <String>[];
            dict.forEach((String key, dynamic value) {
              final String? name = value?.toString();
              if (name != null && name.isNotEmpty) {
                final int? id = int.tryParse(key);
                if (id != null) {
                  nameToId[name] = id;
                  names.add(name);
                }
              }
            });
            _categoryNameToId = nameToId;
            debugPrint('HOME_API_GET_CATEGORIES_FROM_DICT: parsed ${_categoryNameToId.length} entries');
            return names;
          }
        }
        debugPrint('HOME_API_GET_CATEGORIES_EMPTY: No categories found');
        return <String>[];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to access categories.');
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  String? _extractCategoryName(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      return (item['name'] ?? item['title'] ?? item['category_name'] ?? item['label'])?.toString();
    }
    return null;
  }

  /// Resolves category IDs for provided names using the last fetched mapping
  List<int> getCategoryIdsForNames(Iterable<String> names) {
    if (_categoryNameToId.isEmpty) return <int>[];
    final List<int> ids = <int>[];
    for (final String name in names) {
      final int? id = _categoryNameToId[name];
      if (id != null) ids.add(id);
    }
    return ids;
  }

  /// Upload a new feed using multipart/form-data
  Future<void> uploadFeed({
    required File videoFile,
    required File imageFile,
    required String description,
    required List<int> categoryIds,
  }) async {
    try {
      debugPrint('HOME_API_UPLOAD_FEED_CALLED: descLen=${description.length}, categories=${categoryIds.length}');
      debugPrint('HOME_API_UPLOAD_FEED_CATEGORY_IDS: $categoryIds');

      // Create FormData with proper multipart fields
      final Map<String, dynamic> formDataMap = <String, dynamic>{
        'video': await MultipartFile.fromFile(
          videoFile.path, 
          filename: videoFile.uri.pathSegments.isNotEmpty ? videoFile.uri.pathSegments.last : 'video.mp4'
        ),
        'image': await MultipartFile.fromFile(
          imageFile.path, 
          filename: imageFile.uri.pathSegments.isNotEmpty ? imageFile.uri.pathSegments.last : 'image.jpg'
        ),
        'desc': description,
      };
      
      // Add category IDs - try simple format first
      if (categoryIds.isNotEmpty) {
        formDataMap['category'] = categoryIds.first; // Send first category ID as simple value
      }
      
      final FormData formData = FormData.fromMap(formDataMap);

      debugPrint('HOME_API_UPLOAD_FEED_FORM_DATA: video=${videoFile.path}, image=${imageFile.path}, desc=$description, category=$categoryIds');
      debugPrint('HOME_API_UPLOAD_FEED_VIDEO_EXISTS: ${await videoFile.exists()}');
      debugPrint('HOME_API_UPLOAD_FEED_IMAGE_EXISTS: ${await imageFile.exists()}');

      final Response<dynamic> response = await _dio.post(
        'my_feed',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(minutes: 5), // Increase timeout for file uploads
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception('Upload failed: ${response.statusCode} ${response.data}');
      }

      debugPrint('HOME_API_UPLOAD_FEED_SUCCESS: ${response.statusCode}');
      debugPrint('HOME_API_UPLOAD_FEED_RESPONSE: ${response.data}');
    } on DioException catch (e) {
      debugPrint('HOME_API_UPLOAD_FEED_DIO_ERROR: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('HOME_API_UPLOAD_FEED_ERROR_RESPONSE: ${e.response?.statusCode} - ${e.response?.data}');
        throw Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      debugPrint('HOME_API_UPLOAD_FEED_GENERAL_ERROR: $e');
      rethrow;
    }
  }
}
