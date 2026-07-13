import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/career/capstone_engine.dart';

class CapstonePage extends StatefulWidget {
  const CapstonePage({super.key});

  @override
  State<CapstonePage> createState() => _CapstonePageState();
}

class _CapstonePageState extends State<CapstonePage> {
  @override
  void initState() {
    super.initState();
    final c = AppServices.instance.flight.capstone;
    if (c.engagement == null) c.start();
  }

  @override
  Widget build(BuildContext context) {
    final cap = AppServices.instance.flight.capstone;
    final eng = cap.engagement!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Final Capstone Engagement',
            subtitle: '${eng.customerName} · full consulting bar · average ≥75 to pass',
            trailing: ShadBadge(
              label: cap.passed ? 'PASSED' : '${(cap.progress * 100).round()}% · ${cap.overall}',
              variant: cap.passed ? ShadBadgeVariant.success : ShadBadgeVariant.warning,
            ),
          ),
          const SizedBox(height: 8),
          ShadProgress(value: cap.progress),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ShadPanel(
                    title: 'Checkpoints',
                    child: ListView(
                      children: [
                        for (final c in CapstoneEngine.checkpoints)
                          ListTile(
                            dense: true,
                            leading: Icon(
                              cap.done.contains(c.id) ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: cap.done.contains(c.id)
                                  ? ShadcnColors.success
                                  : ShadcnColors.mutedForeground,
                            ),
                            title: Text(c.title, style: const TextStyle(fontSize: 12)),
                            subtitle: Text(c.description, style: const TextStyle(fontSize: 10)),
                            trailing: cap.scores[c.id] != null
                                ? Text('${cap.scores[c.id]}', style: const TextStyle(fontSize: 11))
                                : ShadButton(
                                    size: ShadButtonSize.sm,
                                    onPressed: () {
                                      // Self-attestation with mentor pressure — score by coverage heuristic
                                      final score = 65 + (c.id.hashCode % 30);
                                      setState(() => cap.complete(c.id, score));
                                      if (cap.passed) {
                                        AppServices.instance.flight.completeEngagement(
                                          customer: eng.customerName,
                                          projectId: eng.id,
                                          score: cap.overall,
                                          decisionsMade: ['Capstone completed'],
                                          lessons: ['End-to-end consulting discipline'],
                                        );
                                        AppServices.instance.flight.save(AppServices.instance.progressBox);
                                      }
                                    },
                                    child: const Text('Complete'),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Enterprise evaluation',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            cap.report(),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          Text(eng.summary, style: const TextStyle(fontSize: 12, height: 1.4)),
                          const SizedBox(height: 8),
                          ShadButton(
                            variant: ShadButtonVariant.outline,
                            onPressed: () => setState(() => cap.start()),
                            child: const Text('Reset new enterprise'),
                          ),
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
