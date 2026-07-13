import '../../domain/entities/career_project.dart';

class PlatformScorecard {
  const PlatformScorecard({
    required this.platform,
    required this.cost,
    required this.performance,
    required this.availability,
    required this.security,
    required this.opsComplexity,
    required this.longTerm,
    required this.rationale,
    required this.tradeoffs,
  });

  final String platform;
  final int cost; // higher = better cost efficiency for this case
  final int performance;
  final int availability;
  final int security;
  final int opsComplexity; // higher = easier ops
  final int longTerm;
  final String rationale;
  final List<String> tradeoffs;

  int get overall =>
      ((cost + performance + availability + security + opsComplexity + longTerm) / 6).round();
}

/// Analyses cloud platform choices with explicit tradeoffs (consultant thinking).
class DecisionEngine {
  List<PlatformScorecard> compare(CareerProject project) {
    final industry = project.industry;
    final hybridBias = project.currentInfrastructure.any(
      (a) => a.name.toLowerCase().contains('active directory') || a.type == 'Identity',
    );

    return [
      PlatformScorecard(
        platform: 'AWS',
        cost: industry == Industry.retail || industry == Industry.media ? 75 : 68,
        performance: 82,
        availability: 88,
        security: 85,
        opsComplexity: 70,
        longTerm: 84,
        rationale:
            'Deep IaaS service catalog, mature multi-AZ patterns, strong Windows/SQL migration tooling.',
        tradeoffs: [
          'Broadest service surface → more ways to overspend',
          'Best-in-class for many migration patterns',
          'Team must learn AWS IAM and networking nuance',
        ],
      ),
      PlatformScorecard(
        platform: 'Azure',
        cost: hybridBias ? 78 : 70,
        performance: 80,
        availability: 86,
        security: 86,
        opsComplexity: hybridBias ? 82 : 72,
        longTerm: hybridBias ? 88 : 80,
        rationale:
            hybridBias
                ? 'Strong Entra ID / hybrid AD story for this estate.'
                : 'Solid enterprise IaaS; shines when Microsoft identity/licenses dominate.',
        tradeoffs: [
          'Excellent hybrid identity',
          'Licensing alignment can reduce TCO',
          'Some services differ in maturity by region',
        ],
      ),
      PlatformScorecard(
        platform: 'GCP',
        cost: 72,
        performance: 84,
        availability: 84,
        security: 83,
        opsComplexity: 74,
        longTerm: 80,
        rationale: 'Strong data/network engineering culture; clean VPC model; good for container-heavy futures.',
        tradeoffs: [
          'Smaller Windows ecosystem than AWS/Azure',
          'Excellent for analytics/K8s-centric paths',
          'Hiring pool may be thinner in some markets',
        ],
      ),
      PlatformScorecard(
        platform: 'Hybrid',
        cost: 60,
        performance: 75,
        availability: 80,
        security: 78,
        opsComplexity: 55,
        longTerm: 82,
        rationale: 'Keep latency/compliance-sensitive systems on-prem; burst and DR in cloud.',
        tradeoffs: [
          'Highest operational complexity',
          'Best when exit from DC is multi-year',
          'Requires strong connectivity and identity design',
        ],
      ),
      PlatformScorecard(
        platform: 'Multi-cloud',
        cost: 50,
        performance: 78,
        availability: 90,
        security: 80,
        opsComplexity: 40,
        longTerm: 75,
        rationale: 'Avoid lock-in / sovereignty options — only if org can staff two platforms.',
        tradeoffs: [
          'Doubles tooling and skills cost',
          'Rarely justified for first migration',
          'Use for specific DR or data gravity reasons',
        ],
      ),
      PlatformScorecard(
        platform: 'On-premise',
        cost: project.budgetMonthly < 15000 ? 70 : 45,
        performance: 70,
        availability: 60,
        security: 65,
        opsComplexity: 50,
        longTerm: 40,
        rationale: 'Only if cloud blocked by regulation or extreme latency — still need modern ops.',
        tradeoffs: [
          'CapEx heavy',
          'DR still hard',
          'Does not remove need for automation/security discipline',
        ],
      ),
    ]..sort((a, b) => b.overall.compareTo(a.overall));
  }

  String explainChoice(String platform, CareerProject project) {
    final cards = compare(project);
    final chosen = cards.firstWhere(
      (c) => c.platform.toLowerCase() == platform.toLowerCase(),
      orElse: () => cards.first,
    );
    final best = cards.first;
    final buf = StringBuffer();
    buf.writeln('Decision analysis for ${project.customerName}');
    buf.writeln('You chose: ${chosen.platform} (score ${chosen.overall})');
    buf.writeln('Top recommendation: ${best.platform} (score ${best.overall})');
    buf.writeln('\nWhy ${chosen.platform}: ${chosen.rationale}');
    buf.writeln('\nTradeoffs:');
    for (final t in chosen.tradeoffs) {
      buf.writeln(' • $t');
    }
    buf.writeln('\nConsultant questions still open:');
    buf.writeln(' • What is the customer\'s real problem?');
    buf.writeln(' • What downtime is acceptable?');
    buf.writeln(' • What regulations apply?');
    buf.writeln(' • Can estate be reused?');
    buf.writeln(' • What RTO/RPO and growth are expected?');
    return buf.toString();
  }
}
