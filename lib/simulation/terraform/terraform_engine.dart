import '../aws/aws_engine.dart';

class TfResult {
  const TfResult({
    required this.ok,
    required this.output,
    this.resources = const [],
    this.errors = const [],
  });
  final bool ok;
  final String output;
  final List<String> resources;
  final List<String> errors;
}

class TfResource {
  TfResource({
    required this.type,
    required this.name,
    required this.attrs,
    this.file = 'main.tf',
  });
  final String type;
  final String name;
  final Map<String, String> attrs;
  final String file;

  String get address => '$type.$name';
}

class TfVisualNode {
  TfVisualNode({
    required this.id,
    required this.type,
    required this.label,
    this.parentId,
  });
  final String id;
  final String type;
  final String label;
  final String? parentId;
}

/// Offline Terraform — write real HCL, validate, plan, apply, visual map.
class TerraformEngine {
  TerraformEngine({AwsEngine? aws}) : aws = aws ?? AwsEngine(seedDefaults: false);

  final AwsEngine aws;
  bool initialized = false;
  final Map<String, String> state = {};
  final Set<String> completedActions = {};
  String lastPlan = '';
  List<TfResource> planned = [];
  List<TfVisualNode> visualNodes = [];

  /// Multi-file workspace: filename → HCL content.
  final Map<String, String> files = {
    'main.tf': sampleMain,
    'variables.tf': sampleVariables,
    'outputs.tf': sampleOutputs,
  };

  String get combinedHcl => files.values.join('\n\n');

