class JournalEntry {
  JournalEntry({
    required this.id,
    required this.title,
    required this.projectId,
    required this.createdAt,
    required this.whatHappened,
    required this.decisions,
    required this.failures,
    required this.successes,
    required this.lessons,
    required this.alternatives,
    required this.mistakes,
    required this.improvements,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String projectId;
  final DateTime createdAt;
  final String whatHappened;
  final String decisions;
  final String failures;
  final String successes;
  final String lessons;
  final String alternatives;
  final String mistakes;
  final String improvements;
  final List<String> tags;

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        whatHappened.toLowerCase().contains(q) ||
        lessons.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'projectId': projectId,
        'createdAt': createdAt.toIso8601String(),
        'whatHappened': whatHappened,
        'decisions': decisions,
        'failures': failures,
        'successes': successes,
        'lessons': lessons,
        'alternatives': alternatives,
        'mistakes': mistakes,
        'improvements': improvements,
        'tags': tags,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        projectId: j['projectId'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        whatHappened: j['whatHappened'] as String? ?? '',
        decisions: j['decisions'] as String? ?? '',
        failures: j['failures'] as String? ?? '',
        successes: j['successes'] as String? ?? '',
        lessons: j['lessons'] as String? ?? '',
        alternatives: j['alternatives'] as String? ?? '',
        mistakes: j['mistakes'] as String? ?? '',
        improvements: j['improvements'] as String? ?? '',
        tags: List<String>.from(j['tags'] as List? ?? []),
      );
}

class EngineeringJournal {
  final List<JournalEntry> entries = [];

  void add(JournalEntry e) => entries.insert(0, e);

  void autoFromProject({
    required String projectId,
    required String customerName,
    required int score,
    required List<String> decisions,
    required List<String> lessons,
  }) {
    add(JournalEntry(
      id: 'j-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Engagement: $customerName',
      projectId: projectId,
      createdAt: DateTime.now(),
      whatHappened: 'Completed consulting lifecycle for $customerName with score $score/100.',
      decisions: decisions.join('\n'),
      failures: lessons.where((l) => l.toLowerCase().contains('fail') || l.toLowerCase().contains('miss')).join('\n'),
      successes: 'Project score $score. Deliverables accepted into portfolio.',
      lessons: lessons.join('\n'),
      alternatives: 'Could have phased pilot longer; re-evaluate platform choice annually.',
      mistakes: score < 70 ? 'Discovery or architecture depth insufficient.' : 'None critical recorded.',
      improvements: 'Automate more with Terraform; tighten runbooks after first incident drill.',
      tags: ['project', customerName, if (score >= 80) 'strong'],
    ));
  }

  List<JournalEntry> search(String q) {
    if (q.trim().isEmpty) return entries;
    return entries.where((e) => e.matches(q)).toList();
  }
}
