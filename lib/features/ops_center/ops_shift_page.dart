import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/ops/ops_models.dart';

class OpsShiftPage extends StatefulWidget {
  const OpsShiftPage({super.key});

  @override
  State<OpsShiftPage> createState() => _OpsShiftPageState();
}

class _OpsShiftPageState extends State<OpsShiftPage> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final ops = AppServices.instance.opsCenter;
    if (!ops.shiftActive) ops.startShift();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
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
    final m = ops.metrics.snapshot();
    final hour = ops.virtualHour;
    final progress = ((hour - 9) / 8).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Support Shift Mode',
            subtitle: 'Virtual 8-hour desk · tickets arrive · prioritise by SLA · measure performance',
            trailing: ShadBadge(
              label: ops.shiftActive ? 'ON SHIFT ${hour.toString().padLeft(2, '0')}:00' : 'OFF',
              variant: ops.shiftActive ? ShadBadgeVariant.success : ShadBadgeVariant.secondary,
            ),
          ),
          const SizedBox(height: 8),
          ShadProgress(value: progress, height: 8),
          const SizedBox(height: 4),
          const Text('09:00 ──────── stand-up · tickets · alerts · maintenance ──────── 17:00',
              style: TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Live queue (prioritise)',
                    child: ListView(
                      children: [
                        for (final t in ops.openTickets)
                          ListTile(
                            dense: true,
                            title: Text(
                              '${t.number} ${t.description.split('\n').first}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${t.priority.label} · SLA ${t.slaRemaining.inMinutes}m left'
                              '${t.slaBreached ? ' · BREACHED' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: t.slaBreached || t.priority.name.contains('p1')
                                    ? ShadcnColors.destructive
                                    : ShadcnColors.mutedForeground,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 16),
                            onTap: () => context.go('${AppRoutes.opsTickets}?id=${t.number}'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Shift performance',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final e in m.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                                Text(e.value,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const Divider(),
                        const Text(
                          'Mix: simple tickets, critical incidents, customer misunderstandings, '
                          'monitoring alerts, and scheduled maintenance. Escalate when needed.',
                          style: TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        ShadButton(
                          variant: ShadButtonVariant.outline,
                          onPressed: () {
                            ops.endShift();
                            context.go(AppRoutes.opsCenter);
                          },
                          child: const Text('End shift & return to Ops Center'),
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
