import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/thumbnail_preloader.dart';

class EnhancedVideoPlayer extends StatefulWidget {
  const EnhancedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isPlaying,
    required this.onPlayPause,
    this.aspectRatio,
    this.onControllerReady,
  });

  final String videoUrl;
  final String thumbnailUrl;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double? aspectRatio;
  final Function(VideoPlayerController)? onControllerReady;

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;
  bool _isBuffering = false;
  bool _isThumbnailLoaded = false;
  Timer? _controlsTimer;
  double _currentAspectRatio = 16 / 9; // Default aspect ratio
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(EnhancedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
    } else if (oldWidget.isPlaying != widget.isPlaying && _isInitialized) {
      _handlePlayPause();
    }
  }

  void _initializeVideo() async {
    if (!mounted || _isDisposed) return;

    try {
      // Dispose existing controller if any
      _disposeController();
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      // Listen to controller events
      _controller!.addListener(_videoListener);
      
      await _controller!.initialize();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _currentAspectRatio = _controller!.value.aspectRatio;
        });
        
        // Notify parent about controller readiness
        widget.onControllerReady?.call(_controller!);
        
        // Only auto-play if this video should be playing
        if (widget.isPlaying) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _isDisposed) return;
    
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _isBuffering = controller.value.isBuffering;
    });
  }

  void _handlePlayPause() {
    if (_controller != null && _isInitialized && mounted && !_isDisposed) {
      if (widget.isPlaying) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  void _disposeController() {
    _controlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _seekTo(Duration position) {
    if (_controller != null && _isInitialized) {
      _controller!.seekTo(position);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showControlsTemporarily();
        widget.onPlayPause();
      },
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video or thumbnail
            if (_isInitialized && _controller != null && !_hasError)
              _buildVideoPlayer()
            else
              _buildThumbnail(),
            
            // Buffering indicator
            if (_isBuffering && widget.isPlaying)
              _buildBufferingIndicator(),
            
            // Controls overlay
            if (_showControls && _isInitialized && _controller != null && !_hasError)
              _buildControlsOverlay(),
            
            // Play button overlay (when not playing or not initialized)
            if (!widget.isPlaying || !_isInitialized || _hasError)
              _buildPlayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? _currentAspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? _currentAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
        ),
        child: Stack(
          children: [
            // Thumbnail image with smooth loading and preloading support
            if (widget.thumbnailUrl.isNotEmpty)
              AnimatedOpacity(
                opacity: _isThumbnailLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildThumbnailImage(),
              ),
            
            // Fallback icon when no thumbnail or error
            if (widget.thumbnailUrl.isEmpty || !_isThumbnailLoaded)
              const Center(
                child: Icon(
                  Icons.video_library,
                  color: Colors.white54,
                  size: 60,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    final preloader = ThumbnailPreloader();
    final preloadedImage = preloader.getPreloadedImage(widget.thumbnailUrl);
    
    if (preloadedImage != null) {
      // Use preloaded image for instant display
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isThumbnailLoaded = true;
          });
        }
      });
      
      return Image(
        image: preloadedImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // Fallback to network image with loading states
      return Image.network(
        widget.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Image loaded successfully
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _isThumbnailLoaded = true;
                });
              }
            });
            return child;
          }
          // Show loading indicator while thumbnail loads
          return Container(
            color: const Color(0xFF2C2C2C),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2C2C2C),
            child: const Center(
              child: Icon(
                Icons.video_library,
                color: Colors.white54,
                size: 60,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildBufferingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final controller = _controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;
    
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top controls (play/pause button)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: widget.onPlayPause,
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom controls (progress bar and time)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Progress slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _seekTo(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                // Time labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
