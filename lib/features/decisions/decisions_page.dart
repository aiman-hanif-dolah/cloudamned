import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/career_projects.dart';

class DecisionsPage extends StatefulWidget {
  const DecisionsPage({super.key});

  @override
  State<DecisionsPage> createState() => _DecisionsPageState();
}

class _DecisionsPageState extends State<DecisionsPage> {
  String _platform = 'AWS';
  String? _analysis;

  @override
  Widget build(BuildContext context) {
    final flight = AppServices.instance.flight;
    final project = flight.activeGenerated ??
        flight.discovery.project ??
        CareerProjects.all.first;
    final cards = flight.decisions.compare(project);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Architecture Decision Engine',
            subtitle: '${project.customerName} — choose platform with explicit tradeoffs (never deploy first)',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ShadPanel(
                    title: 'Scorecards',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final c in cards)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShadCard(
                              onTap: () => setState(() {
                                _platform = c.platform;
                                _analysis = flight.decisions.explainChoice(c.platform, project);
                              }),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(c.platform,
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      ShadBadge(label: '${c.overall} overall'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.rationale,
                                      style: const TextStyle(
                                          fontSize: 11, color: ShadcnColors.mutedForeground, height: 1.35)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cost ${c.cost} · Perf ${c.performance} · Avail ${c.availability} · '
                                    'Sec ${c.security} · Ops ${c.opsComplexity} · LT ${c.longTerm}',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
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
                    title: 'Decision brief · $_platform',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        SelectableText(
                          _analysis ??
                              flight.decisions.explainChoice(_platform, project),
                          style: const TextStyle(fontSize: 12, height: 1.45, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppServices.instance.flight.mentor.coach(
                            context: _platform,
                            step: project.id.hashCode,
                          ),
                          style: const TextStyle(fontSize: 12, color: ShadcnColors.info, height: 1.4),
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
