import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF141414),
              Color(0xFF141414),
              Color(0xFF141414),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _Header(),
                    const SizedBox(height: 12),
                    _Subtitle(),
                    const SizedBox(height: 36),
                    _PhoneRow(),
                    const Spacer(),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: const _ContinueButton(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
      child: const Text(
        'Enter Your\nMobile Number',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w900,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Lorem ipsum dolor sit amet consectetur. Porta at id hac vitae. Et tortor at vehicula euismod mi viverra.',
      style: TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w200,
      ),
    );
  }
}

class _PhoneRow extends StatefulWidget {
  const _PhoneRow();

  @override
  State<_PhoneRow> createState() => _PhoneRowState();
}

class _PhoneRowState extends State<_PhoneRow> {
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isPhoneFocused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider provider = context.watch<AuthProvider>();
    return Row(
      children: <Widget>[
        Container(
          width: 86,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0x11111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: _isPhoneFocused ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: _CountryCodeDropdown(
            value: provider.countryCode,
            onChanged: (String? v) => provider.setCountryCode(v ?? provider.countryCode),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0x11111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPhoneFocused ? AppTheme.primaryRed : const Color(0x33FFFFFF),
                width: 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: provider.phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              onChanged: provider.onPhoneChanged,
              decoration: const InputDecoration(
                hintText: 'Enter Mobile Number',
                hintStyle: TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryCodeDropdown extends StatelessWidget {
  const _CountryCodeDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  static const List<Map<String, String>> _codes = <Map<String, String>>[
    {'code': '+91', 'flag': '🇮🇳'},
    {'code': '+1', 'flag': '🇺🇸'},
    {'code': '+44', 'flag': '🇬🇧'},
    {'code': '+971', 'flag': '🇦🇪'},
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A1A1A),
        iconEnabledColor: Colors.white,
        iconSize: 20,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        underline: const SizedBox.shrink(),
        items: _codes
            .map((Map<String, String> item) => DropdownMenuItem<String>(
              value: item['code'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Text(
                  //   item['flag']!,
                  //   style: const TextStyle(fontSize: 20),
                  // ),
                  const SizedBox(width: 8),
                  Text(item['code']!),
                ],
              ),
            ))
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton();

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // Removed shimmer usage in simplified UI
  late AnimationController _glowController;
  late Animation<Alignment> _highlightAlignment;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);

    _highlightAlignment = AlignmentTween(
      begin: const Alignment(-1.1, -0.6),
      end: const Alignment(1.1, 0.6),
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider provider = context.watch<AuthProvider>();
    final bool enabled = provider.isValid && !provider.isLoading;

    return Center(
      child: GestureDetector(
        onTapDown: enabled ? (_) => _animationController.forward() : null,
        onTapUp: enabled ? (_) => _animationController.reverse() : null,
        onTapCancel: enabled ? () => _animationController.reverse() : null,
        onTap: enabled ? provider.continueWithPhone : null,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
                // Glass base
                Container(
                  height: 56,
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0x1AFFFFFF),
                        Color(0x0DFFFFFF),
                        Color(0x14141414),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                // Moving liquid highlight
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (BuildContext context, Widget? child) {
                    return Align(
                      alignment: _highlightAlignment.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              Color(0x26FFFFFF),
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Content
                Container(
                  height: 56,
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (provider.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 12),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (BuildContext context, Widget? child) {
                          final double t = _pulse.value;
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  enabled ? AppTheme.primaryRed : const Color(0xFF2C2C2C),
                                  enabled ? AppTheme.primaryRed.withOpacity(0.85) : const Color(0xFF2C2C2C),
                                ],
                              ),
                              boxShadow: enabled
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: AppTheme.primaryRed.withOpacity(0.25 + 0.25 * t),
                                        blurRadius: 12 + 6 * t,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Positioned(
                                  top: 6,
                                  left: 8,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x55FFFFFF),
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/icons/arrowIcon.png',
                                  width: 20,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Footer removed to match provided UI


