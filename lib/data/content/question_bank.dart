import '../../domain/entities/question.dart';

/// Offline knowledge engine — certification & interview style questions.
abstract final class QuestionBank {
  static List<Question> get all => _questions;

  static List<Question> byDomain(String domain) =>
      _questions.where((q) => q.domain == domain).toList();

  static List<Question> byCertification(String cert) =>
      _questions.where((q) => q.certification == cert).toList();

  static List<Question> sample({int count = 20, String? domain, String? cert}) {
    var pool = _questions;
    if (domain != null) pool = pool.where((q) => q.domain == domain).toList();
    if (cert != null) pool = pool.where((q) => q.certification == cert).toList();
    final shuffled = List<Question>.from(pool)..shuffle();
    return shuffled.take(count).toList();
  }

  static final List<ExamDefinition> exams = [
    const ExamDefinition(
      id: 'exam-ccp',
      title: 'AWS Certified Cloud Practitioner Practice',
      certification: 'AWS CCP',
      durationMinutes: 90,
      passingScore: 70,
      questionCount: 40,
      domains: ['cloud', 'aws', 'security', 'billing'],
      description: 'Foundational AWS knowledge practice exam.',
    ),
    const ExamDefinition(
      id: 'exam-saa',
      title: 'AWS Solutions Architect Associate Practice',
      certification: 'AWS SAA',
      durationMinutes: 130,
      passingScore: 72,
      questionCount: 50,
      domains: ['aws', 'networking', 'security', 'architecture'],
      description: 'Architecture-focused associate practice exam.',
    ),
    const ExamDefinition(
      id: 'exam-az900',
      title: 'Azure AZ-900 Practice',
      certification: 'AZ-900',
      durationMinutes: 60,
      passingScore: 70,
      questionCount: 35,
      domains: ['azure', 'cloud'],
      description: 'Azure fundamentals practice exam.',
    ),
    const ExamDefinition(
      id: 'exam-ace',
      title: 'GCP Associate Cloud Engineer Practice',
      certification: 'GCP ACE',
      durationMinutes: 120,
      passingScore: 70,
      questionCount: 40,
      domains: ['gcp', 'cloud'],
      description: 'GCP ACE practice exam.',
    ),
  ];

