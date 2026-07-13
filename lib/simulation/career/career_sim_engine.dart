import '../../data/content/career_projects.dart';
import '../../data/content/skills_catalog.dart';
import '../../domain/entities/career_project.dart';

class StepValidation {
  const StepValidation({
    required this.ok,
    required this.score,
    required this.feedback,
    this.skillHits = const [],
  });

  final bool ok;
  final int score;
  final String feedback;
  final List<String> skillHits;
}

/// Orchestrates consulting project lifecycle for cloudamned Career Simulation.
class CareerSimEngine {
  CareerProject? active;
  int currentStepIndex = 0;
  final Map<int, StepValidation> stepResults = {};
  final Map<String, dynamic> answers = {};
  final List<String> journal = [];
  final Map<String, double> skills = {
    for (final s in SkillsCatalog.baseSkills()) s.id: 0,
  };

  List<ProjectStep> get steps => ProjectStep.values;

  ProjectStep? get currentStep =>
      currentStepIndex >= 0 && currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  double get projectProgress {
    if (steps.isEmpty) return 0;
    return stepResults.length / steps.length;
  }

  int get overallScore {
    if (stepResults.isEmpty) return 0;
    final sum = stepResults.values.fold<int>(0, (a, b) => a + b.score);
    return (sum / stepResults.length).round();
  }

  void startProject(String projectId) {
    active = CareerProjects.byId(projectId);
    currentStepIndex = 0;
    stepResults.clear();
    answers.clear();
    journal.clear();
    if (active != null) {
      journal.add('Engagement opened: ${active!.customerName}');
      journal.add('Budget: ${active!.currency}${active!.budgetMonthly}/mo · ${active!.timelineWeeks} weeks');
    }
  }

  void abandon() {
    active = null;
    currentStepIndex = 0;
    stepResults.clear();
    answers.clear();
  }

  void _bumpSkills(List<String> ids, double amount) {
    for (final id in ids) {
      skills[id] = ((skills[id] ?? 0) + amount).clamp(0, 100);
    }
  }

  StepValidation submitStep(Map<String, dynamic> payload) {
    final project = active;
    final step = currentStep;
    if (project == null || step == null) {
      return const StepValidation(ok: false, score: 0, feedback: 'No active project.');
    }

    final result = switch (step) {
      ProjectStep.receiveRequirements => _validateRequirements(project, payload),
      ProjectStep.interviewStakeholders => _validateInterview(project, payload),
      ProjectStep.clarificationQuestions => _validateClarifications(project, payload),
      ProjectStep.analyseInfrastructure => _validateAnalysis(project, payload),
      ProjectStep.dependencyMap => _validateDeps(project, payload),
      ProjectStep.identifyRisks => _validateRisks(project, payload),
      ProjectStep.recommendPlatform => _validatePlatform(project, payload),
      ProjectStep.designArchitecture => _validateArchitecture(project, payload),
      ProjectStep.estimateCost => _validateCost(project, payload),
      ProjectStep.migrationStrategy => _validateMigration(project, payload),
      ProjectStep.rollbackStrategy => _validateRollback(project, payload),
      ProjectStep.buildInfrastructure => _validateBuild(project, payload),
      ProjectStep.deployWorkloads => _validateDeploy(project, payload),
      ProjectStep.configureMonitoring => _validateMonitoring(project, payload),
      ProjectStep.securityHardening => _validateSecurity(project, payload),
      ProjectStep.backupStrategy => _validateBackup(project, payload),
      ProjectStep.performTesting => _validateTesting(project, payload),
      ProjectStep.customerAcceptance => _validateAcceptance(project, payload),
      ProjectStep.generateDocumentation => _validateDocs(project, payload),
      ProjectStep.closeProject => _validateClose(project, payload),
    };

    answers[step.name] = payload;
    stepResults[currentStepIndex] = result;
    journal.add('Step ${step.number} ${step.title}: ${result.score}/100 — ${result.feedback}');
    _bumpSkills(result.skillHits, result.ok ? 8 : 3);

    if (result.ok && currentStepIndex < steps.length - 1) {
      currentStepIndex++;
    }
    return result;
  }

