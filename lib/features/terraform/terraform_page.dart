import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/terraform/terraform_engine.dart';

class TerraformPage extends StatefulWidget {
  const TerraformPage({super.key});

  @override
  State<TerraformPage> createState() => _TerraformPageState();
}

class _TerraformPageState extends State<TerraformPage> {
  final engine = AppServices.instance.terraformEngine;
  late String _activeFile;
  late final Map<String, TextEditingController> _controllers;
  final _output = <String>[];

  @override
  void initState() {
    super.initState();
    _activeFile = 'main.tf';
    _controllers = {
      for (final e in engine.files.entries) e.key: TextEditingController(text: e.value),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncFiles() {
    for (final e in _controllers.entries) {
      engine.files[e.key] = e.value.text;
    }
  }

  void _run(String action) {
    _syncFiles();
    final r = switch (action) {
      'init' => engine.init(),
      'validate' => engine.validate(),
      'plan' => engine.plan(),
      'apply' => engine.apply(),
      'destroy' => engine.destroy(),
      'show' => engine.show(),
      _ => engine.validate(),
    };
    setState(() {
      _output.add('\$ terraform $action');
      _output.add(r.output.trimRight());
      if (!r.ok && r.errors.isNotEmpty) {
        _output.add('Errors: ${r.errors.join('; ')}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12.5, height: 1.4);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Terraform Lab',
            subtitle: 'Write complete .tf files · parse · syntax errors · visual infrastructure',
            trailing: ShadBadge(
              label: engine.initialized ? 'initialized' : 'not init',
              variant: engine.initialized ? ShadBadgeVariant.success : ShadBadgeVariant.warning,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final a in ['init', 'validate', 'plan', 'apply', 'show', 'destroy'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ShadButton(
                    size: ShadButtonSize.sm,
                    variant: a == 'apply'
                        ? ShadButtonVariant.primary
                        : a == 'destroy'
                            ? ShadButtonVariant.destructive
                            : ShadButtonVariant.secondary,
                    onPressed: () => _run(a),
                    child: Text(a),
                  ),
                ),
              const Spacer(),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  engine.files['main.tf'] = TerraformEngine.sampleMain;
                  engine.files['variables.tf'] = TerraformEngine.sampleVariables;
                  engine.files['outputs.tf'] = TerraformEngine.sampleOutputs;
                  for (final e in engine.files.entries) {
                    _controllers[e.key]?.text = e.value;
                  }
                  setState(() {});
                },
                child: const Text('Reload samples'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // File tree
                SizedBox(
                  width: 140,
                  child: ShadPanel(
                    title: 'Files',
                    child: ListView(
                      children: [
                        for (final f in engine.files.keys)
                          ListTile(
                            dense: true,
                            selected: _activeFile == f,
                            selectedTileColor: ShadcnColors.sidebarAccent,
                            title: Text(f, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                            onTap: () => setState(() => _activeFile = f),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Editor
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: _activeFile,
                    child: TextField(
                      controller: _controllers[_activeFile],
                      maxLines: null,
                      expands: true,
                      style: mono.copyWith(color: ShadcnColors.foreground),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (v) => engine.files[_activeFile] = v,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Output + visual
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ShadPanel(
                          title: 'CLI output',
                          child: Container(
                            color: ShadcnColors.terminalBg,
                            child: ListView(
                              padding: const EdgeInsets.all(10),
                              children: [
                                for (final l in _output)
                                  SelectableText(
                                    l,
                                    style: mono.copyWith(
                                      color: l.contains('Error') || l.startsWith('│')
                                          ? ShadcnColors.terminalRed
                                          : ShadcnColors.terminalFg,
                                      fontSize: 11.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 2,
                        child: ShadPanel(
                          title: 'Visual infrastructure',
                          child: engine.visualNodes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Run terraform apply to render resources',
                                    style: TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(10),
                                  children: [
                                    for (final n in engine.visualNodes)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: n.parentId != null ? 18.0 : 0,
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              switch (n.type) {
                                                'vpc' => Icons.cloud,
                                                'subnet' => Icons.lan,
                                                'ec2' => Icons.memory,
                                                's3' => Icons.folder_outlined,
                                                'igw' => Icons.public,
                                                'sg' => Icons.security,
                                                _ => Icons.hexagon_outlined,
                                              },
                                              size: 16,
                                              color: ShadcnColors.terraform,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                n.label,
                                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (engine.state.isNotEmpty) ...[
                                      const Divider(),
                                      Text(
                                        'State: ${engine.state.length} resources',
                                        style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
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
