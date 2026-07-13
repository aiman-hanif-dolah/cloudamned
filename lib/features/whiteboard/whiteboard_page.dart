import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/interview/whiteboard_engine.dart';

class WhiteboardPage extends StatefulWidget {
  const WhiteboardPage({super.key});

  @override
  State<WhiteboardPage> createState() => _WhiteboardPageState();
}

class _WhiteboardPageState extends State<WhiteboardPage> {
  WhiteboardPrompt? _prompt;
  final _answer = TextEditingController();
  final _components = <String>{};
  String? _result;

  static const palette = [
    'CDN', 'ALB/API GW', 'Auto Scale', 'Cache', 'Queue', 'Object storage',
    'Multi-AZ DB', 'Private subnet', 'WAF', 'Multi-region', 'Observability', 'DR',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShadSectionHeader(
            title: 'Whiteboard Interview Mode',
            subtitle: 'Unlimited architecture interviews — graded on scale, security, cost, HA, ops',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _prompt == null
                ? GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      for (final p in WhiteboardEngine.prompts)
                        ShadCard(
                          onTap: () => setState(() {
                            _prompt = p;
                            _result = null;
                            _components.clear();
                            _answer.clear();
                          }),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(p.brief,
                                  style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
                            ],
                          ),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ShadPanel(
                          title: _prompt!.title,
                          actions: [
                            TextButton(
                              onPressed: () => setState(() => _prompt = null),
                              child: const Text('Back'),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(_prompt!.brief, style: const TextStyle(fontSize: 13, height: 1.4)),
                                const SizedBox(height: 10),
                                const Text('Draw components (select):', style: TextStyle(fontSize: 12)),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final c in palette)
                                      FilterChip(
                                        label: Text(c, style: const TextStyle(fontSize: 11)),
                                        selected: _components.contains(c),
                                        onSelected: (v) => setState(() {
                                          if (v) {
                                            _components.add(c);
                                          } else {
                                            _components.remove(c);
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _answer,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Walk through the design: data plane, control, security, cost, recovery…',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShadButton(
                                  onPressed: () {
                                    final score = WhiteboardEngine.grade(
                                      _prompt!,
                                      _answer.text,
                                      _components,
                                    );
                                    AppServices.instance.flight.replay.record(
                                      title: _prompt!.title,
                                      answers: [_answer.text],
                                      score: score.overall,
                                      weakTopics: score.missing,
                                      feedback: score.feedback.join(' '),
                                    );
                                    AppServices.instance.flight.awardCareerXp(score.overall);
                                    setState(() {
                                      _result =
                                          'Overall ${score.overall}/100\n'
                                          'Scalability ${score.scalability} · Security ${score.security} · '
                                          'Cost ${score.cost} · Fault tolerance ${score.faultTolerance}\n\n'
                                          '${score.feedback.join('\n')}';
                                    });
                                  },
                                  child: const Text('Submit design'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadPanel(
                          title: 'Feedback / replay',
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              if (_result != null)
                                Text(_result!, style: const TextStyle(fontSize: 12, height: 1.4)),
                              const Divider(),
                              Text(
                                AppServices.instance.flight.replay.improvementReport(),
                                style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                              ),
                              const SizedBox(height: 8),
                              for (final s in AppServices.instance.flight.replay.sessions.take(5))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${s.title}: ${s.score} (conf ${s.confidence})',
                                    style: const TextStyle(fontSize: 11),
                                  ),
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
