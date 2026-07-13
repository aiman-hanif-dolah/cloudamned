import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class OpsPortfolioPage extends StatefulWidget {
  const OpsPortfolioPage({super.key});

  @override
  State<OpsPortfolioPage> createState() => _OpsPortfolioPageState();
}

class _OpsPortfolioPageState extends State<OpsPortfolioPage> {
  String? _id;

  @override
  Widget build(BuildContext context) {
    final items = AppServices.instance.opsCenter.portfolio;
    final selected = items.where((i) => i.id == _id).firstOrNull ?? items.firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Engineering Portfolio',
            subtitle: 'Incident reports · KB · runbooks — export evidence for interviews',
            trailing: ShadBadge(label: '${items.length} artifacts'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const ShadEmpty(
                    title: 'Portfolio empty',
                    description: 'Resolve Ops Center tickets and create KB articles to fill this.',
                    icon: Icons.folder_open,
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: ShadPanel(
                          title: 'Artifacts',
                          child: ListView(
                            children: [
                              for (final i in items)
                                ListTile(
                                  dense: true,
                                  selected: _id == i.id || selected?.id == i.id,
                                  title: Text(i.kind, style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                                  subtitle: Text(i.title,
                                      maxLines: 2,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  onTap: () => setState(() => _id = i.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadPanel(
                          title: selected?.title ?? '',
                          actions: [
                            if (selected != null)
                              IconButton(
                                tooltip: 'Copy to clipboard',
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: selected.body));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied portfolio artifact')),
                                  );
                                },
                              ),
                          ],
                          child: selected == null
                              ? const SizedBox.shrink()
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: SelectableText(
                                    selected.body,
                                    style: const TextStyle(fontSize: 12, height: 1.45, fontFamily: 'monospace'),
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
