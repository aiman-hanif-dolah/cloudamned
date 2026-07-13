import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class KubernetesPage extends StatefulWidget {
  const KubernetesPage({super.key});

  @override
  State<KubernetesPage> createState() => _KubernetesPageState();
}

class _KubernetesPageState extends State<KubernetesPage> {
  final _ctrl = TextEditingController();
  final _log = <String>['Connected to cloudamned-lab cluster (simulated).'];
  final engine = AppServices.instance.k8sEngine;

  void _run(String cmd) {
    final r = engine.exec(cmd);
    setState(() {
      _log.add('\$ $cmd');
      _log.add(r.output.trimRight());
    });
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.35);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Kubernetes Lab',
            subtitle: 'kubectl against a simulated API server',
            trailing: ShadBadge(label: '${engine.completedActions.length} actions'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in [
                'kubectl cluster-info',
                'kubectl get ns',
                'kubectl create deployment web --image=nginx',
                'kubectl get deploy',
                'kubectl get pods',
                'kubectl scale deployment web --replicas=3',
                'kubectl expose deployment web --port=80 --type=ClusterIP',
                'kubectl get svc',
                'kubectl rollout status deployment/web',
              ])
                ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _run(c),
                  backgroundColor: ShadcnColors.secondary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ShadPanel(
              title: 'kubectl',
              child: Container(
                color: ShadcnColors.terminalBg,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final l in _log)
                            SelectableText(l, style: mono.copyWith(color: ShadcnColors.terminalFg)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: _ctrl,
                      style: mono.copyWith(color: ShadcnColors.terminalFg),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: mono.copyWith(color: ShadcnColors.k8s),
                        border: InputBorder.none,
                        hintText: 'kubectl …',
                      ),
                      onSubmitted: _run,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
