import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/comms/comms_grader.dart';
import '../../simulation/meetings/meeting_engine.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  int _tab = 0;
  MeetingScenario? _meeting;
  CustomerQuestion? _question;
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
            title: 'Meetings & Customer Communication',
            subtitle: 'Stand-ups · architecture reviews · exec pitches · graded customer answers',
          ),
          const SizedBox(height: 8),
          ShadTabs(
            tabs: const ['Meetings', 'Customer Q&A'],
            index: _tab,
            onChanged: (i) => setState(() {
              _tab = i;
              _feedback = null;
              _answer.clear();
            }),
          ),
          const SizedBox(height: 12),
          Expanded(child: _tab == 0 ? _meetings() : _comms()),
        ],
      ),
    );
  }

  Widget _meetings() {
    if (_meeting == null) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: [
          for (final m in MeetingBank.scenarios)
            ShadCard(
              onTap: () => setState(() {
                _meeting = m;
                _feedback = null;
                _answer.clear();
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(m.setting, style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                  const SizedBox(height: 6),
                  Text(m.prompt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      );
    }
    final m = _meeting!;
    return ShadPanel(
      title: m.title,
      actions: [
        TextButton(
          onPressed: () => setState(() => _meeting = null),
          child: const Text('Back'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(m.prompt, style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 6),
            Text(
              'Agenda: ${m.agenda.join(' · ')}',
              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _answer,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: 'Speak your update…'),
              ),
            ),
            const SizedBox(height: 8),
            ShadButton(
              onPressed: () {
                final score = MeetingBank.grade(m, _answer.text);
                setState(() {
                  _feedback =
                      'Overall ${score.overall}/100 — comms ${score.communication}, '
                      'decisions ${score.decisions}, technical ${score.technical}\n${score.feedback}';
                });
                AppServices.instance.progressCubit.addXp(score.overall >= 70 ? 40 : 15);
              },
              child: const Text('Submit'),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Text(_feedback!, style: const TextStyle(fontSize: 12, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _comms() {
    if (_question == null) {
      return ListView(
        children: [
          for (final q in CommsGrader.questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShadCard(
                onTap: () => setState(() {
                  _question = q;
                  _feedback = null;
                  _answer.clear();
                }),
                padding: const EdgeInsets.all(12),
                child: Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      );
    }
    final q = _question!;
    return ShadPanel(
      title: 'Customer asks',
      actions: [
        TextButton(
          onPressed: () => setState(() => _question = null),
          child: const Text('Back'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _answer,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: 'Your answer to the customer…'),
              ),
            ),
            const SizedBox(height: 8),
            ShadButton(
              onPressed: () {
                final s = CommsGrader.grade(q, _answer.text);
                setState(() => _feedback = 'Score ${s.overall}/100\n${s.feedback.join('\n')}');
                AppServices.instance.progressCubit.addXp(s.overall >= 70 ? 50 : 20);
              },
              child: const Text('Grade response'),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_feedback!, style: const TextStyle(fontSize: 12, height: 1.4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
