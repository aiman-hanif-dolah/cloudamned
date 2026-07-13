import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class ArchReviewPage extends StatefulWidget {
  const ArchReviewPage({super.key});

  @override
  State<ArchReviewPage> createState() => _ArchReviewPageState();
}

class _ArchReviewPageState extends State<ArchReviewPage> {
  @override
  Widget build(BuildContext context) {
    final engine = AppServices.instance.archReview;
    final d = engine.current;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Architecture Review Mode',
            subtitle: 'Find planted mistakes — public DB, no backups, single AZ, open SGs…',
            trailing: ShadBadge(label: '${engine.score}% found', variant: ShadBadgeVariant.warning),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: d.title,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Text(d.description, style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
                        const SizedBox(height: 12),
                        const Text('Observed components', style: TextStyle(fontWeight: FontWeight.w600)),
                        for (final c in d.components)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('• $c', style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Flag issues',
                    child: ListView(
                      children: [
                        for (final f in d.flaws)
                          CheckboxListTile(
                            dense: true,
                            value: engine.found.contains(f.id),
                            title: Text(f.title, style: const TextStyle(fontSize: 12)),
                            subtitle: Text('${f.severity} · ${f.pillar}\n${f.detail}',
                                style: const TextStyle(fontSize: 10)),
                            onChanged: (_) => setState(() => engine.toggleFound(f.id)),
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
