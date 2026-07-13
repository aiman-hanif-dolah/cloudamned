import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class CareerPage extends StatelessWidget {
  const CareerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, p) {
        final r = p.readiness;
        final successPct = (r.overall * 0.7 + r.interview * 0.3).clamp(0, 100);
        final missing = <String>[];
        if (r.linux < 50) missing.add('Linux administration depth');
        if (r.networking < 50) missing.add('VPC / networking troubleshooting');
        if (r.aws < 50) missing.add('AWS hands-on (IAM, VPC, EC2, S3)');
        if (r.terraform < 40) missing.add('Infrastructure as Code (Terraform)');
        if (r.docker < 40) missing.add('Containers & Docker');
        if (r.kubernetes < 30) missing.add('Kubernetes operations');
        if (r.security < 40) missing.add('Security & least privilege');
        if (r.interview < 40) missing.add('Interview practice under rubric scoring');
        if (missing.isEmpty) missing.add('Capstone production exam (Module 20)');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ShadSectionHeader(
                title: 'Career Progress',
                subtitle: 'Mock interview readiness · skill gaps · predicted success',
              ),
              const SizedBox(height: 16),
              ShadCard(
                child: Column(
                  children: [
                    Text('${successPct.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -1)),
                    const Text('Predicted interview success',
                        style: TextStyle(color: ShadcnColors.mutedForeground)),
                    const SizedBox(height: 8),
                    ShadProgress(value: successPct / 100, height: 8),
                    const SizedBox(height: 8),
                    Text(
                      'Based on ${p.completedLabs.length}/${RoadmapContent.allLabs.length} labs, accuracy ${(p.accuracy * 100).toStringAsFixed(0)}%, domain readiness.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ShadCard(
                      header: const Text('Recommended assessments', style: TextStyle(fontWeight: FontWeight.w600)),
                      child: Column(
                        children: [
                          _Link('Mock technical interview', AppRoutes.interview),
                          _Link('Troubleshooting scenarios', AppRoutes.scenario),
                          _Link('Certification practice exam', AppRoutes.exam),
                          _Link('Final practical exam', '/labs/lab-20-02'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadCard(
                      header: const Text('Missing skills', style: TextStyle(fontWeight: FontWeight.w600)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final m in missing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.chevron_right, size: 16, color: ShadcnColors.warning),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ShadCard(
                header: const Text('Career track: Cloud Technical Engineer (IaaS)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                child: const Text(
                  'Target outcomes: design and operate multi-AZ networks, provision compute and storage, '
                  'secure IAM, automate with Terraform, containerize services, monitor and recover from incidents, '
                  'and communicate clearly under interview and ticket pressure.\n\n'
                  'cloudamned trains these skills entirely offline through realistic local simulations.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: ShadcnColors.mutedForeground),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.route);
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward, size: 14),
      onTap: () => context.go(route),
    );
  }
}