  StepValidation _validateRequirements(CareerProject p, Map<String, dynamic> payload) {
    final goals = (payload['goals'] as List?)?.cast<String>() ?? [];
    final hits = p.businessGoals.where((g) => goals.any((x) => x.toLowerCase().contains(g.toLowerCase().split(' ').first))).length;
    final budgetOk = payload['budgetAcknowledged'] == true;
    final timelineOk = payload['timelineAcknowledged'] == true;
    final score = ((hits / p.businessGoals.length) * 60 + (budgetOk ? 20 : 0) + (timelineOk ? 20 : 0)).round();
    return StepValidation(
      ok: score >= 60,
      score: score,
      feedback: score >= 60
          ? 'Requirements captured. Budget ${p.currency}${p.budgetMonthly}/mo and ${p.timelineWeeks}-week timeline noted.'
          : 'Capture more business goals and explicitly acknowledge budget + timeline.',
      skillHits: const ['cm-stake', 'cf-models', 'ld-prio'],
    );
  }

  StepValidation _validateInterview(CareerProject p, Map<String, dynamic> payload) {
    final spoken = (payload['notes'] as String? ?? '').toLowerCase();
    var hits = 0;
    for (final s in p.stakeholders) {
      if (spoken.contains(s.name.split(' ').last.toLowerCase()) || spoken.contains(s.role.toLowerCase().split(' ').last)) {
        hits++;
      }
      for (final c in s.concerns) {
        if (spoken.contains(c.toLowerCase().split(' ').first)) hits++;
      }
    }
    final score = (40 + hits * 10).clamp(0, 100);
    return StepValidation(
      ok: score >= 55,
      score: score,
      feedback: score >= 55
          ? 'Stakeholder interview notes cover key roles and concerns.'
          : 'Interview IT, security/finance, and business — log names, priorities, fears.',
      skillHits: const ['cm-stake', 'cm-meet', 'bh-star'],
    );
  }

  StepValidation _validateClarifications(CareerProject p, Map<String, dynamic> payload) {
    final asked = (payload['questions'] as List?)?.cast<String>() ?? [];
    final score = (asked.length * 20).clamp(0, 100);
    return StepValidation(
      ok: asked.length >= 3,
      score: score < 40 ? 40 + asked.length * 10 : score,
      feedback: asked.length >= 3
          ? 'Good clarification set. Sample answers unlocked in journal.'
          : 'Ask at least 3 clarifying questions (RTO/RPO, compliance, freeze windows).',
      skillHits: const ['cm-stake', 'ar-mig', 'ld-risk'],
    );
  }

  StepValidation _validateAnalysis(CareerProject p, Map<String, dynamic> payload) {
    final selected = (payload['assets'] as List?)?.cast<String>() ?? [];
    final hits = p.currentInfrastructure.where((a) => selected.contains(a.name)).length;
    final score = ((hits / p.currentInfrastructure.length) * 100).round();
    return StepValidation(
      ok: score >= 70,
      score: score,
      feedback: 'Inventory coverage $hits/${p.currentInfrastructure.length} assets.',
      skillHits: const ['ar-mig', 'win-ad', 'aws-ec2'],
    );
  }

  StepValidation _validateDeps(CareerProject p, Map<String, dynamic> payload) {
    final text = (payload['map'] as String? ?? '').toLowerCase();
    var hits = 0;
    for (final d in p.dependencies) {
      final key = d.split('→').first.trim().toLowerCase().split(' ').first;
      if (text.contains(key) || text.contains('→') || text.contains('->')) hits++;
    }
    final score = (30 + hits * 15).clamp(0, 100);
    return StepValidation(
      ok: score >= 55,
      score: score,
      feedback: score >= 55 ? 'Dependency map accepted.' : 'Map app→DB→identity→files with arrows.',
      skillHits: const ['ar-mig', 'tr-net', 'net-vpc'],
    );
  }

