import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/cost/cost_engine.dart';

class CostLabPage extends StatefulWidget {
  const CostLabPage({super.key});

  @override
  State<CostLabPage> createState() => _CostLabPageState();
}

class _CostLabPageState extends State<CostLabPage> {
  @override
  Widget build(BuildContext context) {
    final engine = AppServices.instance.costEngine;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Cost Optimization Lab',
            subtitle: 'Customer: “Our AWS bill doubled.” Investigate idle resources, transfer, commitments…',
            trailing: ShadBadge(
              label: '\$${engine.wasteIdentified}/mo identified',
              variant: ShadBadgeVariant.warning,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Bill breakdown findings',
                    child: ListView(
                      children: [
                        for (final f in CostEngine.findings)
                          CheckboxListTile(
                            dense: true,
                            value: engine.selected.contains(f.id),
                            title: Text(f.title, style: const TextStyle(fontSize: 12)),
                            subtitle: Text('${f.category} · ~\$${f.monthlyWaste}/mo · ${f.recommendation}',
                                style: const TextStyle(fontSize: 10)),
                            onChanged: (_) => setState(() => engine.toggle(f.id)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Optimization report',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        engine.report(),
                        style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                      ),
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
