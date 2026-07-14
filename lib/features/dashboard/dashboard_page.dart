import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final totalLabs = RoadmapContent.allLabs.length;
    final modules = RoadmapContent.modules;

    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, progress) {
        final done = progress.completedLabs.length;
        final completion = totalLabs == 0 ? 0.0 : done / totalLabs;

        final pageWidth = MediaQuery.sizeOf(context).width;
        final pad = pageWidth < 600 ? 12.0 : 20.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadSectionHeader(
                title: 'cloudamned · Cloud Engineering Flight Simulator',
                subtitle:
                    'Consulting mindset · customer problems · failures · forensics · promotions. Offline. No cloud accounts.',
                trailing: ShadButton(
                  onPressed: () => context.go(AppRoutes.flightDeck),
                  icon: Icons.flight_takeoff,
                  child: const Text('Flight Deck'),
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 1100 ? 4 : (c.maxWidth > 700 ? 2 : 1);
                  final ratio = c.maxWidth < 400 ? 1.6 : (c.maxWidth < 700 ? 1.9 : 2.2);
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: ratio,
                    children: [
                      ShadStatTile(
                        label: 'Overall Readiness',
                        value: '${progress.readiness.overall.toStringAsFixed(0)}%',
                        icon: Icons.speed,
                        color: ShadcnColors.primary,
                        trend: 'Interview success estimate',
                      ),
                      ShadStatTile(
                        label: 'Labs Completed',
                        value: '$done / $totalLabs',
                        icon: Icons.science_outlined,
                        trend: '${(completion * 100).toStringAsFixed(0)}% path complete',
                      ),
                      ShadStatTile(
                        label: 'Level / XP',
                        value: 'L${progress.level}',
                        icon: Icons.star_outline,
                        trend: '${progress.xp} XP · next at ${progress.xpToNextLevel}',
                      ),
                      ShadStatTile(
                        label: 'Time Invested',
                        value: '${progress.timeSpentMinutes}m',
                        icon: Icons.timer_outlined,
                        trend: '${progress.streakDays}-day streak',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, c) {
                  final stack = c.maxWidth < 800;
                  final chart = ShadCard(
                    header: const Text('Skill readiness',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    child: SizedBox(
                      height: stack ? 200 : 220,
                      child: _ReadinessChart(readiness: progress.readiness),
                    ),
                  );
                  final launch = ShadCard(
                    header: const Text('Quick launch',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    child: Column(
                      children: [
                        _QuickLink(Icons.flight_takeoff, 'Flight Deck', AppRoutes.flightDeck, ShadcnColors.primary),
                        _QuickLink(Icons.support_agent, 'Cloud Ops Center', AppRoutes.opsCenter, ShadcnColors.warning),
                        _QuickLink(Icons.hearing, 'Discovery', AppRoutes.discovery, ShadcnColors.info),
                        _QuickLink(Icons.biotech, 'Forensics', AppRoutes.forensics, ShadcnColors.destructive),
                        _QuickLink(Icons.flag, 'Capstone', AppRoutes.capstone, ShadcnColors.warning),
                        _QuickLink(Icons.terminal, 'Linux Terminal', AppRoutes.terminal, ShadcnColors.linux),
                        _QuickLink(Icons.cloud, 'AWS Console', AppRoutes.console, ShadcnColors.aws),
                        _QuickLink(Icons.edit_note, 'Whiteboard', AppRoutes.whiteboard, ShadcnColors.chart4),
                        _QuickLink(Icons.psychology, 'Mentor', AppRoutes.mentor, ShadcnColors.terraform),
                      ],
                    ),
                  );
                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        chart,
                        const SizedBox(height: 12),
                        launch,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: chart),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: launch),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ShadSectionHeader(
                title: 'Learning modules',
                subtitle: '${modules.length} modules · $totalLabs interactive labs',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 1200
                      ? 4
                      : (c.maxWidth > 800 ? 3 : (c.maxWidth > 480 ? 2 : 1));
                  final aspect = c.maxWidth < 400 ? 1.35 : 1.55;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspect,
                    ),
                    itemBuilder: (context, i) {
                      final m = modules[i];
                      final pct = progress.moduleProgress[m.id] ?? 0;
                      return ShadCard(
                        onTap: () => context.go(AppRoutes.roadmap),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ShadBadge(label: 'M${m.order}'),
                                const Spacer(),
                                Text('${m.labCount} labs',
                                    style: const TextStyle(
                                        fontSize: 11, color: ShadcnColors.mutedForeground)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(m.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(m.subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: ShadcnColors.mutedForeground)),
                            const Spacer(),
                            ShadProgress(value: pct),
                            const SizedBox(height: 4),
                            Text('${(pct * 100).toStringAsFixed(0)}% complete',
                                style: const TextStyle(
                                    fontSize: 10, color: ShadcnColors.mutedForeground)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: ShadcnColors.mutedForeground),
      onTap: () => context.go(route),
    );
  }
}

class _ReadinessChart extends StatelessWidget {
  const _ReadinessChart({required this.readiness});
  final ReadinessScores readiness;

  @override
  Widget build(BuildContext context) {
    final data = [
      ('AWS', readiness.aws, ShadcnColors.aws),
      ('Azure', readiness.azure, ShadcnColors.azure),
      ('GCP', readiness.gcp, ShadcnColors.gcp),
      ('Linux', readiness.linux, ShadcnColors.linux),
      ('Net', readiness.networking, ShadcnColors.info),
      ('TF', readiness.terraform, ShadcnColors.terraform),
      ('Docker', readiness.docker, ShadcnColors.docker),
      ('K8s', readiness.kubernetes, ShadcnColors.k8s),
    ];

    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: ShadcnColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i].$1,
                      style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].$2.clamp(2, 100),
                  color: data[i].$3,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
