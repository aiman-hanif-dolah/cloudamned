import '../../domain/entities/lab.dart';

/// Complete learning path: 20 modules, 120+ interactive labs.
abstract final class RoadmapContent {
  static List<LearningModule> get modules => _modules;
  static List<Lab> get allLabs =>
      _modules.expand((m) => m.labs).toList(growable: false);

  static LearningModule? moduleById(String id) {
    try {
      return _modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static Lab? labById(String id) {
    try {
      return allLabs.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<LearningModule> _modules = [
    _m1Fundamentals(),
    _m2Linux(),
    _m3Windows(),
    _m4Networking(),
    _m5Aws(),
    _m6Azure(),
    _m7Gcp(),
    _m8Docker(),
    _m9Kubernetes(),
    _m10Terraform(),
    _m11Cicd(),
    _m12Monitoring(),
    _m13Security(),
    _m14Architecture(),
    _m15Devops(),
    _m16Troubleshooting(),
    _m17Scenarios(),
    _m18Interview(),
    _m19Certification(),
    _m20FinalExam(),
  ];

  static Lab _lab({
    required String id,
    required String moduleId,
    required int order,
    required String title,
    required String summary,
    required String background,
    required List<String> objectives,
    required List<String> requirements,
    required LabDifficulty difficulty,
    required LabType type,
    int xp = 100,
    int minutes = 25,
    List<String> tags = const [],
    List<String> hints = const [],
    List<String> prereqs = const [],
    String simulator = 'none',
    List<String> validation = const [],
  }) {
    return Lab(
      id: id,
      moduleId: moduleId,
      order: order,
      title: title,
      summary: summary,
      background: background,
      objectives: [
        for (var i = 0; i < objectives.length; i++)
          LabObjective(
            id: '$id-obj-${i + 1}',
            description: objectives[i],
            validationKey: validation.length > i ? validation[i] : null,
          ),
      ],
      requirements: requirements,
      difficulty: difficulty,
      type: type,
      xpReward: xp,
      estimatedMinutes: minutes,
      tags: tags,
      hints: hints,
      prerequisites: prereqs,
      simulator: simulator,
      validationRules: validation,
    );
  }

  // ── MODULE 1: Cloud Fundamentals ──────────────────────────────────────────
  static LearningModule _m1Fundamentals() {
    const mid = 'mod-01';
    return LearningModule(
      id: mid,
      order: 1,
      title: 'Cloud Fundamentals',
      subtitle: 'IaaS foundations',
      description:
          'Cloud computing models, virtualization, regions, pricing, and shared responsibility.',
      icon: 'cloud',
      colorKey: 'primary',
      skills: ['Cloud Models', 'Virtualization', 'IaaS', 'Shared Responsibility'],
      labs: [
        _lab(
          id: 'lab-01-01',
          moduleId: mid,
          order: 1,
          title: 'What is Cloud Computing?',
          summary: 'Define cloud computing and its five essential characteristics.',
          background:
              'NIST defines cloud computing with on-demand self-service, broad network access, resource pooling, rapid elasticity, and measured service.',
          objectives: [
            'Identify the five NIST cloud characteristics',
            'Contrast cloud vs traditional hosting',
            'Explain elasticity and measured service',
          ],
          requirements: ['None'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['fundamentals', 'nist'],
          minutes: 15,
        ),
        _lab(
          id: 'lab-01-02',
          moduleId: mid,
          order: 2,
          title: 'On-Premises vs Cloud',
          summary: 'Compare CapEx/OpEx, ownership, and operational models.',
          background:
              'On-premises requires capital expenditure, capacity planning, and physical security. Cloud shifts to OpEx and shared infrastructure.',
          objectives: [
            'Compare CapEx and OpEx models',
            'List operational differences',
            'Choose a model for a sample workload',
          ],
          requirements: ['lab-01-01'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['fundamentals'],
          prereqs: ['lab-01-01'],
        ),
        _lab(
          id: 'lab-01-03',
          moduleId: mid,
          order: 3,
          title: 'Virtualization & Hypervisors',
          summary: 'Understand Type-1/Type-2 hypervisors and multi-tenancy.',
          background:
              'Hypervisors abstract physical hardware into virtual machines. Type-1 (bare metal) powers cloud; Type-2 runs on a host OS.',
          objectives: [
            'Differentiate Type-1 and Type-2 hypervisors',
            'Explain multi-tenancy isolation',
            'Map hypervisor concepts to cloud VMs',
          ],
          requirements: ['lab-01-02'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['virtualization'],
          prereqs: ['lab-01-02'],
        ),
        _lab(
          id: 'lab-01-04',
          moduleId: mid,
          order: 4,
          title: 'VMs vs Containers',
          summary: 'When to use virtual machines versus containers.',
          background:
              'VMs virtualize hardware; containers virtualize the OS. Containers share the kernel and start faster with denser packing.',
          objectives: [
            'Compare isolation models',
            'Identify use cases for each',
            'Describe image and instance lifecycle',
          ],
          requirements: ['lab-01-03'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['containers', 'vm'],
          prereqs: ['lab-01-03'],
        ),
        _lab(
          id: 'lab-01-05',
          moduleId: mid,
          order: 5,
          title: 'IaaS, PaaS, SaaS',
          summary: 'Cloud service models and shared responsibility boundaries.',
          background:
              'IaaS provides compute/network/storage. PaaS abstracts runtime. SaaS delivers complete applications.',
          objectives: [
            'Classify services into IaaS/PaaS/SaaS',
            'Draw responsibility boundaries',
            'Select the right model for a workload',
          ],
          requirements: ['lab-01-04'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['iaas', 'paas', 'saas'],
          prereqs: ['lab-01-04'],
        ),
        _lab(
          id: 'lab-01-06',
          moduleId: mid,
          order: 6,
          title: 'Regions, AZs & Edge',
          summary: 'Geographic design of cloud infrastructure.',
          background:
              'Regions contain multiple Availability Zones. Edge locations cache content closer to users (CDN).',
          objectives: [
            'Define region, AZ, and edge location',
            'Design for multi-AZ high availability',
            'Explain latency and data residency trade-offs',
          ],
          requirements: ['lab-01-05'],
          difficulty: LabDifficulty.beginner,
          type: LabType.theory,
          tags: ['regions', 'ha'],
          prereqs: ['lab-01-05'],
        ),
        _lab(
          id: 'lab-01-07',
          moduleId: mid,
          order: 7,
          title: 'Cloud Pricing Models',
          summary: 'On-demand, reserved, spot, and savings plans.',
          background:
              'Cloud pricing rewards architectural discipline. Wrong instance types and idle resources waste budget.',
          objectives: [
            'Compare pricing models',
            'Estimate monthly cost for a sample stack',
            'Identify cost optimization levers',
          ],
          requirements: ['lab-01-06'],
          difficulty: LabDifficulty.intermediate,
          type: LabType.theory,
          tags: ['pricing', 'finops'],
          prereqs: ['lab-01-06'],
        ),
        _lab(
          id: 'lab-01-08',
          moduleId: mid,
          order: 8,
          title: 'Shared Responsibility Model',
          summary: 'Who secures what in the cloud.',
          background:
              'Providers secure the cloud; customers secure in the cloud. Boundaries shift by service model.',
          objectives: [
            'Map security duties for IaaS vs SaaS',
            'Identify customer-owned controls',
            'Apply the model to a sample incident',
          ],
          requirements: ['lab-01-07'],
          difficulty: LabDifficulty.intermediate,
          type: LabType.theory,
          tags: ['security', 'compliance'],
          prereqs: ['lab-01-07'],
        ),
        _lab(
          id: 'lab-01-09',
          moduleId: mid,
          order: 9,
          title: 'Choose Your Infrastructure',
          summary: 'Hands-on: select compute, storage, and network for a web app.',
          background:
              'A startup needs a small web application. You choose infrastructure components in the simulator.',
          objectives: [
            'Select compute size for a web tier',
            'Choose block vs object storage',
            'Pick a single-AZ vs multi-AZ layout',
          ],
          requirements: ['Modules 1 theory'],
          difficulty: LabDifficulty.intermediate,
          type: LabType.console,
          simulator: 'architecture',
          tags: ['hands-on', 'design'],
          prereqs: ['lab-01-08'],
          minutes: 35,
          xp: 150,
          validation: ['compute_selected', 'storage_selected', 'network_selected'],
        ),
        _lab(
          id: 'lab-01-10',
          moduleId: mid,
          order: 10,
          title: 'Deploy Your First VM',
          summary: 'Launch a virtual machine in the cloud console simulator.',
          background:
              'Walk through instance launch: AMI/image, type, network, security group, key pair, and user data.',
          objectives: [
            'Launch a VM with correct networking',
            'Attach a security group allowing SSH',
            'Verify instance state is running',
          ],
          requirements: ['lab-01-09'],
          difficulty: LabDifficulty.intermediate,
          type: LabType.console,
          simulator: 'aws',
          tags: ['vm', 'ec2', 'hands-on'],
          prereqs: ['lab-01-09'],
          minutes: 40,
          xp: 150,
          validation: ['vm_running', 'sg_ssh', 'key_pair'],
          hints: [
            'Security groups are stateful allow-lists.',
            'Public IP requires a public subnet and internet gateway.',
          ],
        ),
      ],
    );
  }

  // ── MODULE 2: Linux Administration ────────────────────────────────────────
  static LearningModule _m2Linux() {
    const mid = 'mod-02';
    final labs = <Lab>[];
    final specs = [
      ('Navigation Basics', 'pwd, ls, cd, tree', 'terminal', ['pwd', 'ls_home']),
      ('Files & Directories', 'mkdir, touch, cp, mv, rm', 'terminal', ['mkdir_demo', 'touch_file']),
      ('Reading Files', 'cat, less, head, tail', 'terminal', ['cat_file']),
      ('Permissions', 'chmod, chown, umask', 'terminal', ['chmod_755']),
      ('Users & Groups', 'useradd, usermod, passwd, groups', 'terminal', ['user_created']),
      ('Process Management', 'ps, top, kill, nice', 'terminal', ['ps_aux']),
      ('Services with systemd', 'systemctl start/stop/enable', 'terminal', ['nginx_enabled']),
      ('Logs with journalctl', 'Filter and follow unit logs', 'terminal', ['journal_nginx']),
      ('Disk & Filesystems', 'df, du, mount, lsblk', 'terminal', ['df_h']),
      ('Networking Tools', 'ip, ss, ping, curl, traceroute', 'terminal', ['ip_addr']),
      ('SSH & SCP', 'Key-based auth and secure copy', 'terminal', ['ssh_keygen']),
      ('Archives & Packages', 'tar, apt/yum simulation', 'terminal', ['tar_create']),
      ('Text Processing', 'grep, find, sed, awk basics', 'terminal', ['grep_error']),
      ('Firewall (ufw/iptables)', 'Allow SSH and HTTP', 'terminal', ['ufw_allow_22']),
      ('Linux Capstone', 'Harden a web server end-to-end', 'troubleshooting',
          ['nginx_running', 'ufw_active', 'user_deploy']),
    ];
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      labs.add(_lab(
        id: 'lab-02-${(i + 1).toString().padLeft(2, '0')}',
        moduleId: mid,
        order: i + 1,
        title: s.$1,
        summary: s.$2,
        background:
            'Linux is the OS of the cloud. Master the terminal, permissions, services, and networking tools used daily by cloud engineers.',
        objectives: [
          'Complete all interactive terminal tasks for: ${s.$2}',
          'Explain when you would use each command in production',
          'Pass automated validation checks',
        ],
        requirements: i == 0 ? ['Module 1 complete recommended'] : ['Previous Linux lab'],
        difficulty: i < 5
            ? LabDifficulty.beginner
            : i < 12
                ? LabDifficulty.intermediate
                : LabDifficulty.advanced,
        type: s.$3 == 'terminal' ? LabType.terminal : LabType.troubleshooting,
        simulator: 'linux',
        tags: ['linux', 'cli'],
        minutes: 30 + (i * 2),
        xp: 100 + (i * 10),
        validation: s.$4,
        hints: [
          'Use `man <command>` simulation with help <command>.',
          'Tab completion is available for common paths.',
        ],
      ));
    }
    return LearningModule(
      id: mid,
      order: 2,
      title: 'Linux Administration',
      subtitle: 'Interactive terminal mastery',
      description:
          'Real command simulation: filesystem, permissions, systemd, networking, packages, and hardening.',
      icon: 'terminal',
      colorKey: 'linux',
      skills: ['CLI', 'systemd', 'Networking', 'Hardening'],
      labs: labs,
    );
  }

  // ── MODULE 3: Windows Server ──────────────────────────────────────────────
  static LearningModule _m3Windows() {
    const mid = 'mod-03';
    final titles = [
      'Server Manager Overview',
      'Install IIS Web Server',
      'DNS Role Configuration',
      'DHCP Scope Setup',
      'Active Directory Domain Services',
      'Users, Groups & OUs',
      'File Server & Shares',
      'NTFS & Share Permissions',
      'Remote Desktop Services',
      'Windows Firewall Rules',
      'PowerShell Fundamentals',
      'PowerShell Desired State',
      'Group Policy Basics',
      'Certificate Services Intro',
      'Windows Server Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 3,
      title: 'Windows Server',
      subtitle: 'Server Manager & PowerShell',
      description: 'IIS, DNS, DHCP, AD DS, RDP, firewall, and PowerShell administration.',
      icon: 'monitor',
      colorKey: 'azure',
      skills: ['IIS', 'AD DS', 'PowerShell', 'DNS/DHCP'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-03-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: 'Windows Server lab: ${titles[i]}',
            background:
                'Enterprise cloud estates often mix Linux and Windows. Practice Server Manager workflows and PowerShell automation.',
            objectives: [
              'Complete ${titles[i]} in the Server Manager simulator',
              'Verify role health checks pass',
              'Document configuration decisions',
            ],
            requirements: ['Module 2 recommended'],
            difficulty: i < 6 ? LabDifficulty.beginner : LabDifficulty.intermediate,
            type: LabType.console,
            simulator: 'windows',
            tags: ['windows', 'ad', 'iis'],
            minutes: 35,
            xp: 120,
            validation: ['role_configured'],
          ),
      ],
    );
  }

  // ── MODULE 4: Networking ──────────────────────────────────────────────────
  static LearningModule _m4Networking() {
    const mid = 'mod-04';
    final titles = [
      'OSI & TCP/IP Models',
      'IP Addressing & Subnetting',
      'CIDR Notation Deep Dive',
      'Routers & Switches Topology',
      'DNS Resolution Path',
      'DHCP Lease Process',
      'VPC Fundamentals',
      'Public & Private Subnets',
      'Internet Gateway & NAT',
      'Route Tables Deep Dive',
      'Security Groups vs NACLs',
      'Load Balancers (L4/L7)',
      'VPN & Hybrid Connectivity',
      'Firewall Policy Design',
      'Fix Broken Network (Troubleshoot)',
      'Allow SSH & HTTP Securely',
      'Block Malicious Traffic',
      'Network Capstone Topology',
    ];
    return LearningModule(
      id: mid,
      order: 4,
      title: 'Networking',
      subtitle: 'Topology, VPC, security',
      description:
          'Interactive topology builder: subnets, gateways, SGs, load balancers, VPN, and incident response.',
      icon: 'network',
      colorKey: 'info',
      skills: ['CIDR', 'VPC', 'DNS', 'Security Groups'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-04-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background:
                'Networking is the backbone of every cloud design. Misconfigured routes and security groups are the #1 source of outages.',
            objectives: [
              'Complete interactive topology tasks for ${titles[i]}',
              'Validate connectivity with simulated packet paths',
              'Apply least-privilege network access',
            ],
            requirements: ['Linux basics'],
            difficulty: i < 6
                ? LabDifficulty.beginner
                : i < 14
                    ? LabDifficulty.intermediate
                    : LabDifficulty.advanced,
            type: i >= 14 ? LabType.troubleshooting : LabType.console,
            simulator: 'networking',
            tags: ['networking', 'vpc'],
            minutes: 40,
            xp: 130,
            validation: ['network_ok'],
            hints: [
              'Private subnets need NAT for outbound internet.',
              'Security groups are stateful; NACLs are stateless.',
            ],
          ),
      ],
    );
  }

  // ── MODULE 5: AWS ─────────────────────────────────────────────────────────
  static LearningModule _m5Aws() {
    const mid = 'mod-05';
    final titles = [
      'AWS Account & Console Tour',
      'IAM Users, Groups & Roles',
      'IAM Policies Deep Dive',
      'VPC Design Workshop',
      'Subnets & Route Tables',
      'Internet Gateway & NAT Gateway',
      'Security Groups Hands-on',
      'Launch EC2 Instance',
      'SSH into EC2 & Install Nginx',
      'EBS Volumes & Snapshots',
      'S3 Buckets & Lifecycle',
      'RDS MySQL Deployment',
      'Application Load Balancer',
      'Auto Scaling Groups',
      'CloudWatch Metrics & Alarms',
      'Route 53 Hosted Zones',
      'Lambda Hello World',
      'ECS Fargate Service',
      'EKS Cluster Overview',
      'CloudFormation Stack',
      'Secrets Manager & SSM',
      'CloudTrail Audit Trail',
      'Backup & Disaster Recovery',
      'Scale a Production App',
      'Fix Failed Instance (Troubleshoot)',
      'AWS Production Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 5,
      title: 'Amazon Web Services',
      subtitle: 'Full console simulation',
      description:
          'IAM, VPC, EC2, EBS, S3, RDS, ELB, ASG, CloudWatch, Lambda, ECS/EKS, CloudFormation, and DR.',
      icon: 'aws',
      colorKey: 'aws',
      skills: ['IAM', 'EC2', 'VPC', 'S3', 'RDS', 'CloudWatch'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-05-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background:
                'Practice realistic AWS console workflows offline. Every action mutates a simulated account state and produces CLI-like outputs.',
            objectives: [
              'Perform ${titles[i]} in the AWS simulator',
              'Validate resources with describe/list actions',
              'Follow least-privilege IAM practices',
            ],
            requirements: ['Modules 1–4 recommended'],
            difficulty: i < 8
                ? LabDifficulty.beginner
                : i < 18
                    ? LabDifficulty.intermediate
                    : LabDifficulty.advanced,
            type: i >= 24 ? LabType.troubleshooting : LabType.console,
            simulator: 'aws',
            tags: ['aws', 'iaas'],
            minutes: 45,
            xp: 150,
            validation: ['aws_step_complete'],
            hints: [
              'Tag every resource with Environment and Owner.',
              'Prefer roles over long-lived access keys.',
            ],
          ),
      ],
    );
  }

  // ── MODULE 6: Azure ───────────────────────────────────────────────────────
  static LearningModule _m6Azure() {
    const mid = 'mod-06';
    final titles = [
      'Azure Portal & Subscriptions',
      'Resource Groups',
      'Virtual Networks',
      'Azure Virtual Machines',
      'Storage Accounts',
      'Azure AD / Entra ID Basics',
      'NSGs & Application Security',
      'Application Gateway',
      'Azure SQL Database',
      'Azure Functions',
      'Azure Monitor & Alerts',
      'Azure Capstone Deploy',
    ];
    return LearningModule(
      id: mid,
      order: 6,
      title: 'Microsoft Azure',
      subtitle: 'Portal simulation',
      description: 'Resource Groups, VNets, VMs, Storage, Entra ID, App Gateway, SQL, Functions, Monitor.',
      icon: 'azure',
      colorKey: 'azure',
      skills: ['VNet', 'Azure VM', 'Entra ID', 'Azure Monitor'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-06-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Azure Portal simulation with realistic resource models and ARM-like outputs.',
            objectives: [
              'Complete ${titles[i]}',
              'Organize resources in Resource Groups',
              'Apply RBAC least privilege',
            ],
            requirements: ['Cloud fundamentals'],
            difficulty: i < 6 ? LabDifficulty.beginner : LabDifficulty.intermediate,
            type: LabType.console,
            simulator: 'azure',
            tags: ['azure'],
            minutes: 40,
            xp: 140,
            validation: ['azure_step_complete'],
          ),
      ],
    );
  }

  // ── MODULE 7: Google Cloud ────────────────────────────────────────────────
  static LearningModule _m7Gcp() {
    const mid = 'mod-07';
    final titles = [
      'GCP Projects & Hierarchy',
      'Compute Engine VMs',
      'VPC Networks on GCP',
      'Cloud Storage Buckets',
      'Cloud SQL',
      'Cloud Run Services',
      'GKE Cluster Basics',
      'Cloud Build Pipeline',
      'IAM Roles & Service Accounts',
      'GCP Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 7,
      title: 'Google Cloud Platform',
      subtitle: 'Projects to GKE',
      description: 'Compute Engine, Cloud Storage, Cloud Run, GKE, Cloud SQL, Cloud Build, IAM.',
      icon: 'gcp',
      colorKey: 'gcp',
      skills: ['GCE', 'GCS', 'GKE', 'Cloud Run'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-07-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'GCP console simulation focused on production-ready networking and IAM.',
            objectives: [
              'Complete ${titles[i]}',
              'Use gcloud-style commands where applicable',
              'Validate resource state',
            ],
            requirements: ['Cloud fundamentals'],
            difficulty: i < 5 ? LabDifficulty.beginner : LabDifficulty.intermediate,
            type: LabType.console,
            simulator: 'gcp',
            tags: ['gcp'],
            minutes: 40,
            xp: 140,
            validation: ['gcp_step_complete'],
          ),
      ],
    );
  }

  // ── MODULE 8: Docker ──────────────────────────────────────────────────────
  static LearningModule _m8Docker() {
    const mid = 'mod-08';
    final titles = [
      'Install Docker (Simulated)',
      'Dockerfile Fundamentals',
      'Build Your First Image',
      'Run Containers',
      'Volumes & Bind Mounts',
      'Docker Networks',
      'Docker Compose Multi-Service',
      'Tag & Push Images',
      'Debug Container Failures',
      'Docker Capstone App',
    ];
    return LearningModule(
      id: mid,
      order: 8,
      title: 'Docker',
      subtitle: 'Images, containers, compose',
      description: 'Dockerfile, build, run, volumes, networks, Compose, debugging.',
      icon: 'docker',
      colorKey: 'docker',
      skills: ['Dockerfile', 'Compose', 'Networking', 'Debugging'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-08-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background:
                'Local Docker daemon simulation. Commands produce realistic docker CLI output.',
            objectives: [
              'Execute Docker workflows for ${titles[i]}',
              'Inspect containers and images',
              'Fix common runtime errors',
            ],
            requirements: ['Linux terminal'],
            difficulty: i < 4 ? LabDifficulty.beginner : LabDifficulty.intermediate,
            type: i == 8 ? LabType.troubleshooting : LabType.terminal,
            simulator: 'docker',
            tags: ['docker', 'containers'],
            minutes: 35,
            xp: 130,
            validation: ['docker_step'],
          ),
      ],
    );
  }

  // ── MODULE 9: Kubernetes ──────────────────────────────────────────────────
  static LearningModule _m9Kubernetes() {
    const mid = 'mod-09';
    final titles = [
      'Cluster Architecture',
      'Pods & kubectl',
      'ReplicaSets',
      'Deployments',
      'Services (ClusterIP/NodePort/LB)',
      'Ingress Controllers',
      'Namespaces',
      'ConfigMaps & Secrets',
      'Persistent Volumes',
      'Rolling Updates & Rollbacks',
      'Horizontal Pod Autoscaling',
      'Failure Recovery Drill',
    ];
    return LearningModule(
      id: mid,
      order: 9,
      title: 'Kubernetes',
      subtitle: 'Workloads & cluster ops',
      description: 'Pods, Deployments, Services, Ingress, Secrets, PVs, rolling updates, recovery.',
      icon: 'kubernetes',
      colorKey: 'k8s',
      skills: ['kubectl', 'Deployments', 'Services', 'Ingress'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-09-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Simulated Kubernetes API server with kubectl-compatible command surface.',
            objectives: [
              'Complete ${titles[i]}',
              'Verify resources with kubectl get/describe',
              'Handle a failure scenario',
            ],
            requirements: ['Docker module'],
            difficulty: i < 5 ? LabDifficulty.intermediate : LabDifficulty.advanced,
            type: i == 11 ? LabType.troubleshooting : LabType.terminal,
            simulator: 'kubernetes',
            tags: ['k8s', 'containers'],
            minutes: 45,
            xp: 160,
            validation: ['k8s_step'],
          ),
      ],
    );
  }

  // ── MODULE 10: Terraform ──────────────────────────────────────────────────
  static LearningModule _m10Terraform() {
    const mid = 'mod-10';
    final titles = [
      'IaC Concepts',
      'Providers & Backend',
      'Resources & Data Sources',
      'Variables & Outputs',
      'Modules Structure',
      'terraform init',
      'terraform plan',
      'terraform apply',
      'terraform destroy',
      'State Management',
      'Visual Infrastructure Map',
      'Terraform Capstone VPC+EC2',
    ];
    return LearningModule(
      id: mid,
      order: 10,
      title: 'Terraform',
      subtitle: 'Infrastructure as Code',
      description:
          'Editor with validation, plan/apply simulation, modules, state, and auto-generated topology.',
      icon: 'terraform',
      colorKey: 'terraform',
      skills: ['HCL', 'Plan/Apply', 'Modules', 'State'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-10-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background:
                'Write real HCL. The engine validates syntax, produces plan output, and mutates simulated cloud state.',
            objectives: [
              'Write Terraform for ${titles[i]}',
              'Run plan and interpret changes',
              'Apply and verify resources',
            ],
            requirements: ['AWS basics'],
            difficulty: i < 5 ? LabDifficulty.intermediate : LabDifficulty.advanced,
            type: LabType.console,
            simulator: 'terraform',
            tags: ['terraform', 'iac'],
            minutes: 40,
            xp: 150,
            validation: ['tf_step'],
          ),
      ],
    );
  }

