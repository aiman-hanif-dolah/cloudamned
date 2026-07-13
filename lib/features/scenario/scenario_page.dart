import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/incident/incident_engine.dart';

/// Incident-based learning workspace for cloudamned.
class ScenarioPage extends StatefulWidget {
  const ScenarioPage({super.key});

  @override
  State<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends State<ScenarioPage> {
  late final IncidentEngine incidents;
  final _noteCtrl = TextEditingController();
  final _activity = <String>[];

  @override
  void initState() {
    super.initState();
    final svc = AppServices.instance;
    incidents = IncidentEngine(aws: svc.awsEngine, linux: svc.linuxShell);
  }

  void _load(String id) {
    incidents.load(id);
    setState(() {
      _activity
        ..clear()
        ..add('Loaded incident $id')
        ..add(incidents.aws.state.activeIncidentId == id
            ? 'Broken environment is live in AWS Console + Investigation tools.'
            : 'Environment ready.');
    });
  }

  void _runAction(String label, String Function() fn) {
    final out = fn();
    incidents.syncProgress();
    setState(() {
      _activity.add('── $label ──');
      _activity.add(out);
      if (incidents.resolved) {
        _activity.add('✓ INCIDENT RESOLVED — service restored');
        AppServices.instance.progressCubit.addXp(220);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = incidents.active;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Incident Lab',
            subtitle: 'Customer tickets · investigate logs · EC2 · SG · routes · SSH · nginx · restore service',
            trailing: incidents.resolved
                ? const ShadBadge(label: 'RESOLVED', variant: ShadBadgeVariant.success)
                : null,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // Ticket list / investigation
                Expanded(
                  flex: 3,
                  child: active == null
                      ? _catalog()
                      : _workspace(active),
                ),
                const SizedBox(width: 10),
                // Activity log
                SizedBox(
                  width: 320,
                  child: ShadPanel(
                    title: 'Investigation log',
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              for (final l in _activity)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    l,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: l.startsWith('✓')
                                          ? ShadcnColors.success
                                          : ShadcnColors.mutedForeground,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ShadInput(
                                  controller: _noteCtrl,
                                  hint: 'Add ticket note…',
                                ),
                              ),
                              const SizedBox(width: 6),
                              ShadButton(
                                size: ShadButtonSize.sm,
                                onPressed: () {
                                  if (_noteCtrl.text.trim().isEmpty) return;
                                  incidents.addNote(_noteCtrl.text.trim());
                                  setState(() {
                                    _activity.add('NOTE: ${_noteCtrl.text.trim()}');
                                    _noteCtrl.clear();
                                  });
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
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

  Widget _catalog() {
    return ListView(
      children: [
        const Text(
          'Select a customer incident. The simulator loads a broken environment — '
          'you investigate and fix it like a Cloud Technical Engineer.',
          style: TextStyle(fontSize: 13, color: ShadcnColors.mutedForeground, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final inc in IncidentEngine.catalog)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ShadCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ShadcnColors.destructive.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          inc.severity,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ShadcnColors.destructive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          inc.customerMessage,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      ShadButton(
                        size: ShadButtonSize.sm,
                        onPressed: () => _load(inc.id),
                        child: const Text('Take ticket'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inc.background,
                    style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _workspace(IncidentDefinition inc) {
    incidents.syncProgress();
    final pct = incidents.progress;

    return ShadPanel(
      title: '${inc.severity} · ${inc.customerMessage}',
      actions: [
        TextButton(
          onPressed: () => setState(() {
            incidents.activeId = null;
          }),
          child: const Text('Close ticket', style: TextStyle(fontSize: 11)),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(inc.background, style: const TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          ShadProgress(value: pct),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% investigation complete'
            '${incidents.resolved ? ' · RESOLVED' : ''}',
            style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
          ),
          const SizedBox(height: 16),
          const Text('Investigation steps', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final s in inc.steps)
            ListTile(
              dense: true,
              leading: Icon(
                incidents.completedSteps.contains(s.id) ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: incidents.completedSteps.contains(s.id)
                    ? ShadcnColors.success
                    : ShadcnColors.mutedForeground,
              ),
              title: Text(s.title, style: const TextStyle(fontSize: 13)),
              subtitle: Text(s.description, style: const TextStyle(fontSize: 11)),
            ),
          const SizedBox(height: 12),
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () => _runAction('CloudWatch logs', () => incidents.aws.getLogEvents().message),
                child: const Text('Inspect CloudWatch logs'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.secondary,
                onPressed: () {
                  final id = incidents.aws.state.incidentMeta['instanceId'] as String? ??
                      incidents.aws.state.instances.lastOrNull?.id;
                  if (id == null) return;
                  _runAction('EC2 status', () => incidents.aws.describeInstanceStatus(id).message);
                },
                child: const Text('Check EC2 status'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.secondary,
                onPressed: () =>
                    _runAction('Security groups', () => incidents.aws.describeSecurityGroups().message),
                child: const Text('Review security groups'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.secondary,
                onPressed: () =>
                    _runAction('Route tables', () => incidents.aws.describeRouteTables().message),
                child: const Text('Verify route tables'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  final id = incidents.aws.state.incidentMeta['instanceId'] as String? ??
                      incidents.aws.state.instances.lastOrNull?.id;
                  if (id == null) return;
                  _runAction('SSH test', () => incidents.aws.testSsh(id).message);
                },
                child: const Text('Test SSH'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  final id = incidents.aws.state.incidentMeta['instanceId'] as String? ??
                      incidents.aws.state.instances.lastOrNull?.id;
                  if (id == null) return;
                  _runAction('HTTP probe', () => incidents.aws.probeHttp(id).message);
                },
                child: const Text('Probe HTTP / nginx'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () {
                  final sg = incidents.aws.state.incidentMeta['sgId'] as String?;
                  if (sg == null) return;
                  _runAction(
                    'Fix SG: allow HTTP 80',
                    () => incidents.aws
                        .authorizeSecurityGroupIngress(
                          groupId: sg,
                          protocol: 'tcp',
                          fromPort: 80,
                          toPort: 80,
                          cidr: '0.0.0.0/0',
                        )
                        .message,
                  );
                },
                child: const Text('Fix: open SG port 80'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.success,
                onPressed: () {
                  final id = incidents.aws.state.incidentMeta['instanceId'] as String?;
                  if (id == null) return;
                  _runAction('Start nginx', () => incidents.aws.setNginxRunning(id, true).message);
                },
                child: const Text('Fix: start nginx'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.terminal),
                child: const Text('Open Linux terminal'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.console),
                child: const Text('Open AWS Console'),
              ),
            ],
          ),
          if (incidents.resolved) ...[
            const SizedBox(height: 16),
            ShadCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Root cause', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(inc.rootCauseSummary, style: const TextStyle(fontSize: 12, height: 1.4)),
                  const SizedBox(height: 10),
                  const Text('Resolution', style: TextStyle(fontWeight: FontWeight.w600)),
                  for (final r in inc.resolutionSteps)
                    Text('• $r', style: const TextStyle(fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
