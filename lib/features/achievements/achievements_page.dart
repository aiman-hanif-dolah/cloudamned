import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static const catalog = <(String, String, String)>[
    ('first-lab', 'First Steps', 'Complete your first lab'),
    ('lab-10', 'Practitioner', 'Complete 10 labs'),
    ('lab-50', 'Engineer', 'Complete 50 labs'),
    ('linux-starter', 'Linux Terminal', 'Complete a Linux lab'),
    ('aws-starter', 'AWS Console', 'Complete an AWS lab'),
    ('capstone', 'Capstone Graduate', 'Finish the final practical exam'),
    ('level-5', 'Level 5', 'Reach level 5'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, progress) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadSectionHeader(
                title: 'Achievements',
                subtitle: 'Badges · XP · streaks · career ranking signals',
                trailing: ShadBadge(
                  label: '${progress.badges.length}/${catalog.length} unlocked',
                  variant: ShadBadgeVariant.success,
                ),
              ),
              const SizedBox(height: 8),
              Text('Level ${progress.level} · ${progress.xp} XP · ${progress.streakDays}-day streak',
                  style: const TextStyle(color: ShadcnColors.mutedForeground, fontSize: 13)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    for (final b in catalog)
                      ShadCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              progress.badges.contains(b.$1) ? Icons.emoji_events : Icons.lock_outline,
                              color: progress.badges.contains(b.$1)
                                  ? ShadcnColors.warning
                                  : ShadcnColors.mutedForeground,
                            ),
                            const Spacer(),
                            Text(b.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(b.$3,
                                style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
