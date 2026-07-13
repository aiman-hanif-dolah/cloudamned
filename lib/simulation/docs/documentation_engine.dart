class DocArtifact {
  const DocArtifact({
    required this.id,
    required this.title,
    required this.requiredSections,
  });

  final String id;
  final String title;
  final List<String> requiredSections;
}

class DocumentationEngine {
  final Map<String, String> bodies = {};

  static const artifacts = <DocArtifact>[
    DocArtifact(
      id: 'arch',
      title: 'Architecture Document',
      requiredSections: ['context', 'components', 'network', 'security', 'dr'],
    ),
    DocArtifact(
      id: 'migration',
      title: 'Migration Plan',
      requiredSections: ['waves', 'pilot', 'cutover', 'rollback', 'owners'],
    ),
    DocArtifact(
      id: 'deploy',
      title: 'Deployment Guide',
      requiredSections: ['prereq', 'steps', 'validation', 'rollback'],
    ),
    DocArtifact(
      id: 'runbook',
      title: 'Runbook',
      requiredSections: ['symptoms', 'checks', 'remediation', 'escalate'],
    ),
    DocArtifact(
      id: 'ops',
      title: 'Operational Manual',
      requiredSections: ['monitoring', 'backup', 'patch', 'access'],
    ),
    DocArtifact(
      id: 'incident',
      title: 'Incident Report',
      requiredSections: ['impact', 'timeline', 'actions', 'status'],
    ),
    DocArtifact(
      id: 'rca',
      title: 'Root Cause Analysis',
      requiredSections: ['root cause', 'contributing', 'fix', 'prevention'],
    ),
    DocArtifact(
      id: 'postmortem',
      title: 'Postmortem',
      requiredSections: ['summary', 'timeline', 'lessons', 'actions'],
    ),
    DocArtifact(
      id: 'cr',
      title: 'Change Request',
      requiredSections: ['change', 'risk', 'window', 'backout'],
    ),
    DocArtifact(
      id: 'maint',
      title: 'Maintenance Guide',
      requiredSections: ['schedule', 'tasks', 'checks'],
    ),
    DocArtifact(
      id: 'kb',
      title: 'Knowledge Base Article',
      requiredSections: ['problem', 'solution', 'refs'],
    ),
  ];

  int scoreArtifact(DocArtifact doc) {
    final body = (bodies[doc.id] ?? '').toLowerCase();
    if (body.trim().isEmpty) return 0;
    final hits = doc.requiredSections.where((s) => body.contains(s.toLowerCase())).length;
    final lengthBonus = body.length > 200 ? 20 : body.length > 80 ? 10 : 0;
    return ((hits / doc.requiredSections.length) * 80 + lengthBonus).round().clamp(0, 100);
  }

  int get overallScore {
    final scores = artifacts.map(scoreArtifact).toList();
    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  String completenessReport() {
    final buf = StringBuffer('Documentation completeness\n\n');
    for (final d in artifacts) {
      final s = scoreArtifact(d);
      buf.writeln('${d.title.padRight(28)} $s/100');
    }
    buf.writeln('\nPack average: $overallScore/100');
    return buf.toString();
  }
}
