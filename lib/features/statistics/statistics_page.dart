import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, p) {
        final r = p.readiness;
        final modulesDone = p.moduleProgress.values.where((v) => v >= 1).length;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ShadSectionHeader(
                title: 'Statistics',
                subtitle: 'Time, accuracy, domain readiness, interview prediction',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      ShadStatTile(label: 'Time spent', value: '${p.timeSpentMinutes} min', icon: Icons.schedule),
                      ShadStatTile(
                        label: 'Modules completed',
                        value: '$modulesDone / ${RoadmapContent.modules.length}',
                        icon: Icons.view_module,
                      ),
                      ShadStatTile(
                        label: 'Answer accuracy',
                        value: '${(p.accuracy * 100).toStringAsFixed(0)}%',
                        icon: Icons.gps_fixed,
                      ),
                      ShadStatTile(
                        label: 'Interview readiness',
                        value: '${r.interview.toStringAsFixed(0)}%',
                        icon: Icons.record_voice_over,
                        color: ShadcnColors.chart4,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ShadCard(
                header: const Text('Domain readiness', style: TextStyle(fontWeight: FontWeight.w600)),
                child: SizedBox(
                  height: 260,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: [
                            RadarEntry(value: r.aws),
                            RadarEntry(value: r.azure),
                            RadarEntry(value: r.gcp),
                            RadarEntry(value: r.linux),
                            RadarEntry(value: r.networking),
                            RadarEntry(value: r.terraform),
                            RadarEntry(value: r.docker),
                            RadarEntry(value: r.kubernetes),
                            RadarEntry(value: r.security),
                          ],
                          fillColor: ShadcnColors.primary.withValues(alpha: 0.2),
                          borderColor: ShadcnColors.primary,
                          entryRadius: 2,
                          borderWidth: 2,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(color: ShadcnColors.border),
                      tickBorderData: const BorderSide(color: ShadcnColors.border),
                      gridBorderData: const BorderSide(color: ShadcnColors.border, width: 1),
                      ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.transparent),
                      tickCount: 5,
                      titleTextStyle: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                      getTitle: (i, _) {
                        const titles = ['AWS', 'Azure', 'GCP', 'Linux', 'Net', 'TF', 'Docker', 'K8s', 'Sec'];
                        return RadarChartTitle(text: titles[i]);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShadCard(
                header: const Text('Readiness breakdown', style: TextStyle(fontWeight: FontWeight.w600)),
                child: Column(
                  children: [
                    for (final e in [
                      ('Overall', r.overall),
                      ('AWS', r.aws),
                      ('Azure', r.azure),
                      ('GCP', r.gcp),
                      ('Linux', r.linux),
                      ('Networking', r.networking),
                      ('Terraform', r.terraform),
                      ('Docker', r.docker),
                      ('Kubernetes', r.kubernetes),
                      ('Security', r.security),
                      ('Interview', r.interview),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(width: 110, child: Text(e.$1, style: const TextStyle(fontSize: 12))),
                            Expanded(child: ShadProgress(value: e.$2 / 100)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text('${e.$2.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                            ),
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
