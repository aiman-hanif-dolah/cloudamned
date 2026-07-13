import 'package:equatable/equatable.dart';

/// Consulting project lifecycle steps (Cloud Technical Engineer workflow).
enum ProjectStep {
  receiveRequirements,
  interviewStakeholders,
  clarificationQuestions,
  analyseInfrastructure,
  dependencyMap,
  identifyRisks,
  recommendPlatform,
  designArchitecture,
  estimateCost,
  migrationStrategy,
  rollbackStrategy,
  buildInfrastructure,
  deployWorkloads,
  configureMonitoring,
  securityHardening,
  backupStrategy,
  performTesting,
  customerAcceptance,
  generateDocumentation,
  closeProject,
}

extension ProjectStepX on ProjectStep {
  int get number => index + 1;

  String get title => switch (this) {
        ProjectStep.receiveRequirements => 'Receive customer requirements',
        ProjectStep.interviewStakeholders => 'Interview stakeholders',
        ProjectStep.clarificationQuestions => 'Ask clarification questions',
        ProjectStep.analyseInfrastructure => 'Analyse existing infrastructure',
        ProjectStep.dependencyMap => 'Generate dependency map',
        ProjectStep.identifyRisks => 'Identify risks',
        ProjectStep.recommendPlatform => 'Recommend AWS / Azure / GCP / Hybrid',
        ProjectStep.designArchitecture => 'Design architecture',
        ProjectStep.estimateCost => 'Estimate cost',
        ProjectStep.migrationStrategy => 'Generate migration strategy',
        ProjectStep.rollbackStrategy => 'Generate rollback strategy',
        ProjectStep.buildInfrastructure => 'Build infrastructure',
        ProjectStep.deployWorkloads => 'Deploy workloads',
        ProjectStep.configureMonitoring => 'Configure monitoring',
        ProjectStep.securityHardening => 'Perform security hardening',
        ProjectStep.backupStrategy => 'Create backup strategy',
        ProjectStep.performTesting => 'Perform testing',
        ProjectStep.customerAcceptance => 'Customer acceptance',
        ProjectStep.generateDocumentation => 'Generate documentation',
        ProjectStep.closeProject => 'Close project',
      };

  String get description => switch (this) {
        ProjectStep.receiveRequirements =>
          'Review RFP, business goals, budget, timeline, and success criteria.',
        ProjectStep.interviewStakeholders =>
          'Capture IT, security, finance, and business owner priorities.',
        ProjectStep.clarificationQuestions =>
          'Close gaps: RTO/RPO, compliance, integrations, freeze windows.',
        ProjectStep.analyseInfrastructure =>
          'Inventory servers, apps, data, network, identity, licenses.',
        ProjectStep.dependencyMap =>
          'Map app↔DB↔file↔directory↔external dependencies.',
        ProjectStep.identifyRisks =>
          'Technical, operational, security, and commercial risks.',
        ProjectStep.recommendPlatform =>
          'Select cloud/hybrid target with justification.',
        ProjectStep.designArchitecture =>
          'Landing zone, tiers, HA, security, networking, identity.',
        ProjectStep.estimateCost =>
          'Monthly run-rate vs budget; call out drivers and savings.',
        ProjectStep.migrationStrategy =>
          'Wave plan: pilot → production; tools; cutover approach.',
        ProjectStep.rollbackStrategy =>
          'Abort criteria, data reverse-sync, DNS failback.',
        ProjectStep.buildInfrastructure =>
          'Landing zone, VPC, IAM, logging, baseline accounts.',
        ProjectStep.deployWorkloads =>
          'Compute, data, storage, load balancing, DNS.',
        ProjectStep.configureMonitoring =>
          'Metrics, logs, alarms, dashboards, on-call.',
        ProjectStep.securityHardening =>
          'Least privilege, encryption, MFA, SG/NACL, CIS baselines.',
        ProjectStep.backupStrategy =>
          'Backup vaults, retention, restore tests, DR drills.',
        ProjectStep.performTesting =>
          'Functional, performance, failover, security smoke tests.',
        ProjectStep.customerAcceptance =>
          'UAT sign-off against acceptance criteria.',
        ProjectStep.generateDocumentation =>
          'Architecture, runbooks, ops manuals, KB articles.',
        ProjectStep.closeProject =>
          'Handover, lessons learned, managed service transition.',
      };
}

