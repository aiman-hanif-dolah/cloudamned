class InterviewSession {
  InterviewSession({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.answers,
    required this.score,
    required this.weakTopics,
    required this.incorrectTerms,
    required this.confidence,
    required this.feedback,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final List<String> answers;
  final int score;
  final List<String> weakTopics;
  final List<String> incorrectTerms;
  final int confidence;
  final String feedback;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startedAt': startedAt.toIso8601String(),
        'answers': answers,
        'score': score,
        'weakTopics': weakTopics,
        'incorrectTerms': incorrectTerms,
        'confidence': confidence,
        'feedback': feedback,
      };

  factory InterviewSession.fromJson(Map<String, dynamic> j) => InterviewSession(
        id: j['id'] as String,
        title: j['title'] as String,
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        answers: List<String>.from(j['answers'] as List? ?? []),
        score: j['score'] as int? ?? 0,
        weakTopics: List<String>.from(j['weakTopics'] as List? ?? []),
        incorrectTerms: List<String>.from(j['incorrectTerms'] as List? ?? []),
        confidence: j['confidence'] as int? ?? 0,
        feedback: j['feedback'] as String? ?? '',
      );
}

class InterviewReplayStore {
  final List<InterviewSession> sessions = [];

  void record({
    required String title,
    required List<String> answers,
    required int score,
    required List<String> weakTopics,
    String feedback = '',
  }) {
    final text = answers.join(' ').toLowerCase();
    final badTerms = <String>[];
    // Common terminology mistakes
    if (text.contains('s3 instance')) badTerms.add('S3 is object storage, not an "instance"');
    if (text.contains('ec2 bucket')) badTerms.add('EC2 is compute; buckets are S3');
    if (text.contains('region zone') && !text.contains('availability')) {
      badTerms.add('Prefer "Availability Zone" terminology');
    }
    if (text.contains('security group is stateless')) {
      badTerms.add('Security Groups are stateful; NACLs are stateless');
    }

    final confidence = (answers.fold<int>(0, (a, b) => a + b.length) / 20).round().clamp(20, 95);
    sessions.insert(
      0,
      InterviewSession(
        id: 'int-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        startedAt: DateTime.now(),
        answers: answers,
        score: score,
        weakTopics: weakTopics,
        incorrectTerms: badTerms,
        confidence: confidence,
        feedback: feedback.isEmpty
            ? 'Score $score. Revise: ${weakTopics.isEmpty ? 'keep practicing system design depth' : weakTopics.join(', ')}.'
            : feedback,
      ),
    );
  }

  double get averageScore {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.score).reduce((a, b) => a + b) / sessions.length;
  }

  String improvementReport() {
    if (sessions.length < 2) {
      return 'Complete more interviews to track improvement over time.';
    }
    final recent = sessions.take(3).map((s) => s.score).toList();
    final older = sessions.skip(3).take(3).map((s) => s.score).toList();
    final r = recent.reduce((a, b) => a + b) / recent.length;
    final o = older.isEmpty ? r : older.reduce((a, b) => a + b) / older.length;
    final delta = r - o;
    return 'Recent avg ${r.toStringAsFixed(0)} vs prior ${o.toStringAsFixed(0)} '
        '(${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}). '
        'Confidence trend: ${sessions.first.confidence}.';
  }
}
