import '../../domain/entities/career_project.dart';

class DiscoveryQuestion {
  const DiscoveryQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.critical,
  });

  final String id;
  final String question;
  final String category;
  final bool critical;
}

class DiscoveryMessage {
  DiscoveryMessage({required this.from, required this.text, required this.at});
  final String from; // engineer | customer
  final String text;
  final DateTime at;
}

/// Customer-acted discovery interview — missing questions = missing requirements.
class DiscoveryEngine {
  CareerProject? project;
  final List<DiscoveryMessage> transcript = [];
  final Set<String> askedIds = {};
  final Set<String> uncoveredTopics = {};

  static const bank = <DiscoveryQuestion>[
    DiscoveryQuestion(id: 'problem', question: 'What business problem are we really solving?', category: 'problem', critical: true),
    DiscoveryQuestion(id: 'cause', question: 'What is causing the current pain?', category: 'problem', critical: true),
    DiscoveryQuestion(id: 'budget', question: 'What is the monthly budget envelope?', category: 'constraints', critical: true),
    DiscoveryQuestion(id: 'timeline', question: 'What is the hard deadline and why?', category: 'constraints', critical: true),
    DiscoveryQuestion(id: 'downtime', question: 'How much downtime is acceptable for cutover?', category: 'risk', critical: true),
    DiscoveryQuestion(id: 'rto', question: 'What RTO/RPO do you need for tier-1 systems?', category: 'risk', critical: true),
    DiscoveryQuestion(id: 'compliance', question: 'Which regulations or audits apply?', category: 'compliance', critical: true),
    DiscoveryQuestion(id: 'reuse', question: 'What existing infrastructure must we keep or reuse?', category: 'estate', critical: false),
    DiscoveryQuestion(id: 'scale', question: 'What growth do you expect in 12–24 months?', category: 'scale', critical: true),
    DiscoveryQuestion(id: 'perf', question: 'What performance SLAs matter to customers?', category: 'performance', critical: false),
    DiscoveryQuestion(id: 'identity', question: 'How do users and apps authenticate today?', category: 'identity', critical: true),
    DiscoveryQuestion(id: 'data', question: 'Where does sensitive data live and move?', category: 'data', critical: true),
    DiscoveryQuestion(id: 'stakeholders', question: 'Who signs off architecture and change windows?', category: 'people', critical: false),
    DiscoveryQuestion(id: 'ops', question: 'Who will operate this day-2 and with what skills?', category: 'ops', critical: false),
    DiscoveryQuestion(id: 'success', question: 'How will we know the project succeeded?', category: 'success', critical: true),
  ];

  void start(CareerProject p) {
    project = p;
    transcript
      ..clear()
      ..add(DiscoveryMessage(
        from: 'customer',
        text:
            'Hi — we\'re ${p.customerName}. We need help with our infrastructure. What do you need to know?',
        at: DateTime.now(),
      ));
    askedIds.clear();
    uncoveredTopics.clear();
  }

  /// Engineer asks a canned discovery question id or free text (keyword match).
  String ask(String input) {
    final p = project;
    if (p == null) return 'No active customer.';

    transcript.add(DiscoveryMessage(from: 'engineer', text: input, at: DateTime.now()));

    final lower = input.toLowerCase();
    DiscoveryQuestion? matched;
    for (final q in bank) {
      if (lower.contains(q.id) ||
          q.question.toLowerCase().split(' ').where((w) => w.length > 4).any(lower.contains)) {
        matched = q;
        break;
      }
    }
    // Keyword routing
    matched ??= _keywordMatch(lower);

    if (matched == null) {
      final reply =
          'I\'m not sure I follow. Could you ask about budget, downtime, compliance, growth, identity, or success criteria?';
      transcript.add(DiscoveryMessage(from: 'customer', text: reply, at: DateTime.now()));
      return reply;
    }

    askedIds.add(matched.id);
    uncoveredTopics.add(matched.category);
    final reply = _answer(p, matched);
    transcript.add(DiscoveryMessage(from: 'customer', text: reply, at: DateTime.now()));
    return reply;
  }

