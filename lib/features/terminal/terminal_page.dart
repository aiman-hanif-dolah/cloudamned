import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/linux/linux_shell.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _lines = <_TermLine>[];
  late final LinuxShell shell;
  int _histIdx = -1;

  @override
  void initState() {
    super.initState();
    shell = AppServices.instance.linuxShell;
    _lines.add(_TermLine(
      'cloudamned Linux Simulator — Ubuntu 22.04 (offline)\n'
      'Type `help` for commands. User: cloudeng  Host: cloudamned\n',
      kind: _LineKind.system,
    ));
    _lines.add(_TermLine(shell.prompt, kind: _LineKind.prompt));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(String input) {
    final cmd = input;
    setState(() {
      // replace trailing prompt with prompt+command
      if (_lines.isNotEmpty && _lines.last.kind == _LineKind.prompt) {
        _lines[_lines.length - 1] = _TermLine('${shell.prompt}$cmd', kind: _LineKind.input);
      } else {
        _lines.add(_TermLine('${shell.prompt}$cmd', kind: _LineKind.input));
      }
    });

    final result = shell.exec(cmd);
    if (result.stateChanges['clear'] == true) {
      setState(() {
        _lines.clear();
        _lines.add(_TermLine(shell.prompt, kind: _LineKind.prompt));
      });
      _controller.clear();
      _histIdx = -1;
      return;
    }

    setState(() {
      if (result.stdout.isNotEmpty) {
        _lines.add(_TermLine(result.stdout, kind: _LineKind.stdout));
      }
      if (result.stderr.isNotEmpty) {
        _lines.add(_TermLine(result.stderr, kind: _LineKind.stderr));
      }
      _lines.add(_TermLine(shell.prompt, kind: _LineKind.prompt));
    });
    _controller.clear();
    _histIdx = -1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
    _focus.requestFocus();
  }

  void _history(int delta) {
    if (shell.history.isEmpty) return;
    _histIdx = (_histIdx < 0 ? shell.history.length : _histIdx) + delta;
    if (_histIdx < 0) _histIdx = 0;
    if (_histIdx >= shell.history.length) {
      _histIdx = shell.history.length;
      _controller.clear();
      return;
    }
    _controller.text = shell.history[_histIdx];
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.35);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Linux Terminal',
            subtitle: 'Realistic offline shell · filesystem · systemd · networking tools',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadBadge(
                  label: '${shell.completedActions.length} actions',
                  variant: ShadBadgeVariant.success,
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => setState(() {
                    _lines.clear();
                    _lines.add(_TermLine(shell.prompt, kind: _LineKind.prompt));
                  }),
                  child: const Text('Clear view'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ShadPanel(
              title: 'cloudeng@cloudamned — bash',
              child: Container(
                color: ShadcnColors.terminalBg,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _lines.length,
                        itemBuilder: (context, i) {
                          final line = _lines[i];
                          final color = switch (line.kind) {
                            _LineKind.stderr => ShadcnColors.terminalRed,
                            _LineKind.system => ShadcnColors.terminalCyan,
                            _LineKind.prompt || _LineKind.input => ShadcnColors.terminalGreen,
                            _LineKind.stdout => ShadcnColors.terminalFg,
                          };
                          return SelectableText(
                            line.text.endsWith('\n') ? line.text.substring(0, line.text.length - 1) : line.text,
                            style: mono.copyWith(color: color),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: ShadcnColors.border)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(shell.prompt, style: mono.copyWith(color: ShadcnColors.terminalGreen)),
                          Expanded(
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) {
                                if (e is KeyDownEvent) {
                                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                                    _history(-1);
                                  } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                                    _history(1);
                                  }
                                }
                              },
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                autofocus: true,
                                style: mono.copyWith(color: ShadcnColors.terminalFg),
                                cursorColor: ShadcnColors.terminalGreen,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: _run,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in [
                  'help',
                  'pwd',
                  'ls -la',
                  'sudo apt update',
                  'sudo apt install nginx',
                  'sudo systemctl enable nginx',
                  'sudo systemctl restart nginx',
                  'systemctl status nginx',
                  'curl http://localhost',
                  'ip addr',
                  'df -h',
                ])
                ActionChip(
                  label: Text(c, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  onPressed: () => _run(c),
                  backgroundColor: ShadcnColors.secondary,
                  side: const BorderSide(color: ShadcnColors.border),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _LineKind { system, prompt, input, stdout, stderr }

class _TermLine {
  _TermLine(this.text, {required this.kind});
  final String text;
  final _LineKind kind;
}
