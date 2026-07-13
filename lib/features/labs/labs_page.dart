import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class LabsPage extends StatefulWidget {
  const LabsPage({super.key});

  @override
  State<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends State<LabsPage> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final labs = RoadmapContent.allLabs.where((l) {
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          l.title.toLowerCase().contains(q) ||
          l.tags.any((t) => t.contains(q)) ||
          l.summary.toLowerCase().contains(q);
      final matchesFilter = _filter == 'all' ||
          l.type.name == _filter ||
          l.simulator == _filter ||
          l.difficulty.name == _filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, progress) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadSectionHeader(
                title: 'Labs',
                subtitle: '${labs.length} labs match filters · ${progress.completedLabs.length} completed',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      hint: 'Search labs, tags, simulators…',
                      prefix: const Icon(Icons.search, size: 16),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filter,
                    dropdownColor: ShadcnColors.card,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All types')),
                      DropdownMenuItem(value: 'terminal', child: Text('Terminal')),
                      DropdownMenuItem(value: 'console', child: Text('Console')),
                      DropdownMenuItem(value: 'troubleshooting', child: Text('Troubleshooting')),
                      DropdownMenuItem(value: 'scenario', child: Text('Scenario')),
                      DropdownMenuItem(value: 'exam', child: Text('Exam')),
                      DropdownMenuItem(value: 'aws', child: Text('AWS sim')),
                      DropdownMenuItem(value: 'linux', child: Text('Linux sim')),
                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? 'all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: labs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final lab = labs[i];
                    final done = progress.completedLabs.contains(lab.id);
                    return ShadCard(
                      onTap: () => context.go('/labs/${lab.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            done ? Icons.check_circle : Icons.science_outlined,
                            color: done ? ShadcnColors.success : ShadcnColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lab.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(lab.summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: ShadcnColors.mutedForeground)),
                              ],
                            ),
                          ),
                          ShadBadge(label: lab.difficulty.name),
                          const SizedBox(width: 8),
                          ShadBadge(label: lab.simulator, variant: ShadBadgeVariant.outline),
                          const SizedBox(width: 8),
                          Text('${lab.xpReward} XP',
                              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
