import 'package:flutter/material.dart';

import 'plateau_advice.dart';
import '../../core/widgets/sign_out_button.dart';

class AnalyzerScreen extends StatelessWidget {
  const AnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Analyzer'),
      actions: const [SignOutButton()],
    ),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plateauDisclaimer),
          SizedBox(height: 16),
          Text('Plateau analysis is not available yet.'),
        ],
      ),
    ),
  );
}
