import 'dart:async';
import 'package:flutter/material.dart';

class ThumbnailPreloader {
  static final ThumbnailPreloader _instance = ThumbnailPreloader._internal();
  factory ThumbnailPreloader() => _instance;
  ThumbnailPreloader._internal();

  final Map<String, ImageProvider> _preloadedImages = {};
  final Map<String, Completer<ImageProvider>> _loadingCompleters = {};
  final Set<String> _currentlyLoading = {};

  /// Preload thumbnail images for better user experience
  Future<void> preloadThumbnails(List<String> thumbnailUrls) async {
    final futures = thumbnailUrls
        .where((url) => url.isNotEmpty && !_preloadedImages.containsKey(url))
        .map((url) => _preloadSingleThumbnail(url));
    
    await Future.wait(futures);
  }

  /// Preload a single thumbnail
  Future<ImageProvider> _preloadSingleThumbnail(String url) async {
    if (_preloadedImages.containsKey(url)) {
      return _preloadedImages[url]!;
    }

    if (_loadingCompleters.containsKey(url)) {
      return _loadingCompleters[url]!.future;
    }

    if (_currentlyLoading.contains(url)) {
      final completer = Completer<ImageProvider>();
      _loadingCompleters[url] = completer;
      return completer.future;
    }

    _currentlyLoading.add(url);

    try {
      final imageProvider = NetworkImage(url);
      
      // Preload the image
      await precacheImage(imageProvider, NavigationService.navigatorKey.currentContext!);
      
      _preloadedImages[url] = imageProvider;
      _loadingCompleters[url]?.complete(imageProvider);
      _loadingCompleters.remove(url);
      
      return imageProvider;
    } catch (e) {
      debugPrint('Failed to preload thumbnail: $url, error: $e');
      _loadingCompleters[url]?.completeError(e);
      _loadingCompleters.remove(url);
      rethrow;
    } finally {
      _currentlyLoading.remove(url);
    }
  }

  /// Get preloaded image provider
  ImageProvider? getPreloadedImage(String url) {
    return _preloadedImages[url];
  }

  /// Check if image is preloaded
  bool isPreloaded(String url) {
    return _preloadedImages.containsKey(url);
  }

  /// Clear preloaded images to free memory
  void clearCache() {
    _preloadedImages.clear();
    _loadingCompleters.clear();
    _currentlyLoading.clear();
  }

  /// Clear specific image from cache
  void removeFromCache(String url) {
    _preloadedImages.remove(url);
    _loadingCompleters.remove(url);
    _currentlyLoading.remove(url);
  }
}

/// Navigation service to access navigator context
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
