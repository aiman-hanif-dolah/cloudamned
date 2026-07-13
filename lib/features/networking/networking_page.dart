import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/networking/network_engine.dart';

class NetworkingPage extends StatefulWidget {
  const NetworkingPage({super.key});

  @override
  State<NetworkingPage> createState() => _NetworkingPageState();
}

class _NetworkingPageState extends State<NetworkingPage> {
  final engine = AppServices.instance.networkEngine;
  String? _selected;
  String _traceResult = 'Select an instance and run packet trace.';
  final _cidrCtrl = TextEditingController(text: '10.0.3.0/24');

  @override
  void initState() {
    super.initState();
    if (engine.nodes.length < 3) engine.seedBrokenSshScenario();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Networking Lab',
            subtitle: 'Topology builder · CIDR · packet path · security rules',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => setState(() => engine.seedBrokenSshScenario()),
                  child: const Text('Load broken SSH scenario'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.secondary,
                  onPressed: () => setState(() => engine.seedDefault()),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: 'Topology canvas',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapUp: (d) {
                            // add subnet on empty click with shift? skip — use buttons
                          },
                          child: CustomPaint(
                            painter: _TopoPainter(engine, _selected),
                            child: Stack(
                              children: [
                                for (final n in engine.nodes)
                                  Positioned(
                                    left: n.x,
                                    top: n.y,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selected = n.id),
                                      onPanUpdate: (d) {
                                        setState(() {
                                          n.x = (n.x + d.delta.dx).clamp(0, constraints.maxWidth - 120);
                                          n.y = (n.y + d.delta.dy).clamp(0, constraints.maxHeight - 48);
                                        });
                                      },
                                      child: _NodeChip(node: n, selected: _selected == n.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 300,
                  child: ShadPanel(
                    title: 'Inspector',
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        const Text('Add components', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in ['subnet', 'instance', 'nat', 'lb', 'firewall'])
                              ShadButton(
                                size: ShadButtonSize.sm,
                                variant: ShadButtonVariant.outline,
                                onPressed: () => setState(() {
                                  engine.addNode(t, t.toUpperCase(), 150, 150 + engine.nodes.length * 10);
                                }),
                                child: Text('+$t'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('CIDR helper', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(height: 8),
                        ShadInput(controller: _cidrCtrl, hint: '10.0.0.0/24'),
                        const SizedBox(height: 8),
                        Text(
                          NetworkEngine.validCidr(_cidrCtrl.text)
                              ? 'Valid · ~${NetworkEngine.hostCount(_cidrCtrl.text)} usable hosts'
                              : 'Invalid CIDR',
                          style: TextStyle(
                            fontSize: 12,
                            color: NetworkEngine.validCidr(_cidrCtrl.text)
                                ? ShadcnColors.success
                                : ShadcnColors.destructive,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selected != null) ...[
                          Text('Selected: $_selected', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ShadButton(
                            size: ShadButtonSize.sm,
                            onPressed: () => setState(() {
                              engine.setInstanceRule(_selected!, 'allow:22:0.0.0.0/0');
                              _traceResult = 'Rule added: allow TCP/22';
                            }),
                            child: const Text('Allow SSH (22)'),
                          ),
                          const SizedBox(height: 6),
                          ShadButton(
                            size: ShadButtonSize.sm,
                            variant: ShadButtonVariant.secondary,
                            onPressed: () => setState(() {
                              engine.setInstanceRule(_selected!, 'allow:80:0.0.0.0/0');
                            }),
                            child: const Text('Allow HTTP (80)'),
                          ),
                          const SizedBox(height: 6),
                          ShadButton(
                            size: ShadButtonSize.sm,
                            variant: ShadButtonVariant.destructive,
                            onPressed: () => setState(() {
                              engine.setInstanceRule(_selected!, 'deny:22:0.0.0.0/0');
                            }),
                            child: const Text('Block SSH'),
                          ),
                          const SizedBox(height: 12),
                          ShadButton(
                            onPressed: () {
                              final r = engine.trace(targetId: _selected!, port: 22);
                              setState(() {
                                _traceResult =
                                    '${r.ok ? 'SUCCESS' : 'FAIL'}: ${r.reason}\nPath: ${r.path.join(' → ')}';
                              });
                            },
                            child: const Text('Trace packet → :22'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(_traceResult,
                            style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.4)),
                      ],
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

class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.node, required this.selected});
  final NetNode node;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = switch (node.type) {
      'igw' || 'internet' => ShadcnColors.info,
      'subnet' => ShadcnColors.primary,
      'instance' => ShadcnColors.success,
      'firewall' => ShadcnColors.destructive,
      'lb' => ShadcnColors.warning,
      _ => ShadcnColors.mutedForeground,
    };
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? ShadcnColors.primary : color.withValues(alpha: 0.6), width: selected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(node.type.toUpperCase(),
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
          Text(node.label, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TopoPainter extends CustomPainter {
  _TopoPainter(this.engine, this.selected);
  final NetworkEngine engine;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ShadcnColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final l in engine.links) {
      final a = engine.nodes.where((n) => n.id == l.from).firstOrNull;
      final b = engine.nodes.where((n) => n.id == l.to).firstOrNull;
      if (a == null || b == null) continue;
      canvas.drawLine(
        Offset(a.x + 65, a.y + 24),
        Offset(b.x + 65, b.y + 24),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TopoPainter oldDelegate) => true;
}
