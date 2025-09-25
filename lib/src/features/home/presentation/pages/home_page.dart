import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/feed_model.dart';
import '../../data/services/home_api_service.dart';
import '../widgets/enhanced_video_player.dart';
import 'add_feed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'Explore';
  late final Future<List<String>> _categoriesFuture;
  late final HomeApiService _apiService;
  int? _currentlyPlayingIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = HomeApiService();
    _categoriesFuture = _apiService.getCategories();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Auto-pause video when scrolling away from current playing video
      if (_currentlyPlayingIndex != null) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = _scrollController.position;
          final viewportHeight = position.viewportDimension;
          final currentOffset = position.pixels;
          
          // Calculate approximate position of current playing video
          final videoHeight = 460.0; // Approximate video height
          final videoTop = _currentlyPlayingIndex! * videoHeight;
          final videoBottom = videoTop + videoHeight;
          
          // If current playing video is not in viewport, pause it
          if (videoBottom < currentOffset || videoTop > currentOffset + viewportHeight) {
            setState(() {
              _currentlyPlayingIndex = null;
            });
          }
        }
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentlyPlayingIndex = null; // Reset playing video when filter changes
    });
  }

  void _onVideoPlayPause(int index) {
    setState(() {
      if (_currentlyPlayingIndex == index) {
        _currentlyPlayingIndex = null; // Pause current video
      } else {
        _currentlyPlayingIndex = index; // Play new video (this will auto-pause others)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // _selectedFilter is used in the onFilterChanged callback below
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AddFeedPage(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 100,
          child: Image.asset(
            'assets/icons/addIcon.png',
            width: 80,
            height: 80,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _categoriesFuture,
              builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                final List<String> categories = snapshot.data ?? <String>[];
                if (isLoading) {
                  return const _LoadingFilterRow();
                }
                if (categories.isEmpty) {
                  return _FilterButtons(
                    categories: const <String>['Explore', 'Trending', 'All Categories', 'Photos'],
                    selectedFilter: _selectedFilter,
                    onFilterChanged: _onFilterChanged,
                  );
                }
                final List<String> items = <String>['Explore', ...categories];
                return _FilterButtons(
                  categories: items,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: _onFilterChanged,
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _FeedList(
                selectedFilter: _selectedFilter,
                apiService: _apiService,
                currentlyPlayingIndex: _currentlyPlayingIndex,
                onVideoPlayPause: _onVideoPlayPause,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello Maria',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back to Section',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _FilterButtons extends StatelessWidget {
  const _FilterButtons({
    required this.categories,
    required this.selectedFilter,
    required this.onFilterChanged,
  });
  final List<String> categories;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 10, end: 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
      builder: (BuildContext context, double dy, Widget? child) {
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(opacity: (1 - (dy / 10)).clamp(0.0, 1.0), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.asMap().entries.map((entry) {
              final int index = entry.key;
              final String label = entry.value;
              final bool isFirst = index == 0;
              
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _FilterButton(
                      label: label,
                      isSelected: selectedFilter == label,
                      icon: isFirst && label == 'Explore' ? 'assets/icons/exploreIcon.png' : null,
                      onTap: () => onFilterChanged(label),
                    ),
                  ),
                  if (isFirst && categories.length > 1) ...[
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _LoadingFilterRow extends StatelessWidget {
  const _LoadingFilterRow();

  @override
  Widget build(BuildContext context) {
    const List<double> widths = <double>[64, 92, 120, 80, 100];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widths
              .map((double w) => Container(
                    width: w,
                    height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// removed _FilterSeparator (no longer used)

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ?  const Color.fromARGB(255, 255, 144, 144).withOpacity(0.1) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(
            color:  AppTheme.primaryRed.withOpacity(0.6),
            width: 1,
          ) : Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.3),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 20,
                height: 20,
                // decoration: BoxDecoration(
                //   color: Colors.white.withOpacity(0.1),
                //   shape: BoxShape.circle,
                // ),
                child: Center(
                  child: Image.asset(
                    icon!,
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
               
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  const _FeedList({
    required this.selectedFilter,
    required this.apiService,
    required this.currentlyPlayingIndex,
    required this.onVideoPlayPause,
    required this.scrollController,
  });

  final String selectedFilter;
  final HomeApiService apiService;
  final int? currentlyPlayingIndex;
  final ValueChanged<int> onVideoPlayPause;
  final ScrollController scrollController;

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  List<FeedModel> _feeds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void didUpdateWidget(_FeedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _loadFeeds();
    }
  }

  Future<void> _loadFeeds() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final feeds = await widget.apiService.getFeeds(category: widget.selectedFilter);
      if (mounted) {
        setState(() {
          _feeds = feeds;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load feeds',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No feeds available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemCount: _feeds.length,
      itemBuilder: (context, index) {
        final feed = _feeds[index];
        return _FeedCard(
          feed: feed,
          isPlaying: widget.currentlyPlayingIndex == index,
          onPlayPause: () => widget.onVideoPlayPause(index),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.feed,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final FeedModel feed;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: feed.userDetails.avatar.isNotEmpty && !feed.userDetails.avatar.startsWith('assets/')
                        ? Image.network(
                            feed.userDetails.avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            feed.userDetails.avatar.isNotEmpty && feed.userDetails.avatar.startsWith('assets/')
                                ? feed.userDetails.avatar
                                : 'assets/images/avatar.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed.userDetails.name.isNotEmpty 
                            ? feed.userDetails.name 
                            : feed.userDetails.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TimeUtils.formatTimeAgo(feed.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Video player
          EnhancedVideoPlayer(
            videoUrl: feed.video,
            thumbnailUrl: feed.thumbnail,
            isPlaying: isPlaying,
            onPlayPause: onPlayPause,
          ),
          const SizedBox(height: 12),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: feed.description.length > 150 
                        ? '${feed.description.substring(0, 150)}...'
                        : feed.description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                  if (feed.description.length > 150)
                    const TextSpan(
                      text: ' See More',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decorationColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Action buttons (likes, comments)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_border,
                  count: feed.likes,
                  onTap: () {
                    // Handle like action
                  },
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: feed.comments,
                  onTap: () {
                    // Handle comment action
                  },
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.share_outlined,
                  count: 0,
                  onTap: () {
                    // Handle share action
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
