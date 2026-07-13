import 'dart:async';
import 'dart:math';

import 'incident_catalog.dart';
import 'ops_models.dart';
import 'runbook_catalog.dart';

/// Cloud Operations Center — service desk + shift + monitoring + KB + portfolio.
/// Additive module; does not replace existing TicketEngine / Incident Lab.
class OpsCenterEngine {
  OpsCenterEngine() {
    queue.addAll(IncidentCatalog.seedQueue(count: 18));
    _seedMonitoring();
    _seedStandup();
  }

  final List<OpsTicket> queue = [];
  final List<KbArticle> knowledgeBase = [];
  final List<PortfolioItem> portfolio = [];
  final ShiftMetrics metrics = ShiftMetrics();
  final List<String> customerNotifications = [];
  final List<String> recentDeployments = [
    'web-api 1.8.4 → prod (green)',
    'terraform network module apply (staging)',
    'cert-rotator nightly job OK',
  ];
  final List<String> upcomingMaintenance = [
    'Sun 02:00 — DB minor patch (approved CR-4412)',
    'Tue 22:00 — NAT failover drill',
  ];
  final List<String> recentEscalations = [];
  final List<String> standupNotes = [];

  // Live monitoring (0-100 style gauges + series)
  final Map<String, double> gauges = {};
  final Map<String, List<double>> series = {};
  final List<String> liveAlerts = [];

  // Shift state
  bool shiftActive = false;
  DateTime? shiftStarted;
  int virtualHour = 9; // 09:00–17:00
  Timer? _tick;
  final _rng = Random();

  String engineerName = 'You (Graduate CTE)';

  List<OpsTicket> get openTickets => queue
      .where((t) =>
          t.status != OpsTicketStatus.closed &&
          t.status != OpsTicketStatus.kbCreated &&
          t.status != OpsTicketStatus.resolved)
      .toList();

  List<OpsTicket> get critical =>
      queue.where((t) => t.priority == OpsPriority.p1Critical && t.status != OpsTicketStatus.closed).toList();

  double get infraHealth {
    final cpu = gauges['CPU'] ?? 50;
    final mem = gauges['Memory'] ?? 50;
    final err = gauges['Error Rate'] ?? 5;
    return (100 - (cpu + mem) / 4 - err).clamp(0, 100);
  }

  void _seedMonitoring() {
    for (final k in [
      'CPU',
      'Memory',
      'Disk Usage',
      'Network',
      'Latency',
      'Error Rate',
      'HTTP 5xx',
      'Response Time',
      'Active Users',
      'Running Containers',
      'Virtual Machines',
      'Storage Capacity',
      'Database Health',
      'Queue Length',
      'Health Score',
    ]) {
      gauges[k] = 20 + _rng.nextDouble() * 40;
      series[k] = List.generate(20, (_) => 15 + _rng.nextDouble() * 50);
    }
    gauges['Database Health'] = 88;
    gauges['Health Score'] = 82;
  }

  void _seedStandup() {
    standupNotes.addAll([
      'Yesterday: 4 tickets closed, 1 escalated (provider networking).',
      'Today: Watch ALB 5xx, cert expiry in 12 days, staging TF apply.',
      'Critical: Customer portal latency SLO at risk during promo.',
      'Pending: Waiting on customer for VPN peer IP confirmation.',
      'Deployments: web-api 1.8.4 rolled out; monitor error budget.',
      'Maintenance: Sunday DB patch CR-4412 needs peer review.',
    ]);
  }

