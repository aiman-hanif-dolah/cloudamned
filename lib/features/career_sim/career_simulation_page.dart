import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/career_projects.dart';
import '../../domain/entities/career_project.dart';
import '../../simulation/career/career_sim_engine.dart';

/// Heart of cloudamned — consulting project lifecycle simulator.
class CareerSimulationPage extends StatefulWidget {
  const CareerSimulationPage({super.key});

  @override
  State<CareerSimulationPage> createState() => _CareerSimulationPageState();
}

class _CareerSimulationPageState extends State<CareerSimulationPage> {
  late final CareerSimEngine engine;
  final _text = TextEditingController();
  final _cost = TextEditingController(text: '22000');
  final _selectedGoals = <String>{};
  final _selectedAssets = <String>{};
  final _selectedComponents = <String>{};
  final _selectedBuilt = <String>{};
  final _selectedDeployed = <String>{};
  final _selectedControls = <String>{};
  final _selectedTests = <String>{};
  final _selectedDocs = <String>{};
  final _selectedCriteria = <String>{};
  final _risks = <String>[];
  final _questions = <String>[];
  String _platform = 'aws';
  bool _budgetAck = false;
  bool _timelineAck = false;
  bool _signed = false;
  bool _handover = false;
  StepValidation? _last;

  @override
  void initState() {
    super.initState();
    engine = AppServices.instance.careerSim;
  }

