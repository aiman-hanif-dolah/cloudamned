import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/ops/runbook_catalog.dart';

class OpsKbPage extends StatefulWidget {
  const OpsKbPage({super.key});

  @override
  State<OpsKbPage> createState() => _OpsKbPageState();
}

class _OpsKbPageState extends State<OpsKbPage> {
  int _tab = 0;
  String? _kbId;
  String? _rbId;

  @override
  Widget build(BuildContext context) {
    final ops = AppServices.instance.opsCenter;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShadSectionHeader(
            title: 'Knowledge Base & Runbooks',
            subtitle: 'Resolved work becomes institutional memory — problem, RCA, fix, prevention',
          ),
          const SizedBox(height: 8),
          ShadTabs(
            tabs: const ['KB Articles', 'Runbooks'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _tab == 0
                ? Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: ShadPanel(
                          title: 'Articles (${ops.knowledgeBase.length})',
                          child: ops.knowledgeBase.isEmpty
                              ? const ShadEmpty(
                                  title: 'No articles yet',
                                  description: 'Resolve a ticket and click Create KB article.',
                                )
                              : ListView(
                                  children: [
                                    for (final a in ops.knowledgeBase)
                                      ListTile(
                                        dense: true,
                                        selected: _kbId == a.id,
                                        title: Text(a.id, style: const TextStyle(fontSize: 11)),
                                        subtitle: Text(a.title,
                                            maxLines: 2,
                                            style: const TextStyle(fontSize: 10)),
                                        onTap: () => setState(() => _kbId = a.id),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadPanel(
                          title: _kbId ?? 'Select article',
                          child: Builder(
                            builder: (context) {
                              final a = ops.knowledgeBase.where((x) => x.id == _kbId).firstOrNull;
                              if (a == null) {
                                return const Center(
                                  child: Text('Select a KB article',
                                      style: TextStyle(color: ShadcnColors.mutedForeground)),
                                );
                              }
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(
                                  'Problem\n${a.problem}\n\nEnvironment\n${a.environment}\n\n'
                                  'Symptoms\n${a.symptoms}\n\nRoot Cause\n${a.rootCause}\n\n'
                                  'Resolution\n${a.resolution}\n\nVerification\n${a.verification}\n\n'
                                  'Prevention\n${a.prevention}\n\n'
                                  'Related: ${a.relatedTickets.join(', ')} · ${a.relatedRunbooks.join(', ')}',
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: ShadPanel(
                          title: 'Runbooks',
                          child: ListView(
                            children: [
                              for (final r in RunbookCatalog.all)
                                ListTile(
                                  dense: true,
                                  selected: _rbId == r.id,
                                  title: Text(r.title, style: const TextStyle(fontSize: 12)),
                                  subtitle: Text(r.category, style: const TextStyle(fontSize: 10)),
                                  onTap: () => setState(() => _rbId = r.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadPanel(
                          title: RunbookCatalog.byId(_rbId ?? '')?.title ?? 'Select runbook',
                          child: Builder(
                            builder: (context) {
                              final r = RunbookCatalog.byId(_rbId ?? '');
                              if (r == null) {
                                return const Center(child: Text('Select a runbook'));
                              }
                              return ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  Text(r.summary,
                                      style: const TextStyle(
                                          fontSize: 12, color: ShadcnColors.mutedForeground)),
                                  const SizedBox(height: 12),
                                  for (var i = 0; i < r.steps.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('${i + 1}. ${r.steps[i]}',
                                          style: const TextStyle(fontSize: 13, height: 1.35)),
                                    ),
                                ],
                              );
                            },
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
