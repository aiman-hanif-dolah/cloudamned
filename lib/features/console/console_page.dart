import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/aws/aws_engine.dart';

/// Full AWS Console clone — manual VPC → subnets → IGW → NAT → routes → SG → EC2 → EBS → S3.
class ConsolePage extends StatefulWidget {
  const ConsolePage({super.key});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  late final AwsEngine aws;
  String _service = 'VPC';
  final _log = <String>[];

  // Form controllers
  final _vpcCidr = TextEditingController(text: '10.0.0.0/16');
  final _vpcName = TextEditingController(text: 'prod-vpc');
  final _subnetCidr = TextEditingController(text: '10.0.1.0/24');
  final _subnetName = TextEditingController(text: 'public-a');
  final _az = TextEditingController(text: 'us-east-1a');
  final _bucket = TextEditingController(text: 'cloudamned-prod-backups');
  final _instanceName = TextEditingController(text: 'web-1');
  final _sgName = TextEditingController(text: 'web-sg');
  final _rtbName = TextEditingController(text: 'public-rt');
  String? _selectedVpc;
  String? _selectedSubnet;
  String? _selectedIgw;
  String? _selectedRtb;
  String? _selectedSg;
  String? _selectedInstance;
  String? _selectedEip;
  String? _selectedNat;
  bool _mapPublic = true;
  int _ebsSize = 20;

  @override
  void initState() {
    super.initState();
    aws = AppServices.instance.awsEngine;
    _log.add('AWS Management Console (cloudamned offline clone)');
    _log.add('Account ${aws.state.accountId} · ${aws.region}');
    _log.add('Mode: blank account — create resources exactly as in AWS.');
    _log.add(aws.summary().message);
  }

