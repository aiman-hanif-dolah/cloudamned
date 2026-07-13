import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class WellArchitectedPage extends StatefulWidget {
  const WellArchitectedPage({super.key});

  @override
  State<WellArchitectedPage> createState() => _WellArchitectedPageState();
}

class _WellArchitectedPageState extends State<WellArchitectedPage> {
  final _components = <String>{
    'ALB',
    'Multi-AZ',
    'Private subnet',
    'RDS',
    'CloudWatch alarms',
  };
  bool multiAz = true;
  bool privateData = true;
  bool backups = false;
  bool monitoring = true;
  bool leastPrivilege = false;
  bool encryption = false;
  bool costTags = false;
  bool asg = true;
  bool sustainability = false;

  static const options = [
    'ALB', 'ASG', 'Multi-AZ', 'Private subnet', 'RDS', 'S3 lifecycle',
    'CloudTrail', 'WAF', 'KMS', 'CloudFront', 'Savings plan', 'Runbook',
  ];

  @override
  Widget build(BuildContext context) {
    final result = AppServices.instance.flight.wa.score(
      components: _components,
      multiAz: multiAz,
      privateData: privateData,
      backups: backups,
      monitoring: monitoring,
      leastPrivilege: leastPrivilege,
      encryption: encryption,
      costTags: costTags,
      asgOrServerless: asg,
      sustainabilityNotes: sustainability,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Well-Architected Review',
            subtitle: 'Operational Excellence · Security · Reliability · Performance · Cost · Sustainability',
            trailing: ShadBadge(label: '${result.overall}/100', variant: ShadBadgeVariant.success),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Architecture inputs',
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        const Text('Components', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        for (final o in options)
                          CheckboxListTile(
                            dense: true,
                            value: _components.contains(o),
                            title: Text(o, style: const TextStyle(fontSize: 12)),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _components.add(o);
                              } else {
                                _components.remove(o);
                              }
                            }),
                          ),
                        const Divider(),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Multi-AZ', style: TextStyle(fontSize: 12)),
                          value: multiAz,
                          onChanged: (v) => setState(() => multiAz = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Private data tier', style: TextStyle(fontSize: 12)),
                          value: privateData,
                          onChanged: (v) => setState(() => privateData = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Backups + restore', style: TextStyle(fontSize: 12)),
                          value: backups,
                          onChanged: (v) => setState(() => backups = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Monitoring', style: TextStyle(fontSize: 12)),
                          value: monitoring,
                          onChanged: (v) => setState(() => monitoring = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Least privilege IAM', style: TextStyle(fontSize: 12)),
                          value: leastPrivilege,
                          onChanged: (v) => setState(() => leastPrivilege = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Encryption', style: TextStyle(fontSize: 12)),
                          value: encryption,
                          onChanged: (v) => setState(() => encryption = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Cost tags / budgets', style: TextStyle(fontSize: 12)),
                          value: costTags,
                          onChanged: (v) => setState(() => costTags = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('ASG / serverless elasticity', style: TextStyle(fontSize: 12)),
                          value: asg,
                          onChanged: (v) => setState(() => asg = v),
                        ),
                        SwitchListTile(
                          dense: true,
                          title: const Text('Sustainability notes', style: TextStyle(fontSize: 12)),
                          value: sustainability,
                          onChanged: (v) => setState(() => sustainability = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Architect feedback',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final e in result.pillars.entries) ...[
                          Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ShadProgress(value: e.value / 100),
                          Text('${e.value}/100',
                              style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                          const SizedBox(height: 8),
                        ],
                        const Divider(),
                        const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.w600)),
                        for (final r in result.recommendations)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('• $r', style: const TextStyle(fontSize: 12, height: 1.35)),
                          ),
                      ],
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