  static final List<Question> _questions = [
    // Cloud fundamentals
    const Question(
      id: 'q-001',
      type: QuestionType.multipleChoice,
      domain: 'cloud',
      difficulty: 'beginner',
      prompt: 'Which NIST characteristic describes paying only for resources consumed?',
      choices: ['Broad network access', 'Measured service', 'Resource pooling', 'Rapid elasticity'],
      correctAnswers: ['Measured service'],
      explanation: 'Measured service means usage is monitored, controlled, and reported.',
      tags: ['nist'],
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-002',
      type: QuestionType.multipleChoice,
      domain: 'cloud',
      difficulty: 'beginner',
      prompt: 'EC2 is an example of which service model?',
      choices: ['SaaS', 'PaaS', 'IaaS', 'FaaS only'],
      correctAnswers: ['IaaS'],
      explanation: 'EC2 provides virtual machines — classic IaaS.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-003',
      type: QuestionType.trueFalse,
      domain: 'cloud',
      difficulty: 'beginner',
      prompt: 'In the shared responsibility model, the customer is always responsible for physical datacenter security.',
      choices: ['True', 'False'],
      correctAnswers: ['False'],
      explanation: 'The provider is responsible for physical security of the cloud.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-004',
      type: QuestionType.multipleChoice,
      domain: 'cloud',
      difficulty: 'beginner',
      prompt: 'What is an Availability Zone?',
      choices: [
        'A global edge cache',
        'One or more discrete data centers with redundant power and networking',
        'A billing account',
        'A single physical server',
      ],
      correctAnswers: ['One or more discrete data centers with redundant power and networking'],
      explanation: 'AZs are isolated locations within a region for high availability.',
      certification: 'AWS CCP',
    ),
    // Linux
    const Question(
      id: 'q-010',
      type: QuestionType.multipleChoice,
      domain: 'linux',
      difficulty: 'beginner',
      prompt: 'Which command shows the current working directory?',
      choices: ['ls', 'pwd', 'cd', 'whoami'],
      correctAnswers: ['pwd'],
      explanation: 'pwd prints the working directory.',
    ),
    const Question(
      id: 'q-011',
      type: QuestionType.multipleChoice,
      domain: 'linux',
      difficulty: 'intermediate',
      prompt: 'What does chmod 755 file do?',
      choices: [
        'Owner rwx, group and others rx',
        'Everyone rwx',
        'Owner rw only',
        'Removes all permissions',
      ],
      correctAnswers: ['Owner rwx, group and others rx'],
      explanation: '7=rwx, 5=r-x for group and others.',
    ),
    const Question(
      id: 'q-012',
      type: QuestionType.fillBlank,
      domain: 'linux',
      difficulty: 'intermediate',
      prompt: 'Complete: systemctl _____ nginx  (to start the service)',
      correctAnswers: ['start'],
      explanation: 'systemctl start nginx starts the unit.',
    ),
    const Question(
      id: 'q-013',
      type: QuestionType.multipleChoice,
      domain: 'linux',
      difficulty: 'intermediate',
      prompt: 'Which tool inspects systemd unit logs?',
      choices: ['syslogd', 'journalctl', 'dmesg only', 'top'],
      correctAnswers: ['journalctl'],
      explanation: 'journalctl queries the systemd journal.',
    ),
    // Networking
    const Question(
      id: 'q-020',
      type: QuestionType.multipleChoice,
      domain: 'networking',
      difficulty: 'intermediate',
      prompt: 'How many usable host addresses are in a /24 IPv4 subnet?',
      choices: ['254', '256', '255', '128'],
      correctAnswers: ['254'],
      explanation: '256 addresses minus network and broadcast = 254 usable.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-021',
      type: QuestionType.multipleChoice,
      domain: 'networking',
      difficulty: 'intermediate',
      prompt: 'Security groups are:',
      choices: [
        'Stateless and deny by default with explicit allows only at NACL layer only',
        'Stateful allow-lists applied at the ENI level',
        'Only used for on-premises firewalls',
        'The same as route tables',
      ],
      correctAnswers: ['Stateful allow-lists applied at the ENI level'],
      explanation: 'SGs are stateful and filter traffic at the instance/ENI.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-022',
      type: QuestionType.trueFalse,
      domain: 'networking',
      difficulty: 'beginner',
      prompt: 'A private subnet can reach the internet without NAT or similar egress path.',
      choices: ['True', 'False'],
      correctAnswers: ['False'],
      explanation: 'Private subnets need NAT Gateway/Instance (or equivalent) for outbound internet.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-023',
      type: QuestionType.multipleChoice,
      domain: 'networking',
      difficulty: 'advanced',
      prompt: 'Which device rewrites private source IPs for outbound internet traffic?',
      choices: ['Internet Gateway only', 'NAT Gateway', 'Security Group', 'Route 53'],
      correctAnswers: ['NAT Gateway'],
      explanation: 'NAT Gateway provides source NAT for private subnet egress.',
      certification: 'AWS SAA',
    ),
    // AWS
    const Question(
      id: 'q-030',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'beginner',
      prompt: 'Which service stores objects (files) durably?',
      choices: ['EBS', 'EFS', 'S3', 'RDS'],
      correctAnswers: ['S3'],
      explanation: 'S3 is object storage.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-031',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'intermediate',
      prompt: 'Best practice for granting AWS access to applications on EC2?',
      choices: [
        'Embed access keys in code',
        'Use IAM instance profiles / roles',
        'Share root credentials',
        'Open security group 0.0.0.0/0 on all ports',
      ],
      correctAnswers: ['Use IAM instance profiles / roles'],
      explanation: 'Roles provide temporary credentials without hardcoding keys.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-032',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'intermediate',
      prompt: 'Which service provides managed relational databases?',
      choices: ['S3', 'DynamoDB', 'RDS', 'CloudFront'],
      correctAnswers: ['RDS'],
      explanation: 'RDS manages engines like MySQL, PostgreSQL, etc.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-033',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'advanced',
      prompt: 'To distribute HTTP traffic across multiple AZs, you typically use:',
      choices: ['NAT Gateway', 'Application Load Balancer', 'EBS Multi-Attach only', 'CloudTrail'],
      correctAnswers: ['Application Load Balancer'],
      explanation: 'ALB is a Layer-7 load balancer spanning subnets/AZs.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-034',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'intermediate',
      prompt: 'CloudWatch is primarily used for:',
      choices: ['Source control', 'Metrics, logs, and alarms', 'DNS only', 'Object versioning'],
      correctAnswers: ['Metrics, logs, and alarms'],
      explanation: 'CloudWatch is the monitoring and observability service.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-035',
      type: QuestionType.scenario,
      domain: 'aws',
      difficulty: 'advanced',
      prompt:
          'An EC2 instance in a private subnet cannot reach the internet for package updates, but instances in the public subnet can. What is the most likely missing component?',
      choices: [
        'Route 53 private hosted zone',
        'NAT Gateway (or NAT instance) and correct route table entry',
        'S3 bucket policy',
        'CloudFront distribution',
      ],
      correctAnswers: ['NAT Gateway (or NAT instance) and correct route table entry'],
      explanation: 'Private subnets need NAT + 0.0.0.0/0 route to NAT for outbound access.',
      certification: 'AWS SAA',
    ),
    // Azure
    const Question(
      id: 'q-040',
      type: QuestionType.multipleChoice,
      domain: 'azure',
      difficulty: 'beginner',
      prompt: 'What is the primary logical container for Azure resources?',
      choices: ['Availability Set', 'Resource Group', 'Management Group only', 'NSG'],
      correctAnswers: ['Resource Group'],
      explanation: 'Resource Groups organize and manage related resources.',
      certification: 'AZ-900',
    ),
    const Question(
      id: 'q-041',
      type: QuestionType.multipleChoice,
      domain: 'azure',
      difficulty: 'beginner',
      prompt: 'Azure Virtual Network is analogous to which AWS concept?',
      choices: ['S3', 'VPC', 'IAM User', 'CloudTrail'],
      correctAnswers: ['VPC'],
      explanation: 'VNets provide isolated private networks like VPCs.',
      certification: 'AZ-900',
    ),
    // GCP
    const Question(
      id: 'q-050',
      type: QuestionType.multipleChoice,
      domain: 'gcp',
      difficulty: 'beginner',
      prompt: 'Which GCP service runs containers without managing clusters?',
      choices: ['Compute Engine only', 'Cloud Run', 'Cloud Storage', 'BigQuery'],
      correctAnswers: ['Cloud Run'],
      explanation: 'Cloud Run is a managed container platform.',
      certification: 'GCP ACE',
    ),
    const Question(
      id: 'q-051',
      type: QuestionType.multipleChoice,
      domain: 'gcp',
      difficulty: 'intermediate',
      prompt: 'GKE is Google\'s managed service for:',
      choices: ['Object storage', 'Kubernetes', 'DNS only', 'SMTP'],
      correctAnswers: ['Kubernetes'],
      explanation: 'Google Kubernetes Engine manages K8s clusters.',
      certification: 'GCP ACE',
    ),
    // Docker / K8s
    const Question(
      id: 'q-060',
      type: QuestionType.multipleChoice,
      domain: 'docker',
      difficulty: 'beginner',
      prompt: 'Which file defines how to build a Docker image?',
      choices: ['docker-compose.yml only', 'Dockerfile', 'Jenkinsfile', 'Podfile'],
      correctAnswers: ['Dockerfile'],
      explanation: 'Dockerfile contains image build instructions.',
    ),
    const Question(
      id: 'q-061',
      type: QuestionType.multipleChoice,
      domain: 'kubernetes',
      difficulty: 'intermediate',
      prompt: 'A Deployment manages:',
      choices: ['Only Services', 'ReplicaSets and Pods for declarative updates', 'Only Ingress', 'Nodes only'],
      correctAnswers: ['ReplicaSets and Pods for declarative updates'],
      explanation: 'Deployments own ReplicaSets which own Pods.',
    ),
    const Question(
      id: 'q-062',
      type: QuestionType.multipleChoice,
      domain: 'kubernetes',
      difficulty: 'intermediate',
      prompt: 'Which Service type exposes pods on each node\'s IP at a static port?',
      choices: ['ClusterIP', 'NodePort', 'ExternalName only', 'Headless only'],
      correctAnswers: ['NodePort'],
      explanation: 'NodePort opens a port on every node.',
    ),
    // Terraform
    const Question(
      id: 'q-070',
      type: QuestionType.multipleChoice,
      domain: 'terraform',
      difficulty: 'beginner',
      prompt: 'Which command shows the execution plan without applying?',
      choices: ['terraform init', 'terraform plan', 'terraform apply -auto-approve', 'terraform output'],
      correctAnswers: ['terraform plan'],
      explanation: 'plan previews changes.',
    ),
    const Question(
      id: 'q-071',
      type: QuestionType.multipleChoice,
      domain: 'terraform',
      difficulty: 'intermediate',
      prompt: 'Terraform state primarily tracks:',
      choices: [
        'Git commit history',
        'Mapping between config and real infrastructure',
        'Container image layers',
        'DNS cache',
      ],
      correctAnswers: ['Mapping between config and real infrastructure'],
      explanation: 'State binds resources in config to remote IDs/attributes.',
    ),
    // Security
    const Question(
      id: 'q-080',
      type: QuestionType.multipleChoice,
      domain: 'security',
      difficulty: 'intermediate',
      prompt: 'Least privilege means:',
      choices: [
        'Grant admin to all operators',
        'Grant only permissions required to perform a task',
        'Disable MFA',
        'Use one shared account',
      ],
      correctAnswers: ['Grant only permissions required to perform a task'],
      explanation: 'Least privilege minimizes blast radius of compromise.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-081',
      type: QuestionType.trueFalse,
      domain: 'security',
      difficulty: 'beginner',
      prompt: 'Encrypting data in transit typically uses TLS/HTTPS.',
      choices: ['True', 'False'],
      correctAnswers: ['True'],
      explanation: 'TLS protects data on the wire.',
    ),
    // Troubleshooting / scenarios
    const Question(
      id: 'q-090',
      type: QuestionType.scenario,
      domain: 'troubleshooting',
      difficulty: 'advanced',
      prompt:
          'SSH to an EC2 public IP times out. Security group allows 22 from your IP. What else should you check first?',
      choices: [
        'S3 bucket policy',
        'Network ACL, route to IGW, and instance status checks',
        'RDS parameter group',
        'Lambda concurrency',
      ],
      correctAnswers: ['Network ACL, route to IGW, and instance status checks'],
      explanation: 'SSH path requires routing, NACL, SG, and healthy instance.',
    ),
    const Question(
      id: 'q-091',
      type: QuestionType.logAnalysis,
      domain: 'troubleshooting',
      difficulty: 'advanced',
      prompt:
          'Log line: "nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)". Root cause?',
      choices: [
        'Disk full',
        'Another process is listening on port 80',
        'DNS failure',
        'Expired certificate only',
      ],
      correctAnswers: ['Another process is listening on port 80'],
      explanation: 'bind failure 98 means the port is occupied.',
    ),
    // Interview behavioral
    const Question(
      id: 'q-100',
      type: QuestionType.scenario,
      domain: 'interview',
      difficulty: 'intermediate',
      prompt:
          'Describe (select best structure) how you would answer a behavioral question about a production outage.',
      choices: [
        'Only list technologies used',
        'STAR: Situation, Task, Action, Result with metrics',
        'Blame another team',
        'Skip the result',
      ],
      correctAnswers: ['STAR: Situation, Task, Action, Result with metrics'],
      explanation: 'STAR with measurable impact is the expected interview structure.',
    ),
    // More AWS SAA style
    const Question(
      id: 'q-110',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'advanced',
      prompt: 'For static website hosting with global low latency, which combo is common?',
      choices: [
        'EBS + IGW',
        'S3 + CloudFront',
        'RDS + NAT',
        'SQS + VPC Endpoint only',
      ],
      correctAnswers: ['S3 + CloudFront'],
      explanation: 'S3 origin with CloudFront CDN is a standard pattern.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-111',
      type: QuestionType.multipleChoice,
      domain: 'aws',
      difficulty: 'intermediate',
      prompt: 'Which service records API activity for audit?',
      choices: ['CloudWatch Logs only', 'CloudTrail', 'Config only', 'X-Ray only'],
      correctAnswers: ['CloudTrail'],
      explanation: 'CloudTrail logs AWS API calls for governance.',
      certification: 'AWS CCP',
    ),
    const Question(
      id: 'q-112',
      type: QuestionType.multipleChoice,
      domain: 'architecture',
      difficulty: 'advanced',
      prompt: 'Which design improves availability for a stateful database tier on AWS?',
      choices: [
        'Single AZ RDS',
        'Multi-AZ RDS with automated failover',
        'Store DB on instance store only',
        'Disable backups',
      ],
      correctAnswers: ['Multi-AZ RDS with automated failover'],
      explanation: 'Multi-AZ provides synchronous standby failover.',
      certification: 'AWS SAA',
    ),
    const Question(
      id: 'q-113',
      type: QuestionType.multipleChoice,
      domain: 'cicd',
      difficulty: 'intermediate',
      prompt: 'A canary deployment means:',
      choices: [
        'Deploy to all users at once',
        'Route a small percentage of traffic to the new version first',
        'Never roll back',
        'Only test locally',
      ],
      correctAnswers: ['Route a small percentage of traffic to the new version first'],
      explanation: 'Canaries reduce risk by gradual exposure.',
    ),
    const Question(
      id: 'q-114',
      type: QuestionType.multipleChoice,
      domain: 'docker',
      difficulty: 'intermediate',
      prompt: 'docker-compose is used to:',
      choices: [
        'Define multi-container applications',
        'Replace Kubernetes entirely always',
        'Manage IAM policies',
        'Provision VPCs',
      ],
      correctAnswers: ['Define multi-container applications'],
      explanation: 'Compose files describe multi-service stacks for local/dev and simple deploys.',
    ),
    const Question(
      id: 'q-115',
      type: QuestionType.fillBlank,
      domain: 'terraform',
      difficulty: 'beginner',
      prompt: 'Command to initialize working directory: terraform ____',
      correctAnswers: ['init'],
      explanation: 'terraform init downloads providers and sets up backend.',
    ),
    // Expand bank with generated variants for volume
    ..._generateBatch(),
  ];

