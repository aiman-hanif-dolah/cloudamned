import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/security/security_audit_engine.dart';

class SecurityAuditPage extends StatefulWidget {
  const SecurityAuditPage({super.key});

  @override
  State<SecurityAuditPage> createState() => _SecurityAuditPageState();
}

class _SecurityAuditPageState extends State<SecurityAuditPage> {
  @override
  Widget build(BuildContext context) {
    final engine = AppServices.instance.securityAudit;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Security Audit Mode',
            subtitle: 'IAM · MFA · SG · encryption · secrets · logging · compliance',
            trailing: ShadBadge(label: '${engine.score}% findings', variant: ShadBadgeVariant.destructive),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Audit checklist',
                    child: ListView(
                      children: [
                        for (final i in SecurityAuditEngine.items)
                          CheckboxListTile(
                            dense: true,
                            value: engine.flagged.contains(i.id),
                            title: Text('[${i.severity}] ${i.area}', style: const TextStyle(fontSize: 12)),
                            subtitle: Text(i.finding, style: const TextStyle(fontSize: 11)),
                            onChanged: (_) => setState(() => engine.toggle(i.id)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'Audit report',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        engine.report(),
                        style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
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
