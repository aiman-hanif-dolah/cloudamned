import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/career/discovery_engine.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final flight = AppServices.instance.flight;
    if (flight.discovery.project == null) {
      flight.beginDiscovery();
    }
  }

  void _ask([String? preset]) {
    final q = preset ?? _ctrl.text.trim();
    if (q.isEmpty) return;
    AppServices.instance.flight.discovery.ask(q);
    _ctrl.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = AppServices.instance.flight.discovery;
    final p = d.project;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Requirement Gathering',
            subtitle: p == null
                ? 'No customer — generate from Flight Deck'
                : '${p.customerName} · ask like a consultant · missing questions = missing requirements',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadBadge(
                  label: '${(d.coverage * 100).round()}% critical',
                  variant: d.coverage >= 0.8 ? ShadBadgeVariant.success : ShadBadgeVariant.warning,
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () {
                    AppServices.instance.flight.beginDiscovery(
                      AppServices.instance.flight.generateProject(),
                    );
                    setState(() {});
                  },
                  child: const Text('New customer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: 'Customer conversation',
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: d.transcript.length,
                            itemBuilder: (context, i) {
                              final m = d.transcript[i];
                              final isYou = m.from == 'engineer';
                              return Align(
                                alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  constraints: const BoxConstraints(maxWidth: 480),
                                  decoration: BoxDecoration(
                                    color: isYou ? ShadcnColors.primary.withValues(alpha: 0.15) : ShadcnColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: ShadcnColors.border),
                                  ),
                                  child: Text(
                                    '${isYou ? 'You' : 'Customer'}: ${m.text}',
                                    style: const TextStyle(fontSize: 12, height: 1.4),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ShadInput(
                                  controller: _ctrl,
                                  hint: 'Ask about budget, downtime, RTO, compliance, growth…',
                                  onSubmitted: (_) => _ask(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ShadButton(onPressed: _ask, child: const Text('Ask')),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final q in DiscoveryEngine.bank.take(8))
                              ActionChip(
                                label: Text(q.question, style: const TextStyle(fontSize: 10)),
                                onPressed: () => _ask(q.question),
                                backgroundColor: ShadcnColors.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 300,
                  child: ShadPanel(
                    title: 'Discovery scorecard',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        SelectableText(
                          d.scorecard(),
                          style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppServices.instance.flight.mentor.reviewDecision(
                            'proceed to architecture',
                            missingDiscovery: d.missingCritical,
                          ),
                          style: const TextStyle(fontSize: 11, color: ShadcnColors.info, height: 1.4),
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
