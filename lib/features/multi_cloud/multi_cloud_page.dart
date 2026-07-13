import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/widgets/shadcn_widgets.dart';

class MultiCloudPage extends StatefulWidget {
  const MultiCloudPage({super.key});

  @override
  State<MultiCloudPage> createState() => _MultiCloudPageState();
}

class _MultiCloudPageState extends State<MultiCloudPage> {
  int _users = 100000;

  @override
  Widget build(BuildContext context) {
    final mc = AppServices.instance.flight.multiCloud;
    final fps = mc.footprints(users: _users);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Multi-Cloud Deployment Compare',
            subtitle: 'Identical logical 3-tier design on AWS, Azure, GCP — cost, availability, ops',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Users (scale): ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _users.toDouble(),
                  min: 10000,
                  max: 1000000,
                  divisions: 99,
                  label: '$_users',
                  onChanged: (v) => setState(() => _users = v.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Deploy footprints',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final f in fps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShadCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.provider, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    '\$${f.monthlyCost}/mo · avail ${f.availability}% · '
                                    'latency ${f.latencyMs}ms · security ${f.securityPosture} · scale ${f.scalability}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Text(f.notes, style: const TextStyle(fontSize: 11, height: 1.3)),
                                  const SizedBox(height: 6),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    onPressed: () => setState(() => mc.markDeployed(f.provider)),
                                    child: Text(
                                      mc.deployed[f.provider] == true ? 'Deployed ✓' : 'Simulate deploy',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Business suitability report',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        mc.comparisonReport(users: _users),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
