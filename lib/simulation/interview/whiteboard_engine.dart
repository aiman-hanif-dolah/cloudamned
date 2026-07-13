import 'design_evaluator.dart';

class WhiteboardPrompt {
  const WhiteboardPrompt({
    required this.id,
    required this.title,
    required this.brief,
    required this.mustMention,
  });

  final String id;
  final String title;
  final String brief;
  final List<String> mustMention;
}

class WhiteboardEngine {
  static const prompts = <WhiteboardPrompt>[
    WhiteboardPrompt(
      id: 'netflix',
      title: 'Design Netflix',
      brief: 'Global streaming, recommendations, CDN, multi-region, DRM-ish constraints.',
      mustMention: ['cdn', 'multi-region', 'cache', 'encode', 'object storage', 'auto scale', 'failover'],
    ),
    WhiteboardPrompt(
      id: 'grab',
      title: 'Design Grab',
      brief: 'Ride + delivery marketplace, real-time matching, payments, maps.',
      mustMention: ['queue', 'matching', 'geo', 'payment', 'multi-az', 'fraud', 'api gateway'],
    ),
    WhiteboardPrompt(
      id: 'astro',
      title: 'Design Astro GO',
      brief: 'Regional OTT video with live and VOD, peak events.',
      mustMention: ['cdn', 'live', 'origin', 'drm', 'scale', 'cache', 'monitoring'],
    ),
    WhiteboardPrompt(
      id: 'maybank',
      title: 'Design Maybank digital banking edge',
      brief: 'Mobile banking APIs, strong security, audit, high availability.',
      mustMention: ['waf', 'private', 'encryption', 'mfa', 'audit', 'multi-az', 'dr'],
    ),
    WhiteboardPrompt(
      id: 'lms',
      title: 'Design a university LMS',
      brief: 'Registration spikes, SSO with campus AD, content storage.',
      mustMention: ['sso', 'auto scale', 'cdn', 'database', 'backup', 'waf', 'queue'],
    ),
    WhiteboardPrompt(
      id: 'shopee',
      title: 'Design Shopee',
      brief: 'E-commerce marketplace, flash sales, search, payments.',
      mustMention: ['cache', 'queue', 'search', 'payment', 'cdn', 'auto scale', 'multi-az'],
    ),
    WhiteboardPrompt(
      id: 'emr',
      title: 'Design a hospital EMR',
      brief: 'PHI protection, availability for clinicians, integrations.',
      mustMention: ['encryption', 'private', 'audit', 'backup', 'ha', 'identity', 'dr'],
    ),
    WhiteboardPrompt(
      id: 'logistics',
      title: 'Design a logistics platform',
      brief: 'Tracking, routing, partner APIs, warehouse events.',
      mustMention: ['event', 'queue', 'api', 'geo', 'multi-az', 'observability', 'retry'],
    ),
  ];

  static DesignScore grade(WhiteboardPrompt p, String answer, Set<String> drawnComponents) {
    final text = '${answer.toLowerCase()} ${drawnComponents.join(' ').toLowerCase()}';
    final hits = p.mustMention.where((m) => text.contains(m)).length;
    final coverage = hits / p.mustMention.length;

    // Map into design dimensions
    final synthetic = DesignPrompt(
      id: p.id,
      title: p.title,
      prompt: p.brief,
      followUps: const [],
      keywords: {
        'scalability': ['scale', 'cdn', 'cache', 'queue', 'auto', 'shard', 'replica'],
        'security': ['waf', 'encrypt', 'mfa', 'private', 'iam', 'tls', 'audit'],
        'cost': ['cache', 'lifecycle', 'right', 'spot', 'serverless', 'cdn'],
        'faultTolerance': ['multi-az', 'multi-region', 'failover', 'backup', 'dr', 'retry', 'health'],
      },
      rubric: 'Must cover ${p.mustMention.join(', ')}',
    );
    final base = DesignInterviewBank.evaluate(synthetic, answer);
    final boost = (coverage * 20).round();
    return DesignScore(
      scalability: (base.scalability + boost).clamp(0, 100),
      security: (base.security + boost).clamp(0, 100),
      cost: base.cost,
      faultTolerance: (base.faultTolerance + boost).clamp(0, 100),
      overall: (base.overall + boost).clamp(0, 100),
      feedback: [
        ...base.feedback,
        'Whiteboard must-mention coverage: $hits/${p.mustMention.length}.',
        if (hits < p.mustMention.length)
          'Missing: ${p.mustMention.where((m) => !text.contains(m)).join(', ')}',
      ],
      missing: base.missing,
    );
  }
}
