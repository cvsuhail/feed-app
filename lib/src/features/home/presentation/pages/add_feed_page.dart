import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class AddFeedPage extends StatefulWidget {
  const AddFeedPage({super.key});

  @override
  State<AddFeedPage> createState() => _AddFeedPageState();
}

class _AddFeedPageState extends State<AddFeedPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedCategories = <String>{};

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const _HeaderBar(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _UploadVideoCard(),
                    SizedBox(height: 24),
                    _UploadThumbCard(),
                    SizedBox(height: 24),
                    _DescriptionSection(controller: _descriptionController),
                    SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    SizedBox(height: 12),
                    _CategoriesSection(
                      selectedCategories: _selectedCategories,
                      onCategorySelected: (String category) {
                        setState(() {
                          if (_selectedCategories.contains(category)) {
                            _selectedCategories.remove(category);
                          } else {
                            _selectedCategories.add(category);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              // decoration: BoxDecoration(
              //   color: Colors.white.withOpacity(0.06),
              //   shape: BoxShape.circle,
              //   border: Border.all(color: Colors.white.withOpacity(0.15)),
              // ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icons/backIcon.png',
                width: 36,
                height: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Add Feeds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(66, 83, 17, 27),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color.fromARGB(255, 246, 0, 0).withOpacity(0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Share Post',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadVideoCard extends StatelessWidget {
  const _UploadVideoCard();

  @override
  Widget build(BuildContext context) {
    return _DashedBorderBox(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/icons/videoUploadIcon.png',
              width: 54,
              height: 54,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a video from Gallery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadThumbCard extends StatelessWidget {
  const _UploadThumbCard();

  @override
  Widget build(BuildContext context) {
    return _DashedBorderBox(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/icons/thumbUploadIcon.png',
              width: 36,
              height: 36,
              color: Colors.white,
            ),
            const SizedBox(width: 14),
            const Text(
              'Add a Thumbnail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.controller});
  
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Add Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
           
          ),
          child: TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              hintText: 'Write a description for your feed...',
              hintStyle: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({
    required this.selectedCategories,
    required this.onCategorySelected,
  });
  
  final Set<String> selectedCategories;
  final void Function(String category) onCategorySelected;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  late final Dio _dio;
  late final Future<List<String>> _future;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://frijo.noviindus.in/api/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      ),
    );
    _future = _fetchCategories();
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final Response<dynamic> response = await _dio.get('category_list');
      final dynamic decoded = response.data;
      if (decoded is List) {
        return decoded
            .map((dynamic e) => _extractCategoryName(e))
            .whereType<String>()
            .toList(growable: false);
      }
      if (decoded is Map<String, dynamic>) {
        final dynamic data = decoded['data'] ?? decoded['categories'] ?? decoded['result'];
        if (data is List) {
          return data
              .map((dynamic e) => _extractCategoryName(e))
              .whereType<String>()
              .toList(growable: false);
        }
      }
      return const <String>[];
    } on DioException {
      return const <String>[];
    }
  }

  String? _extractCategoryName(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      return (item['name'] ?? item['title'] ?? item['category_name'] ?? item['label'])?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Categories This Project',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            FutureBuilder<List<String>>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                final List<String> categories = snapshot.data ?? const <String>[];
                final bool showToggle = categories.length > 6;
                if (!showToggle) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => setState(() { _expanded = !_expanded; }),
                  child: Row(
                    children: <Widget>[
                      Text(
                        _expanded ? 'View Less' : 'View All',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.rotate(
                        angle: math.pi,
                        child: Image.asset(
                          'assets/icons/backIcon.png',
                          width: 16,
                          height: 16,
                          color: const Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<String>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const <double>[80, 120, 90, 100, 140, 110]
                    .map((double w) => _ChipSkeleton(width: w))
                    .toList(growable: false),
              );
            }
            final List<String> categories = snapshot.data ?? const <String>[];
            if (categories.isEmpty) {
              return const Text(
                'No categories available',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              );
            }
            final List<String> visible = _expanded ? categories : categories.take(6).toList(growable: false);
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: visible
                  .map((String c) => _CategoryChip(
                        label: c,
                        isSelected: widget.selectedCategories.contains(c),
                        onTap: () => widget.onCategorySelected(c),
                      ))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 246, 0, 0).withOpacity(0.2)
              : const Color.fromARGB(66, 83, 17, 27),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 246, 0, 0).withOpacity(0.6)
                : const Color.fromARGB(255, 246, 0, 0).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCCCCCC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChipSkeleton extends StatelessWidget {
  const _ChipSkeleton({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
    );
  }
}

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({
    required this.child,
    this.radius = 12,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.white.withOpacity(0.15),
        radius: radius,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    const double dashWidth = 6;
    const double dashSpace = 6;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    final ui.Path path = ui.Path()..addRRect(rrect);
    final ui.PathMetrics metrics = path.computeMetrics(forceClosed: false);
    for (final ui.PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
