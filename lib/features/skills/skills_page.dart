import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/skills_catalog.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final career = AppServices.instance.careerSim;
    final readiness = career.readinessReport();
    final byCat = career.categoryAverages();
    final skills = SkillsCatalog.baseSkills();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Skill Analytics & Interview Readiness',
            subtitle: '${skills.length}+ skills tracked · weighted readiness report',
            trailing: ShadBadge(
              label: 'Overall ${readiness['Overall']!.toStringAsFixed(0)}%',
              variant: ShadBadgeVariant.success,
            ),
          ),
          const SizedBox(height: 16),
          ShadCard(
            header: const Text('Interview readiness (weighted)', style: TextStyle(fontWeight: FontWeight.w600)),
            child: Column(
              children: [
                for (final e in readiness.entries.where((e) => e.key != 'Overall'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 140, child: Text(e.key, style: const TextStyle(fontSize: 12))),
                        Expanded(child: ShadProgress(value: e.value / 100)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text('${e.value.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ShadCard(
            header: const Text('Category averages', style: TextStyle(fontWeight: FontWeight.w600)),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in byCat.entries)
                  ShadBadge(
                    label: '${e.key} ${e.value.toStringAsFixed(0)}%',
                    variant: e.value >= 50 ? ShadBadgeVariant.success : ShadBadgeVariant.outline,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Individual skills', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          for (final cat in SkillsCatalog.categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Text(cat, style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
            ),
            for (final s in skills.where((x) => x.category == cat))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(width: 180, child: Text(s.name, style: const TextStyle(fontSize: 11))),
                    Expanded(child: ShadProgress(value: (career.skills[s.id] ?? 0) / 100, height: 4)),
                    const SizedBox(width: 8),
                    Text('${(career.skills[s.id] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