  DiscoveryQuestion? _keywordMatch(String lower) {
    if (lower.contains('budget') || lower.contains('cost')) {
      return bank.firstWhere((q) => q.id == 'budget');
    }
    if (lower.contains('downtime') || lower.contains('outage')) {
      return bank.firstWhere((q) => q.id == 'downtime');
    }
    if (lower.contains('rto') || lower.contains('rpo') || lower.contains('recover')) {
      return bank.firstWhere((q) => q.id == 'rto');
    }
    if (lower.contains('compliance') || lower.contains('audit') || lower.contains('pdpa')) {
      return bank.firstWhere((q) => q.id == 'compliance');
    }
    if (lower.contains('growth') || lower.contains('scale') || lower.contains('users')) {
      return bank.firstWhere((q) => q.id == 'scale');
    }
    if (lower.contains('identity') || lower.contains('login') || lower.contains('ad ')) {
      return bank.firstWhere((q) => q.id == 'identity');
    }
    if (lower.contains('problem') || lower.contains('pain') || lower.contains('why')) {
      return bank.firstWhere((q) => q.id == 'problem');
    }
    if (lower.contains('success') || lower.contains('done') || lower.contains('kpi')) {
      return bank.firstWhere((q) => q.id == 'success');
    }
    if (lower.contains('deadline') || lower.contains('timeline') || lower.contains('when')) {
      return bank.firstWhere((q) => q.id == 'timeline');
    }
    return null;
  }

  String _answer(CareerProject p, DiscoveryQuestion q) {
    return switch (q.id) {
      'problem' =>
        'Our real problem: ${p.businessGoals.take(2).join(' and ').toLowerCase()}. ${p.summary}',
      'cause' =>
        'Root causes we see: ${p.keyRisks.take(2).join('; ')}. Also legacy: ${p.currentInfrastructure.map((a) => a.name).take(3).join(', ')}.',
      'budget' =>
        'Finance approved roughly ${p.currency}${p.budgetMonthly}/month steady-state. Stretch is painful.',
      'timeline' =>
        'We have about ${p.timelineWeeks} weeks. ${p.constraints.where((c) => c.toLowerCase().contains('freeze') || c.toLowerCase().contains('rto')).join(' ')}',
      'downtime' =>
        p.clarificationAnswers['What is RTO for SQL?'] ??
            p.clarificationAnswers['What is RTO for tier-1?'] ??
            'Prefer under 4 hours planned; unplanned must be shorter.',
      'rto' =>
        p.clarificationAnswers['What is RTO for tier-1?'] ??
            p.clarificationAnswers['What is RTO for SQL?'] ??
            'Tier-1 RTO under a few hours; RPO near-zero preferred for DB.',
      'compliance' =>
        p.constraints.where((c) => c.toLowerCase().contains('compliance')).firstOrNull ??
            'We care about basic security hygiene and data residency.',
      'reuse' =>
        'Must keep/integrate: ${p.currentInfrastructure.map((a) => a.name).join(', ')}. Dependencies: ${p.dependencies.join('; ')}.',
      'scale' =>
        p.clarificationAnswers['Growth?'] ?? 'Expect significant growth; design for multi-AZ at least.',
      'perf' => 'Customer-facing latency matters more than batch jobs. Peak is business hours.',
      'identity' =>
        p.currentInfrastructure.any((a) => a.name.toLowerCase().contains('active directory') || a.type == 'Identity')
            ? 'Active Directory is source of truth for SSO today.'
            : 'Mix of local accounts and LDAP — messy.',
      'data' =>
        'Sensitive data mainly in ${p.currentInfrastructure.where((a) => a.type.contains('Database') || a.type.contains('Storage')).map((a) => a.name).join(', ')}.',
      'stakeholders' =>
        p.stakeholders.map((s) => '${s.name} (${s.role})').join('; ') + ' — they sign off changes.',
      'ops' =>
        'Small IT team; they need runbooks and training. Limited cloud experience.',
      'success' => p.successCriteria.join(' | '),
      _ => 'Let me check with my team and get back to you.',
    };
  }

  double get coverage {
    final critical = bank.where((q) => q.critical).length;
    final got = bank.where((q) => q.critical && askedIds.contains(q.id)).length;
    return got / critical;
  }

  List<String> get missingCritical =>
      bank.where((q) => q.critical && !askedIds.contains(q.id)).map((q) => q.question).toList();

  String scorecard() {
    final pct = (coverage * 100).round();
    final buf = StringBuffer('Discovery coverage: $pct%\n');
    if (missingCritical.isNotEmpty) {
      buf.writeln('Missing critical questions:');
      for (final m in missingCritical) {
        buf.writeln(' • $m');
      }
      buf.writeln('\nPoor discovery → weak architecture later.');
    } else {
      buf.writeln('Strong discovery. You may proceed to architecture decisions.');
    }
    return buf.toString();
  }
}
