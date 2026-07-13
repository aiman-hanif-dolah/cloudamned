/// Local offline evaluator for system-design interview answers in cloudamned.
class DesignPrompt {
  const DesignPrompt({
    required this.id,
    required this.title,
    required this.prompt,
    required this.followUps,
    required this.keywords,
    required this.rubric,
  });

  final String id;
  final String title;
  final String prompt;
  final List<String> followUps;
  /// Keywords/phrases that score under each dimension.
  final Map<String, List<String>> keywords;
  final String rubric;
}

class DesignScore {
  const DesignScore({
    required this.scalability,
    required this.security,
    required this.cost,
    required this.faultTolerance,
    required this.overall,
    required this.feedback,
    required this.missing,
  });

  final int scalability;
  final int security;
  final int cost;
  final int faultTolerance;
  final int overall;
  final List<String> feedback;
  final List<String> missing;
}

abstract final class DesignInterviewBank {
  static const prompts = <DesignPrompt>[
    DesignPrompt(
      id: 'migrate-legacy',
      title: 'Legacy migration to AWS',
      prompt:
          'How would you migrate a legacy monolithic application (on-prem VMs, shared SQL database, '
          'file shares) to AWS with minimal downtime?',
      followUps: [
        'How do you handle the database cutover?',
        'What is your rollback plan?',
        'How do you migrate file storage?',
      ],
      keywords: {
        'scalability': [
          'asg',
          'auto scaling',
          'load balancer',
          'alb',
          'horizontal',
          'stateless',
          'multi-az',
        ],
        'security': [
          'iam',
          'security group',
          'private subnet',
          'encryption',
          'secrets',
          'least privilege',
          'vpn',
          'direct connect',
        ],
        'cost': [
          'reserved',
          'savings plan',
          'right-size',
          's3',
          'lifecycle',
          'spot',
          'cost',
        ],
        'faultTolerance': [
          'multi-az',
          'backup',
          'snapshot',
          'rds',
          'failover',
          'rollback',
          'blue/green',
          'pilot light',
          'dms',
        ],
      },
      rubric:
          'Strong answers mention phased migration (rehost/replatform), hybrid connectivity, '
          'database replication (DMS), multi-AZ, security boundaries, and rollback.',
    ),
    DesignPrompt(
      id: 'ha-web-1m',
      title: 'HA web app for 1M users',
      prompt:
          'Design a highly available web application on AWS for one million monthly users. '
          'Cover network, compute, data, caching, CDN, security, and operations.',
      followUps: [
        'Where do you put the database?',
        'How do you absorb traffic spikes?',
        'How do you observe the system in production?',
      ],
      keywords: {
        'scalability': [
          'cloudfront',
          'cdn',
          'alb',
          'auto scaling',
          'asg',
          'cache',
          'elasticache',
          'read replica',
          'sqs',
          'queue',
          'horizontal',
        ],
        'security': [
          'waf',
          'security group',
          'private subnet',
          'iam',
          'tls',
          'https',
          'secrets manager',
          'kms',
          'least privilege',
        ],
        'cost': [
          's3',
          'cloudfront',
          'right-size',
          'reserved',
          'spot',
          'serverless',
          'lifecycle',
          'cost explorer',
        ],
        'faultTolerance': [
          'multi-az',
          'multi-region',
          'rds multi-az',
          'health check',
          'failover',
          'backup',
          'rto',
          'rpo',
          'circuit breaker',
        ],
      },
      rubric:
          'Expect multi-AZ VPC, ALB + ASG or containers, RDS multi-AZ, CDN, caching, WAF, '
          'observability, and cost-aware choices.',
    ),
    DesignPrompt(
      id: 'secure-vpc',
      title: 'Secure multi-tier VPC',
      prompt:
          'Design a secure three-tier VPC architecture (web, app, data) including subnets, '
          'routing, bastion/SSM access, and east-west traffic controls.',
      followUps: [
        'How do private instances get OS updates?',
        'How do you audit API activity?',
      ],
      keywords: {
        'scalability': ['multi-az', 'alb', 'asg', 'nat gateway', 'subnet'],
        'security': [
          'private subnet',
          'public subnet',
          'nacl',
          'security group',
          'bastion',
          'ssm',
          'session manager',
          'least privilege',
          'flow logs',
        ],
        'cost': ['single nat', 'vpc endpoints', 'cost', 'right-size'],
        'faultTolerance': ['multi-az', 'nat per az', 'route table', 'failover'],
      },
      rubric:
          'Public subnets only for ALB/bastion; app/data private; NAT or endpoints; SG least privilege; multi-AZ.',
    ),
    DesignPrompt(
      id: 'troubleshoot-latency',
      title: 'Database latency spike',
      prompt:
          'Production reports elevated database latency. Walk me through your investigation '
          'and short-term mitigation as the on-call Cloud Technical Engineer.',
      followUps: [
        'What metrics do you look at first?',
        'When do you scale vertically vs add replicas?',
      ],
      keywords: {
        'scalability': ['read replica', 'connection pool', 'cache', 'scale'],
        'security': ['iam', 'audit', 'cloudtrail'],
        'cost': ['right-size', 'reserved', 'storage type'],
        'faultTolerance': [
          'cloudwatch',
          'slow query',
          'failover',
          'multi-az',
          'backup',
          'alarm',
          'runbook',
        ],
      },
      rubric:
          'Metrics → logs → slow queries → connections → storage/CPU → mitigate (cache, replicas) → postmortem.',
    ),
  ];

  static DesignScore evaluate(DesignPrompt prompt, String answer) {
    final text = answer.toLowerCase();
    int scoreDim(String dim) {
      final keys = prompt.keywords[dim] ?? [];
      if (keys.isEmpty) return 50;
      var hits = 0;
      for (final k in keys) {
        if (text.contains(k.toLowerCase())) hits++;
      }
      final ratio = hits / keys.length;
      // Base for writing something substantive
      final base = answer.trim().length < 80
          ? 15
          : answer.trim().length < 200
              ? 35
              : 50;
      return (base + ratio * 50).round().clamp(0, 100);
    }

    final scalability = scoreDim('scalability');
    final security = scoreDim('security');
    final cost = scoreDim('cost');
    final fault = scoreDim('faultTolerance');
    final overall = ((scalability + security + cost + fault) / 4).round();

    final missing = <String>[];
    final feedback = <String>[];

    void check(String dim, int score, String tip) {
      if (score < 60) {
        missing.add(dim);
        feedback.add('Strengthen $dim: $tip');
      } else {
        feedback.add('$dim looks solid ($score/100).');
      }
    }

    check('scalability', scalability, 'mention load balancing, auto scaling, caching, multi-AZ.');
    check('security', security, 'mention IAM least privilege, private subnets, encryption, SGs.');
    check('cost', cost, 'mention right-sizing, reserved/savings, S3 tiers, avoiding idle NAT sprawl.');
    check('fault tolerance', fault, 'mention multi-AZ, backups, health checks, failover, RTO/RPO.');

    if (answer.trim().length < 120) {
      feedback.add('Answer is thin — interviewers expect structured depth (context → design → trade-offs → ops).');
    } else {
      feedback.add('Good length for a verbal design answer.');
    }
    feedback.add('Rubric focus: ${prompt.rubric}');

    return DesignScore(
      scalability: scalability,
      security: security,
      cost: cost,
      faultTolerance: fault,
      overall: overall,
      feedback: feedback,
      missing: missing,
    );
  }
}
