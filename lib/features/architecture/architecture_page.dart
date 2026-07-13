import 'package:flutter/material.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class ArchitecturePage extends StatefulWidget {
  const ArchitecturePage({super.key});

  @override
  State<ArchitecturePage> createState() => _ArchitecturePageState();
}

class _ArchitecturePageState extends State<ArchitecturePage> {
  final _palette = ['VPC', 'Public Subnet', 'Private Subnet', 'ALB', 'EC2', 'ASG', 'RDS', 'S3', 'CloudFront', 'Route53', 'NAT', 'Lambda'];
  final _placed = <_ArchNode>[];
  String? _scoreText;

  void _add(String type) {
    setState(() {
      _placed.add(_ArchNode(type, 40.0 + _placed.length * 24, 40.0 + (_placed.length % 5) * 50));
      _scoreText = null;
    });
  }

  void _evaluate() {
    final types = _placed.map((e) => e.type).toSet();
    var score = 40;
    final notes = <String>[];
    if (types.contains('VPC')) {
      score += 5;
    } else {
      notes.add('Missing VPC boundary');
    }
    if (types.contains('Public Subnet') && types.contains('Private Subnet')) {
      score += 10;
    } else {
      notes.add('Prefer public+private subnet split');
    }
    if (types.contains('ALB')) {
      score += 10;
    } else {
      notes.add('No load balancer for HA ingress');
    }
    if (types.contains('ASG') || types.contains('EC2')) {
      score += 10;
    } else {
      notes.add('No compute tier');
    }
    if (types.contains('RDS')) {
      score += 10;
    } else {
      notes.add('No managed data tier');
    }
    if (types.contains('S3')) {
      score += 5;
    }
    if (types.contains('NAT')) {
      score += 5;
    } else {
      notes.add('Private egress via NAT recommended');
    }
    if (types.contains('CloudFront') || types.contains('Route53')) score += 5;

    final scalability = types.contains('ASG') ? 85 : 55;
    final availability = types.contains('ALB') && types.contains('Private Subnet') ? 80 : 50;
    final security = types.contains('Private Subnet') && types.contains('NAT') ? 78 : 45;
    final cost = types.contains('Lambda') ? 75 : 60;
    final performance = types.contains('CloudFront') ? 82 : 65;
    final overall = ((scalability + availability + security + cost + performance) / 5).round();

    setState(() {
      _scoreText =
          'Overall: $overall/100\n'
          'Scalability: $scalability  Availability: $availability\n'
          'Security: $security  Cost: $cost  Performance: $performance\n'
          'Heuristic score: $score\n'
          '${notes.isEmpty ? 'Solid baseline design.' : notes.map((n) => '• $n').join('\n')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Architecture Builder',
            subtitle: 'Drag-and-drop style placement · automated well-architected style scoring',
            trailing: ShadButton(onPressed: _evaluate, child: const Text('Evaluate design')),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: ShadPanel(
                    title: 'Palette',
                    child: ListView(
                      children: [
                        for (final p in _palette)
                          ListTile(
                            dense: true,
                            title: Text(p, style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.add, size: 14),
                            onTap: () => _add(p),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: 'Canvas',
                    child: Stack(
                      children: [
                        Container(color: ShadcnColors.background),
                        for (final n in _placed)
                          Positioned(
                            left: n.x,
                            top: n.y,
                            child: GestureDetector(
                              onPanUpdate: (d) => setState(() {
                                n.x += d.delta.dx;
                                n.y += d.delta.dy;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ShadcnColors.card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: ShadcnColors.primary.withValues(alpha: 0.5)),
                                ),
                                child: Text(n.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  child: ShadPanel(
                    title: 'Evaluation',
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _scoreText ?? 'Place components, then evaluate.\n\nRubric: scalability, availability, security, cost, performance.',
                        style: const TextStyle(fontSize: 12, height: 1.45, color: ShadcnColors.mutedForeground),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchNode {
  _ArchNode(this.type, this.x, this.y);
  final String type;
  double x;
  double y;
}
