import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Reports',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('reports'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) return const EmptyState(message: 'No reports found');
            return Column(
              children: reports
                  .map((r) => ListTile(
                        title: Text((r['report_type'] ?? '-').toString()),
                        subtitle: Text('Format: ${r['format'] ?? '-'}'),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
