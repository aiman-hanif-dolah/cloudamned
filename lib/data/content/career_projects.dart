import '../../domain/entities/career_project.dart';

/// Customer projects for cloudamned Career Simulation (consulting-style).
abstract final class CareerProjects {
  static List<CareerProject> get all => _projects;

  static CareerProject? byId(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static final _projects = <CareerProject>[
    CareerProject(
      id: 'proj-abc-mfg',
      customerName: 'ABC Manufacturing Sdn Bhd',
      industry: Industry.manufacturing,
      summary:
          'On-prem Windows estate (AD, IIS, SQL, NAS, VMware) needs cost reduction, security uplift, HA, and DR with a path to scale.',
      businessGoals: const [
        'Reduce cost',
        'Improve security',
        'Disaster Recovery',
        'High Availability',
        'Future scalability',
      ],
      budgetMonthly: 25000,
      currency: 'RM',
      timelineWeeks: 6,
      currentInfrastructure: const [
        OnPremAsset(name: 'Windows Server 2019 (DC/File)', type: 'AD DS + File', notes: '2 DCs, single site', criticality: 'critical'),
        OnPremAsset(name: 'SQL Server 2017', type: 'Database', notes: 'Always On not configured', criticality: 'critical'),
        OnPremAsset(name: 'IIS Web Farm', type: 'App', notes: '2 nodes, sticky sessions', criticality: 'high'),
        OnPremAsset(name: 'Active Directory', type: 'Identity', notes: 'On-prem only, no MFA', criticality: 'critical'),
        OnPremAsset(name: 'NAS Storage', type: 'Storage', notes: 'NFS/SMB shares for drawings', criticality: 'high'),
        OnPremAsset(name: 'VMware Cluster', type: 'Virtualization', notes: '3 hosts, no DR site', criticality: 'high'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Dato\' Lim',
          role: 'CEO',
          priorities: ['Uptime for production line apps', 'Predictable cost'],
          concerns: ['Downtime during cutover', 'Hidden cloud fees'],
        ),
        Stakeholder(
          name: 'Siti Rahman',
          role: 'IT Manager',
          priorities: ['Security', 'Backup', 'Skills transfer'],
          concerns: ['Team Linux readiness', 'AD hybrid identity'],
        ),
        Stakeholder(
          name: 'Ganesh',
          role: 'Finance Controller',
          priorities: ['Stay within RM25k/mo', 'CapEx → OpEx clarity'],
          concerns: ['Egress charges', 'License mobility'],
        ),
      ],
      constraints: const [
        'Must retain Active Directory for ERP SSO',
        'Max planned downtime 4 hours for SQL cutover',
        'Data residency preferred in Singapore region',
        'No permanent VPN-only access for partners',
      ],
      successCriteria: const [
        'Web + SQL available multi-AZ',
        'RPO ≤ 15 min, RTO ≤ 1 hour for tier-1 apps',
        'Monthly forecast ≤ RM25,000',
        'MFA enforced for privileged access',
        'Documented runbooks + knowledge transfer',
      ],
      recommendedPlatform: CloudPlatform.aws,
      platformRationale:
          'AWS has mature Windows/SQL migration patterns (Migration Hub, DMS, FSX/FSx File Gateway alternatives), '
          'strong multi-AZ RDS/SQL options, and clear landing-zone controls within budget for a mid-size estate.',
      targetMonthlyCost: 22500,
      keyRisks: const [
        'SQL cutover data loss if replication lag',
        'AD hybrid misconfiguration locks admins out',
        'NAS file latency after lift',
        'Scope creep beyond 6 weeks',
      ],
      dependencies: const [
        'IIS → SQL Server (OLEDB)',
        'ERP client → AD Kerberos',
        'File shares → Engineering CAD workstations',
        'Backup jobs → NAS snapshots',
      ],
      clarificationAnswers: const {
        'What is RTO for SQL?': '1 hour for production DB.',
        'Is internet-facing web required?': 'Yes, customer portal on IIS.',
        'Compliance?': 'ISO 27001 aspirations; no PCI.',
        'Freeze windows?': 'Sundays 02:00–06:00 MYT only.',
      },
      architectureMustHave: const [
        'Multi-AZ VPC',
        'Private data subnet',
        'ALB',
        'IAM least privilege',
        'CloudTrail',
        'Backups',
        'Monitoring',
      ],
      companyProfile: 'Cloud migration + managed services engagement',
    ),
    CareerProject(
      id: 'proj-bank-secure',
      customerName: 'Merdeka Digital Bank',
      industry: Industry.banking,
      summary: 'Core banking peripheral apps need hardened landing zone, audit logging, and DR in a second region.',
      businessGoals: const ['Regulatory logging', 'DR', 'Zero-trust network', 'Cost control'],
      budgetMonthly: 80000,
      currency: 'RM',
      timelineWeeks: 12,
      currentInfrastructure: const [
        OnPremAsset(name: 'Core middleware', type: 'App', notes: 'Java on RHEL', criticality: 'critical'),
        OnPremAsset(name: 'Oracle DB', type: 'Database', notes: 'RAC two-node', criticality: 'critical'),
        OnPremAsset(name: 'HSM', type: 'Security', notes: 'Payment crypto', criticality: 'critical'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Aisha Noor',
          role: 'CISO',
          priorities: ['Audit trail', 'Encryption', 'MFA'],
          concerns: ['Shared tenancy', 'Insider risk'],
        ),
      ],
      constraints: const ['Data residency MY/SG', 'Change board weekly'],
      successCriteria: const ['CloudTrail org trail', 'Immutable logs', 'DR drill passed'],
      recommendedPlatform: CloudPlatform.aws,
      platformRationale: 'Mature banking reference architectures and Control Tower/landing zone patterns.',
      targetMonthlyCost: 72000,
      keyRisks: const ['Regulatory delay', 'Oracle licensing'],
      dependencies: const ['Middleware → Oracle', 'SIEM → logs'],
      clarificationAnswers: const {'DR region?': 'ap-southeast-1 primary, ap-southeast-3 DR.'},
      architectureMustHave: const ['Organizations', 'CloudTrail', 'Private subnets', 'KMS', 'GuardDuty'],
    ),
    CareerProject(
      id: 'proj-hospital',
      customerName: 'Sunrise General Hospital',
      industry: Industry.hospital,
      summary: 'PACS and HIS partial cloud migration with strict availability and PHI protection.',
      businessGoals: const ['HA for HIS', 'Secure imaging storage', 'Remote clinic access'],
      budgetMonthly: 45000,
      currency: 'RM',
      timelineWeeks: 10,
      currentInfrastructure: const [
        OnPremAsset(name: 'HIS', type: 'App', notes: 'Windows + SQL', criticality: 'critical'),
        OnPremAsset(name: 'PACS', type: 'Storage/App', notes: 'Large object storage', criticality: 'critical'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Dr. Wong',
          role: 'Medical Director',
          priorities: ['Uptime', 'Clinician UX'],
          concerns: ['Any downtime risks patients'],
        ),
      ],
      constraints: const ['PHI encryption required', 'Near-zero downtime preferred'],
      successCriteria: const ['Encrypted at rest/transit', 'Multi-AZ', 'Backup restore tested'],
      recommendedPlatform: CloudPlatform.hybrid,
      platformRationale: 'Keep latency-sensitive imaging edge on-prem; burst/DR and portal on cloud.',
      targetMonthlyCost: 40000,
      keyRisks: const ['Bandwidth for imaging', 'Clinical change management'],
      dependencies: const ['HIS → SQL', 'PACS → NAS'],
      clarificationAnswers: const {'Peak imaging hours?': '08:00–14:00 weekdays.'},
      architectureMustHave: const ['Private Link patterns', 'Encryption', 'VPN/Direct Connect', 'Monitoring'],
    ),
    CareerProject(
      id: 'proj-retail',
      customerName: 'Pasaraya Mega Retail',
      industry: Industry.retail,
      summary: 'E-commerce + store inventory APIs; bill doubled last quarter — optimize and harden.',
      businessGoals: const ['Cut 30% cloud spend', 'Black Friday scale', 'Security audit pass'],
      budgetMonthly: 35000,
      currency: 'RM',
      timelineWeeks: 5,
      currentInfrastructure: const [
        OnPremAsset(name: 'Legacy POS sync', type: 'Integration', notes: 'Nightly batch', criticality: 'medium'),
        OnPremAsset(name: 'Cloud e-com (messy)', type: 'AWS', notes: 'Idle ASG, public S3', criticality: 'high'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Mei Ling',
          role: 'Head of Digital',
          priorities: ['Conversion', 'Cost'],
          concerns: ['Perf regressions'],
        ),
      ],
      constraints: const ['No full rewrite this quarter'],
      successCriteria: const ['−30% bill', 'No public buckets', 'Autoscaling validated'],
      recommendedPlatform: CloudPlatform.aws,
      platformRationale: 'Already on AWS; optimize in place then landing-zone cleanup.',
      targetMonthlyCost: 24000,
      keyRisks: const ['Cutting capacity breaks flash sales'],
      dependencies: const ['E-com → inventory API → SQL'],
      clarificationAnswers: const {'Peak RPS?': '8k at flash sale.'},
      architectureMustHave: const ['CDN', 'ASG', 'WAF', 'Private data', 'Budgets alarms'],
    ),
    CareerProject(
      id: 'proj-uni',
      customerName: 'Universiti Teknologi Nusantara',
      industry: Industry.education,
      summary: 'Student portal and LMS migration from aging VMware; semester start is hard deadline.',
      businessGoals: const ['Scale for registration week', 'Lower ops toil', 'SSO with campus AD'],
      budgetMonthly: 18000,
      currency: 'RM',
      timelineWeeks: 8,
      currentInfrastructure: const [
        OnPremAsset(name: 'Moodle LMS', type: 'App', notes: 'LAMP stack', criticality: 'high'),
        OnPremAsset(name: 'Student portal', type: 'App', notes: '.NET IIS', criticality: 'high'),
        OnPremAsset(name: 'Campus AD', type: 'Identity', notes: 'Must remain source of truth', criticality: 'critical'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Prof. Halim',
          role: 'CIO',
          priorities: ['Semester readiness', 'Budget'],
          concerns: ['Student outcry if down'],
        ),
      ],
      constraints: const ['Registration freeze: last 2 weeks of month 2'],
      successCriteria: const ['Load test 5x peak', 'SSO works', 'Ops runbook'],
      recommendedPlatform: CloudPlatform.azure,
      platformRationale: 'Strong AD/Entra hybrid identity for campus and education licensing alignment.',
      targetMonthlyCost: 16000,
      keyRisks: const ['Identity federation breakage'],
      dependencies: const ['Portal → AD', 'LMS → MySQL'],
      clarificationAnswers: const {'Primary cloud preference?': 'Open; Microsoft campus agreement exists.'},
      architectureMustHave: const ['Hybrid identity', 'WAF', 'Backups', 'Multi-AZ'],
    ),
    CareerProject(
      id: 'proj-gov',
      customerName: 'State Digital Services Agency',
      industry: Industry.government,
      summary: 'Citizen services modernization with audit, sovereignty, and managed landing zone.',
      businessGoals: const ['Citizen uptime', 'Auditability', 'Standard landing zone'],
      budgetMonthly: 60000,
      currency: 'RM',
      timelineWeeks: 14,
      currentInfrastructure: const [
        OnPremAsset(name: 'Citizen portal', type: 'App', notes: 'Monolith', criticality: 'critical'),
      ],
      stakeholders: const [
        Stakeholder(
          name: 'Encik Razak',
          role: 'Director',
          priorities: ['Compliance', 'Transparency'],
          concerns: ['Vendor lock-in'],
        ),
      ],
      constraints: const ['Prefer multi-cloud readiness', 'Mandatory logging'],
      successCriteria: const ['Landing zone live', 'Config rules', 'DR plan'],
      recommendedPlatform: CloudPlatform.hybrid,
      platformRationale: 'Landing zone on AWS with documented Azure DR pattern for sovereignty options.',
      targetMonthlyCost: 55000,
      keyRisks: const ['Procurement delays'],
      dependencies: const ['Portal → National ID API'],
      clarificationAnswers: const {'Log retention?': '7 years.'},
      architectureMustHave: const ['Organizations', 'Config', 'CloudTrail', 'Private apps', 'Budgets'],
    ),
  ];
}
