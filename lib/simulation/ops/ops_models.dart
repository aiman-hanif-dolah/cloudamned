/// Cloud Operations Center models — original service desk for cloudamned.
/// Does not replace existing TicketEngine; additive only.

enum OpsTicketStatus {
  newTicket,
  assigned,
  investigating,
  waitingCustomer,
  waitingInternal,
  resolved,
  closed,
  kbCreated,
}

extension OpsTicketStatusX on OpsTicketStatus {
  String get label => switch (this) {
        OpsTicketStatus.newTicket => 'New',
        OpsTicketStatus.assigned => 'Assigned',
        OpsTicketStatus.investigating => 'Investigating',
        OpsTicketStatus.waitingCustomer => 'Waiting For Customer',
        OpsTicketStatus.waitingInternal => 'Waiting For Internal Team',
        OpsTicketStatus.resolved => 'Resolved',
        OpsTicketStatus.closed => 'Closed',
        OpsTicketStatus.kbCreated => 'Knowledge Base Created',
      };
}

enum OpsPriority { p1Critical, p2High, p3Medium, p4Low }

extension OpsPriorityX on OpsPriority {
  String get label => switch (this) {
        OpsPriority.p1Critical => 'P1 Critical',
        OpsPriority.p2High => 'P2 High',
        OpsPriority.p3Medium => 'P3 Medium',
        OpsPriority.p4Low => 'P4 Low',
      };

  int get slaMinutes => switch (this) {
        OpsPriority.p1Critical => 30,
        OpsPriority.p2High => 60,
        OpsPriority.p3Medium => 240,
        OpsPriority.p4Low => 1440,
      };
}

enum CloudProviderLabel { aws, azure, gcp, hybrid, onPrem }

class TimelineEvent {
  TimelineEvent({
    required this.at,
    required this.actor,
    required this.message,
    this.kind = 'note',
  });

  final DateTime at;
  final String actor;
  final String message;
  final String kind;
}

class OpsTicket {
  OpsTicket({
    required this.number,
    required this.customerName,
    required this.priority,
    required this.severity,
    required this.affectedService,
    required this.provider,
    required this.description,
    required this.investigationSteps,
    required this.correctRootCause,
    required this.correctResolution,
    required this.runbookId,
    this.status = OpsTicketStatus.newTicket,
    this.assignedEngineer = '',
    DateTime? createdAt,
    this.attachments = const ['screenshot.png', 'alert-export.json'],
    this.internalNotes = const [],
    this.customerReplies = const [],
    this.timeline = const [],
    this.resolutionHistory = const [],
    this.rca = '',
    this.kbLink = '',
    this.evidenceCollected = const {},
    this.escalated = false,
    this.escalationReason = '',
  }) : createdAt = createdAt ?? DateTime.now();

  final String number;
  final String customerName;
  OpsPriority priority;
  String severity;
  OpsTicketStatus status;
  String assignedEngineer;
  final DateTime createdAt;
  final String affectedService;
  final CloudProviderLabel provider;
  final String description;
  final List<String> attachments;
  List<String> internalNotes;
  List<String> customerReplies;
  List<TimelineEvent> timeline;
  List<String> resolutionHistory;
  String rca;
  String kbLink;
  final List<String> investigationSteps;
  final String correctRootCause;
  final String correctResolution;
  final String runbookId;
  Set<String> evidenceCollected;
  bool escalated;
  String escalationReason;

  int get slaMinutes => priority.slaMinutes;

  Duration get age => DateTime.now().difference(createdAt);

  Duration get slaRemaining {
    final used = age;
    final total = Duration(minutes: slaMinutes);
    final left = total - used;
    return left.isNegative ? Duration.zero : left;
  }

  bool get slaBreached => age.inMinutes > slaMinutes;

