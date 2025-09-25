import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/core/theme/app_theme.dart';
import 'src/features/auth/presentation/pages/login_page.dart';
import 'src/features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FeedApp());
}

class FeedApp extends StatelessWidget {
  const FeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'feedApp',
        themeMode: ThemeMode.dark,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        builder: (BuildContext context, Widget? child) {
          return DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'Montserrat'),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const LoginPage(),
      ),
    );
  }
}