enum Industry {
  manufacturing,
  banking,
  healthcare,
  education,
  retail,
  logistics,
  government,
  media,
  hospital,
  factory,
}

enum CloudPlatform { aws, azure, gcp, hybrid }

class Stakeholder extends Equatable {
  const Stakeholder({
    required this.name,
    required this.role,
    required this.priorities,
    required this.concerns,
  });

  final String name;
  final String role;
  final List<String> priorities;
  final List<String> concerns;

  @override
  List<Object?> get props => [name, role];
}

class OnPremAsset extends Equatable {
  const OnPremAsset({
    required this.name,
    required this.type,
    required this.notes,
    this.criticality = 'medium',
  });

  final String name;
  final String type;
  final String notes;
  final String criticality;

  @override
  List<Object?> get props => [name, type];
}

class CareerProject extends Equatable {
  const CareerProject({
    required this.id,
    required this.customerName,
    required this.industry,
    required this.summary,
    required this.businessGoals,
    required this.budgetMonthly,
    required this.currency,
    required this.timelineWeeks,
    required this.currentInfrastructure,
    required this.stakeholders,
    required this.constraints,
    required this.successCriteria,
    required this.recommendedPlatform,
    required this.platformRationale,
    required this.targetMonthlyCost,
    required this.keyRisks,
    required this.dependencies,
    required this.clarificationAnswers,
    required this.architectureMustHave,
    this.companyProfile = 'managed services / migration',
  });

  final String id;
  final String customerName;
  final Industry industry;
  final String summary;
  final List<String> businessGoals;
  final int budgetMonthly;
  final String currency;
  final int timelineWeeks;
  final List<OnPremAsset> currentInfrastructure;
  final List<Stakeholder> stakeholders;
  final List<String> constraints;
  final List<String> successCriteria;
  final CloudPlatform recommendedPlatform;
  final String platformRationale;
  final int targetMonthlyCost;
  final List<String> keyRisks;
  final List<String> dependencies;
  final Map<String, String> clarificationAnswers;
  final List<String> architectureMustHave;
  final String companyProfile;

  @override
  List<Object?> get props => [id];
}

class TicketPriority {
  static const critical = 'Critical';
  static const high = 'High';
  static const medium = 'Medium';
  static const low = 'Low';
}

class ServiceTicket extends Equatable {
  const ServiceTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.slaMinutes,
    required this.category,
    this.customer = 'Internal',
    this.status = TicketStatus.open,
    this.customerUpdates = const [],
    this.findings = const [],
    this.rca = '',
    this.postmortem = '',
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final int slaMinutes;
  final String category;
  final String customer;
  final TicketStatus status;
  final List<String> customerUpdates;
  final List<String> findings;
  final String rca;
  final String postmortem;

  ServiceTicket copyWith({
    TicketStatus? status,
    List<String>? customerUpdates,
    List<String>? findings,
    String? rca,
    String? postmortem,
  }) {
    return ServiceTicket(
      id: id,
      title: title,
      description: description,
      priority: priority,
      slaMinutes: slaMinutes,
      category: category,
      customer: customer,
      status: status ?? this.status,
      customerUpdates: customerUpdates ?? this.customerUpdates,
      findings: findings ?? this.findings,
      rca: rca ?? this.rca,
      postmortem: postmortem ?? this.postmortem,
    );
  }

  @override
  List<Object?> get props => [id, status];
}

enum TicketStatus {
  open,
  assigned,
  investigating,
  waitingCustomer,
  resolved,
  closed,
}

class SkillNode extends Equatable {
  const SkillNode({
    required this.id,
    required this.name,
    required this.category,
    this.level = 0,
  });

  final String id;
  final String name;
  final String category;
  final double level; // 0-100

  SkillNode copyWith({double? level}) =>
      SkillNode(id: id, name: name, category: category, level: level ?? this.level);

  @override
  List<Object?> get props => [id, level];
}
