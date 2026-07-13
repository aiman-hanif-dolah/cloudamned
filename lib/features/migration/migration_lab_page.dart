import 'package:flutter/material.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/career_projects.dart';

class MigrationLabPage extends StatefulWidget {
  const MigrationLabPage({super.key});

  @override
  State<MigrationLabPage> createState() => _MigrationLabPageState();
}

class _MigrationLabPageState extends State<MigrationLabPage> {
  String? _customerId;
  final _done = <String>{};
  final _notes = TextEditingController();

  static const phases = [
    'Discovery',
    'Assessment',
    'Dependency Mapping',
    'Migration Planning',
    'Pilot Migration',
    'Production Migration',
    'Validation',
    'Rollback readiness',
    'Post Migration Review',
    'Downtime Calculation',
    'Risk Analysis',
    'Cost Comparison',
  ];

  @override
  Widget build(BuildContext context) {
    final project = _customerId == null ? null : CareerProjects.byId(_customerId!);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ShadSectionHeader(
            title: 'Cloud Migration Lab',
            subtitle: 'Migrate real estates — hospital, bank, factory, retail, university, government',
          ),
          const SizedBox(height: 12),
          if (project == null)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  for (final p in CareerProjects.all)
                    ShadCard(
                      onTap: () => setState(() {
                        _customerId = p.id;
                        _done.clear();
                      }),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${p.industry.name} · ${p.timelineWeeks} weeks · ${p.currency}${p.budgetMonthly}/mo',
                              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                          const SizedBox(height: 6),
                          Text(p.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShadPanel(
                      title: '${project.customerName} · migration phases',
                      actions: [
                        TextButton(
                          onPressed: () => setState(() => _customerId = null),
                          child: const Text('Back', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      child: ListView(
                        children: [
                          for (final phase in phases)
                            CheckboxListTile(
                              dense: true,
                              value: _done.contains(phase),
                              title: Text(phase, style: const TextStyle(fontSize: 13)),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _done.add(phase);
                                } else {
                                  _done.remove(phase);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadPanel(
                      title: 'Planning workspace',
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Text('Progress: ${_done.length}/${phases.length}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ShadProgress(value: _done.length / phases.length),
                          const SizedBox(height: 12),
                          const Text('Assets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          for (final a in project.currentInfrastructure)
                            Text('• ${a.name} [${a.criticality}] ${a.notes}',
                                style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 8),
                          const Text('Dependencies', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          for (final d in project.dependencies)
                            Text('• $d', style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 8),
                          const Text('Risks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          for (final r in project.keyRisks)
                            Text('• $r', style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notes,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Downtime calc, cost compare, pilot notes…',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target platform: ${project.recommendedPlatform.name}\n'
                            '${project.platformRationale}',
                            style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground, height: 1.35),
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
