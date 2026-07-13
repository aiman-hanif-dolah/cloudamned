import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/landing_zone/landing_zone_engine.dart';

class LandingZonePage extends StatefulWidget {
  const LandingZonePage({super.key});

  @override
  State<LandingZonePage> createState() => _LandingZonePageState();
}

class _LandingZonePageState extends State<LandingZonePage> {
  late final LandingZoneEngine engine;

  @override
  void initState() {
    super.initState();
    engine = AppServices.instance.landingZone;
  }

  @override
  Widget build(BuildContext context) {
    final pillars = engine.pillarScores();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Landing Zone Builder',
            subtitle: 'Enterprise cloud foundation · graded with Well-Architected pillars',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadBadge(label: '${engine.overallScore}% coverage', variant: ShadBadgeVariant.success),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => setState(engine.enableAll),
                  child: const Text('Enable baseline'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: 'Controls',
                    child: ListView(
                      children: [
                        for (final c in LandingZoneEngine.catalog)
                          CheckboxListTile(
                            dense: true,
                            value: engine.enabled.contains(c.id),
                            title: Text(c.name, style: const TextStyle(fontSize: 13)),
                            subtitle: Text('${c.description} · ${c.pillar}',
                                style: const TextStyle(fontSize: 11)),
                            onChanged: (_) => setState(() => engine.toggle(c.id)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Well-Architected score',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final e in pillars.entries) ...[
                          Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ShadProgress(value: e.value / 100),
                          const SizedBox(height: 4),
                          Text('${e.value}%',
                              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                          const SizedBox(height: 10),
                        ],
                        const Divider(),
                        SelectableText(
                          engine.gradeReport(),
                          style: const TextStyle(fontSize: 11, height: 1.4, fontFamily: 'monospace'),
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
