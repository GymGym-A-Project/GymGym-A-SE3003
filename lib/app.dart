import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme.dart';

class GymGymApp extends StatelessWidget {
  const GymGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GymGym-A',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
