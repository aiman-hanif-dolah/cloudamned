import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class DockerPage extends StatefulWidget {
  const DockerPage({super.key});

  @override
  State<DockerPage> createState() => _DockerPageState();
}

class _DockerPageState extends State<DockerPage> {
  final _ctrl = TextEditingController();
  final _log = <String>[];
  final engine = AppServices.instance.dockerEngine;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Docker Lab',
            subtitle: 'Offline docker CLI · images · containers · compose',
            trailing: ShadBadge(label: '${engine.completedActions.length} actions', variant: ShadBadgeVariant.success),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in [
                'docker version',
                'docker images',
                'docker ps -a',
                'docker run -d --name web -p 8080:80 nginx:alpine',
                'docker build -t myapp:latest .',
                'docker compose up',
                'docker logs web',
                'docker network ls',
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
              title: 'docker@cloudamned',
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
                        prefixStyle: mono.copyWith(color: ShadcnColors.docker),
                        border: InputBorder.none,
                        hintText: 'docker …',
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