  void _act(String title, AwsResult Function() fn) {
    final r = fn();
    setState(() {
      _log.add('');
      _log.add('── $title ──');
      _log.add(r.message);
      if (!r.ok) _log.add('✗ Request failed');
      // refresh selections
      _selectedVpc ??= aws.state.vpcs.lastOrNull?.id;
      _selectedSubnet ??= aws.state.subnets.lastOrNull?.id;
      _selectedIgw ??= aws.state.igws.lastOrNull?.id;
      _selectedRtb ??= aws.state.routeTables.lastOrNull?.id;
      _selectedSg ??= aws.state.securityGroups.lastOrNull?.id;
      _selectedInstance ??= aws.state.instances.lastOrNull?.id;
      _selectedEip ??= aws.state.elasticIps.lastOrNull?.allocationId;
      _selectedNat ??= aws.state.natGateways.lastOrNull?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 11.5, height: 1.35);
    final checklist = aws.vpcBuildChecklist();
    final done = checklist.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'AWS Console',
            subtitle: 'Manual control plane · VPC · Subnets · IGW · NAT · Routes · SG · EC2 · EBS · S3',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadBadge(label: '$done/${checklist.length} build steps', variant: ShadBadgeVariant.success),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () => setState(() {
                    aws.resetBlank();
                    _log
                      ..clear()
                      ..add('Account reset to blank. Build VPC from scratch.');
                  }),
                  child: const Text('Blank account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // Service nav
                SizedBox(
                  width: 168,
                  child: ShadPanel(
                    title: 'Services',
                    child: ListView(
                      children: [
                        for (final s in [
                          'VPC',
                          'Subnets',
                          'Internet Gateway',
                          'NAT Gateway',
                          'Route Tables',
                          'Security Groups',
                          'EC2',
                          'EBS',
                          'S3',
                          'CloudWatch',
                          'Checklist',
                          'Topology',
                          'CloudTrail',
                        ])
                          ListTile(
                            dense: true,
                            selected: _service == s,
                            selectedTileColor: ShadcnColors.sidebarAccent,
                            title: Text(s, style: const TextStyle(fontSize: 12)),
                            onTap: () => setState(() => _service = s),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Main work area
                Expanded(
                  flex: 3,
                  child: ShadPanel(
                    title: '$_service · ${aws.region}',
                    child: ListView(
                      padding: const EdgeInsets.all(14),
                      children: _buildServiceBody(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Output
                Expanded(
                  flex: 2,
                  child: ShadPanel(
                    title: 'API response / CloudTrail',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => setState(() => _log.clear()),
                      ),
                    ],
                    child: Container(
                      color: ShadcnColors.terminalBg,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _log.length,
                        itemBuilder: (_, i) => SelectableText(
                          _log[i],
                          style: mono.copyWith(
                            color: _log[i].startsWith('✗') || _log[i].contains('Error') || _log[i].contains('Invalid')
                                ? ShadcnColors.terminalRed
                                : ShadcnColors.terminalFg,
                          ),
                        ),
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

  List<Widget> _buildServiceBody() {
    switch (_service) {
      case 'VPC':
        return [
          _h('Create VPC'),
          _field('Name tag', _vpcName),
          _field('IPv4 CIDR', _vpcCidr),
          const SizedBox(height: 8),
          ShadButton(
            onPressed: () => _act('CreateVpc', () => aws.createVpc(_vpcCidr.text, name: _vpcName.text)),
            child: const Text('Create VPC'),
          ),
          const SizedBox(height: 16),
          _h('Your VPCs'),
          ...aws.state.vpcs.map((v) => _row('${v.id}  ${v.cidr}  ${v.name}')),
          if (aws.state.vpcs.isEmpty) _muted('No VPCs — create one to continue.'),
        ];
      case 'Subnets':
        return [
          _h('Create subnet'),
          _dropdownVpc(),
          _field('Name', _subnetName),
          _field('CIDR', _subnetCidr),
          _field('AZ', _az),
          SwitchListTile(
            dense: true,
            title: const Text('Map public IP on launch', style: TextStyle(fontSize: 12)),
            value: _mapPublic,
            onChanged: (v) => setState(() => _mapPublic = v),
          ),
          ShadButton(
            onPressed: () {
              final vpc = _selectedVpc ?? aws.state.vpcs.lastOrNull?.id;
              if (vpc == null) {
                _log.add('Create a VPC first');
                setState(() {});
                return;
              }
              _act(
                'CreateSubnet',
                () => aws.createSubnet(
                  vpcId: vpc,
                  cidr: _subnetCidr.text,
                  az: _az.text,
                  mapPublicIpOnLaunch: _mapPublic,
                  name: _subnetName.text,
                ),
              );
            },
            child: const Text('Create subnet'),
          ),
          const SizedBox(height: 12),
          ShadButton(
            size: ShadButtonSize.sm,
            variant: ShadButtonVariant.secondary,
            onPressed: () {
              _subnetCidr.text = '10.0.2.0/24';
              _subnetName.text = 'private-a';
              _mapPublic = false;
              setState(() {});
            },
            child: const Text('Preset: private 10.0.2.0/24'),
          ),
          const SizedBox(height: 16),
          _h('Subnets'),
          ...aws.state.subnets.map(
            (s) => _row('${s.id}  ${s.cidr}  ${s.isPublic ? 'PUBLIC' : 'PRIVATE'}  ${s.name}'),
          ),
        ];
      case 'Internet Gateway':
        return [
          _h('Create & attach Internet Gateway'),
          ShadButton(
            onPressed: () => _act('CreateInternetGateway', () => aws.createInternetGateway()),
            child: const Text('Create Internet Gateway'),
          ),
          const SizedBox(height: 12),
          _dropdownVpc(),
          _dropdown(
            'Internet Gateway',
            aws.state.igws.map((g) => g.id).toList(),
            _selectedIgw,
            (v) => setState(() => _selectedIgw = v),
          ),
          const SizedBox(height: 8),
          ShadButton(
            onPressed: () {
              final igw = _selectedIgw ?? aws.state.igws.lastOrNull?.id;
              final vpc = _selectedVpc ?? aws.state.vpcs.lastOrNull?.id;
              if (igw == null || vpc == null) return;
              _act('AttachInternetGateway', () => aws.attachInternetGateway(igwId: igw, vpcId: vpc));
            },
            child: const Text('Attach to VPC'),
          ),
          const SizedBox(height: 16),
          ...aws.state.igws.map((g) => _row('${g.id}  vpc=${g.vpcId ?? '-'}  ${g.state}')),
        ];
      case 'NAT Gateway':
        return [
          _h('Allocate Elastic IP → Create NAT in public subnet'),
          ShadButton(
            onPressed: () => _act('AllocateAddress', aws.allocateAddress),
            child: const Text('Allocate Elastic IP'),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'Elastic IP allocation',
            aws.state.elasticIps.map((e) => e.allocationId).toList(),
            _selectedEip,
            (v) => setState(() => _selectedEip = v),
          ),
          _dropdown(
            'Public subnet',
            aws.state.subnets.where((s) => s.isPublic).map((s) => s.id).toList(),
            _selectedSubnet,
            (v) => setState(() => _selectedSubnet = v),
          ),
          const SizedBox(height: 8),
          ShadButton(
            onPressed: () {
              final subnet = _selectedSubnet ??
                  aws.state.subnets.where((s) => s.isPublic).map((s) => s.id).firstOrNull;
              final eip = _selectedEip ?? aws.state.elasticIps.lastOrNull?.allocationId;
              if (subnet == null || eip == null) {
                _log.add('Need public subnet + Elastic IP');
                setState(() {});
                return;
              }
              _act(
                'CreateNatGateway',
                () => aws.createNatGateway(subnetId: subnet, allocationId: eip),
              );
            },
            child: const Text('Create NAT Gateway'),
          ),
          const SizedBox(height: 16),
          ...aws.state.natGateways.map((n) => _row('${n.id}  subnet=${n.subnetId}  ${n.state}')),
        ];
      case 'Route Tables':
        return [
          _h('Create route table'),
          _dropdownVpc(),
          _field('Name', _rtbName),
          ShadButton(
            onPressed: () {
              final vpc = _selectedVpc ?? aws.state.vpcs.lastOrNull?.id;
              if (vpc == null) return;
              _act('CreateRouteTable', () => aws.createRouteTable(vpcId: vpc, name: _rtbName.text));
            },
            child: const Text('Create route table'),
          ),
          const SizedBox(height: 16),
          _h('Add route 0.0.0.0/0'),
          _dropdown(
            'Route table',
            aws.state.routeTables.map((r) => r.id).toList(),
            _selectedRtb,
            (v) => setState(() => _selectedRtb = v),
          ),
          _dropdown(
            'Target IGW',
            aws.state.igws.map((g) => g.id).toList(),
            _selectedIgw,
            (v) => setState(() => _selectedIgw = v),
          ),
          ShadButton(
            size: ShadButtonSize.sm,
            onPressed: () {
              final rtb = _selectedRtb ?? aws.state.routeTables.lastOrNull?.id;
              final igw = _selectedIgw ?? aws.state.igws.where((g) => g.vpcId != null).map((g) => g.id).firstOrNull;
              if (rtb == null || igw == null) return;
              _act(
                'CreateRoute→IGW',
                () => aws.createRoute(routeTableId: rtb, destinationCidr: '0.0.0.0/0', gatewayId: igw),
              );
            },
            child: const Text('Route 0.0.0.0/0 → IGW'),
          ),
          const SizedBox(height: 8),
          _dropdown(
            'Target NAT',
            aws.state.natGateways.map((n) => n.id).toList(),
            _selectedNat,
            (v) => setState(() => _selectedNat = v),
          ),
          ShadButton(
            size: ShadButtonSize.sm,
            variant: ShadButtonVariant.secondary,
            onPressed: () {
              final rtb = _selectedRtb ?? aws.state.routeTables.lastOrNull?.id;
              final nat = _selectedNat ?? aws.state.natGateways.lastOrNull?.id;
              if (rtb == null || nat == null) return;
              _act(
                'CreateRoute→NAT',
                () => aws.createRoute(routeTableId: rtb, destinationCidr: '0.0.0.0/0', natGatewayId: nat),
              );
            },
            child: const Text('Route 0.0.0.0/0 → NAT'),
          ),
          const SizedBox(height: 16),
          _h('Associate with subnet'),
          _dropdown(
            'Subnet',
            aws.state.subnets.map((s) => s.id).toList(),
            _selectedSubnet,
            (v) => setState(() => _selectedSubnet = v),
          ),
          ShadButton(
            onPressed: () {
              final rtb = _selectedRtb ?? aws.state.routeTables.lastOrNull?.id;
              final sn = _selectedSubnet ?? aws.state.subnets.lastOrNull?.id;
              if (rtb == null || sn == null) return;
              _act('AssociateRouteTable', () => aws.associateRouteTable(routeTableId: rtb, subnetId: sn));
            },
            child: const Text('Associate route table'),
          ),
          const SizedBox(height: 16),
          ShadButton(
            variant: ShadButtonVariant.outline,
            onPressed: () => _act('DescribeRouteTables', aws.describeRouteTables),
            child: const Text('Describe route tables'),
          ),
        ];
      case 'Security Groups':
        return [
          _h('Create security group'),
          _dropdownVpc(),
          _field('Name', _sgName),
          ShadButton(
            onPressed: () {
              final vpc = _selectedVpc ?? aws.state.vpcs.lastOrNull?.id;
              if (vpc == null) return;
              _act(
                'CreateSecurityGroup',
                () => aws.createSecurityGroup(
                  name: _sgName.text,
                  description: 'managed in cloudamned console',
                  vpcId: vpc,
                ),
              );
            },
            child: const Text('Create security group'),
          ),
          const SizedBox(height: 16),
          _h('Inbound rules'),
          _dropdown(
            'Security group',
            aws.state.securityGroups.map((g) => g.id).toList(),
            _selectedSg,
            (v) => setState(() => _selectedSg = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () => _sgRule(22),
                child: const Text('Allow SSH 22'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () => _sgRule(80),
                child: const Text('Allow HTTP 80'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: () => _sgRule(443),
                child: const Text('Allow HTTPS 443'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShadButton(
            variant: ShadButtonVariant.outline,
            onPressed: () => _act('DescribeSecurityGroups', aws.describeSecurityGroups),
            child: const Text('Describe security groups'),
          ),
        ];
      case 'EC2':
        return [
          _h('Launch instance'),
          _field('Name', _instanceName),
          _dropdown(
            'Subnet',
            aws.state.subnets.map((s) => '${s.id} (${s.isPublic ? 'public' : 'private'})').toList(),
            _selectedSubnet == null
                ? null
                : aws.state.subnets
                    .where((s) => s.id == _selectedSubnet)
                    .map((s) => '${s.id} (${s.isPublic ? 'public' : 'private'})')
                    .firstOrNull,
            (v) => setState(() => _selectedSubnet = v?.split(' ').first),
          ),
          _dropdown(
            'Security group',
            aws.state.securityGroups.map((g) => g.id).toList(),
            _selectedSg,
            (v) => setState(() => _selectedSg = v),
          ),
          const SizedBox(height: 8),
          ShadButton(
            onPressed: () {
              final subnet = _selectedSubnet ?? aws.state.subnets.lastOrNull?.id;
              final sg = _selectedSg ?? aws.state.securityGroups.lastOrNull?.id;
              _act(
                'RunInstances',
                () => aws.runInstances(
                  name: _instanceName.text,
                  subnetId: subnet,
                  securityGroupIds: sg == null ? null : [sg],
                ),
              );
            },
            child: const Text('Launch t3.micro'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.secondary,
                onPressed: () => _act('DescribeInstances', aws.describeInstances),
                child: const Text('Describe'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  final id = aws.state.instances.lastOrNull?.id;
                  if (id == null) return;
                  _act('TestSSH', () => aws.testSsh(id));
                },
                child: const Text('Test SSH'),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  final id = aws.state.instances.lastOrNull?.id;
                  if (id == null) return;
                  _act('ProbeHTTP', () => aws.probeHttp(id));
                },
                child: const Text('Probe HTTP'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...aws.state.instances.map(
            (i) => _row('${i.id}  ${i.state}  ${i.publicIp ?? i.privateIp}  ${i.name}'),
          ),
        ];
      case 'EBS':
        return [
          _h('Create volume'),
          Row(
            children: [
              const Text('Size GiB: ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _ebsSize.toDouble(),
                  min: 8,
                  max: 100,
                  divisions: 92,
                  label: '$_ebsSize',
                  onChanged: (v) => setState(() => _ebsSize = v.round()),
                ),
              ),
              Text('$_ebsSize', style: const TextStyle(fontSize: 12)),
            ],
          ),
          ShadButton(
            onPressed: () => _act('CreateVolume', () => aws.createVolume(sizeGiB: _ebsSize)),
            child: const Text('Create volume'),
          ),
          const SizedBox(height: 12),
          ShadButton(
            variant: ShadButtonVariant.secondary,
            onPressed: () {
              final vol = aws.state.volumes.lastOrNull?.id;
              final inst = aws.state.instances.lastOrNull?.id;
              if (vol == null || inst == null) {
                _log.add('Need volume + instance');
                setState(() {});
                return;
              }
              _act('AttachVolume', () => aws.attachVolume(volumeId: vol, instanceId: inst));
            },
            child: const Text('Attach last volume → last instance'),
          ),
          const SizedBox(height: 16),
          ...aws.state.volumes.map((v) => _row('${v.id}  ${v.sizeGiB}GiB  ${v.state}  ${v.instanceId ?? ''}')),
        ];
      case 'S3':
        return [
          _h('Create bucket'),
          _field('Bucket name', _bucket),
          ShadButton(
            onPressed: () => _act('CreateBucket', () => aws.createBucket(_bucket.text)),
            child: const Text('Create bucket'),
          ),
          const SizedBox(height: 8),
          ShadButton(
            variant: ShadButtonVariant.secondary,
            onPressed: () => _act(
              'PutObject',
              () => aws.putObject(_bucket.text, 'backups/server-backup.img', 'simulated-backup'),
            ),
            child: const Text('Upload backup object'),
          ),
          const SizedBox(height: 16),
          ...aws.state.buckets.map((b) => _row('s3://${b.name}  objects=${b.objects.length}')),
        ];
      case 'CloudWatch':
        return [
          ShadButton(
            onPressed: () => _act('GetLogEvents', () => aws.getLogEvents()),
            child: const Text('Get log events'),
          ),
          const SizedBox(height: 8),
          ShadButton(
            variant: ShadButtonVariant.secondary,
            onPressed: () => _act(
              'PutMetricAlarm',
              () => aws.putMetricAlarm(name: 'high-cpu', metric: 'CPUUtilization', threshold: 80),
            ),
            child: const Text('Create CPU alarm'),
          ),
          const SizedBox(height: 16),
          ...aws.state.alarms.map((a) => _row('${a.name}  ${a.metric}  ${a.state}')),
        ];
      case 'Checklist':
        final cl = aws.vpcBuildChecklist();
        return [
          _h('Production VPC build checklist'),
          const Text(
            'Create each resource manually — same order as real AWS.',
            style: TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          for (final e in cl.entries)
            ListTile(
              dense: true,
              leading: Icon(
                e.value ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: e.value ? ShadcnColors.success : ShadcnColors.mutedForeground,
              ),
              title: Text(e.key, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 12),
          ShadButton(
            variant: ShadButtonVariant.outline,
            onPressed: () => _act('Summary', aws.summary),
            child: const Text('Account summary'),
          ),
        ];
      case 'Topology':
        final nodes = aws.topologyNodes();
        return [
          _h('Infrastructure topology'),
          if (nodes.isEmpty) _muted('No resources yet.'),
          for (final n in nodes)
            Padding(
              padding: EdgeInsets.only(left: n['parent'] != null ? 16.0 : 0, bottom: 6),
              child: Row(
                children: [
                  Icon(_topoIcon(n['type']!), size: 16, color: ShadcnColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${n['type']}: ${n['label']}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
        ];
      case 'CloudTrail':
        return [
          for (final e in aws.state.cloudTrailEvents.take(50))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(e, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
        ];
      default:
        return [_muted('Select a service')];
    }
  }

  void _sgRule(int port) {
    final sg = _selectedSg ?? aws.state.securityGroups.lastOrNull?.id;
    if (sg == null) return;
    _act(
      'AuthorizeSecurityGroupIngress :$port',
      () => aws.authorizeSecurityGroupIngress(
        groupId: sg,
        protocol: 'tcp',
        fromPort: port,
        toPort: port,
        cidr: '0.0.0.0/0',
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _field(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
            const SizedBox(height: 4),
            ShadInput(controller: c),
          ],
        ),
      );

  Widget _row(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
      );

  Widget _muted(String t) => Text(t, style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground));

  Widget _dropdownVpc() => _dropdown(
        'VPC',
        aws.state.vpcs.map((v) => v.id).toList(),
        _selectedVpc,
        (v) => setState(() => _selectedVpc = v),
      );

  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('No $label available yet', style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
      );
    }
    final v = value != null && items.contains(value) ? value : items.last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
          DropdownButton<String>(
            isExpanded: true,
            value: v,
            dropdownColor: ShadcnColors.card,
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _topoIcon(String type) => switch (type) {
        'vpc' => Icons.cloud,
        'public_subnet' || 'private_subnet' || 'subnet' => Icons.lan,
        'igw' => Icons.public,
        'nat' => Icons.swap_horiz,
        'ec2' => Icons.memory,
        's3' => Icons.folder_outlined,
        _ => Icons.circle,
      };
}
