import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isPlaying,
    this.onPlayPause,
    this.onTap,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  bool _isLoading = true;
  bool _hasError = false;
  int _initializationAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if video URL actually changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
    } else if (oldWidget.isPlaying != widget.isPlaying) {
      // Only handle play/pause if video URL is the same
      _handlePlayPause();
    }
  }

  void _initializeVideo() async {
    if (!mounted || _hasError) return;
    
    // Circuit breaker: prevent too many initialization attempts
    if (_initializationAttempts >= 3) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }
    
    _initializationAttempts++;
    
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      
      if (mounted && _controller != null) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _hasError = false;
        });
        
        // Auto-play if this video should be playing
        if (widget.isPlaying) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Video initialization error (attempt $_initializationAttempts): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_initializationAttempts >= 3) {
            _hasError = true;
          }
        });
      }
    }
  }

  void _handlePlayPause() {
    if (_controller != null && _isInitialized && mounted) {
      if (widget.isPlaying) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    // Auto-hide controls after 3 seconds
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _seekTo(Duration position) {
    if (_controller != null && _isInitialized) {
      _controller!.seekTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          _toggleControls();
          widget.onTap?.call();
        }
      },
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player or thumbnail
            if (_isInitialized && _controller != null && mounted && !_hasError)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            else if (_isLoading && !_hasError)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            else
              _buildThumbnail(),
            
            // Controls overlay
            if (_showControls && _isInitialized && _controller != null && mounted && !_hasError)
              _buildControlsOverlay(),
            
            // Play button overlay (when not playing or not initialized)
            if (!widget.isPlaying || !_isInitialized || _hasError)
              _buildPlayButtonOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: double.infinity,
      height: 460,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        image: widget.thumbnailUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(widget.thumbnailUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.thumbnailUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons.video_library,
                color: Colors.white54,
                size: 60,
              ),
            )
          : null,
    );
  }

  Widget _buildPlayButtonOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: GestureDetector(
          onTap: widget.onPlayPause,
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
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (_controller == null || !_isInitialized) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: widget.onPlayPause,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Seek backward
                GestureDetector(
                  onTap: () {
                    final currentPosition = _controller!.value.position;
                    final newPosition = currentPosition - const Duration(seconds: 10);
                    _seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Seek forward
                GestureDetector(
                  onTap: () {
                    final currentPosition = _controller!.value.position;
                    final duration = _controller!.value.duration;
                    final newPosition = currentPosition + const Duration(seconds: 10);
                    _seekTo(newPosition > duration ? duration : newPosition);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
