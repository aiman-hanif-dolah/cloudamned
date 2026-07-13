import 'package:flutter/material.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class CicdPage extends StatefulWidget {
  const CicdPage({super.key});

  @override
  State<CicdPage> createState() => _CicdPageState();
}

class _CicdPageState extends State<CicdPage> {
  String _tool = 'GitHub Actions';
  final _stages = <_Stage>[
    _Stage('Checkout', 'success', '12s'),
    _Stage('Build', 'success', '48s'),
    _Stage('Test', 'failure', '31s'),
    _Stage('Security scan', 'pending', '-'),
    _Stage('Deploy', 'pending', '-'),
  ];
  final _logs = <String>[
    '##[group]Run npm test',
    'FAIL src/health.test.ts',
    'Expected status 200, received 503',
    '##[error]Process completed with exit code 1',
  ];

  void _fixTest() {
    setState(() {
      _stages[2] = _Stage('Test', 'success', '28s');
      _stages[3] = _Stage('Security scan', 'success', '22s');
      _stages[4] = _Stage('Deploy', 'success', '41s');
      _logs
        ..clear()
        ..addAll([
          '##[group]Run npm test',
          'PASS src/health.test.ts',
          '##[endgroup]',
          'Deployed revision web-42 to production',
          'Rollback target: web-41',
        ]);
    });
  }

  void _rollback() {
    setState(() {
      _logs.add('Rollback initiated → web-41');
      _logs.add('ALB target group shifted. Health checks green.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'CI/CD Lab',
            subtitle: 'Jenkins · GitHub Actions · GitLab CI pipeline simulation',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final t in ['GitHub Actions', 'Jenkins', 'GitLab CI'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      selected: _tool == t,
                      onSelected: (_) => setState(() => _tool = t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: '$_tool · main · #1284',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final s in _stages)
                          ListTile(
                            leading: Icon(
                              s.status == 'success'
                                  ? Icons.check_circle
                                  : s.status == 'failure'
                                      ? Icons.cancel
                                      : Icons.schedule,
                              color: s.status == 'success'
                                  ? ShadcnColors.success
                                  : s.status == 'failure'
                                      ? ShadcnColors.destructive
                                      : ShadcnColors.mutedForeground,
                            ),
                            title: Text(s.name),
                            trailing: Text(s.duration,
                                style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ShadButton(onPressed: _fixTest, child: const Text('Fix tests & re-run')),
                            const SizedBox(width: 8),
                            ShadButton(
                              variant: ShadButtonVariant.outline,
                              onPressed: _rollback,
                              child: const Text('Rollback deploy'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Job logs',
                    child: Container(
                      color: ShadcnColors.terminalBg,
                      padding: const EdgeInsets.all(12),
                      child: ListView(
                        children: [
                          for (final l in _logs)
                            Text(l,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: l.contains('error') || l.contains('FAIL')
                                      ? ShadcnColors.terminalRed
                                      : ShadcnColors.terminalFg,
                                )),
                        ],
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

class _Stage {
  _Stage(this.name, this.status, this.duration);
  final String name;
  final String status;
  final String duration;
}