  StepValidation _validateRisks(CareerProject p, Map<String, dynamic> payload) {
    final risks = (payload['risks'] as List?)?.cast<String>() ?? [];
    final text = risks.join(' ').toLowerCase();
    var hits = 0;
    for (final r in p.keyRisks) {
      if (r.toLowerCase().split(' ').any((w) => w.length > 4 && text.contains(w))) hits++;
    }
    final score = (risks.length * 15 + hits * 10).clamp(0, 100);
    return StepValidation(
      ok: risks.length >= 3,
      score: score,
      feedback: risks.length >= 3 ? 'Risk register looks solid.' : 'List ≥3 risks with impact.',
      skillHits: const ['ld-risk', 'sec-audit', 'ar-dr'],
    );
  }

  StepValidation _validatePlatform(CareerProject p, Map<String, dynamic> payload) {
    final choice = payload['platform'] as String? ?? '';
    final rationale = (payload['rationale'] as String? ?? '').toLowerCase();
    final match = choice.toLowerCase() == p.recommendedPlatform.name;
    final rich = rationale.length > 80;
    final score = (match ? 55 : 30) + (rich ? 35 : 10) + (rationale.contains('cost') || rationale.contains('budget') ? 10 : 0);
    return StepValidation(
      ok: score >= 60,
      score: score.clamp(0, 100),
      feedback: match
          ? 'Platform recommendation aligns with engagement guidance (${p.recommendedPlatform.name}).'
          : 'Consider ${p.recommendedPlatform.name}: ${p.platformRationale}',
      skillHits: const ['ar-mig', 'cf-models', 'cm-exec'],
    );
  }

  StepValidation _validateArchitecture(CareerProject p, Map<String, dynamic> payload) {
    final comps = (payload['components'] as List?)?.cast<String>() ?? [];
    final lower = comps.map((e) => e.toLowerCase()).toList();
    var hits = 0;
    for (final m in p.architectureMustHave) {
      final key = m.toLowerCase().split(' ').last;
      if (lower.any((c) => c.contains(key) || key.contains(c.split(' ').last))) hits++;
    }
    final multiAz = lower.any((c) => c.contains('multi-az') || c.contains('multi az') || c.contains('az'));
    final private = lower.any((c) => c.contains('private'));
    final score = ((hits / p.architectureMustHave.length) * 70 + (multiAz ? 15 : 0) + (private ? 15 : 0)).round();
    return StepValidation(
      ok: score >= 65,
      score: score.clamp(0, 100),
      feedback: 'Architecture covers $hits/${p.architectureMustHave.length} must-haves.',
      skillHits: const ['ar-ha', 'aws-lz', 'net-vpc', 'sec-iam'],
    );
  }

  StepValidation _validateCost(CareerProject p, Map<String, dynamic> payload) {
    final estimate = (payload['estimate'] as num?)?.toInt() ?? 0;
    final within = estimate > 0 && estimate <= p.budgetMonthly;
    final nearTarget = (estimate - p.targetMonthlyCost).abs() <= p.budgetMonthly * 0.25;
    final notes = (payload['notes'] as String? ?? '').length > 40;
    final score = (within ? 50 : 20) + (nearTarget ? 30 : 10) + (notes ? 20 : 0);
    return StepValidation(
      ok: within && notes,
      score: score.clamp(0, 100),
      feedback: within
          ? 'Estimate ${p.currency}$estimate is within budget ${p.currency}${p.budgetMonthly}.'
          : 'Estimate must be ≤ budget ${p.currency}${p.budgetMonthly}/mo with driver notes.',
      skillHits: const ['aws-cost', 'ar-cost', 'cm-exec'],
    );
  }

  StepValidation _validateMigration(CareerProject p, Map<String, dynamic> payload) {
    final text = (payload['plan'] as String? ?? '').toLowerCase();
    final keys = ['pilot', 'wave', 'cutover', 'rehost', 'replatform', 'dms', 'backup'];
    final hits = keys.where((k) => text.contains(k)).length;
    final score = (30 + hits * 12).clamp(0, 100);
    return StepValidation(
      ok: hits >= 3,
      score: score,
      feedback: hits >= 3 ? 'Migration strategy has wave/pilot/cutover structure.' : 'Include pilot, waves, cutover method, tools.',
      skillHits: const ['ar-mig', 'aws-ec2', 'ops-runbook'],
    );
  }

