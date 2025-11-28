import 'package:flutter/material.dart';
import '../widgets/config_summary_widget.dart';

class ConfigSummaryScreen extends StatelessWidget {
  const ConfigSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riepilogo Configurazione'),
      ),
      body: const ConfigSummaryWidget(),
    );
  }
}
