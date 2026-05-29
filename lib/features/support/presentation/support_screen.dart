import 'package:flutter/material.dart';

import '../../../core/ui/app_widgets.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SectionCard(
        title: 'Support',
        child: Column(
          children: [
            ListTile(leading: Icon(Icons.help_outline), title: Text('FAQ')),
            Divider(),
            ListTile(leading: Icon(Icons.support_agent), title: Text('Contact Support')),
            Divider(),
            ListTile(leading: Icon(Icons.feedback_outlined), title: Text('Send Feedback')),
          ],
        ),
      ),
    );
  }
}
