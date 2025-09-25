import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../data/services/home_api_service.dart';

class AddFeedPage extends StatefulWidget {
  const AddFeedPage({super.key});

  @override
  State<AddFeedPage> createState() => _AddFeedPageState();
}

class _AddFeedPageState extends State<AddFeedPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedCategories = <String>{};
  final HomeApiService _api = HomeApiService();

  File? _selectedVideo;
  File? _selectedImage;
  bool _submitting = false;
  bool _hasValidationErrors = false;
  String? _videoFileSize;
  String? _imageFileSize;

  Future<void> _pickVideo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        allowCompression: false, // Keep original quality
      );
      
      if (result != null && result.files.single.path != null) {
        final File videoFile = File(result.files.single.path!);
        
        // Validate file exists and is readable
        if (await videoFile.exists()) {
          final int fileSizeBytes = await videoFile.length();
          final String fileSizeText = _formatFileSize(fileSizeBytes);
          
          setState(() {
            _selectedVideo = videoFile;
            _videoFileSize = fileSizeText;
            _hasValidationErrors = false; // Clear validation errors when user selects file
          });
          
          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video selected: ${videoFile.path.split('/').last}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Selected video file does not exist');
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select video: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowCompression: false, // Keep original quality
      );
      
      if (result != null && result.files.single.path != null) {
        final File imageFile = File(result.files.single.path!);
        
        // Validate file exists and is readable
        if (await imageFile.exists()) {
          final int fileSizeBytes = await imageFile.length();
          final String fileSizeText = _formatFileSize(fileSizeBytes);
          
          setState(() {
            _selectedImage = imageFile;
            _imageFileSize = fileSizeText;
            _hasValidationErrors = false; // Clear validation errors when user selects file
          });
          
          // Show success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image selected: ${imageFile.path.split('/').last}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Selected image file does not exist');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    
    // Comprehensive validation for all mandatory fields
    String? validationError = _validateForm();
    if (validationError != null) {
      setState(() { _hasValidationErrors = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() { _submitting = true; });
    try {
      // Ensure categories are loaded at least once to populate mapping
      await _api.getCategories();
      final List<int> categoryIds = _api.getCategoryIdsForNames(_selectedCategories);
      
      if (categoryIds.isEmpty) {
        throw Exception('Selected categories could not be mapped to valid IDs. Please try selecting different categories.');
      }
      
      await _api.uploadFeed(
        videoFile: _selectedVideo!,
        imageFile: _selectedImage!,
        description: _descriptionController.text.trim(),
        categoryIds: categoryIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed uploaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _submitting = false; });
      }
    }
  }

  String? _validateForm() {
    if (_selectedVideo == null) {
      return 'Please select a video from your gallery.';
    }
    if (_selectedImage == null) {
      return 'Please select a thumbnail image from your gallery.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please enter a description for your feed.';
    }
    if (_descriptionController.text.trim().length < 10) {
      return 'Description must be at least 10 characters long.';
    }
    if (_selectedCategories.isEmpty) {
      return 'Please select at least one category for your feed.';
    }
    return null; // No validation errors
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      if (_hasValidationErrors && _descriptionController.text.trim().isNotEmpty) {
        setState(() { _hasValidationErrors = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _HeaderBar(onShare: _submit, submitting: _submitting),
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
                    _UploadVideoCard(
                      onPick: _pickVideo,
                      fileName: _selectedVideo != null ? _selectedVideo!.path.split('/').last : null,
                      fileSize: _videoFileSize,
                      hasError: _hasValidationErrors && _selectedVideo == null,
                    ),
                    SizedBox(height: 24),
                    _UploadThumbCard(
                      onPick: _pickImage,
                      fileName: _selectedImage != null ? _selectedImage!.path.split('/').last : null,
                      fileSize: _imageFileSize,
                      hasError: _hasValidationErrors && _selectedImage == null,
                    ),
                    SizedBox(height: 24),
                    _DescriptionSection(
                      controller: _descriptionController,
                      hasError: _hasValidationErrors && _descriptionController.text.trim().isEmpty,
                    ),
                    SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    SizedBox(height: 12),
                    _CategoriesSection(
                      selectedCategories: _selectedCategories,
                      hasError: _hasValidationErrors && _selectedCategories.isEmpty,
                      onCategorySelected: (String category) {
                        setState(() {
                          if (_selectedCategories.contains(category)) {
                            _selectedCategories.remove(category);
                          } else {
                            _selectedCategories.add(category);
                          }
                          _hasValidationErrors = false; // Clear validation errors when user selects category
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
  const _HeaderBar({required this.onShare, required this.submitting});
  final VoidCallback onShare;
  final bool submitting;

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
          GestureDetector(
            onTap: submitting ? null : onShare,
            child: Opacity(
              opacity: submitting ? 0.6 : 1.0,
              child: Container(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (submitting) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Share Post',
                      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadVideoCard extends StatelessWidget {
  const _UploadVideoCard({
    required this.onPick, 
    this.fileName,
    this.hasError = false,
    this.fileSize,
  });
  final VoidCallback onPick;
  final String? fileName;
  final bool hasError;
  final String? fileSize;

  @override
  Widget build(BuildContext context) {
    return _DashedBorderBox(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        child: GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: hasError ? Border.all(color: Colors.red, width: 2) : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  'assets/icons/videoUploadIcon.png',
                  width: 54,
                  height: 54,
                  color: hasError ? Colors.red : Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  fileName ?? 'Select a video from Gallery',
                  style: TextStyle(
                    color: hasError ? Colors.red : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fileName != null && fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fileSize!,
                    style: TextStyle(
                      color: hasError ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (hasError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Video selection is required',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}

class _UploadThumbCard extends StatelessWidget {
  const _UploadThumbCard({
    required this.onPick, 
    this.fileName,
    this.hasError = false,
    this.fileSize,
  });
  final VoidCallback onPick;
  final String? fileName;
  final bool hasError;
  final String? fileSize;

  @override
  Widget build(BuildContext context) {
    return _DashedBorderBox(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        child: GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: hasError ? Border.all(color: Colors.red, width: 2) : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 28),
            child:             Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/icons/thumbUploadIcon.png',
                      width: 36,
                      height: 36,
                      color: hasError ? Colors.red : Colors.white,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      fileName ?? 'Add a Thumbnail',
                      style: TextStyle(
                        color: hasError ? Colors.red : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (fileName != null && fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fileSize!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: hasError ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (hasError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Thumbnail selection is required',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.controller,
    this.hasError = false,
  });
  
  final TextEditingController controller;
  final bool hasError;

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
            border: hasError ? Border.all(color: Colors.red, width: 2) : null,
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
            decoration: InputDecoration(
              hintText: 'Write a description for your feed...',
              hintStyle: TextStyle(
                color: hasError ? Colors.red.withOpacity(0.7) : const Color(0xFF9E9E9E),
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
        if (hasError) ...[
          const SizedBox(height: 8),
          const Text(
            'Description is required (minimum 10 characters)',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({
    required this.selectedCategories,
    required this.onCategorySelected,
    this.hasError = false,
  });
  
  final Set<String> selectedCategories;
  final void Function(String category) onCategorySelected;
  final bool hasError;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  late final HomeApiService _apiService;
  late final Future<List<String>> _future;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _apiService = HomeApiService();
    _future = _apiService.getCategories();
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: visible
                      .map((String c) => _CategoryChip(
                            label: c,
                            isSelected: widget.selectedCategories.contains(c),
                            onTap: () => widget.onCategorySelected(c),
                          ))
                      .toList(growable: false),
                ),
                if (widget.hasError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Please select at least one category',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
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
