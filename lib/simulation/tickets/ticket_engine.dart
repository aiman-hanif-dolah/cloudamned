import '../../domain/entities/career_project.dart';

/// Enterprise ITSM-style ticket queue for cloudamned.
class TicketEngine {
  final List<ServiceTicket> tickets = List.from(_seed);
  final List<String> metricsLog = [];

  int get openCount =>
      tickets.where((t) => t.status != TicketStatus.closed && t.status != TicketStatus.resolved).length;

  int get resolvedCount =>
      tickets.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).length;

  double get slaCompliance {
    // Simplified: critical tickets resolved count as compliance signal
    final critical = tickets.where((t) => t.priority == TicketPriority.critical);
    if (critical.isEmpty) return 100;
    final done = critical.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).length;
    return (done / critical.length) * 100;
  }

  ServiceTicket? byId(String id) {
    try {
      return tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void assign(String id) => _update(id, (t) => t.copyWith(status: TicketStatus.assigned));

  void investigate(String id, String finding) {
    _update(id, (t) {
      return t.copyWith(
        status: TicketStatus.investigating,
        findings: [...t.findings, finding],
      );
    });
  }

  void updateCustomer(String id, String message) {
    _update(id, (t) {
      return t.copyWith(
        status: TicketStatus.waitingCustomer,
        customerUpdates: [...t.customerUpdates, '${DateTime.now().toIso8601String()}: $message'],
      );
    });
  }

  void resolve(String id, {required String rca, required String postmortem}) {
    _update(id, (t) {
      return t.copyWith(
        status: TicketStatus.resolved,
        rca: rca,
        postmortem: postmortem,
      );
    });
    metricsLog.add('Resolved $id at ${DateTime.now()}');
  }

  void close(String id) => _update(id, (t) => t.copyWith(status: TicketStatus.closed));

  void _update(String id, ServiceTicket Function(ServiceTicket) fn) {
    final i = tickets.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tickets[i] = fn(tickets[i]);
  }

  static const _seed = <ServiceTicket>[
    ServiceTicket(
      id: 'INC000123',
      title: 'Website down',
      description:
          'Customer reports production homepage timeouts. ALB targets unhealthy. 30-minute SLA. Customer communication required.',
      priority: TicketPriority.critical,
      slaMinutes: 30,
      category: 'Availability',
      customer: 'ABC Manufacturing Sdn Bhd',
    ),
    ServiceTicket(
      id: 'INC000124',
      title: 'SSH timeout to bastion',
      description: 'Engineers cannot SSH to bastion host after SG change window.',
      priority: TicketPriority.high,
      slaMinutes: 60,
      category: 'Access',
      customer: 'Merdeka Digital Bank',
    ),
    ServiceTicket(
      id: 'INC000125',
      title: 'Database latency elevated',
      description: 'p95 SQL latency 3× baseline since 09:40. Orders delayed.',
      priority: TicketPriority.critical,
      slaMinutes: 45,
      category: 'Performance',
      customer: 'Pasaraya Mega Retail',
    ),
    ServiceTicket(
      id: 'INC000126',
      title: 'Terraform apply failed',
      description: 'Pipeline plan OK, apply fails on aws_security_group rule conflict.',
      priority: TicketPriority.medium,
      slaMinutes: 120,
      category: 'IaC',
      customer: 'Internal Platform',
    ),
    ServiceTicket(
      id: 'INC000127',
      title: 'SSL certificate expired',
      description: 'Browser NET::ERR_CERT_DATE_INVALID on portal.example.com.',
      priority: TicketPriority.high,
      slaMinutes: 60,
      category: 'Security',
      customer: 'Universiti Teknologi Nusantara',
    ),
    ServiceTicket(
      id: 'INC000128',
      title: 'Disk full on logging host',
      description: '/var at 98%. Fluent Bit crashing. Gaps in SIEM.',
      priority: TicketPriority.high,
      slaMinutes: 90,
      category: 'Capacity',
      customer: 'State Digital Services Agency',
    ),
    ServiceTicket(
      id: 'REQ000201',
      title: 'New VPC for staging',
      description: 'Request multi-AZ staging VPC with restricted peer to prod.',
      priority: TicketPriority.low,
      slaMinutes: 1440,
      category: 'Change',
      customer: 'Internal Platform',
    ),
    ServiceTicket(
      id: 'INC000129',
      title: 'IAM permission denied',
      description: 'Deploy role cannot DescribeImages during ASG refresh.',
      priority: TicketPriority.medium,
      slaMinutes: 180,
      category: 'IAM',
      customer: 'Sunrise General Hospital',
    ),
  ];
}
