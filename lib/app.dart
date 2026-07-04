import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/app_shell.dart';

class StockLabApp extends StatelessWidget {
  const StockLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