  @override
  void dispose() {
    _text.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _start(String id) {
    engine.startProject(id);
    _resetForm();
    setState(() => _last = null);
  }

  void _resetForm() {
    _text.clear();
    _selectedGoals.clear();
    _selectedAssets.clear();
    _selectedComponents.clear();
    _selectedBuilt.clear();
    _selectedDeployed.clear();
    _selectedControls.clear();
    _selectedTests.clear();
    _selectedDocs.clear();
    _selectedCriteria.clear();
    _risks.clear();
    _questions.clear();
    _budgetAck = false;
    _timelineAck = false;
    _signed = false;
    _handover = false;
  }

  void _submit() {
    final step = engine.currentStep;
    final p = engine.active;
    if (step == null || p == null) return;

    final payload = <String, dynamic>{};
    switch (step) {
      case ProjectStep.receiveRequirements:
        payload['goals'] = _selectedGoals.toList();
        payload['budgetAcknowledged'] = _budgetAck;
        payload['timelineAcknowledged'] = _timelineAck;
      case ProjectStep.interviewStakeholders:
        payload['notes'] = _text.text;
      case ProjectStep.clarificationQuestions:
        payload['questions'] = _questions.isEmpty ? _text.text.split('\n').where((e) => e.trim().isNotEmpty).toList() : _questions;
      case ProjectStep.analyseInfrastructure:
        payload['assets'] = _selectedAssets.toList();
      case ProjectStep.dependencyMap:
        payload['map'] = _text.text;
      case ProjectStep.identifyRisks:
        payload['risks'] = _risks.isEmpty ? _text.text.split('\n').where((e) => e.trim().isNotEmpty).toList() : _risks;
      case ProjectStep.recommendPlatform:
        payload['platform'] = _platform;
        payload['rationale'] = _text.text;
      case ProjectStep.designArchitecture:
        payload['components'] = _selectedComponents.toList();
      case ProjectStep.estimateCost:
        payload['estimate'] = int.tryParse(_cost.text) ?? 0;
        payload['notes'] = _text.text;
      case ProjectStep.migrationStrategy:
      case ProjectStep.rollbackStrategy:
      case ProjectStep.configureMonitoring:
      case ProjectStep.backupStrategy:
        payload['plan'] = _text.text;
      case ProjectStep.buildInfrastructure:
        payload['built'] = _selectedBuilt.toList();
      case ProjectStep.deployWorkloads:
        payload['deployed'] = _selectedDeployed.toList();
      case ProjectStep.securityHardening:
        payload['controls'] = _selectedControls.toList();
      case ProjectStep.performTesting:
        payload['tests'] = _selectedTests.toList();
      case ProjectStep.customerAcceptance:
        payload['signed'] = _signed;
        payload['criteriaMet'] = _selectedCriteria.toList();
      case ProjectStep.generateDocumentation:
        payload['docs'] = _selectedDocs.toList();
      case ProjectStep.closeProject:
        payload['handover'] = _handover;
        payload['lessons'] = _text.text;
    }

    final result = engine.submitStep(payload);
    if (result.ok) _resetForm();
    setState(() => _last = result);

    if (result.ok) {
      AppServices.instance.progressCubit.addXp(40);
      AppServices.instance.logActivity('career', '${p.customerName} step ${step.number}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = engine.active;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: project == null ? _catalog() : _workspace(project),
    );
  }

  Widget _catalog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShadSectionHeader(
          title: 'Career Simulation',
          subtitle:
              'You are employed as a Cloud Technical Engineer — receive customer projects, run the full consulting lifecycle, get scored on every decision',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: CareerProjects.all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = CareerProjects.all[i];
              return ShadCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.customerName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        ShadBadge(label: p.industry.name),
                        const SizedBox(width: 8),
                        ShadBadge(
                          label: '${p.currency}${p.budgetMonthly}/mo',
                          variant: ShadBadgeVariant.outline,
                        ),
                        const SizedBox(width: 8),
                        ShadBadge(label: '${p.timelineWeeks}w', variant: ShadBadgeVariant.secondary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.summary,
                        style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.4)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final g in p.businessGoals) ShadBadge(label: g, variant: ShadBadgeVariant.outline)],
                    ),
                    const SizedBox(height: 12),
                    ShadButton(
                      onPressed: () => _start(p.id),
                      icon: Icons.work_outline,
                      child: const Text('Accept engagement'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _workspace(CareerProject p) {
    final step = engine.currentStep!;
    return Row(
      children: [
        // Step rail
        SizedBox(
          width: 240,
          child: ShadPanel(
            title: 'Lifecycle',
            child: ListView.builder(
              itemCount: engine.steps.length,
              itemBuilder: (context, i) {
                final s = engine.steps[i];
                final done = engine.stepResults.containsKey(i);
                final current = i == engine.currentStepIndex;
                return ListTile(
                  dense: true,
                  selected: current,
                  selectedTileColor: ShadcnColors.sidebarAccent,
                  leading: Icon(
                    done ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: done
                        ? ShadcnColors.success
                        : current
                            ? ShadcnColors.primary
                            : ShadcnColors.mutedForeground,
                  ),
                  title: Text(
                    '${s.number}. ${s.title}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Main
        Expanded(
          flex: 3,
          child: ShadPanel(
            title: '${p.customerName} · Step ${step.number}/20',
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  engine.abandon();
                  _last = null;
                }),
                child: const Text('Exit', style: TextStyle(fontSize: 11)),
              ),
            ],
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                LinearProgressIndicator(value: engine.projectProgress, minHeight: 4),
                const SizedBox(height: 12),
                Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(step.description,
                    style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.4)),
                const SizedBox(height: 16),
                ..._stepForm(p, step),
                const SizedBox(height: 16),
                ShadButton(onPressed: _submit, child: const Text('Submit step for validation')),
                if (_last != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ShadcnColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _last!.ok ? ShadcnColors.success : ShadcnColors.warning,
                      ),
                    ),
                    child: Text(
                      '${_last!.ok ? "PASS" : "NEEDS WORK"} · ${_last!.score}/100\n${_last!.feedback}',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Brief
        SizedBox(
          width: 280,
          child: ShadPanel(
            title: 'Engagement brief',
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Budget: ${p.currency}${p.budgetMonthly}/mo', style: const TextStyle(fontSize: 12)),
                Text('Timeline: ${p.timelineWeeks} weeks', style: const TextStyle(fontSize: 12)),
                Text('Profile: ${p.companyProfile}',
                    style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                const Divider(),
                const Text('Goals', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                for (final g in p.businessGoals)
                  Text('• $g', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                const Text('On-prem', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                for (final a in p.currentInfrastructure)
                  Text('• ${a.name} (${a.type})', style: const TextStyle(fontSize: 11)),
                const Divider(),
                Text('Project score: ${engine.overallScore}/100',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('Journal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                for (final j in engine.journal.reversed.take(12))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(j,
                        style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground, height: 1.3)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _stepForm(CareerProject p, ProjectStep step) {
    switch (step) {
      case ProjectStep.receiveRequirements:
        return [
          const Text('Select business goals present in the brief:', style: TextStyle(fontSize: 12)),
          for (final g in p.businessGoals)
            CheckboxListTile(
              dense: true,
              value: _selectedGoals.contains(g),
              title: Text(g, style: const TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedGoals.add(g);
                } else {
                  _selectedGoals.remove(g);
                }
              }),
            ),
          CheckboxListTile(
            dense: true,
            value: _budgetAck,
            title: Text('Acknowledge budget ${p.currency}${p.budgetMonthly}/mo',
                style: const TextStyle(fontSize: 12)),
            onChanged: (v) => setState(() => _budgetAck = v ?? false),
          ),
          CheckboxListTile(
            dense: true,
            value: _timelineAck,
            title: Text('Acknowledge ${p.timelineWeeks}-week timeline', style: const TextStyle(fontSize: 12)),
            onChanged: (v) => setState(() => _timelineAck = v ?? false),
          ),
        ];
      case ProjectStep.interviewStakeholders:
        return [
          Text(
            'Stakeholders: ${p.stakeholders.map((s) => '${s.name} (${s.role})').join('; ')}',
            style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          const Text('Interview notes (mention roles & concerns):', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          TextField(controller: _text, maxLines: 8, decoration: const InputDecoration(hintText: 'Meeting notes…')),
        ];
      case ProjectStep.clarificationQuestions:
        return [
          const Text('List clarification questions (one per line):', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'What is RTO for SQL?\nCompliance scope?\n…'),
          ),
          if (p.clarificationAnswers.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Known Q&A (reference):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            for (final e in p.clarificationAnswers.entries)
              Text('Q: ${e.key}\nA: ${e.value}',
                  style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
          ],
        ];
      case ProjectStep.analyseInfrastructure:
        return [
          const Text('Inventory assets you discovered:', style: TextStyle(fontSize: 12)),
          for (final a in p.currentInfrastructure)
            CheckboxListTile(
              dense: true,
              value: _selectedAssets.contains(a.name),
              title: Text('${a.name} — ${a.notes}', style: const TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedAssets.add(a.name);
                } else {
                  _selectedAssets.remove(a.name);
                }
              }),
            ),
        ];
      case ProjectStep.dependencyMap:
        return [
          Text('Known deps: ${p.dependencies.join(' | ')}',
              style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
          const SizedBox(height: 6),
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'IIS → SQL\nERP → AD\n…'),
          ),
        ];
      case ProjectStep.identifyRisks:
        return [
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Risk per line…'),
          ),
        ];
      case ProjectStep.recommendPlatform:
        return [
          Wrap(
            spacing: 8,
            children: [
              for (final plat in ['aws', 'azure', 'gcp', 'hybrid'])
                ChoiceChip(
                  label: Text(plat.toUpperCase()),
                  selected: _platform == plat,
                  onSelected: (_) => setState(() => _platform = plat),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Rationale (cost, skills, services, constraints)…'),
          ),
        ];
      case ProjectStep.designArchitecture:
        final options = [
          ...p.architectureMustHave,
          'Multi-AZ VPC',
          'Private data subnet',
          'ALB',
          'NAT Gateway',
          'WAF',
          'CloudFront',
          'IAM least privilege',
          'CloudTrail',
          'Backups',
          'Monitoring',
          'KMS encryption',
        ].toSet().toList();
        return [
          const Text('Select architecture components:', style: TextStyle(fontSize: 12)),
          for (final c in options)
            CheckboxListTile(
              dense: true,
              value: _selectedComponents.contains(c),
              title: Text(c, style: const TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedComponents.add(c);
                } else {
                  _selectedComponents.remove(c);
                }
              }),
            ),
        ];
      case ProjectStep.estimateCost:
        return [
          Text('Budget ceiling: ${p.currency}${p.budgetMonthly}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          ShadInput(controller: _cost, hint: 'Monthly estimate'),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Cost drivers & savings levers…'),
          ),
        ];
      case ProjectStep.migrationStrategy:
      case ProjectStep.rollbackStrategy:
      case ProjectStep.configureMonitoring:
      case ProjectStep.backupStrategy:
        return [
          TextField(
            controller: _text,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: step == ProjectStep.migrationStrategy
                  ? 'Pilot/pilot/cutover/tools…'
                  : step == ProjectStep.rollbackStrategy
                      ? 'Abort criteria, DNS failback, RPO…'
                      : step == ProjectStep.configureMonitoring
                          ? 'Metrics, logs, alarms, on-call…'
                          : 'Vault, retention, restore test, RTO/RPO…',
            ),
          ),
        ];
      case ProjectStep.buildInfrastructure:
        return _checklist(
          ['VPC', 'Subnets', 'IAM', 'Logging', 'CloudTrail', 'Account structure', 'Budgets'],
          _selectedBuilt,
        );
      case ProjectStep.deployWorkloads:
        return _checklist(
          ['Compute / EC2', 'Database', 'Load balancer', 'DNS', 'Object storage', 'File service'],
          _selectedDeployed,
        );
      case ProjectStep.securityHardening:
        return _checklist(
          ['MFA', 'Encryption', 'Least privilege IAM', 'Security groups tightened', 'Private subnets', 'Patch baseline'],
          _selectedControls,
        );
      case ProjectStep.performTesting:
        return _checklist(
          ['Functional UAT', 'Failover test', 'Security smoke test', 'Backup restore test', 'Performance smoke'],
          _selectedTests,
        );
      case ProjectStep.customerAcceptance:
        return [
          for (final c in p.successCriteria)
            CheckboxListTile(
              dense: true,
              value: _selectedCriteria.contains(c),
              title: Text(c, style: const TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedCriteria.add(c);
                } else {
                  _selectedCriteria.remove(c);
                }
              }),
            ),
          CheckboxListTile(
            dense: true,
            value: _signed,
            title: const Text('Customer sign-off obtained', style: TextStyle(fontSize: 12)),
            onChanged: (v) => setState(() => _signed = v ?? false),
          ),
        ];
      case ProjectStep.generateDocumentation:
        return _checklist(
          ['Architecture Document', 'Migration Plan', 'Runbook', 'Incident Report', 'Operational Manual', 'KB Article'],
          _selectedDocs,
        );
      case ProjectStep.closeProject:
        return [
          CheckboxListTile(
            dense: true,
            value: _handover,
            title: const Text('Handover to managed services complete', style: TextStyle(fontSize: 12)),
            onChanged: (v) => setState(() => _handover = v ?? false),
          ),
          TextField(
            controller: _text,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Lessons learned…'),
          ),
        ];
    }
  }

  List<Widget> _checklist(List<String> items, Set<String> selected) {
    return [
      for (final c in items)
        CheckboxListTile(
          dense: true,
          value: selected.contains(c),
          title: Text(c, style: const TextStyle(fontSize: 12)),
          onChanged: (v) => setState(() {
            if (v == true) {
              selected.add(c);
            } else {
              selected.remove(c);
            }
          }),
        ),
    ];
  }
}