  static List<Question> _generateBatch() {
    final list = <Question>[];
    final domains = {
      'aws': [
        ['What does S3 versioning provide?', 'Object history and recovery', 'Lower latency only', 'IAM roles', 'VPC peering', 'Object history and recovery'],
        ['Which storage is block-level for EC2?', 'EBS', 'S3', 'Glacier', 'SNS', 'EBS'],
        ['Auto Scaling primarily helps with?', 'Elasticity under load', 'DNS only', 'Certificate renewal', 'Git branching', 'Elasticity under load'],
        ['Systems Manager Session Manager is used to?', 'Shell access without bastion SSH', 'Store objects', 'Balance HTTP', 'Compile code', 'Shell access without bastion SSH'],
        ['Secrets Manager stores?', 'Credentials and secrets with rotation', 'AMIs', 'VPC CIDRs', 'Route tables', 'Credentials and secrets with rotation'],
      ],
      'linux': [
        ['Which command finds files by name?', 'find', 'ps', 'df', 'free', 'find'],
        ['journalctl -u nginx shows?', 'Logs for nginx unit', 'Disk usage', 'CPU topology', 'Open ports only', 'Logs for nginx unit'],
        ['ss -tlnp is used to?', 'List listening TCP ports', 'Format disks', 'Create users', 'Compile kernels', 'List listening TCP ports'],
        ['tar -czf archive.tgz dir creates?', 'Gzipped tar archive', 'ISO image', 'Swap file', 'RAID array', 'Gzipped tar archive'],
        ['Which file holds user account info?', '/etc/passwd', '/var/log/syslog', '/etc/fstab', '/proc/cpuinfo', '/etc/passwd'],
      ],
      'networking': [
        ['CIDR /16 provides how many addresses?', '65536', '256', '16', '2', '65536'],
        ['DNS resolves?', 'Names to IP addresses', 'CPU to cores', 'IAM to policies', 'Pods to nodes only', 'Names to IP addresses'],
        ['HTTPS default port?', '443', '80', '22', '3306', '443'],
        ['A route table associates with?', 'Subnets', 'S3 buckets', 'IAM users', 'AMIs', 'Subnets'],
        ['NACLs are evaluated?', 'Stateless at subnet boundary', 'Only on laptops', 'Inside containers only', 'Never', 'Stateless at subnet boundary'],
      ],
      'azure': [
        ['NSG stands for?', 'Network Security Group', 'Node Service Gateway', 'National Storage Grid', 'Network Session Graph', 'Network Security Group'],
        ['Azure AD is now often called?', 'Microsoft Entra ID', 'AWS IAM', 'GCP IAM', 'Okta only', 'Microsoft Entra ID'],
        ['App Service is primarily?', 'PaaS for web apps', 'Object storage', 'Bare metal rental', 'CDN only', 'PaaS for web apps'],
      ],
      'gcp': [
        ['GCS is?', 'Object storage', 'Managed Kubernetes', 'Message queue', 'VPN only', 'Object storage'],
        ['Compute Engine provides?', 'Virtual machines', 'Serverless SQL only', 'CDN only', 'Source repos only', 'Virtual machines'],
        ['Cloud Build is used for?', 'CI builds', 'Object lifecycle only', 'DNSSEC only', 'Billing export only', 'CI builds'],
      ],
    };

    var n = 200;
    domains.forEach((domain, items) {
      for (final item in items) {
        list.add(Question(
          id: 'q-$n',
          type: QuestionType.multipleChoice,
          domain: domain,
          difficulty: 'intermediate',
          prompt: item[0],
          choices: [item[1], item[2], item[3], item[4]],
          correctAnswers: [item[5]],
          explanation: 'Correct answer: ${item[5]}.',
          certification: domain == 'aws'
              ? 'AWS SAA'
              : domain == 'azure'
                  ? 'AZ-900'
                  : domain == 'gcp'
                      ? 'GCP ACE'
                      : null,
        ));
        n++;
      }
    });

    // True/false batch
    final tf = [
      ['Regions contain multiple AZs.', true, 'cloud'],
      ['Containers share the host kernel.', true, 'docker'],
      ['Terraform apply always requires cloud credentials in cloudamned.', false, 'terraform'],
      ['Security groups are stateful.', true, 'networking'],
      ['Root AWS user should be used for daily work.', false, 'security'],
      ['Kubernetes Pods are the smallest deployable unit.', true, 'kubernetes'],
      ['Blue/green keeps two environments for safe cutover.', true, 'cicd'],
      ['Prometheus scrapes metrics endpoints.', true, 'monitoring'],
    ];
    for (final t in tf) {
      list.add(Question(
        id: 'q-$n',
        type: QuestionType.trueFalse,
        domain: t[2] as String,
        difficulty: 'beginner',
        prompt: t[0] as String,
        choices: const ['True', 'False'],
        correctAnswers: [(t[1] as bool) ? 'True' : 'False'],
        explanation: 'Statement is ${t[1]}.',
      ));
      n++;
    }
    return list;
  }
}