  StepValidation _validateRollback(CareerProject p, Map<String, dynamic> payload) {
    final text = (payload['plan'] as String? ?? '').toLowerCase();
    final keys = ['rollback', 'abort', 'dns', 'snapshot', 'failback', 'rpo', 'rto'];
    final hits = keys.where((k) => text.contains(k)).length;
    final score = (25 + hits * 12).clamp(0, 100);
    return StepValidation(
      ok: hits >= 3,
      score: score,
      feedback: hits >= 3 ? 'Rollback plan accepted.' : 'Define abort criteria, DNS failback, data reverse path.',
      skillHits: const ['ar-dr', 'tr-rca', 'ld-risk'],
    );
  }

  StepValidation _validateBuild(CareerProject p, Map<String, dynamic> payload) {
    final items = (payload['built'] as List?)?.cast<String>() ?? [];
    final need = ['vpc', 'subnet', 'iam', 'logging', 'cloudtrail', 'account'];
    final lower = items.map((e) => e.toLowerCase()).join(' ');
    final hits = need.where((n) => lower.contains(n)).length;
    final score = ((hits / need.length) * 100).round();
    return StepValidation(
      ok: hits >= 4,
      score: score,
      feedback: 'Landing zone components marked: $hits/${need.length}.',
      skillHits: const ['aws-lz', 'aws-org', 'aws-iam', 'aws-trail'],
    );
  }

  StepValidation _validateDeploy(CareerProject p, Map<String, dynamic> payload) {
    final items = (payload['deployed'] as List?)?.cast<String>() ?? [];
    final score = (items.length * 20).clamp(0, 100);
    return StepValidation(
      ok: items.length >= 3,
      score: score,
      feedback: items.length >= 3 ? 'Workload deployment checklist complete.' : 'Deploy compute, data, LB/DNS at minimum.',
      skillHits: const ['aws-ec2', 'aws-rds', 'net-lb'],
    );
  }

  StepValidation _validateMonitoring(CareerProject p, Map<String, dynamic> payload) {
    final text = (payload['plan'] as String? ?? '').toLowerCase();
    final keys = ['alarm', 'dashboard', 'log', 'metric', 'on-call', 'cloudwatch', 'slo'];
    final hits = keys.where((k) => text.contains(k)).length;
    final score = (20 + hits * 12).clamp(0, 100);
    return StepValidation(
      ok: hits >= 3,
      score: score,
      feedback: hits >= 3 ? 'Monitoring design accepted.' : 'Cover metrics, logs, alarms, ownership.',
      skillHits: const ['aws-cw', 'ops-sre', 'tr-logs'],
    );
  }

  StepValidation _validateSecurity(CareerProject p, Map<String, dynamic> payload) {
    final controls = (payload['controls'] as List?)?.cast<String>() ?? [];
    final need = ['mfa', 'encryption', 'least', 'security group', 'private', 'patch'];
    final lower = controls.map((e) => e.toLowerCase()).join(' ');
    final hits = need.where((n) => lower.contains(n)).length;
    final score = ((hits / need.length) * 100).round();
    return StepValidation(
      ok: hits >= 4,
      score: score,
      feedback: 'Security controls $hits/${need.length}.',
      skillHits: const ['sec-iam', 'sec-mfa', 'sec-enc', 'sec-audit'],
    );
  }

  StepValidation _validateBackup(CareerProject p, Map<String, dynamic> payload) {
    final text = (payload['plan'] as String? ?? '').toLowerCase();
    final keys = ['backup', 'retention', 'restore', 'vault', 'snapshot', 'rpo', 'rto'];
    final hits = keys.where((k) => text.contains(k)).length;
    final score = (25 + hits * 12).clamp(0, 100);
    return StepValidation(
      ok: hits >= 3,
      score: score,
      feedback: hits >= 3 ? 'Backup/DR strategy accepted.' : 'Include vault, retention, restore test, RPO/RTO.',
      skillHits: const ['ar-dr', 'aws-ebs', 'ops-runbook'],
    );
  }

