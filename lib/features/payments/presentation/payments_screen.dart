import 'package:flutter/material.dart';

import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ResourceApi();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Payments',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: api.list('payments'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error.toString());
            final pays = snapshot.data ?? [];
            if (pays.isEmpty) return const EmptyState(message: 'No payments found');

            final total = pays.fold<num>(0, (sum, p) => sum + ((p['amount'] as num?) ?? 0));
            final pending = pays
                .where((p) => (p['status'] ?? '').toString().toLowerCase() != 'paid')
                .fold<num>(0, (sum, p) => sum + ((p['amount'] as num?) ?? 0));

            return Column(
              children: [
                ListTile(title: const Text('Total Payments'), trailing: Text('\$$total')),
                ListTile(title: const Text('Pending'), trailing: Text('\$$pending')),
                const Divider(),
                ...pays.map((p) => ListTile(
                      title: Text((p['reference_no'] ?? 'Payment').toString()),
                      subtitle: Text('Method: ${p['method'] ?? '-'}'),
                      trailing: Text('\$${p['amount'] ?? 0}'),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
