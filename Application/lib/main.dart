import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

void main() {
  runApp(const CarlinqApp());
}

class CarlinqApp extends StatelessWidget {
  const CarlinqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          title: 'Carlinq',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: app.themeMode,
          locale: app.locale,
          supportedLocales: const [Locale('fr'), Locale('en')],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