  StepValidation _validateTesting(CareerProject p, Map<String, dynamic> payload) {
    final tests = (payload['tests'] as List?)?.cast<String>() ?? [];
    final score = (tests.length * 20).clamp(0, 100);
    return StepValidation(
      ok: tests.length >= 3,
      score: score,
      feedback: tests.length >= 3 ? 'Test plan sufficient for UAT gate.' : 'Include functional, failover, security tests.',
      skillHits: const ['tr-perf', 'ar-ha', 'sec-audit'],
    );
  }

  StepValidation _validateAcceptance(CareerProject p, Map<String, dynamic> payload) {
    final signed = payload['signed'] == true;
    final criteria = (payload['criteriaMet'] as List?)?.cast<String>() ?? [];
    final score = (signed ? 50 : 0) + (criteria.length * 12).clamp(0, 50);
    return StepValidation(
      ok: signed && criteria.length >= 2,
      score: score.clamp(0, 100),
      feedback: signed ? 'Customer acceptance recorded.' : 'Obtain sign-off against success criteria.',
      skillHits: const ['cm-cust', 'cm-write', 'ld-decide'],
    );
  }

  StepValidation _validateDocs(CareerProject p, Map<String, dynamic> payload) {
    final docs = (payload['docs'] as List?)?.cast<String>() ?? [];
    final need = ['architecture', 'runbook', 'migration', 'incident', 'operations'];
    final lower = docs.map((e) => e.toLowerCase()).join(' ');
    final hits = need.where((n) => lower.contains(n)).length;
    final score = ((hits / need.length) * 100).round();
    return StepValidation(
      ok: hits >= 4,
      score: score,
      feedback: 'Documentation pack $hits/${need.length} artifacts.',
      skillHits: const ['cm-write', 'ops-runbook', 'ops-postmortem'],
    );
  }

  StepValidation _validateClose(CareerProject p, Map<String, dynamic> payload) {
    final handover = payload['handover'] == true;
    final lessons = (payload['lessons'] as String? ?? '').length > 30;
    final score = (handover ? 50 : 0) + (lessons ? 50 : 15);
    final ok = handover && lessons;
    if (ok) {
      _bumpSkills(const ['ops-ticket', 'ld-decide', 'cm-exec'], 12);
      journal.add('PROJECT CLOSED: ${p.customerName} · score $overallScore/100');
    }
    return StepValidation(
      ok: ok,
      score: score,
      feedback: ok ? 'Engagement closed. Ready for managed services transition.' : 'Complete handover checklist + lessons learned.',
      skillHits: const ['ld-decide', 'cm-exec', 'ops-postmortem'],
    );
  }

  Map<String, double> categoryAverages() {
    final byCat = <String, List<double>>{};
    for (final s in SkillsCatalog.baseSkills()) {
      byCat.putIfAbsent(s.category, () => []).add(skills[s.id] ?? 0);
    }
    return {
      for (final e in byCat.entries)
        e.key: e.value.isEmpty ? 0 : e.value.reduce((a, b) => a + b) / e.value.length,
    };
  }

  /// Weighted interview readiness across career dimensions.
  Map<String, double> readinessReport() {
    final cat = categoryAverages();
    double g(String c) => cat[c] ?? 0;
    final weighted = {
      'Cloud Fundamentals': g('Cloud Fundamentals'),
      'AWS': g('AWS'),
      'Azure': g('Azure'),
      'Google Cloud': g('GCP'),
      'Networking': g('Networking'),
      'Linux': g('Linux'),
      'Terraform': g('Terraform'),
      'DevOps': g('DevOps'),
      'Security': g('Security'),
      'Architecture': g('Architecture'),
      'Troubleshooting': g('Troubleshooting'),
      'Communication': g('Communication'),
      'Behavioral': g('Behavioral'),
    };
    final overall = weighted.values.isEmpty
        ? 0.0
        : weighted.values.reduce((a, b) => a + b) / weighted.length;
    return {...weighted, 'Overall': overall};
  }
}
