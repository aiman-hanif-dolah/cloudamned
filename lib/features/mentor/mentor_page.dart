import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class MentorPage extends StatefulWidget {
  const MentorPage({super.key});

  @override
  State<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends State<MentorPage> {
  final _assumption = TextEditingController();
  final _log = <String>[];
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final mentor = AppServices.instance.flight.mentor;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShadSectionHeader(
            title: 'Mentor — Principal Cloud Architect',
            subtitle: 'Guides with questions. Challenges assumptions. Teaches judgement, not memorisation.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Session',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final l in _log)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(l, style: const TextStyle(fontSize: 12, height: 1.45, color: ShadcnColors.info)),
                          ),
                        if (_log.isEmpty)
                          const Text(
                            'Ask for coaching. I will not give the answer.',
                            style: TextStyle(color: ShadcnColors.mutedForeground),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 320,
                  child: ShadPanel(
                    title: 'Actions',
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShadButton(
                            onPressed: () {
                              setState(() {
                                _log.add(mentor.coach(step: _step++));
                              });
                            },
                            child: const Text('Next guiding question'),
                          ),
                          const SizedBox(height: 12),
                          ShadInput(controller: _assumption, hint: 'Your assumption…'),
                          const SizedBox(height: 8),
                          ShadButton(
                            variant: ShadButtonVariant.secondary,
                            onPressed: () {
                              if (_assumption.text.trim().isEmpty) return;
                              setState(() {
                                _log.add(mentor.challenge(_assumption.text.trim()));
                                _assumption.clear();
                              });
                            },
                            child: const Text('Challenge assumption'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Good engineers explain tradeoffs. Great engineers know which constraint is sacred to the customer.',
                            style: TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground, height: 1.4),
                          ),
                        ],
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