  TfResult validate([String? hcl]) {
    final src = hcl ?? combinedHcl;
    final errors = <String>[];
    if (src.trim().isEmpty) {
      return const TfResult(ok: false, output: 'Error: empty configuration', errors: ['empty']);
    }

    // Brace balance
    var depth = 0;
    var line = 1;
    for (var i = 0; i < src.length; i++) {
      final c = src[i];
      if (c == '\n') line++;
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth < 0) {
          errors.add('main.tf:$line: Unexpected closing brace "}"');
          depth = 0;
        }
      }
    }
    if (depth != 0) errors.add('Unbalanced braces: $depth unclosed block(s)');

    // Quote balance (rough)
    final quotes = '"'.allMatches(src).length;
    if (quotes.isOdd) errors.add('Unbalanced double quotes');

    // Required provider for aws resources
    final resources = _parseAllFiles();
    final hasAwsResource = resources.any((r) => r.type.startsWith('aws_'));
    final hasProvider = RegExp(r'provider\s+"aws"').hasMatch(src);
    if (hasAwsResource && !hasProvider) {
      errors.add('Missing provider "aws" block required for aws_* resources');
    }

    // Resource block shape
    final broken = RegExp(r'resource\s+[^{]+\{').allMatches(src);
    for (final m in broken) {
      final head = m.group(0)!;
      if (!RegExp(r'resource\s+"[^"]+"\s+"[^"]+"\s*\{').hasMatch(head)) {
        errors.add('Invalid resource header near: ${head.trim()} (expected resource "type" "name" {)');
      }
    }

    // Unknown attribute type typos
    for (final r in resources) {
      if (r.type == 'aws_instance' && !r.attrs.containsKey('instance_type') && !r.attrs.containsKey('ami')) {
        errors.add('${r.address}: aws_instance typically requires ami and instance_type');
      }
      if (r.type == 'aws_vpc' && !r.attrs.containsKey('cidr_block')) {
        errors.add('${r.address}: aws_vpc requires cidr_block');
      }
      if (r.type == 'aws_s3_bucket' && !r.attrs.containsKey('bucket')) {
        errors.add('${r.address}: aws_s3_bucket requires bucket');
      }
    }

    if (errors.isNotEmpty) {
      return TfResult(
        ok: false,
        output: '╷\n│ Error: Configuration validation failed\n│\n'
            '${errors.map((e) => '│   - $e').join('\n')}\n╵\n',
        errors: errors,
      );
    }
    completedActions.add('tf_validate');
    return TfResult(
      ok: true,
      output: 'Success! The configuration is valid.\n'
          'Parsed ${resources.length} resource(s) across ${files.length} file(s).\n',
      resources: resources.map((r) => r.address).toList(),
    );
  }

  TfResult init() {
    initialized = true;
    completedActions.add('tf_init');
    return const TfResult(
      ok: true,
      output: 'Initializing the backend...\n\n'
          'Initializing provider plugins...\n'
          '- Finding hashicorp/aws versions matching "~> 5.0"...\n'
          '- Installing hashicorp/aws v5.40.0...\n'
          '- Installed hashicorp/aws v5.40.0 (signed by HashiCorp)\n\n'
          'Terraform has created a lock file .terraform.lock.hcl\n\n'
          'Terraform has been successfully initialized!\n',
    );
  }

  TfResult plan([String? hcl]) {
    if (!initialized) {
      return const TfResult(ok: false, output: 'Error: Run "terraform init" first');
    }
    final v = validate(hcl);
    if (!v.ok) return v;
    planned = _parseAllFiles();
    final buf = StringBuffer(
      'Terraform used the selected providers to generate the following execution plan.\n'
      'Resource actions are indicated with the following symbols:\n'
      '  + create\n\n'
      'Terraform will perform the following actions:\n\n',
    );
    var add = 0;
    for (final r in planned) {
      final key = r.address;
      if (!state.containsKey(key)) {
        add++;
        buf.writeln('  # $key will be created');
        buf.writeln('  + resource "${r.type}" "${r.name}" {');
        for (final e in r.attrs.entries) {
          buf.writeln('      + ${e.key.padRight(22)} = "${e.value}"');
        }
        buf.writeln('    }');
        buf.writeln();
      }
    }
    buf.writeln('Plan: $add to add, 0 to change, 0 to destroy.');
    lastPlan = buf.toString();
    completedActions.add('tf_plan');
    return TfResult(ok: true, output: lastPlan, resources: planned.map((r) => r.address).toList());
  }

  TfResult apply([String? hcl]) {
    final p = plan(hcl);
    if (!p.ok) return p;
    final created = <String>[];
    final out = StringBuffer();
    for (final r in planned) {
      final key = r.address;
      if (state.containsKey(key)) continue;
      out.writeln('$key: Creating...');
      final id = _applyResource(r);
      state[key] = id;
      created.add('$key');
      out.writeln('$key: Creation complete after 1s [id=$id]');
    }
    _rebuildVisual();
    completedActions.add('tf_apply');
    out.writeln();
    out.writeln('Apply complete! Resources: ${created.length} added, 0 changed, 0 destroyed.');
    if (created.isNotEmpty) {
      out.writeln('\nOutputs:\n');
      // fake outputs from outputs.tf
      if (state.keys.any((k) => k.startsWith('aws_vpc'))) {
        out.writeln('vpc_id = "${state.entries.firstWhere((e) => e.key.startsWith('aws_vpc')).value}"');
      }
    }
    return TfResult(ok: true, output: out.toString(), resources: created);
  }

  TfResult destroy() {
    final n = state.length;
    state.clear();
    visualNodes.clear();
    completedActions.add('tf_destroy');
    return TfResult(ok: true, output: 'Destroy complete! Resources: $n destroyed.\n');
  }

  TfResult show() {
    if (state.isEmpty) return const TfResult(ok: true, output: 'No state.');
    final buf = StringBuffer('# terraform.tfstate (cloudamned simulated)\n\n');
    for (final e in state.entries) {
      buf.writeln('resource "${e.key}" {');
      buf.writeln('  id = "${e.value}"');
      buf.writeln('}');
      buf.writeln();
    }
    return TfResult(ok: true, output: buf.toString());
  }

  void _rebuildVisual() {
    visualNodes = [];
    String? vpcId;
    for (final e in state.entries) {
      final type = e.key.split('.').first;
      final name = e.key.split('.').skip(1).join('.');
      if (type == 'aws_vpc') {
        vpcId = e.value;
        visualNodes.add(TfVisualNode(id: e.value, type: 'vpc', label: 'VPC $name'));
      } else if (type == 'aws_subnet') {
        visualNodes.add(TfVisualNode(
          id: e.value,
          type: 'subnet',
          label: 'Subnet $name',
          parentId: vpcId,
        ));
      } else if (type == 'aws_instance') {
        visualNodes.add(TfVisualNode(
          id: e.value,
          type: 'ec2',
          label: 'EC2 $name',
          parentId: vpcId,
        ));
      } else if (type == 'aws_s3_bucket') {
        visualNodes.add(TfVisualNode(id: e.value, type: 's3', label: 'S3 $name'));
      } else if (type == 'aws_security_group') {
        visualNodes.add(TfVisualNode(
          id: e.value,
          type: 'sg',
          label: 'SG $name',
          parentId: vpcId,
        ));
      } else if (type == 'aws_internet_gateway') {
        visualNodes.add(TfVisualNode(
          id: e.value,
          type: 'igw',
          label: 'IGW $name',
          parentId: vpcId,
        ));
      } else {
        visualNodes.add(TfVisualNode(id: e.value, type: type, label: '$type $name'));
      }
    }
  }

  String _applyResource(TfResource r) {
    switch (r.type) {
      case 'aws_vpc':
        final res = aws.createVpc(r.attrs['cidr_block'] ?? '10.0.0.0/16', name: r.name);
        return res.data?['vpcId'] as String? ?? 'vpc-sim';
      case 'aws_subnet':
        final vpcId = state.values.firstWhere(
          (v) => v.startsWith('vpc-'),
          orElse: () => aws.state.vpcs.isNotEmpty ? aws.state.vpcs.first.id : 'vpc-missing',
        );
        if (vpcId == 'vpc-missing' && aws.state.vpcs.isEmpty) {
          aws.createVpc('10.0.0.0/16', name: 'implicit');
        }
        final vid = aws.state.vpcs.first.id;
        final res = aws.createSubnet(
          vpcId: vid,
          cidr: r.attrs['cidr_block'] ?? '10.0.1.0/24',
          az: r.attrs['availability_zone'] ?? '${aws.region}a',
          mapPublicIpOnLaunch: r.attrs['map_public_ip_on_launch'] == 'true',
          name: r.name,
        );
        return res.data?['subnetId'] as String? ?? 'subnet-sim';
      case 'aws_internet_gateway':
        final res = aws.createInternetGateway();
        final igwId = res.data?['igwId'] as String? ?? 'igw-sim';
        if (aws.state.vpcs.isNotEmpty) {
          aws.attachInternetGateway(igwId: igwId, vpcId: aws.state.vpcs.first.id);
        }
        return igwId;
      case 'aws_instance':
        final res = aws.runInstances(
          instanceType: r.attrs['instance_type'] ?? 't3.micro',
          ami: r.attrs['ami'] ?? 'ami-0abcdef1234567890',
          name: r.name,
        );
        return res.data?['instanceId'] as String? ?? 'i-sim';
      case 'aws_s3_bucket':
        final name = r.attrs['bucket'] ?? 'cloudamned-${r.name}';
        aws.createBucket(name);
        return name;
      case 'aws_security_group':
        final vpcId = aws.state.vpcs.isNotEmpty ? aws.state.vpcs.first.id : null;
        if (vpcId == null) {
          aws.createVpc('10.0.0.0/16');
        }
        final res = aws.createSecurityGroup(
          name: r.name,
          description: r.attrs['description'] ?? 'managed by terraform',
          vpcId: aws.state.vpcs.first.id,
        );
        return res.data?['sgId'] as String? ?? 'sg-sim';
      default:
        return '${r.type.replaceAll('aws_', '')}-${r.name}-sim';
    }
  }

  List<TfResource> _parseAllFiles() {
    final resources = <TfResource>[];
    for (final entry in files.entries) {
      resources.addAll(_parseResources(entry.value, file: entry.key));
    }
    return resources;
  }

  List<TfResource> _parseResources(String hcl, {String file = 'main.tf'}) {
    final resources = <TfResource>[];
    // Support nested braces with a simple scanner
    final re = RegExp(r'resource\s+"([^"]+)"\s+"([^"]+)"\s*\{');
    for (final m in re.allMatches(hcl)) {
      final type = m.group(1)!;
      final name = m.group(2)!;
      final start = m.end;
      var depth = 1;
      var i = start;
      while (i < hcl.length && depth > 0) {
        if (hcl[i] == '{') depth++;
        if (hcl[i] == '}') depth--;
        i++;
      }
      final body = hcl.substring(start, i - 1);
      final attrs = <String, String>{};
      final attrRe = RegExp(r'([a-zA-Z0-9_]+)\s*=\s*"([^"]*)"');
      for (final a in attrRe.allMatches(body)) {
        attrs[a.group(1)!] = a.group(2)!;
      }
      final boolRe = RegExp(r'([a-zA-Z0-9_]+)\s*=\s*(true|false)');
      for (final a in boolRe.allMatches(body)) {
        attrs[a.group(1)!] = a.group(2)!;
      }
      resources.add(TfResource(type: type, name: name, attrs: attrs, file: file));
    }
    return resources;
  }

  static const sampleMain = '''
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "gw" {
}

resource "aws_security_group" "web" {
  description = "allow http and ssh"
}

resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

resource "aws_s3_bucket" "backups" {
  bucket = "cloudamned-backups-lab"
}
''';

  static const sampleVariables = '''
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
''';

  static const sampleOutputs = '''
output "vpc_id" {
  value = aws_vpc.main.id
}

output "web_instance_id" {
  value = aws_instance.web.id
}
''';

  /// Backward-compatible sample used by older UI.
  static const sampleHcl = sampleMain;
}
