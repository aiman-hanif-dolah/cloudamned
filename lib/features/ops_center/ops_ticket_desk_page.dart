import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/ops/ops_models.dart';
import '../../simulation/ops/runbook_catalog.dart';

/// Full service-desk ticket workspace with investigation workflow.
class OpsTicketDeskPage extends StatefulWidget {
  const OpsTicketDeskPage({super.key, this.initialId});

  final String? initialId;

  @override
  State<OpsTicketDeskPage> createState() => _OpsTicketDeskPageState();
}

class _OpsTicketDeskPageState extends State<OpsTicketDeskPage> {
  String? _selected;
  final _note = TextEditingController();
  final _customer = TextEditingController();
  final _root = TextEditingController();
  final _fix = TextEditingController();
  final _rca = TextEditingController();
  final _escReason = TextEditingController();
  final _escEvidence = TextEditingController();
  final _escFindings = TextEditingController();
  final _escRec = TextEditingController();
  String? _banner;
  bool _shadow = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
    _selected ??= AppServices.instance.opsCenter.queue.firstOrNull?.number;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['id'];
    if (q != null && q.isNotEmpty) {
      _selected = q;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _customer.dispose();
    _root.dispose();
    _fix.dispose();
    _rca.dispose();
    _escReason.dispose();
    _escEvidence.dispose();
    _escFindings.dispose();
    _escRec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = AppServices.instance.opsCenter;
    final ticket = _selected == null ? null : ops.byNumber(_selected!);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Service Desk',
            subtitle: 'Original ops ticketing — investigate before you fix · SLA · runbooks · escalate',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterChip(
                  label: const Text('Shadow senior', style: TextStyle(fontSize: 11)),
                  selected: _shadow,
                  onSelected: (v) => setState(() => _shadow = v),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => context.go(AppRoutes.opsCenter),
                  child: const Text('Ops Center'),
                ),
              ],
            ),
          ),
          if (_banner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_banner!, style: const TextStyle(fontSize: 12, color: ShadcnColors.info)),
            ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 260,
                  child: ShadPanel(
                    title: 'Queue (${ops.queue.length})',
                    child: ListView.builder(
                      itemCount: ops.queue.length,
                      itemBuilder: (context, i) {
                        final t = ops.queue[i];
                        return ListTile(
                          dense: true,
                          selected: _selected == t.number,
                          selectedTileColor: ShadcnColors.sidebarAccent,
                          title: Text(t.number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${t.priority.label} · ${t.status.label}\n${t.description.split('\n').first}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                          isThreeLine: true,
                          onTap: () => setState(() {
                            _selected = t.number;
                            _banner = null;
                          }),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ticket == null
                      ? const ShadEmpty(title: 'Select a ticket')
                      : _workspace(ticket),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspace(OpsTicket t) {
    final ops = AppServices.instance.opsCenter;
    final rb = RunbookCatalog.byId(t.runbookId);
    final actions = ops.investigationActionsFor(t);

    return ShadPanel(
      title: '${t.number} · ${t.customerName}',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ShadBadge(label: t.priority.label, variant: ShadBadgeVariant.destructive),
              ShadBadge(label: t.status.label),
              ShadBadge(label: t.provider.name, variant: ShadBadgeVariant.outline),
              ShadBadge(
                label: t.slaBreached ? 'SLA BREACHED' : 'SLA ${t.slaRemaining.inMinutes}m',
                variant: t.slaBreached ? ShadBadgeVariant.destructive : ShadBadgeVariant.success,
              ),
              ShadBadge(label: t.affectedService, variant: ShadBadgeVariant.secondary),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.description, style: const TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Text('Attachments: ${t.attachments.join(', ')}',
              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
          if (_shadow) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: ShadcnColors.border),
                borderRadius: BorderRadius.circular(6),
                color: ShadcnColors.secondary,
              ),
              child: Text(
                'Shadow Senior: ${ops.shadowQuestion(t)}',
                style: const TextStyle(fontSize: 12, color: ShadcnColors.info, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text('1. Lifecycle actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () {
                  ops.assign(t.number);
                  setState(() => _banner = 'Assigned to you');
                },
                child: const Text('Assign to me'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.secondary,
                onPressed: () {
                  ops.setWaitingInternal(t.number, 'Platform team');
                  setState(() {});
                },
                child: const Text('Wait internal'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.terminal),
                child: const Text('Linux terminal'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.console),
                child: const Text('Cloud console'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.forensics),
                child: const Text('Forensics'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('2. Investigation — collect evidence before fixing',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in actions.take(16))
                FilterChip(
                  label: Text(
                    a.replaceAll('step:', '').replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: t.evidenceCollected.contains(a),
                  onSelected: (_) {
                    ops.collectEvidence(t.number, a);
                    setState(() {});
                  },
                ),
            ],
          ),
          Text(
            'Evidence: ${t.evidenceCollected.length} collected',
            style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          if (rb != null) ...[
            Text('3. Runbook: ${rb.title}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(rb.summary, style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
            for (var i = 0; i < rb.steps.length; i++)
              Text('${i + 1}. ${rb.steps[i]}', style: const TextStyle(fontSize: 11, height: 1.35)),
            const SizedBox(height: 12),
          ],
          const Text('4. Customer communication', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          ShadInput(controller: _customer, hint: 'Update / request info / confirm resolution…'),
          const SizedBox(height: 6),
          ShadButton(
            size: ShadButtonSize.sm,
            onPressed: () {
              final s = ops.sendCustomerUpdate(t.number, _customer.text);
              setState(() {
                _banner = 'Customer message graded $s/100 (clarity, professionalism, empathy)';
                _customer.clear();
              });
            },
            child: const Text('Send customer update'),
          ),
          const SizedBox(height: 12),
          const Text('5. Propose resolution (after evidence)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _root,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Root cause…', isDense: true),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _fix,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Resolution steps…', isDense: true),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _rca,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'RCA write-up…', isDense: true),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ShadButton(
                onPressed: () {
                  final r = ops.resolve(
                    number: t.number,
                    rootCause: _root.text,
                    resolution: _fix.text,
                    rca: _rca.text,
                  );
                  setState(() => _banner = '${r.ok ? "OK" : "Review"} · accuracy ${r.accuracy}% — ${r.feedback}');
                  if (r.ok) {
                    AppServices.instance.progressCubit.addXp(60);
                  }
                },
                child: const Text('Submit resolution'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                variant: ShadButtonVariant.secondary,
                onPressed: () {
                  try {
                    final kb = ops.createKbFromTicket(t.number);
                    setState(() => _banner = 'KB ${kb.id} created · portfolio updated');
                    AppServices.instance.progressCubit.addXp(40);
                  } catch (_) {
                    setState(() => _banner = 'Resolve ticket before KB (or use after resolve)');
                  }
                },
                child: const Text('Create KB article'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  ops.close(t.number);
                  setState(() => _banner = 'Closed ${t.number}');
                },
                child: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('6. Escalate (when appropriate)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          ShadInput(controller: _escReason, hint: 'Reason (provider outage, security, redesign…)'),
          const SizedBox(height: 4),
          ShadInput(controller: _escEvidence, hint: 'Evidence summary'),
          const SizedBox(height: 4),
          ShadInput(controller: _escFindings, hint: 'Current findings'),
          const SizedBox(height: 4),
          ShadInput(controller: _escRec, hint: 'Recommendation'),
          const SizedBox(height: 6),
          ShadButton(
            size: ShadButtonSize.sm,
            variant: ShadButtonVariant.destructive,
            onPressed: () {
              final fb = ops.escalate(
                number: t.number,
                reason: _escReason.text,
                evidence: _escEvidence.text,
                findings: _escFindings.text,
                recommendation: _escRec.text,
              );
              setState(() => _banner = fb);
            },
            child: const Text('Escalate to senior'),
          ),
          const SizedBox(height: 14),
          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          for (final e in t.timeline.reversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${e.at.toIso8601String().substring(11, 19)} [${e.kind}] ${e.actor}: ${e.message}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: ShadcnColors.mutedForeground),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Internal notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ShadInput(controller: _note, hint: 'Add internal note…'),
          const SizedBox(height: 4),
          ShadButton(
            size: ShadButtonSize.sm,
            variant: ShadButtonVariant.ghost,
            onPressed: () {
              if (_note.text.trim().isEmpty) return;
              ops.addInternalNote(t.number, _note.text.trim());
              _note.clear();
              setState(() {});
            },
            child: const Text('Add note'),
          ),
          for (final n in t.internalNotes) Text('• $n', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
