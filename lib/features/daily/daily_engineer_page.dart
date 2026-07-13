import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class DailyEngineerPage extends StatefulWidget {
  const DailyEngineerPage({super.key});

  @override
  State<DailyEngineerPage> createState() => _DailyEngineerPageState();
}

class _DailyEngineerPageState extends State<DailyEngineerPage> {
  int? _active;
  final _answer = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final day = AppServices.instance.dailyEngineer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Daily Engineer Mode',
            subtitle: 'Simulate a full workday — stand-up to EOD summary',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadBadge(label: '${day.completedCount}/${day.schedule.length} · avg ${day.dayScore}'),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => setState(day.reshuffle),
                  child: const Text('New day'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ShadProgress(value: day.progress),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Schedule',
                    child: ListView.builder(
                      itemCount: day.schedule.length,
                      itemBuilder: (context, i) {
                        final b = day.schedule[i];
                        return ListTile(
                          dense: true,
                          selected: _active == i,
                          leading: Icon(
                            b.completed ? Icons.check_circle : Icons.schedule,
                            size: 16,
                            color: b.completed ? ShadcnColors.success : ShadcnColors.mutedForeground,
                          ),
                          title: Text('${b.time}  ${b.title}', style: const TextStyle(fontSize: 12)),
                          subtitle: Text(b.kind, style: const TextStyle(fontSize: 10)),
                          trailing: b.score != null
                              ? Text('${b.score}', style: const TextStyle(fontSize: 11))
                              : null,
                          onTap: () => setState(() => _active = i),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _active == null
                      ? const ShadEmpty(title: 'Select a time block', icon: Icons.today_outlined)
                      : ShadPanel(
                          title: day.schedule[_active!].title,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(day.schedule[_active!].prompt,
                                    style: const TextStyle(fontSize: 13, height: 1.4)),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _answer,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Your response / actions…',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShadButton(
                                  onPressed: () {
                                    final text = _answer.text.trim();
                                    final score = text.length < 40
                                        ? 40
                                        : text.length < 120
                                            ? 70
                                            : 88;
                                    setState(() {
                                      day.complete(_active!, score: score, notes: text);
                                      _answer.clear();
                                    });
                                    AppServices.instance.progressCubit.addXp(25);
                                  },
                                  child: const Text('Complete block'),
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
