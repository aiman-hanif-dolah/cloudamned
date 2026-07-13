import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final _rng = Random(42);
  late List<FlSpot> _cpu;
  late List<FlSpot> _mem;
  final _alerts = <String>[
    'OK  high-cpu on web-asg (threshold 80%)',
    'ALARM  disk-usage on db-1 (92%)',
    'OK  alb-5xx (threshold 5%)',
  ];
  final _logs = <String>[
    '10:01:02 web-1 nginx: 200 GET / 45ms',
    '10:01:05 web-2 nginx: 200 GET /api/health 12ms',
    '10:01:08 db-1 mysql: slow query 2.1s SELECT * FROM orders',
    '10:01:15 web-1 kernel: high memory pressure reclaim',
  ];

  @override
  void initState() {
    super.initState();
    _cpu = List.generate(20, (i) => FlSpot(i.toDouble(), 30 + _rng.nextDouble() * 50));
    _mem = List.generate(20, (i) => FlSpot(i.toDouble(), 40 + _rng.nextDouble() * 40));
  }

  void _refresh() {
    setState(() {
      _cpu = List.generate(20, (i) => FlSpot(i.toDouble(), 20 + _rng.nextDouble() * 70));
      _mem = List.generate(20, (i) => FlSpot(i.toDouble(), 35 + _rng.nextDouble() * 50));
      _logs.insert(0, '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} sampled metrics refreshed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Monitoring',
            subtitle: 'CloudWatch-style metrics · logs · alerts · incident response',
            trailing: ShadButton(
              size: ShadButtonSize.sm,
              onPressed: _refresh,
              icon: Icons.refresh,
              child: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: ShadCard(
                          header: const Text('CPU Utilization %', style: TextStyle(fontWeight: FontWeight.w600)),
                          child: LineChart(_chart(_cpu, ShadcnColors.chart1)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ShadCard(
                          header: const Text('Memory Used %', style: TextStyle(fontWeight: FontWeight.w600)),
                          child: LineChart(_chart(_mem, ShadcnColors.chart2)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ShadPanel(
                          title: 'Alarms',
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              for (final a in _alerts)
                                ListTile(
                                  dense: true,
                                  leading: Icon(
                                    a.startsWith('ALARM') ? Icons.warning_amber : Icons.check_circle,
                                    size: 16,
                                    color: a.startsWith('ALARM') ? ShadcnColors.warning : ShadcnColors.success,
                                  ),
                                  title: Text(a, style: const TextStyle(fontSize: 11)),
                                ),
                              const SizedBox(height: 8),
                              ShadButton(
                                size: ShadButtonSize.sm,
                                onPressed: () => setState(() {
                                  _alerts.insert(0, 'OK  disk-usage on db-1 (cleared after expand volume)');
                                }),
                                child: const Text('Simulate remediation'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ShadPanel(
                          title: 'Log stream',
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              for (final l in _logs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(l,
                                      style: const TextStyle(
                                          fontSize: 11, fontFamily: 'monospace', color: ShadcnColors.mutedForeground)),
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
          ),
        ],
      ),
    );
  }

  LineChartData _chart(List<FlSpot> spots, Color color) {
    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: ShadcnColors.border, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
        ),
      ],
    );
  }
}
