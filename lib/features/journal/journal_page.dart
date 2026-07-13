import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _q = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final journal = AppServices.instance.flight.journal;
    final entries = journal.search(_query);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Engineering Journal',
            subtitle: 'Searchable portfolio — decisions, failures, lessons, alternatives',
            trailing: ShadButton(
              size: ShadButtonSize.sm,
              variant: ShadButtonVariant.outline,
              onPressed: () {
                journal.autoFromProject(
                  projectId: 'manual',
                  customerName: 'Manual note',
                  score: 70,
                  decisions: ['Documented working notes'],
                  lessons: ['Capture lessons while context is fresh'],
                );
                setState(() {});
              },
              child: const Text('Add sample entry'),
            ),
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _q,
            hint: 'Search journal…',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: entries.isEmpty
                ? const ShadEmpty(
                    title: 'No entries yet',
                    description: 'Complete projects or add notes — this becomes your interview portfolio.',
                    icon: Icons.menu_book_outlined,
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return ShadCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              e.createdAt.toIso8601String(),
                              style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground),
                            ),
                            const SizedBox(height: 8),
                            Text(e.whatHappened, style: const TextStyle(fontSize: 12, height: 1.35)),
                            const SizedBox(height: 6),
                            Text('Decisions: ${e.decisions}',
                                style: const TextStyle(fontSize: 11, height: 1.3)),
                            Text('Lessons: ${e.lessons}',
                                style: const TextStyle(fontSize: 11, height: 1.3)),
                            Text('Improvements: ${e.improvements}',
                                style: const TextStyle(fontSize: 11, height: 1.3)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
