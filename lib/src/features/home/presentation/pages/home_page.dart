import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'Explore';
  late final Future<List<String>> _categoriesFuture;
  late final Dio _dio;

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
    _categoriesFuture = _fetchCategories();
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final Response<dynamic> response = await _dio.get('category_list');
      final dynamic decoded = response.data;
      if (decoded is List) {
        return decoded
            .map((dynamic e) => _extractCategoryName(e))
            .whereType<String>()
            .toList();
      }
      if (decoded is Map<String, dynamic>) {
        final dynamic data = decoded['data'] ?? decoded['categories'] ?? decoded['result'];
        if (data is List) {
          return data
              .map((dynamic e) => _extractCategoryName(e))
              .whereType<String>()
              .toList();
        }
      }
      return <String>[];
    } on DioException {
      return <String>[];
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
    // _selectedFilter is used in the onFilterChanged callback below
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton(
          onPressed: () {},
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
                    onFilterChanged: (String filter) {
                      setState(() { _selectedFilter = filter; });
                    },
                  );
                }
                final List<String> items = <String>['Explore', ...categories];
                return _FilterButtons(
                  categories: items,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (String filter) {
                    setState(() { _selectedFilter = filter; });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _FeedList(),
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
    return Padding(
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

class _FeedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: const [
        _FeedCard(
          userName: 'Michel Jhon',
          timeAgo: '5 days ago',
          description: 'Lorem ipsum dolor sit amet consectetur. Leo ac lorem faucli bus facilisis tellus. At vitae dis commodo nunc sollicitudin elementum suspendisse... See More',
          hasActionButton: false,
        ),
        _FeedCard(
          userName: 'Blessy',
          timeAgo: '5 days ago',
          description: 'Lorem ipsum dolor sit amet consectetur. Leo ac lorem faucli bus facilisis tellus. At vitae dis commodo nunc sollicitudin elementum suspendisse... See More',
          hasActionButton: false,
        ),
        _FeedCard(
          userName: 'Blessy',
          timeAgo: '5 days ago',
          description: 'Lorem ipsum dolor sit amet consectetur. Leo ac lorem faucli bus facilisis tellus. At vitae dis commodo nunc sollicitudin elementum suspendisse... See More',
          hasActionButton: false,
        ),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.userName,
    required this.timeAgo,
    required this.description,
    required this.hasActionButton,
  });

  final String userName;
  final String timeAgo;
  final String description;
  final bool hasActionButton;

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
                    child: Image.asset(
                      'assets/images/avatar.png',
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
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
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
          // Video thumbnail
          Container(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 450,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.asset('assets/icons/playIcon.png'),
                    ),
                  ),
                ),
                if (hasActionButton)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryRed,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: description.contains('See More') 
                        ? description.replaceAll('... See More', '...')
                        : description,
                    style:  TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                  if (description.contains('See More'))
                    TextSpan(
                      text: ' See More',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decorationColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
