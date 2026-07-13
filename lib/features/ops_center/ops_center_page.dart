import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/ops/ops_models.dart';

/// Cloud Operations Center — career-mode ops dashboard (additive module).
class OpsCenterPage extends StatefulWidget {
  const OpsCenterPage({super.key});

  @override
  State<OpsCenterPage> createState() => _OpsCenterPageState();
}

class _OpsCenterPageState extends State<OpsCenterPage> {
  Timer? _ui;

  @override
  void initState() {
    super.initState();
    _ui = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ui?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = AppServices.instance.opsCenter;
    final open = ops.openTickets;
    final critical = ops.critical;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Cloud Operations Center',
            subtitle:
                'First day on the desk — tickets, SLAs, monitoring, runbooks. Existing labs & simulators stay available.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ops.shiftActive ? ShadButtonVariant.secondary : ShadButtonVariant.primary,
                  onPressed: () {
                    if (ops.shiftActive) {
                      ops.endShift();
                    } else {
                      ops.startShift();
                    }
                    setState(() {});
                  },
                  child: Text(ops.shiftActive ? 'End shift (${ops.virtualHour}:00)' : 'Start 8h shift'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => context.go(AppRoutes.opsShift),
                  child: const Text('Shift console'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // KPI row
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _kpi('Assigned open', '${open.length}', ShadcnColors.primary),
                _kpi('Critical', '${critical.length}', ShadcnColors.destructive),
                _kpi('Infra health', '${ops.infraHealth.toStringAsFixed(0)}%', ShadcnColors.success),
                _kpi('Live alerts', '${ops.liveAlerts.length}', ShadcnColors.warning),
                _kpi('SLA compliance', '${ops.metrics.slaCompliance.toStringAsFixed(0)}%', ShadcnColors.info),
                _kpi('KB articles', '${ops.knowledgeBase.length}', ShadcnColors.chart4),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // Left column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ShadPanel(
                          title: 'Assigned / open tickets',
                          actions: [
                            TextButton(
                              onPressed: () => context.go(AppRoutes.opsTickets),
                              child: const Text('Open desk', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                          child: ListView.builder(
                            itemCount: open.length.clamp(0, 12),
                            itemBuilder: (context, i) {
                              final t = open[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 16,
                                  color: t.priority == OpsPriority.p1Critical
                                      ? ShadcnColors.destructive
                                      : ShadcnColors.mutedForeground,
                                ),
                                title: Text(
                                  '${t.number} · ${t.description.split('\n').first}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${t.priority.label} · ${t.status.label} · SLA ${t.slaRemaining.inMinutes}m'
                                  '${t.slaBreached ? ' BREACHED' : ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: t.slaBreached ? ShadcnColors.destructive : ShadcnColors.mutedForeground,
                                  ),
                                ),
                                onTap: () => context.go('${AppRoutes.opsTickets}?id=${t.number}'),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ShadPanel(
                          title: 'Stand-up / shift summary',
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              for (final n in ops.standupNotes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $n', style: const TextStyle(fontSize: 11, height: 1.35)),
                                ),
                              const Divider(),
                              Text(
                                'Metrics: closed ${ops.metrics.ticketsClosed} · '
                                'escalations ${ops.metrics.escalations} · '
                                'avg resolve ${ops.metrics.avgResolution.toStringAsFixed(0)}m',
                                style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Middle
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: ShadPanel(
                          title: 'Infrastructure health / monitoring',
                          actions: [
                            TextButton(
                              onPressed: () => context.go(AppRoutes.opsMonitoring),
                              child: const Text('Full dash', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              for (final k in ['CPU', 'Memory', 'Disk Usage', 'Error Rate', 'Latency', 'Database Health'])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(k, style: const TextStyle(fontSize: 11)),
                                          const Spacer(),
                                          Text(
                                            '${(ops.gauges[k] ?? 0).toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                          ),
                                        ],
                                      ),
                                      ShadProgress(
                                        value: (ops.gauges[k] ?? 0) / 100,
                                        color: (ops.gauges[k] ?? 0) > 85
                                            ? ShadcnColors.destructive
                                            : ShadcnColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ShadPanel(
                          title: 'Cloud alerts',
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              if (ops.liveAlerts.isEmpty)
                                const Text('No active threshold alerts',
                                    style: TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                              for (final a in ops.liveAlerts)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(a,
                                      style: const TextStyle(fontSize: 11, color: ShadcnColors.warning)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: ShadPanel(
                          title: 'Recent deployments · maintenance',
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              const Text('Deployments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                              for (final d in ops.recentDeployments)
                                Text('• $d', style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 8),
                              const Text('Upcoming maintenance',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                              for (final m in ops.upcomingMaintenance)
                                Text('• $m', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ShadPanel(
                          title: 'Customer · escalations · KB',
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                              for (final n in ops.customerNotifications.take(5))
                                Text('• $n',
                                    style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                              const SizedBox(height: 8),
                              const Text('Escalations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                              for (final e in ops.recentEscalations.take(4))
                                Text('• $e', style: const TextStyle(fontSize: 10)),
                              if (ops.recentEscalations.isEmpty)
                                const Text('None this shift',
                                    style: TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => context.go(AppRoutes.opsPortfolio),
                                    child: const Text('Portfolio'),
                                  ),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => context.go(AppRoutes.opsInterview),
                                    child: const Text('Ops interview'),
                                  ),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => context.go(AppRoutes.opsKb),
                                    child: const Text('Knowledge base'),
                                  ),
                                ],
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

  Widget _kpi(String label, String value, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
