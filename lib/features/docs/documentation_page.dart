import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/docs/documentation_engine.dart';

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key});

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  String _active = DocumentationEngine.artifacts.first.id;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final engine = AppServices.instance.docs;
    _ctrl = TextEditingController(text: engine.bodies[_active] ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = AppServices.instance.docs;
    final doc = DocumentationEngine.artifacts.firstWhere((a) => a.id == _active);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Documentation Lab',
            subtitle: 'Architecture · runbooks · RCA · postmortem · change requests',
            trailing: ShadBadge(label: 'Pack ${engine.overallScore}/100'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: ShadPanel(
                    title: 'Artifacts',
                    child: ListView(
                      children: [
                        for (final a in DocumentationEngine.artifacts)
                          ListTile(
                            dense: true,
                            selected: _active == a.id,
                            title: Text(a.title, style: const TextStyle(fontSize: 11)),
                            trailing: Text('${engine.scoreArtifact(a)}',
                                style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground)),
                            onTap: () {
                              engine.bodies[_active] = _ctrl.text;
                              setState(() {
                                _active = a.id;
                                _ctrl.text = engine.bodies[_active] ?? '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ShadPanel(
                    title: doc.title,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Include sections: ${doc.requiredSections.join(', ')}',
                            style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            maxLines: null,
                            expands: true,
                            onChanged: (v) => engine.bodies[_active] = v,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              hintText: 'Write document body…',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Completeness',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        engine.completenessReport(),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
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
