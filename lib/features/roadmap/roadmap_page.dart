import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/lab.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _expandedId = RoadmapContent.modules.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, progress) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: RoadmapContent.modules.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ShadSectionHeader(
                        title: 'Learning Roadmap',
                        subtitle:
                            '${RoadmapContent.allLabs.length} labs across ${RoadmapContent.modules.length} modules — fundamentals to production capstone.',
                      ),
                    );
                  }
                  final m = RoadmapContent.modules[index - 1];
                  final pct = progress.moduleProgress[m.id] ?? 0;
                  final expanded = _expandedId == m.id;
                  final done = m.labs.where((l) => progress.completedLabs.contains(l.id)).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShadCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _expandedId = expanded ? null : m.id),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: ShadcnColors.secondary,
                                    child: Text('${m.order}',
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(m.subtitle,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: ShadcnColors.mutedForeground)),
                                      ],
                                    ),
                                  ),
                                  Text('$done/${m.labCount}',
                                      style: const TextStyle(
                                          fontSize: 12, color: ShadcnColors.mutedForeground)),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 80, child: ShadProgress(value: pct)),
                                  const SizedBox(width: 8),
                                  Icon(
                                    expanded ? Icons.expand_less : Icons.expand_more,
                                    color: ShadcnColors.mutedForeground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (expanded) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  for (final lab in m.labs)
                                    _LabRow(
                                      lab: lab,
                                      completed: progress.completedLabs.contains(lab.id),
                                      onOpen: () => context.go('/labs/${lab.id}'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 300,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: ShadcnColors.border)),
                color: ShadcnColors.panel,
              ),
              padding: const EdgeInsets.all(16),
              child: _ModuleDetail(
                module: RoadmapContent.modules.firstWhere(
                  (m) => m.id == (_expandedId ?? RoadmapContent.modules.first.id),
                ),
                progress: progress,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({required this.lab, required this.completed, required this.onOpen});
  final Lab lab;
  final bool completed;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        completed ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
        color: completed ? ShadcnColors.success : ShadcnColors.mutedForeground,
      ),
      title: Text(lab.title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        '${lab.difficulty.name} · ${lab.estimatedMinutes}m · ${lab.xpReward} XP · ${lab.type.name}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: ShadButton(
        onPressed: onOpen,
        size: ShadButtonSize.sm,
        variant: ShadButtonVariant.outline,
        child: const Text('Open'),
      ),
    );
  }
}

class _ModuleDetail extends StatelessWidget {
  const _ModuleDetail({required this.module, required this.progress});
  final LearningModule module;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(module.description,
            style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.4)),
        const SizedBox(height: 16),
        const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final s in module.skills) ShadBadge(label: s)],
        ),
        const SizedBox(height: 16),
        const Text('Stats', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        Text('Labs: ${module.labCount}', style: const TextStyle(fontSize: 12)),
        Text('Total XP: ${module.totalXp}', style: const TextStyle(fontSize: 12)),
        Text(
          'Progress: ${((progress.moduleProgress[module.id] ?? 0) * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
