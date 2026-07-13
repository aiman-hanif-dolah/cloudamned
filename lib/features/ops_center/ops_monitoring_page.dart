import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class OpsMonitoringPage extends StatefulWidget {
  const OpsMonitoringPage({super.key});

  @override
  State<OpsMonitoringPage> createState() => _OpsMonitoringPageState();
}

class _OpsMonitoringPageState extends State<OpsMonitoringPage> {
  Timer? _t;
  String _focus = 'CPU';

  @override
  void initState() {
    super.initState();
    final ops = AppServices.instance.opsCenter;
    if (!ops.shiftActive) ops.startShift();
    _t = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = AppServices.instance.opsCenter;
    final series = ops.series[_focus] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Monitoring Center',
            subtitle: 'Live gauges · thresholds · health scores (updates continuously during shift)',
            trailing: ShadBadge(label: 'Health ${ops.infraHealth.toStringAsFixed(0)}%'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: ShadPanel(
                    title: 'Signals',
                    child: ListView(
                      children: [
                        for (final k in ops.gauges.keys)
                          ListTile(
                            dense: true,
                            selected: _focus == k,
                            title: Text(k, style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                              (ops.gauges[k] ?? 0).toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 11,
                                color: (ops.gauges[k] ?? 0) > 85
                                    ? ShadcnColors.destructive
                                    : ShadcnColors.mutedForeground,
                              ),
                            ),
                            onTap: () => setState(() => _focus = k),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: '$_focus trend',
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: series.length < 2
                          ? const Center(child: Text('Waiting for samples…'))
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: 100,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) =>
                                      const FlLine(color: ShadcnColors.border, strokeWidth: 1),
                                ),
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (var i = 0; i < series.length; i++)
                                        FlSpot(i.toDouble(), series[i]),
                                    ],
                                    isCurved: true,
                                    color: ShadcnColors.primary,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: ShadcnColors.primary.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: ShadPanel(
                    title: 'Active alerts',
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        if (ops.liveAlerts.isEmpty)
                          const Text('All clear', style: TextStyle(color: ShadcnColors.mutedForeground)),
                        for (final a in ops.liveAlerts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(a, style: const TextStyle(fontSize: 11, color: ShadcnColors.warning)),
                          ),
                        const Divider(),
                        Text(
                          'VMs ${(ops.gauges['Virtual Machines'] ?? 0).toStringAsFixed(0)} · '
                          'Containers ${(ops.gauges['Running Containers'] ?? 0).toStringAsFixed(0)} · '
                          'Users ${(ops.gauges['Active Users'] ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
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