  void startShift() {
    shiftActive = true;
    shiftStarted = DateTime.now();
    virtualHour = 9;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 8), (_) => _onShiftTick());
    _pulseMonitoring();
  }

  void endShift() {
    shiftActive = false;
    _tick?.cancel();
    _tick = null;
  }

  void dispose() => _tick?.cancel();

  void _onShiftTick() {
    if (!shiftActive) return;
    virtualHour = 9 + ((DateTime.now().difference(shiftStarted!).inSeconds ~/ 8) % 9);
    _pulseMonitoring();
    // New tickets occasionally
    if (_rng.nextDouble() < 0.35) {
      final t = IncidentCatalog.generate();
      queue.insert(0, t);
      customerNotifications.insert(0, '${t.number}: ${t.description.split('\n').first}');
      if (customerNotifications.length > 20) customerNotifications.removeLast();
    }
    // Alerts from thresholds
    liveAlerts.clear();
    if ((gauges['CPU'] ?? 0) > 85) liveAlerts.add('ALARM CPU > 85% on web-asg');
    if ((gauges['Disk Usage'] ?? 0) > 90) liveAlerts.add('ALARM Disk /var > 90% log-aggregator');
    if ((gauges['Error Rate'] ?? 0) > 8) liveAlerts.add('ALARM Error rate elevated orders-api');
    if ((gauges['HTTP 5xx'] ?? 0) > 5) liveAlerts.add('ALARM ALB 5xx spike');
    if ((gauges['Database Health'] ?? 100) < 70) liveAlerts.add('ALARM DB health degraded');
  }

  void _pulseMonitoring() {
    for (final e in gauges.entries.toList()) {
      var v = e.value + (_rng.nextDouble() - 0.45) * 8;
      v = v.clamp(5, 98);
      gauges[e.key] = v;
      final s = series[e.key] ?? [];
      s.add(v);
      if (s.length > 24) s.removeAt(0);
      series[e.key] = s;
    }
    gauges['Health Score'] = infraHealth;
  }

  OpsTicket? byNumber(String n) {
    try {
      return queue.firstWhere((t) => t.number == n);
    } catch (_) {
      return null;
    }
  }

  void assign(String number) {
    final t = byNumber(number);
    if (t == null) return;
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.assigned,
      assignedEngineer: engineerName,
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Assigned to $engineerName', kind: 'assign'),
      ],
    );
    metrics.responses++;
    metrics.responseMinutes.add(t.age.inMinutes.clamp(0, 120));
  }

  void collectEvidence(String number, String evidenceId) {
    final t = byNumber(number);
    if (t == null) return;
    final set = {...t.evidenceCollected, evidenceId};
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.investigating,
      evidenceCollected: set,
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Evidence: $evidenceId', kind: 'evidence'),
      ],
    );
    metrics.investigations++;
  }

  void addInternalNote(String number, String note) {
    final t = byNumber(number);
    if (t == null) return;
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      internalNotes: [...t.internalNotes, note],
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Internal: $note', kind: 'note'),
      ],
    );
  }

  /// Grade customer message for professionalism / clarity (local rubric).
  int sendCustomerUpdate(String number, String message) {
    final t = byNumber(number);
    if (t == null) return 0;
    final score = _gradeComms(message);
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.waitingCustomer,
      customerReplies: [...t.customerReplies, 'Engineer: $message'],
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Customer update sent (score $score)', kind: 'comms'),
      ],
    );
    metrics.commsScores.add(score);
    customerNotifications.insert(0, '${t.number} update sent');
    return score;
  }

  int _gradeComms(String message) {
    final m = message.toLowerCase();
    var s = 40;
    if (message.trim().length > 40) s += 15;
    if (m.contains('investigat') || m.contains('checking')) s += 10;
    if (m.contains('eta') || m.contains('update') || m.contains('next')) s += 10;
    if (m.contains('sorry') || m.contains('thank') || m.contains('appreciate')) s += 10;
    if (m.contains('root cause') || m.contains('resolved') || m.contains('confirm')) s += 10;
    if (m.contains('idiot') || m.contains('stupid') || m.contains('as soon as possible!!!!')) s -= 30;
    return s.clamp(0, 100);
  }

  void setWaitingInternal(String number, String team) {
    final t = byNumber(number);
    if (t == null) return;
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.waitingInternal,
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Waiting on $team', kind: 'wait'),
      ],
    );
  }

  /// Propose resolution after investigation — scores accuracy vs catalog.
  ({bool ok, int accuracy, String feedback}) resolve({
    required String number,
    required String rootCause,
    required String resolution,
    required String rca,
  }) {
    final t = byNumber(number);
    if (t == null) {
      return (ok: false, accuracy: 0, feedback: 'Ticket not found');
    }
    if (t.evidenceCollected.length < 2) {
      return (
        ok: false,
        accuracy: 20,
        feedback: 'Collect more evidence before proposing a fix (min 2 investigation actions).',
      );
    }

    final accuracy = _scoreMatch(rootCause, t.correctRootCause) * 0.55 +
        _scoreMatch(resolution, t.correctResolution) * 0.45;

    final breached = t.slaBreached;
    if (breached) {
      metrics.slaMisses++;
    } else {
      metrics.slaHits++;
    }
    metrics.resolutionMinutes.add(t.age.inMinutes.clamp(1, 480));
    metrics.accuracyScores.add(accuracy.round());
    metrics.ticketsClosed++;

    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.resolved,
      rca: rca,
      resolutionHistory: [...t.resolutionHistory, resolution],
      timeline: [
        ...t.timeline,
        TimelineEvent(
          at: DateTime.now(),
          actor: engineerName,
          message: 'Resolved (accuracy ${accuracy.round()}%)',
          kind: 'resolve',
        ),
      ],
    );

    // Portfolio artifact
    portfolio.insert(
      0,
      PortfolioItem(
        id: 'pf-${t.number}-incident',
        kind: 'Incident Report',
        title: '${t.number} — ${t.description.split('\n').first}',
        body: 'Customer: ${t.customerName}\nService: ${t.affectedService}\n'
            'Root cause: $rootCause\nResolution: $resolution\nRCA:\n$rca\n'
            'Evidence: ${t.evidenceCollected.join(', ')}',
      ),
    );

    return (
      ok: accuracy >= 50,
      accuracy: accuracy.round(),
      feedback: accuracy >= 70
          ? 'Solid investigation and resolution. Consider creating a KB article.'
          : 'Partial match. Model RCA: ${t.correctRootCause}\nModel fix: ${t.correctResolution}',
    );
  }

  double _scoreMatch(String a, String b) {
    final ta = a.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((w) => w.length > 3).toSet();
    final tb = b.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((w) => w.length > 3).toSet();
    if (tb.isEmpty) return 50;
    final hit = ta.intersection(tb).length;
    return (hit / tb.length * 100).clamp(0, 100);
  }

  void close(String number) {
    final t = byNumber(number);
    if (t == null) return;
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.closed,
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'Ticket closed', kind: 'close'),
      ],
    );
  }

  KbArticle createKbFromTicket(String number) {
    final t = byNumber(number);
    if (t == null) {
      throw StateError('ticket');
    }
    final article = KbArticle(
      id: 'KB-${t.number}',
      title: t.description.split('\n').first,
      problem: t.description,
      environment: '${t.provider.name} · ${t.affectedService} · ${t.customerName}',
      symptoms: t.timeline.map((e) => e.message).take(5).join('; '),
      rootCause: t.rca.isNotEmpty ? t.rca : t.correctRootCause,
      resolution: t.resolutionHistory.isNotEmpty ? t.resolutionHistory.last : t.correctResolution,
      verification: 'Health checks green; customer validated; alerts cleared.',
      prevention: 'Monitoring, IaC peer review, runbook linkage, change checklist.',
      relatedTickets: [t.number],
      relatedRunbooks: [t.runbookId],
    );
    knowledgeBase.insert(0, article);
    metrics.docsScores.add(85);

    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      status: OpsTicketStatus.kbCreated,
      kbLink: article.id,
      timeline: [
        ...t.timeline,
        TimelineEvent(at: DateTime.now(), actor: engineerName, message: 'KB ${article.id} created', kind: 'kb'),
      ],
    );

    portfolio.insert(
      0,
      PortfolioItem(
        id: 'pf-${article.id}',
        kind: 'Knowledge Base Article',
        title: article.title,
        body: _formatKb(article),
      ),
    );

    final rb = RunbookCatalog.byId(t.runbookId);
    if (rb != null) {
      portfolio.insert(
        0,
        PortfolioItem(
          id: 'pf-rb-${rb.id}-${t.number}',
          kind: 'Runbook',
          title: rb.title,
          body: '${rb.summary}\n\n${rb.steps.map((s) => '• $s').join('\n')}',
        ),
      );
    }

    return article;
  }

  String _formatKb(KbArticle a) => '''
# ${a.title}

## Problem
${a.problem}

## Environment
${a.environment}

## Symptoms
${a.symptoms}

## Root Cause
${a.rootCause}

## Resolution
${a.resolution}

## Verification
${a.verification}

## Prevention
${a.prevention}

## Related Tickets
${a.relatedTickets.join(', ')}

## Related Runbooks
${a.relatedRunbooks.join(', ')}
''';

  /// Escalation when junior cannot safely resolve.
  String escalate({
    required String number,
    required String reason,
    required String evidence,
    required String findings,
    required String recommendation,
  }) {
    final t = byNumber(number);
    if (t == null) return 'Ticket not found';
    final i = queue.indexOf(t);
    queue[i] = t.copyWith(
      escalated: true,
      escalationReason: reason,
      status: OpsTicketStatus.waitingInternal,
      timeline: [
        ...t.timeline,
        TimelineEvent(
          at: DateTime.now(),
          actor: engineerName,
          message: 'ESCALATED: $reason',
          kind: 'escalate',
        ),
      ],
    );
    metrics.escalations++;
    recentEscalations.insert(0, '${t.number}: $reason');
    final feedback = _seniorFeedback(reason, evidence, findings);
    return feedback;
  }

  String _seniorFeedback(String reason, String evidence, String findings) {
    final r = reason.toLowerCase();
    if (evidence.trim().length < 20) {
      return 'Senior CTE: Escalation noted, but attach more evidence (logs, timestamps, what you already ruled out).';
    }
    if (r.contains('outage') || r.contains('provider') || r.contains('hardware')) {
      return 'Senior CTE: Correct to escalate provider/hardware scope. Open provider case; keep customer updates every 30m.';
    }
    if (r.contains('security') || r.contains('breach')) {
      return 'Senior CTE: Security path engaged. Freeze changes; preserve logs; notify security on-call.';
    }
    if (r.contains('redesign') || r.contains('architecture')) {
      return 'Senior CTE: Good call — this is design debt, not a P1 patch. Create problem ticket + architecture review.';
    }
    return 'Senior CTE: Thanks for structured findings: "$findings". We will take ownership; you stay on customer comms.';
  }

  /// Shadow senior questions (investigation mentor).
  String shadowQuestion(OpsTicket t) {
    final asked = t.evidenceCollected.length;
    final qs = [
      'What evidence supports your current hypothesis?',
      'Have you checked DNS and certificates for ${t.affectedService}?',
      'What changed recently (deploy, SG, TF, IAM)?',
      'Could this be networking (SG/NACL/route) rather than compute?',
      'Which monitoring signal first went red?',
      'If you restart now, what will you lose for forensics?',
      'Is this single-tenant blast radius or platform-wide?',
    ];
    return qs[asked % qs.length];
  }

  List<String> investigationActionsFor(OpsTicket t) => [
        'monitoring_dashboard',
        'linux_logs',
        'windows_event_viewer',
        'terraform_state',
        'iam_policies',
        'security_groups',
        'route_tables',
        'dns_records',
        'cicd_logs',
        'deployment_history',
        'storage_usage',
        'network_topology',
        ...t.investigationSteps.map((s) => 'step:${s.toLowerCase().replaceAll(' ', '_')}'),
      ];
}
