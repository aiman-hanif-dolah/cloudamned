import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/ops/ops_interview.dart';

class OpsInterviewPage extends StatefulWidget {
  const OpsInterviewPage({super.key});

  @override
  State<OpsInterviewPage> createState() => _OpsInterviewPageState();
}

class _OpsInterviewPageState extends State<OpsInterviewPage> {
  OpsInterviewQuestion? _q;
  final _answer = TextEditingController();
  String? _feedback;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShadSectionHeader(
            title: 'Ops Interview Prep',
            subtitle: 'Questions drawn from real junior CTE desk work — tech + structure + communication',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _q == null
                ? ListView(
                    children: [
                      for (final q in OpsInterviewBank.questions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ShadCard(
                            onTap: () => setState(() {
                              _q = q;
                              _feedback = null;
                              _answer.clear();
                            }),
                            padding: const EdgeInsets.all(14),
                            child: Text(q.prompt, style: const TextStyle(fontSize: 13, height: 1.35)),
                          ),
                        ),
                    ],
                  )
                : ShadPanel(
                    title: 'Question',
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _q = null),
                        child: const Text('Back'),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_q!.prompt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _answer,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                hintText: 'Structure your answer: first checks → evidence → decision → comms…',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ShadButton(
                            onPressed: () {
                              final s = OpsInterviewBank.grade(_q!, _answer.text);
                              setState(() {
                                _feedback =
                                    'Overall ${s.overall}/100 · Technical ${s.technical} · '
                                    'Structure ${s.structure} · Communication ${s.communication}\n\n${s.feedback}';
                              });
                              AppServices.instance.progressCubit.addXp(s.overall >= 70 ? 50 : 20);
                              AppServices.instance.opsCenter.metrics.commsScores.add(s.communication);
                              AppServices.instance.opsCenter.metrics.accuracyScores.add(s.technical);
                            },
                            child: const Text('Evaluate answer'),
                          ),
                          if (_feedback != null) ...[
                            const SizedBox(height: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  _feedback!,
                                  style: const TextStyle(fontSize: 12, height: 1.4, color: ShadcnColors.mutedForeground),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