  OpsTicket copyWith({
    OpsTicketStatus? status,
    String? assignedEngineer,
    List<String>? internalNotes,
    List<String>? customerReplies,
    List<TimelineEvent>? timeline,
    List<String>? resolutionHistory,
    String? rca,
    String? kbLink,
    Set<String>? evidenceCollected,
    bool? escalated,
    String? escalationReason,
  }) {
    return OpsTicket(
      number: number,
      customerName: customerName,
      priority: priority,
      severity: severity,
      affectedService: affectedService,
      provider: provider,
      description: description,
      investigationSteps: investigationSteps,
      correctRootCause: correctRootCause,
      correctResolution: correctResolution,
      runbookId: runbookId,
      status: status ?? this.status,
      assignedEngineer: assignedEngineer ?? this.assignedEngineer,
      createdAt: createdAt,
      attachments: attachments,
      internalNotes: internalNotes ?? this.internalNotes,
      customerReplies: customerReplies ?? this.customerReplies,
      timeline: timeline ?? this.timeline,
      resolutionHistory: resolutionHistory ?? this.resolutionHistory,
      rca: rca ?? this.rca,
      kbLink: kbLink ?? this.kbLink,
      evidenceCollected: evidenceCollected ?? this.evidenceCollected,
      escalated: escalated ?? this.escalated,
      escalationReason: escalationReason ?? this.escalationReason,
    );
  }
}

class Runbook {
  const Runbook({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
    required this.category,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> steps;
  final String category;
}

class KbArticle {
  KbArticle({
    required this.id,
    required this.title,
    required this.problem,
    required this.environment,
    required this.symptoms,
    required this.rootCause,
    required this.resolution,
    required this.verification,
    required this.prevention,
    required this.relatedTickets,
    required this.relatedRunbooks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String problem;
  final String environment;
  final String symptoms;
  final String rootCause;
  final String resolution;
  final String verification;
  final String prevention;
  final List<String> relatedTickets;
  final List<String> relatedRunbooks;
  final DateTime createdAt;
}

class PortfolioItem {
  PortfolioItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime createdAt;
}

class ShiftMetrics {
  int ticketsClosed = 0;
  int escalations = 0;
  int responses = 0;
  int investigations = 0;
  int slaHits = 0;
  int slaMisses = 0;
  final List<int> resolutionMinutes = [];
  final List<int> responseMinutes = [];
  final List<int> commsScores = [];
  final List<int> accuracyScores = [];
  final List<int> docsScores = [];

  double get avgResolution {
    if (resolutionMinutes.isEmpty) return 0;
    return resolutionMinutes.reduce((a, b) => a + b) / resolutionMinutes.length;
  }

  double get avgResponse {
    if (responseMinutes.isEmpty) return 0;
    return responseMinutes.reduce((a, b) => a + b) / responseMinutes.length;
  }

  double get slaCompliance {
    final t = slaHits + slaMisses;
    if (t == 0) return 100;
    return slaHits / t * 100;
  }

  double get escalationRate {
    final t = ticketsClosed + escalations;
    if (t == 0) return 0;
    return escalations / t * 100;
  }

  double get avgComms {
    if (commsScores.isEmpty) return 0;
    return commsScores.reduce((a, b) => a + b) / commsScores.length;
  }

  double get avgAccuracy {
    if (accuracyScores.isEmpty) return 0;
    return accuracyScores.reduce((a, b) => a + b) / accuracyScores.length;
  }

  Map<String, String> snapshot() => {
        'Avg Response (min)': avgResponse.toStringAsFixed(1),
        'Avg Resolution (min)': avgResolution.toStringAsFixed(1),
        'Tickets Closed': '$ticketsClosed',
        'Escalation Rate': '${escalationRate.toStringAsFixed(0)}%',
        'SLA Compliance': '${slaCompliance.toStringAsFixed(0)}%',
        'Comms Score': avgComms.toStringAsFixed(0),
        'Investigation Accuracy': avgAccuracy.toStringAsFixed(0),
        'Docs Quality': docsScores.isEmpty
            ? '—'
            : (docsScores.reduce((a, b) => a + b) / docsScores.length).toStringAsFixed(0),
      };
}
