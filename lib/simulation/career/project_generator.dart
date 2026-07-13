import 'dart:math';

import '../../domain/entities/career_project.dart';

/// Generates unlimited unique consulting engagements for cloudamned.
class ProjectGenerator {
  ProjectGenerator([int? seed]) : _rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);

  final Random _rng;
  int _seq = 0;

  static const _industries = Industry.values;

  static const _prefixes = [
    'Apex', 'Nexus', 'Meridian', 'Horizon', 'Summit', 'Atlas', 'Vertex', 'Pinnacle',
    'Cascade', 'Pacific', 'Aurora', 'Stellar', 'Quantum', 'Legacy', 'Prime', 'Unity',
  ];
  static const _suffixes = [
    'Holdings', 'Group', 'Sdn Bhd', 'Berhad', 'Labs', 'Systems', 'Digital',
    'Services', 'Logistics', 'Health', 'Bank', 'Retail', 'Media', 'Energy',
  ];

  static const _legacyStacks = [
    ['Windows Server 2016', 'SQL Server', 'IIS', 'Active Directory', 'VMware'],
    ['RHEL 7', 'Oracle DB', 'Tomcat', 'LDAP', 'NetApp'],
    ['Ubuntu 18.04', 'PostgreSQL', 'Nginx', 'FreeIPA', 'Proxmox'],
    ['Windows Server 2019', 'MySQL', 'Apache', 'AD DS', 'Hyper-V'],
    ['AIX', 'DB2', 'WebSphere', 'Mainframe batch', 'Tape backup'],
    ['CentOS 7', 'MongoDB', 'Node.js', 'Jenkins on VM', 'NFS NAS'],
  ];

  static const _goalsPool = [
    'Reduce cost',
    'Improve security',
    'Disaster Recovery',
    'High Availability',
    'Future scalability',
    'Faster releases',
    'Compliance audit pass',
    'Exit datacenter lease',
    'Enable remote workforce',
    'Improve customer latency',
    'Modernize legacy apps',
    'Centralize identity',
  ];

  static const _compliancePool = [
    'ISO 27001',
    'PDPA Malaysia',
    'PCI-DSS subset',
    'Bank Negara guidelines',
    'HIPAA-like PHI controls',
    'Government data residency',
    'SOC 2 aspirations',
    'None formal (SME)',
  ];

  static const _problemsPool = [
    'Backup untested for 18 months',
    'Single AZ mental model on-prem',
    'Shared admin passwords',
    'No MFA',
    'Nightly batch windows too short',
    'Storage growth 40%/year',
    'SSL certificates managed manually',
    'No CMDB / unknown dependencies',
    'Bill shock after partial cloud lift',
    'Change freezes every month-end',
  ];

  CareerProject generate() {
    _seq++;
    final industry = _industries[_rng.nextInt(_industries.length)];
    final name =
        '${_prefixes[_rng.nextInt(_prefixes.length)]} ${_suffixes[_rng.nextInt(_suffixes.length)]}';
    final stack = _legacyStacks[_rng.nextInt(_legacyStacks.length)];
    final goals = _pick(_goalsPool, 3 + _rng.nextInt(3));
    final problems = _pick(_problemsPool, 2 + _rng.nextInt(3));
    final compliance = _compliancePool[_rng.nextInt(_compliancePool.length)];
    final budget = 8000 + _rng.nextInt(120) * 1000;
    final weeks = 4 + _rng.nextInt(12);
    final rtoHours = [1, 2, 4, 8, 24][_rng.nextInt(5)];
    final growth = 10 + _rng.nextInt(80);

    final platform = switch (industry) {
      Industry.education || Industry.government =>
        _rng.nextBool() ? CloudPlatform.azure : CloudPlatform.hybrid,
      Industry.banking || Industry.healthcare || Industry.hospital =>
        _rng.nextBool() ? CloudPlatform.aws : CloudPlatform.hybrid,
      _ => CloudPlatform.values[_rng.nextInt(CloudPlatform.values.length)],
    };

    final assets = [
      for (var i = 0; i < stack.length; i++)
        OnPremAsset(
          name: stack[i],
          type: i == 0
              ? 'OS/Platform'
              : i == 1
                  ? 'Database'
                  : i == 2
                      ? 'App tier'
                      : 'Infra',
          notes: problems[i % problems.length],
          criticality: i < 2 ? 'critical' : 'high',
        ),
    ];

    final stakeholders = [
      Stakeholder(
        name: _name(),
        role: 'CEO / Business Owner',
        priorities: ['Uptime', 'Predictable cost'],
        concerns: ['Downtime', 'Hidden fees'],
      ),
      Stakeholder(
        name: _name(),
        role: 'IT Manager',
        priorities: ['Security', 'Skills transfer'],
        concerns: ['Team readiness', 'Identity'],
      ),
      Stakeholder(
        name: _name(),
        role: 'Finance',
        priorities: ['Budget ${budget ~/ 1000}k/mo'],
        concerns: ['Egress', 'License mobility'],
      ),
    ];

    return CareerProject(
      id: 'gen-${DateTime.now().millisecondsSinceEpoch}-$_seq',
      customerName: name,
      industry: industry,
      summary:
          '${industry.name} organisation with ${stack.take(3).join(', ')}. '
          'Problems: ${problems.take(2).join('; ')}. Growth forecast +$growth% demand in 18 months.',
      businessGoals: goals,
      budgetMonthly: budget,
      currency: 'RM',
      timelineWeeks: weeks,
      currentInfrastructure: assets,
      stakeholders: stakeholders,
      constraints: [
        'Compliance: $compliance',
        'RTO target ≤ $rtoHours hours for tier-1',
        'Risk tolerance: ${['low', 'medium', 'high'][_rng.nextInt(3)]}',
        'Technical debt: ${problems.first}',
      ],
      successCriteria: [
        'Meet budget RM$budget/mo (±15%)',
        'Documented DR with restore test',
        'MFA for privileged access',
        'Multi-AZ for production tier-1',
        'Handover runbooks complete',
      ],
      recommendedPlatform: platform,
      platformRationale:
          'Generated fit for $industry with $compliance and RTO ${rtoHours}h; '
          'prefer ${platform.name} given identity/data patterns in the estate.',
      targetMonthlyCost: (budget * (0.75 + _rng.nextDouble() * 0.2)).round(),
      keyRisks: problems.take(4).toList(),
      dependencies: [
        '${stack[2]} → ${stack[1]}',
        'Clients → ${stack.length > 3 ? stack[3] : 'Identity'}',
        'Backups → storage appliance',
      ],
      clarificationAnswers: {
        'What is RTO for tier-1?': '$rtoHours hours.',
        'Data residency?': ['Malaysia preferred', 'Singapore OK', 'APAC any'][_rng.nextInt(3)],
        'Freeze windows?': ['Sunday 02:00–06:00', 'Month-end freeze', 'None'][_rng.nextInt(3)],
        'Growth?': '+$growth% traffic in 18 months.',
      },
      architectureMustHave: const [
        'Multi-AZ VPC',
        'Private data subnet',
        'IAM least privilege',
        'Backups',
        'Monitoring',
        'CloudTrail / audit logging',
      ],
      companyProfile: 'cloudamned consulting engagement · generated',
    );
  }

  List<String> _pick(List<String> pool, int n) {
    final copy = List<String>.from(pool)..shuffle(_rng);
    return copy.take(n.clamp(1, pool.length)).toList();
  }

  String _name() {
    const first = ['Aisha', 'Wei', 'Raj', 'Siti', 'Daniel', 'Mei', 'Arif', 'Nora', 'Farid', 'Priya'];
    const last = ['Tan', 'Lim', 'Rahman', 'Wong', 'Kumar', 'Abdullah', 'Chen', 'Ismail', 'Goh', 'Devi'];
    return '${first[_rng.nextInt(first.length)]} ${last[_rng.nextInt(last.length)]}';
  }
}
