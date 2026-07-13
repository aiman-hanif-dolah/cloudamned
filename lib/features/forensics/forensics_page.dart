import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class ForensicsPage extends StatefulWidget {
  const ForensicsPage({super.key});

  @override
  State<ForensicsPage> createState() => _ForensicsPageState();
}

class _ForensicsPageState extends State<ForensicsPage> {
  String _bundle = 'Application logs';

  @override
  Widget build(BuildContext context) {
    final flight = AppServices.instance.flight;
    final bundles = flight.forensics.bundles();
    final lines = bundles[_bundle] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Forensics & Failure Engine',
            subtitle: 'Nothing always works — inject failures, investigate like production',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.destructive,
                  onPressed: () {
                    flight.injectFailure();
                    setState(() {});
                  },
                  child: const Text('Inject failure'),
                ),
                const SizedBox(width: 8),
                ShadBadge(label: '${flight.failures.active.length} active'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (flight.failures.active.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in flight.failures.active)
                    Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 8),
                      child: ShadCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12, color: ShadcnColors.destructive)),
                            Text(f.symptoms,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                            const Spacer(),
                            ShadButton(
                              size: ShadButtonSize.sm,
                              onPressed: () {
                                flight.failures.resolve(f.id);
                                flight.reputation.bump('Incident Resolution', 5);
                                flight.awardCareerXp(40);
                                setState(() {});
                              },
                              child: const Text('Mark recovered'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: ShadPanel(
                    title: 'Evidence bundles',
                    child: ListView(
                      children: [
                        for (final k in bundles.keys)
                          ListTile(
                            dense: true,
                            selected: _bundle == k,
                            title: Text(k, style: const TextStyle(fontSize: 11)),
                            trailing: Text('${bundles[k]!.length}',
                                style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                            onTap: () => setState(() => _bundle = k),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: _bundle,
                    child: Container(
                      color: ShadcnColors.terminalBg,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final l in lines)
                            SelectableText(
                              l,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: ShadcnColors.terminalFg,
                                height: 1.35,
                              ),
                            ),
                          if (lines.isEmpty)
                            const Text('No events — inject a failure or open an incident.',
                                style: TextStyle(color: ShadcnColors.mutedForeground)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: ShadPanel(
                    title: 'Hints (after you look)',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final f in flight.failures.active) ...[
                          Text(f.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          for (final h in f.remediationHints)
                            Text('• $h', style: const TextStyle(fontSize: 11, height: 1.35)),
                          const SizedBox(height: 10),
                        ],
                        if (flight.failures.active.isEmpty)
                          const Text('No active failures.',
                              style: TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
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
