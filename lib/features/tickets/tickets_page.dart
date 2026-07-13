import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../domain/entities/career_project.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  String? _selected;
  final _finding = TextEditingController();
  final _customerMsg = TextEditingController();
  final _rca = TextEditingController();
  final _post = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final engine = AppServices.instance.tickets;
    final ticket = _selected == null ? null : engine.byId(_selected!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Ticket Management',
            subtitle: 'Enterprise queue · SLA · customer updates · RCA · postmortem',
            trailing: ShadBadge(
              label: '${engine.openCount} open · SLA ${engine.slaCompliance.toStringAsFixed(0)}%',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Queue',
                    child: ListView(
                      children: [
                        for (final t in engine.tickets)
                          ListTile(
                            dense: true,
                            selected: _selected == t.id,
                            selectedTileColor: ShadcnColors.sidebarAccent,
                            leading: Icon(
                              Icons.confirmation_number_outlined,
                              size: 16,
                              color: t.priority == TicketPriority.critical
                                  ? ShadcnColors.destructive
                                  : ShadcnColors.mutedForeground,
                            ),
                            title: Text('${t.id} · ${t.title}', style: const TextStyle(fontSize: 12)),
                            subtitle: Text(
                              '${t.priority} · SLA ${t.slaMinutes}m · ${t.status.name} · ${t.customer}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onTap: () => setState(() => _selected = t.id),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ticket == null
                      ? const ShadEmpty(title: 'Select a ticket', icon: Icons.inbox_outlined)
                      : ShadPanel(
                          title: '${ticket.id} · ${ticket.title}',
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              Text(ticket.description, style: const TextStyle(fontSize: 12, height: 1.4)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  ShadBadge(label: ticket.priority, variant: ShadBadgeVariant.destructive),
                                  ShadBadge(label: 'SLA ${ticket.slaMinutes}m'),
                                  ShadBadge(label: ticket.status.name, variant: ShadBadgeVariant.outline),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    onPressed: () => setState(() => engine.assign(ticket.id)),
                                    child: const Text('Assign to me'),
                                  ),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.secondary,
                                    onPressed: () => context.go(AppRoutes.scenario),
                                    child: const Text('Open IR tools'),
                                  ),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => context.go(AppRoutes.console),
                                    child: const Text('AWS Console'),
                                  ),
                                  ShadButton(
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => context.go(AppRoutes.terminal),
                                    child: const Text('Terminal'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ShadInput(controller: _finding, hint: 'Investigation finding…'),
                              const SizedBox(height: 6),
                              ShadButton(
                                size: ShadButtonSize.sm,
                                onPressed: () {
                                  if (_finding.text.trim().isEmpty) return;
                                  setState(() {
                                    engine.investigate(ticket.id, _finding.text.trim());
                                    _finding.clear();
                                  });
                                },
                                child: const Text('Add finding'),
                              ),
                              const SizedBox(height: 12),
                              ShadInput(controller: _customerMsg, hint: 'Customer update…'),
                              const SizedBox(height: 6),
                              ShadButton(
                                size: ShadButtonSize.sm,
                                variant: ShadButtonVariant.secondary,
                                onPressed: () {
                                  if (_customerMsg.text.trim().isEmpty) return;
                                  setState(() {
                                    engine.updateCustomer(ticket.id, _customerMsg.text.trim());
                                    _customerMsg.clear();
                                  });
                                },
                                child: const Text('Send customer update'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _rca,
                                maxLines: 3,
                                decoration: const InputDecoration(hintText: 'Root cause analysis…'),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _post,
                                maxLines: 3,
                                decoration: const InputDecoration(hintText: 'Postmortem summary…'),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ShadButton(
                                    onPressed: () {
                                      setState(() {
                                        engine.resolve(
                                          ticket.id,
                                          rca: _rca.text,
                                          postmortem: _post.text,
                                        );
                                      });
                                      AppServices.instance.progressCubit.addXp(80);
                                    },
                                    child: const Text('Resolve'),
                                  ),
                                  const SizedBox(width: 8),
                                  ShadButton(
                                    variant: ShadButtonVariant.outline,
                                    onPressed: () => setState(() => engine.close(ticket.id)),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                              if (ticket.findings.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Findings', style: TextStyle(fontWeight: FontWeight.w600)),
                                for (final f in ticket.findings)
                                  Text('• $f', style: const TextStyle(fontSize: 11)),
                              ],
                              if (ticket.customerUpdates.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Customer comms', style: TextStyle(fontWeight: FontWeight.w600)),
                                for (final u in ticket.customerUpdates)
                                  Text(u, style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                              ],
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
