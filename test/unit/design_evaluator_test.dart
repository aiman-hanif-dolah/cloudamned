import 'package:cloudamned/simulation/interview/design_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strong HA design scores higher than empty answer', () {
    final prompt = DesignInterviewBank.prompts.firstWhere((p) => p.id == 'ha-web-1m');
    final weak = DesignInterviewBank.evaluate(prompt, 'Use some servers.');
    final strong = DesignInterviewBank.evaluate(
      prompt,
      'Multi-AZ VPC with public and private subnets. ALB fronts an Auto Scaling group of '
      'stateless web instances. RDS Multi-AZ for the database, ElastiCache for sessions, '
      'CloudFront CDN and S3 for static assets. WAF, security groups, private subnets for data, '
      'IAM least privilege, KMS encryption, Secrets Manager. Cost via right-sizing and reserved '
      'instances. Health checks, multi-AZ failover, backups for RTO/RPO.',
    );
    expect(strong.overall, greaterThan(weak.overall));
    expect(strong.scalability, greaterThan(50));
    expect(strong.security, greaterThan(50));
  });
}