  // ── MODULE 11: CI/CD ──────────────────────────────────────────────────────
  static LearningModule _m11Cicd() {
    const mid = 'mod-11';
    final titles = [
      'CI/CD Concepts',
      'Jenkins Pipeline Basics',
      'GitHub Actions Workflow',
      'GitLab CI Stages',
      'Build Pipeline',
      'Test Pipeline',
      'Deploy Pipeline',
      'Rollback Strategies',
      'Broken Pipeline Troubleshooting',
      'CI/CD Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 11,
      title: 'CI/CD',
      subtitle: 'Jenkins, Actions, GitLab',
      description: 'Build, test, deploy, rollback, and pipeline troubleshooting.',
      icon: 'git-branch',
      colorKey: 'primary',
      skills: ['Jenkins', 'GitHub Actions', 'Pipelines', 'Rollback'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-11-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Configure pipelines and debug failing stages with realistic logs.',
            objectives: [
              'Configure ${titles[i]}',
              'Interpret pipeline logs',
              'Achieve green build',
            ],
            requirements: ['Git basics'],
            difficulty: LabDifficulty.intermediate,
            type: i == 8 ? LabType.troubleshooting : LabType.console,
            simulator: 'cicd',
            tags: ['cicd', 'devops'],
            minutes: 40,
            xp: 140,
            validation: ['pipeline_green'],
          ),
      ],
    );
  }

  // ── MODULE 12: Monitoring ─────────────────────────────────────────────────
  static LearningModule _m12Monitoring() {
    const mid = 'mod-12';
    final titles = [
      'Observability Pillars',
      'CloudWatch Dashboards',
      'Prometheus Metrics',
      'Grafana Visualization',
      'ELK Stack Overview',
      'Log Analysis Drill',
      'Alerting Strategies',
      'Incident Response Runbook',
      'SLO/SLI Basics',
      'Monitoring Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 12,
      title: 'Monitoring',
      subtitle: 'Metrics, logs, alerts',
      description: 'CloudWatch, Prometheus, Grafana, ELK, incident response.',
      icon: 'activity',
      colorKey: 'success',
      skills: ['Metrics', 'Logs', 'Alerts', 'IR'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-12-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Practice reading metrics and logs under simulated incident pressure.',
            objectives: [
              'Complete ${titles[i]}',
              'Create or interpret an alert',
              'Document root cause',
            ],
            requirements: ['AWS CloudWatch lab'],
            difficulty: LabDifficulty.intermediate,
            type: LabType.console,
            simulator: 'monitoring',
            tags: ['monitoring', 'sre'],
            minutes: 35,
            xp: 140,
            validation: ['alert_configured'],
          ),
      ],
    );
  }

  // ── MODULE 13: Security ───────────────────────────────────────────────────
  static LearningModule _m13Security() {
    const mid = 'mod-13';
    final titles = [
      'Least Privilege Design',
      'IAM Policy Hardening',
      'Encryption at Rest & Transit',
      'MFA Enforcement',
      'Secrets Management',
      'Certificates & PKI',
      'SSL/TLS & HTTPS',
      'Security Group Hardening',
      'Patch Management',
      'Compliance Frameworks Overview',
      'Security Capstone Audit',
    ];
    return LearningModule(
      id: mid,
      order: 13,
      title: 'Security',
      subtitle: 'Identity, encryption, compliance',
      description: 'IAM, encryption, MFA, secrets, TLS, patching, compliance.',
      icon: 'shield',
      colorKey: 'destructive',
      skills: ['IAM', 'Encryption', 'TLS', 'Compliance'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-13-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Security is continuous. Practice hardening and audit remediation.',
            objectives: [
              'Apply security controls for ${titles[i]}',
              'Pass automated security checks',
              'Document residual risk',
            ],
            requirements: ['IAM labs'],
            difficulty: LabDifficulty.advanced,
            type: LabType.console,
            simulator: 'aws',
            tags: ['security'],
            minutes: 40,
            xp: 160,
            validation: ['security_ok'],
          ),
      ],
    );
  }

  // ── MODULE 14: Architecture ───────────────────────────────────────────────
  static LearningModule _m14Architecture() {
    const mid = 'mod-14';
    final titles = [
      'Well-Architected Overview',
      '3-Tier Web Architecture',
      'High Availability Patterns',
      'Serverless Architecture',
      'Event-Driven Design',
      'Multi-Region Strategy',
      'Cost-Optimized Design',
      'Secure Architecture Review',
      'Architecture Evaluation Lab',
      'Architecture Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 14,
      title: 'Architecture Design',
      subtitle: 'Drag-and-drop builder',
      description: 'Design systems and get scored on scalability, availability, security, cost, performance.',
      icon: 'layout',
      colorKey: 'chart4',
      skills: ['HA', 'Security', 'Cost', 'Performance'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-14-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Drag components, connect them, submit for automated evaluation.',
            objectives: [
              'Design architecture for ${titles[i]}',
              'Score ≥ 70 on evaluation rubric',
              'Explain trade-offs',
            ],
            requirements: ['AWS + Networking'],
            difficulty: LabDifficulty.advanced,
            type: LabType.architecture,
            simulator: 'architecture',
            tags: ['architecture'],
            minutes: 50,
            xp: 180,
            validation: ['arch_score_70'],
          ),
      ],
    );
  }

  // ── MODULE 15: DevOps ─────────────────────────────────────────────────────
  static LearningModule _m15Devops() {
    const mid = 'mod-15';
    final titles = [
      'Git Fundamentals',
      'GitFlow Branching',
      'Pull Requests & Reviews',
      'Merge Conflict Resolution',
      'Containerized Delivery',
      'Release Automation',
      'Blue/Green Deployments',
      'Canary Releases',
      'DevOps Capstone',
    ];
    return LearningModule(
      id: mid,
      order: 15,
      title: 'DevOps',
      subtitle: 'Git, releases, strategies',
      description: 'GitFlow, PRs, conflicts, blue/green, canary.',
      icon: 'git-merge',
      colorKey: 'warning',
      skills: ['Git', 'GitFlow', 'Blue/Green', 'Canary'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-15-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Practice modern delivery workflows used by cloud platform teams.',
            objectives: [
              'Complete ${titles[i]}',
              'Demonstrate safe release practice',
              'Document rollback plan',
            ],
            requirements: ['CI/CD module'],
            difficulty: LabDifficulty.intermediate,
            type: LabType.console,
            simulator: 'cicd',
            tags: ['devops', 'git'],
            minutes: 35,
            xp: 130,
            validation: ['devops_step'],
          ),
      ],
    );
  }

  // ── MODULE 16: Troubleshooting ────────────────────────────────────────────
  static LearningModule _m16Troubleshooting() {
    const mid = 'mod-16';
    final titles = [
      'SSH Inaccessible',
      'Website Down',
      'Disk Full',
      'DNS Broken',
      'Permission Denied',
      'High CPU',
      'Memory Leak',
      'Container CrashLoop',
      'Pipeline Failed',
      'Terraform Apply Error',
      'Database Unavailable',
      'Certificate Expired',
    ];
    return LearningModule(
      id: mid,
      order: 16,
      title: 'Troubleshooting',
      subtitle: 'Broken infra drills',
      description: 'Investigate logs, find root cause, implement fix. Real engineer work.',
      icon: 'wrench',
      colorKey: 'warning',
      skills: ['RCA', 'Logs', 'Networking', 'Systems'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-16-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: 'Troubleshoot: ${titles[i]}',
            background:
                'Incident ticket: customer reports "${titles[i]}". Investigate using terminal, console, and logs. Fix and verify.',
            objectives: [
              'Identify root cause of ${titles[i]}',
              'Implement the correct fix',
              'Verify service restoration',
            ],
            requirements: ['Core platform modules'],
            difficulty: LabDifficulty.advanced,
            type: LabType.troubleshooting,
            simulator: 'multi',
            tags: ['troubleshooting', 'incident'],
            minutes: 45,
            xp: 200,
            validation: ['incident_resolved'],
            hints: [
              'Start with blast radius and recent changes.',
              'Check security groups, routes, and process health.',
            ],
          ),
      ],
    );
  }

  // ── MODULE 17: Real Job Scenarios ─────────────────────────────────────────
  static LearningModule _m17Scenarios() {
    const mid = 'mod-17';
    final titles = [
      'My website is down',
      'EC2 cannot connect to RDS',
      'Accidentally deleted storage',
      'Database latency spiked',
      'Cannot SSH to bastion',
      'CI/CD pipeline fails on deploy',
      'Certificate expired on ALB',
      'Users cannot login (IAM)',
      'Cost anomaly investigation',
      'Multi-AZ failover drill',
    ];
    return LearningModule(
      id: mid,
      order: 17,
      title: 'Real Job Scenarios',
      subtitle: 'Customer tickets',
      description: 'End-to-end tickets mirroring Cloud Technical Engineer day-to-day work.',
      icon: 'briefcase',
      colorKey: 'primary',
      skills: ['Support', 'RCA', 'Communication'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-17-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: 'Ticket: ${titles[i]}',
            background:
                'You are on-call. Customer message: "${titles[i]}". Severity 2. Time box 45 minutes. Update the ticket with findings.',
            objectives: [
              'Triage and scope the issue',
              'Resolve or mitigate',
              'Write clear customer-facing summary',
            ],
            requirements: ['Troubleshooting module'],
            difficulty: LabDifficulty.advanced,
            type: LabType.scenario,
            simulator: 'scenario',
            tags: ['scenario', 'oncall'],
            minutes: 45,
            xp: 220,
            validation: ['ticket_resolved'],
          ),
      ],
    );
  }

  // ── MODULE 18: Interview Mode ─────────────────────────────────────────────
  static LearningModule _m18Interview() {
    const mid = 'mod-18';
    final titles = [
      'HR Screening Practice',
      'Technical Fundamentals Interview',
      'Linux Deep Dive Interview',
      'Networking Interview',
      'AWS Architecture Interview',
      'System Design: Web App',
      'System Design: Multi-Region',
      'Behavioral STAR Stories',
      'Troubleshooting Live Interview',
      'Full Mock Interview',
    ];
    return LearningModule(
      id: mid,
      order: 18,
      title: 'Interview Mode',
      subtitle: 'HR + technical + design',
      description: 'Local rubric evaluation for HR, technical, system design, and behavioral questions.',
      icon: 'mic',
      colorKey: 'chart4',
      skills: ['Interview', 'System Design', 'Behavioral'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-18-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background:
                'Answer interview questions. Responses are scored against predefined rubrics (local, offline).',
            objectives: [
              'Answer all questions in the set',
              'Achieve rubric score ≥ 70%',
              'Review feedback and weak areas',
            ],
            requirements: ['Related domain modules'],
            difficulty: LabDifficulty.advanced,
            type: LabType.interview,
            simulator: 'interview',
            tags: ['interview'],
            minutes: 50,
            xp: 200,
            validation: ['interview_score_70'],
          ),
      ],
    );
  }

  // ── MODULE 19: Certification Practice ─────────────────────────────────────
  static LearningModule _m19Certification() {
    const mid = 'mod-19';
    final titles = [
      'AWS CCP Practice Set A',
      'AWS CCP Practice Set B',
      'AWS SAA Practice Set A',
      'AWS SAA Practice Set B',
      'Azure AZ-900 Practice',
      'GCP ACE Practice',
      'Mixed Cloud Fundamentals Exam',
      'Timed Full-Length AWS SAA',
    ];
    return LearningModule(
      id: mid,
      order: 19,
      title: 'Certification Practice',
      subtitle: 'CCP, SAA, AZ-900, ACE',
      description: 'Timed exams, large question bank, detailed explanations.',
      icon: 'award',
      colorKey: 'success',
      skills: ['CCP', 'SAA', 'AZ-900', 'ACE'],
      labs: [
        for (var i = 0; i < titles.length; i++)
          _lab(
            id: 'lab-19-${(i + 1).toString().padLeft(2, '0')}',
            moduleId: mid,
            order: i + 1,
            title: titles[i],
            summary: titles[i],
            background: 'Certification-style questions with explanations after each exam.',
            objectives: [
              'Complete exam under time pressure',
              'Score at or above passing threshold',
              'Review every missed explanation',
            ],
            requirements: ['Domain knowledge'],
            difficulty: LabDifficulty.intermediate,
            type: LabType.exam,
            simulator: 'exam',
            tags: ['certification', 'exam'],
            minutes: 90,
            xp: 250,
            validation: ['exam_pass'],
          ),
      ],
    );
  }

  // ── MODULE 20: Final Practical Exam ───────────────────────────────────────
  static LearningModule _m20FinalExam() {
    const mid = 'mod-20';
    return LearningModule(
      id: mid,
      order: 20,
      title: 'Final Practical Exam',
      subtitle: 'Production infrastructure',
      description:
          'Build complete HA, secure, monitored, CI/CD-enabled infrastructure. Auto-graded.',
      icon: 'flag',
      colorKey: 'primary',
      skills: ['HA', 'Security', 'Monitoring', 'CI/CD', 'DR'],
      labs: [
        _lab(
          id: 'lab-20-01',
          moduleId: mid,
          order: 1,
          title: 'Practical Briefing',
          summary: 'Read requirements and scoring rubric for the final exam.',
          background:
              'You will design and deploy a production-grade 3-tier application environment offline in the simulators.',
          objectives: [
            'Read all requirements',
            'Plan your architecture',
            'Confirm scoring rubric understanding',
          ],
          requirements: ['Modules 1–19 recommended'],
          difficulty: LabDifficulty.expert,
          type: LabType.theory,
          tags: ['capstone'],
          minutes: 20,
          xp: 50,
        ),
        _lab(
          id: 'lab-20-02',
          moduleId: mid,
          order: 2,
          title: 'Build Production Infrastructure',
          summary:
              'HA, secure, monitored, logged, CI/CD, backups, scaling, recovery — full stack.',
          background:
              'Requirements: multi-AZ VPC, public/private subnets, ALB, ASG web tier, RDS multi-AZ, S3 backups, CloudWatch alarms, least-privilege IAM, CI/CD deploy path, documented runbook.',
          objectives: [
            'Deploy multi-AZ network and compute',
            'Configure secure data tier with backups',
            'Enable monitoring and alerts',
            'Wire CI/CD deploy path',
            'Demonstrate recovery procedure',
            'Score ≥ 80 on automated grader',
          ],
          requirements: ['lab-20-01'],
          difficulty: LabDifficulty.expert,
          type: LabType.exam,
          simulator: 'multi',
          tags: ['capstone', 'exam'],
          prereqs: ['lab-20-01'],
          minutes: 180,
          xp: 1000,
          validation: [
            'ha_network',
            'secure_iam',
            'monitoring',
            'cicd',
            'backups',
            'scaling',
            'recovery',
            'score_80',
          ],
          hints: [
            'Use Terraform for reproducible infrastructure.',
            'Private subnets for app and data tiers.',
            'ALB in public subnets only.',
          ],
        ),
      ],
    );
  }
}
