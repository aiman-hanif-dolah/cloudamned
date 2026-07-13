import 'aws_state.dart';

class AwsResult {
  const AwsResult({required this.ok, required this.message, this.data});
  final bool ok;
  final String message;
  final Map<String, dynamic>? data;
}

/// Offline AWS control-plane simulation — full console clone workflows.
class AwsEngine {
  AwsEngine({AwsState? state, bool seedDefaults = false}) : state = state ?? AwsState() {
    if (seedDefaults) {
      this.state.seedDefaults();
    } else {
      // Console clone starts blank so users build VPC manually.
      this.state.seedBlankAccount();
    }
  }

  final AwsState state;
  final Set<String> completedActions = {};

  void resetBlank() {
    completedActions.clear();
    state.seedBlankAccount();
  }

  void resetDefaults() {
    completedActions.clear();
    state.clearAll();
    state.seedDefaults();
  }

  // ── IAM ──────────────────────────────────────────────────────────────────
  AwsResult createUser(String name) {
    if (state.users.any((u) => u.name == name)) {
      return AwsResult(ok: false, message: 'EntityAlreadyExists: User $name already exists');
    }
    state.users.add(IamUser(name: name));
    state.trail('iam:CreateUser name=$name');
    completedActions.add('iam_user');
    return AwsResult(
      ok: true,
      message: 'User created\n'
          'UserName: $name\n'
          'Arn: arn:aws:iam::${state.accountId}:user/$name\n'
          'CreateDate: ${DateTime.now().toUtc()}',
    );
  }

  AwsResult attachUserPolicy(String user, String policyArn) {
    final u = state.users.where((e) => e.name == user).firstOrNull;
    if (u == null) return AwsResult(ok: false, message: 'NoSuchEntity: User $user');
    u.policies = [...u.policies, policyArn];
    state.trail('iam:AttachUserPolicy user=$user policy=$policyArn');
    completedActions.add('iam_policy_attached');
    return AwsResult(ok: true, message: 'Policy attached to $user');
  }

  AwsResult createRole(String name, {String trust = 'ec2.amazonaws.com'}) {
    state.roles.add(IamRole(
      name: name,
      trust:
          '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"$trust"},"Action":"sts:AssumeRole"}]}',
    ));
    state.trail('iam:CreateRole name=$name');
    return AwsResult(
      ok: true,
      message: 'Role created\nArn: arn:aws:iam::${state.accountId}:role/$name',
    );
  }

  AwsResult createKeyPair(String name) {
    if (state.keyPairs.any((k) => k.name == name)) {
      return AwsResult(ok: false, message: 'InvalidKeyPair.Duplicate: $name');
    }
    state.keyPairs.add(KeyPair(name: name, fingerprint: 'aa:bb:cc:dd:ee:ff'));
    state.trail('ec2:CreateKeyPair name=$name');
    completedActions.add('key_pair');
    return AwsResult(
      ok: true,
      message: 'KeyName: $name\nKeyFingerprint: aa:bb:cc:dd:ee:ff\n'
          '-----BEGIN RSA PRIVATE KEY-----\n(simulated material)\n-----END RSA PRIVATE KEY-----',
    );
  }

  // ── VPC ──────────────────────────────────────────────────────────────────
  AwsResult createVpc(String cidr, {String name = ''}) {
    if (!_validCidr(cidr)) {
      return AwsResult(ok: false, message: 'InvalidParameterValue: CIDR $cidr is invalid');
    }
    final vpc = Vpc(id: state.id('vpc'), cidr: cidr, name: name);
    state.vpcs.add(vpc);
    // Main route table created automatically (AWS behavior)
    final mainRtb = RouteTable(
      id: state.id('rtb'),
      vpcId: vpc.id,
      name: 'main',
      routes: [Route(destination: cidr, target: 'local')],
    );
    state.routeTables.add(mainRtb);
    // Default SG
    state.securityGroups.add(SecurityGroup(
      id: state.id('sg'),
      vpcId: vpc.id,
      name: 'default',
      description: 'default VPC security group',
      ingress: [],
      egress: [SgRule(protocol: '-1', fromPort: 0, toPort: 0, cidr: '0.0.0.0/0')],
    ));
    state.trail('ec2:CreateVpc cidr=$cidr name=$name');
    completedActions.add('vpc_created');
    return AwsResult(
      ok: true,
      message: 'VpcId: ${vpc.id}\nCidrBlock: $cidr\nState: available\n'
          'MainRouteTable: ${mainRtb.id}\nDefaultSecurityGroup: ${state.securityGroups.last.id}',
      data: {'vpcId': vpc.id, 'rtbId': mainRtb.id, 'sgId': state.securityGroups.last.id},
    );
  }

  AwsResult createSubnet({
    required String vpcId,
    required String cidr,
    required String az,
    bool mapPublicIpOnLaunch = false,
    String name = '',
  }) {
    final vpc = state.vpcs.where((v) => v.id == vpcId).firstOrNull;
    if (vpc == null) {
      return AwsResult(ok: false, message: 'InvalidVpcID.NotFound: $vpcId');
    }
    if (!_validCidr(cidr)) {
      return AwsResult(ok: false, message: 'InvalidParameterValue: CIDR $cidr is invalid');
    }
    final sn = Subnet(
      id: state.id('subnet'),
      vpcId: vpcId,
      cidr: cidr,
      az: az,
      isPublic: mapPublicIpOnLaunch,
      mapPublicIpOnLaunch: mapPublicIpOnLaunch,
      name: name,
    );
    state.subnets.add(sn);
    state.trail('ec2:CreateSubnet vpc=$vpcId cidr=$cidr az=$az');
    completedActions.add('subnet_created');
    if (mapPublicIpOnLaunch) {
      completedActions.add('public_subnet');
    } else {
      completedActions.add('private_subnet');
    }
    return AwsResult(
      ok: true,
      message: 'SubnetId: ${sn.id}\nCidrBlock: $cidr\nAvailabilityZone: $az\n'
          'MapPublicIpOnLaunch: $mapPublicIpOnLaunch\nVpcId: $vpcId',
      data: {'subnetId': sn.id},
    );
  }

  AwsResult createInternetGateway({String name = ''}) {
    final igw = InternetGateway(id: state.id('igw'), state: 'available');
    state.igws.add(igw);
    state.trail('ec2:CreateInternetGateway');
    completedActions.add('igw_created');
    return AwsResult(
      ok: true,
      message: 'InternetGatewayId: ${igw.id}\nState: available',
      data: {'igwId': igw.id},
    );
  }

  AwsResult attachInternetGateway({required String igwId, required String vpcId}) {
    final igw = state.igws.where((g) => g.id == igwId).firstOrNull;
    if (igw == null) return AwsResult(ok: false, message: 'InvalidInternetGatewayID.NotFound: $igwId');
    if (!state.vpcs.any((v) => v.id == vpcId)) {
      return AwsResult(ok: false, message: 'InvalidVpcID.NotFound: $vpcId');
    }
    if (igw.vpcId != null) {
      return AwsResult(ok: false, message: 'Resource.AlreadyAssociated: IGW already attached');
    }
    igw.vpcId = vpcId;
    igw.state = 'attached';
    state.trail('ec2:AttachInternetGateway igw=$igwId vpc=$vpcId');
    completedActions.add('igw_attached');
    return AwsResult(ok: true, message: 'InternetGateway $igwId attached to $vpcId');
  }

  AwsResult allocateAddress() {
    final eip = ElasticIp(
      allocationId: state.id('eipalloc'),
      publicIp: '54.${20 + state.elasticIps.length}.${10 + state.elasticIps.length}.44',
    );
    state.elasticIps.add(eip);
    state.trail('ec2:AllocateAddress allocationId=${eip.allocationId}');
    completedActions.add('eip_allocated');
    return AwsResult(
      ok: true,
      message: 'AllocationId: ${eip.allocationId}\nPublicIp: ${eip.publicIp}\nDomain: vpc',
      data: {'allocationId': eip.allocationId, 'publicIp': eip.publicIp},
    );
  }

  AwsResult createNatGateway({required String subnetId, required String allocationId}) {
    final subnet = state.subnets.where((s) => s.id == subnetId).firstOrNull;
    if (subnet == null) return AwsResult(ok: false, message: 'InvalidSubnetID.NotFound: $subnetId');
    final eip = state.elasticIps.where((e) => e.allocationId == allocationId).firstOrNull;
    if (eip == null) {
      return AwsResult(ok: false, message: 'InvalidAllocationID.NotFound: $allocationId');
    }
    final nat = NatGateway(
      id: state.id('nat'),
      subnetId: subnetId,
      allocationId: allocationId,
      state: 'available',
    );
    state.natGateways.add(nat);
    eip.associationId = nat.id;
    state.trail('ec2:CreateNatGateway nat=${nat.id} subnet=$subnetId');
    completedActions.add('nat_created');
    return AwsResult(
      ok: true,
      message: 'NatGatewayId: ${nat.id}\nSubnetId: $subnetId\nState: available\n'
          'PublicIp: ${eip.publicIp}',
      data: {'natId': nat.id},
    );
  }

  AwsResult createRouteTable({required String vpcId, String name = ''}) {
    if (!state.vpcs.any((v) => v.id == vpcId)) {
      return AwsResult(ok: false, message: 'InvalidVpcID.NotFound: $vpcId');
    }
    final vpc = state.vpcs.firstWhere((v) => v.id == vpcId);
    final rtb = RouteTable(
      id: state.id('rtb'),
      vpcId: vpcId,
      name: name,
      routes: [Route(destination: vpc.cidr, target: 'local')],
    );
    state.routeTables.add(rtb);
    state.trail('ec2:CreateRouteTable vpc=$vpcId');
    completedActions.add('rtb_created');
    return AwsResult(
      ok: true,
      message: 'RouteTableId: ${rtb.id}\nVpcId: $vpcId',
      data: {'rtbId': rtb.id},
    );
  }

  AwsResult createRoute({
    required String routeTableId,
    required String destinationCidr,
    String? gatewayId,
    String? natGatewayId,
  }) {
    final rtb = state.routeTables.where((r) => r.id == routeTableId).firstOrNull;
    if (rtb == null) {
      return AwsResult(ok: false, message: 'InvalidRouteTableID.NotFound: $routeTableId');
    }
    final target = gatewayId ?? natGatewayId;
    if (target == null) {
      return AwsResult(ok: false, message: 'MissingParameter: GatewayId or NatGatewayId required');
    }
    if (gatewayId != null && !state.igws.any((g) => g.id == gatewayId)) {
      return AwsResult(ok: false, message: 'InvalidGatewayID.NotFound: $gatewayId');
    }
    if (natGatewayId != null && !state.natGateways.any((n) => n.id == natGatewayId)) {
      return AwsResult(ok: false, message: 'InvalidNatGatewayID.NotFound: $natGatewayId');
    }
    rtb.routes.removeWhere((r) => r.destination == destinationCidr);
    rtb.routes.add(Route(destination: destinationCidr, target: target));
    state.trail('ec2:CreateRoute rtb=$routeTableId dest=$destinationCidr target=$target');
    if (gatewayId != null) completedActions.add('route_igw');
    if (natGatewayId != null) completedActions.add('route_nat');
    return AwsResult(
      ok: true,
      message: 'Return: true\nRoute: $destinationCidr → $target',
    );
  }

  AwsResult associateRouteTable({required String routeTableId, required String subnetId}) {
    if (!state.routeTables.any((r) => r.id == routeTableId)) {
      return AwsResult(ok: false, message: 'InvalidRouteTableID.NotFound: $routeTableId');
    }
    if (!state.subnets.any((s) => s.id == subnetId)) {
      return AwsResult(ok: false, message: 'InvalidSubnetID.NotFound: $subnetId');
    }
    state.rtbAssociations.removeWhere((a) => a.subnetId == subnetId);
    final assoc = RouteTableAssociation(
      id: state.id('rtbassoc'),
      routeTableId: routeTableId,
      subnetId: subnetId,
    );
    state.rtbAssociations.add(assoc);
    // Mark subnet public if RT points to IGW
    final rtb = state.routeTables.firstWhere((r) => r.id == routeTableId);
    final hasIgw = rtb.routes.any((r) => r.destination == '0.0.0.0/0' && r.target.startsWith('igw-'));
    final subnet = state.subnets.firstWhere((s) => s.id == subnetId);
    if (hasIgw) subnet.isPublic = true;
    state.trail('ec2:AssociateRouteTable rtb=$routeTableId subnet=$subnetId');
    completedActions.add('rtb_associated');
    return AwsResult(ok: true, message: 'AssociationId: ${assoc.id}');
  }

  AwsResult createSecurityGroup({
    required String name,
    required String description,
    required String vpcId,
  }) {
    if (!state.vpcs.any((v) => v.id == vpcId)) {
      return AwsResult(ok: false, message: 'InvalidVpcID.NotFound: $vpcId');
    }
    if (state.securityGroups.any((g) => g.name == name && g.vpcId == vpcId)) {
      return AwsResult(ok: false, message: 'InvalidGroup.Duplicate: $name');
    }
    final sg = SecurityGroup(
      id: state.id('sg'),
      vpcId: vpcId,
      name: name,
      description: description,
      ingress: [],
      egress: [SgRule(protocol: '-1', fromPort: 0, toPort: 0, cidr: '0.0.0.0/0')],
    );
    state.securityGroups.add(sg);
    state.trail('ec2:CreateSecurityGroup name=$name vpc=$vpcId');
    completedActions.add('sg_created');
    return AwsResult(
      ok: true,
      message: 'GroupId: ${sg.id}\nGroupName: $name',
      data: {'sgId': sg.id},
    );
  }

  AwsResult authorizeSecurityGroupIngress({
    required String groupId,
    required String protocol,
    required int fromPort,
    required int toPort,
    required String cidr,
  }) {
    final sg = state.securityGroups.where((g) => g.id == groupId).firstOrNull;
    if (sg == null) return AwsResult(ok: false, message: 'InvalidGroup.NotFound: $groupId');
    sg.ingress.add(SgRule(protocol: protocol, fromPort: fromPort, toPort: toPort, cidr: cidr));
    state.trail('ec2:AuthorizeSecurityGroupIngress sg=$groupId $protocol $fromPort-$toPort $cidr');
    if (fromPort == 22) completedActions.add('sg_ssh');
    if (fromPort == 80) completedActions.add('sg_http');
    if (fromPort == 443) completedActions.add('sg_https');
    // Incident fix path
    if (state.activeIncidentId == 'website-down' && fromPort == 80) {
      completedActions.add('incident_sg_fixed');
      _recheckIncident();
    }
    return AwsResult(
      ok: true,
      message: 'Ingress rule added: $protocol $fromPort-$toPort from $cidr',
    );
  }

  AwsResult revokeSecurityGroupIngress({
    required String groupId,
    required int fromPort,
  }) {
    final sg = state.securityGroups.where((g) => g.id == groupId).firstOrNull;
    if (sg == null) return AwsResult(ok: false, message: 'InvalidGroup.NotFound: $groupId');
    sg.ingress.removeWhere((r) => r.fromPort == fromPort);
    state.trail('ec2:RevokeSecurityGroupIngress sg=$groupId port=$fromPort');
    return AwsResult(ok: true, message: 'Ingress rule revoked for port $fromPort');
  }

  // ── EC2 ──────────────────────────────────────────────────────────────────
  AwsResult runInstances({
    String ami = 'ami-0abcdef1234567890',
    String instanceType = 't3.micro',
    String? subnetId,
    List<String>? securityGroupIds,
    String? keyName,
    String name = 'web-1',
    String userData = '',
  }) {
    if (state.subnets.isEmpty) {
      return AwsResult(
        ok: false,
        message: 'InvalidSubnetID.NotFound: Create a subnet before launching instances',
      );
    }
    final subnet = subnetId != null
        ? state.subnets.where((s) => s.id == subnetId).firstOrNull
        : state.subnets.where((s) => s.isPublic).firstOrNull ?? state.subnets.first;
    if (subnet == null) {
      return AwsResult(ok: false, message: 'InvalidSubnetID.NotFound');
    }
    final sgs = securityGroupIds ??
        state.securityGroups.where((g) => g.vpcId == subnet.vpcId).map((g) => g.id).take(1).toList();
    if (sgs.isEmpty) {
      return AwsResult(ok: false, message: 'InvalidGroup.NotFound: no security group in VPC');
    }
    final idx = state.instances.length + 10;
    final parts = subnet.cidr.split('/')[0].split('.');
    final privateIp = '${parts[0]}.${parts[1]}.${parts[2]}.$idx';
    final assignPublic = subnet.isPublic || subnet.mapPublicIpOnLaunch;
    final inst = Ec2Instance(
      id: state.id('i'),
      instanceType: instanceType,
      ami: ami,
      state: 'running',
      subnetId: subnet.id,
      vpcId: subnet.vpcId,
      securityGroupIds: List.from(sgs),
      privateIp: privateIp,
      publicIp: assignPublic ? '54.89.${idx}.12' : null,
      keyName: keyName ?? state.keyPairs.firstOrNull?.name,
      name: name,
      userData: userData,
      nginxRunning: userData.toLowerCase().contains('nginx'),
    );
    state.instances.add(inst);
    state.trail('ec2:RunInstances id=${inst.id} type=$instanceType subnet=${subnet.id}');
    state.emitLog(logGroup: '/aws/ec2/${inst.name}', message: 'Instance ${inst.id} reached running state', stream: inst.id);
    completedActions.add('vm_running');
    if (inst.keyName != null) completedActions.add('key_pair');
    return AwsResult(
      ok: true,
      message: 'InstanceId: ${inst.id}\n'
          'InstanceType: $instanceType\n'
          'State: running\n'
          'PrivateIpAddress: ${inst.privateIp}\n'
          'PublicIpAddress: ${inst.publicIp ?? 'none'}\n'
          'KeyName: ${inst.keyName ?? 'none'}\n'
          'SubnetId: ${inst.subnetId}\n'
          'SecurityGroups: ${sgs.join(', ')}',
      data: {'instanceId': inst.id, 'publicIp': inst.publicIp},
    );
  }

  AwsResult describeInstances() {
    if (state.instances.isEmpty) {
      return const AwsResult(ok: true, message: 'No instances found.');
    }
    final buf = StringBuffer('Instances:\n');
    for (final i in state.instances) {
      buf.writeln(
        '  ${i.id}  ${i.state.padRight(10)}  ${i.instanceType.padRight(10)}  '
        'status=${i.statusCheck}  pub=${i.publicIp ?? '-'}  priv=${i.privateIp}  '
        'name=${i.name}  nginx=${i.nginxRunning}',
      );
    }
    completedActions.add('describe_instances');
    return AwsResult(ok: true, message: buf.toString().trimRight());
  }

  AwsResult describeInstanceStatus(String id) {
    final i = state.instances.where((e) => e.id == id).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'InvalidInstanceID.NotFound: $id');
    completedActions.add('check_ec2_status');
    return AwsResult(
      ok: true,
      message: 'InstanceId: $id\nInstanceState: ${i.state}\n'
          'SystemStatus: ${i.statusCheck}\nInstanceStatus: ${i.statusCheck}',
    );
  }

  AwsResult stopInstance(String id) {
    final i = state.instances.where((e) => e.id == id).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'InvalidInstanceID.NotFound: $id');
    i.state = 'stopped';
    state.trail('ec2:StopInstances id=$id');
    return AwsResult(ok: true, message: 'Stopping $id → stopped');
  }

  AwsResult startInstance(String id) {
    final i = state.instances.where((e) => e.id == id).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'InvalidInstanceID.NotFound: $id');
    i.state = 'running';
    i.statusCheck = 'ok';
    state.trail('ec2:StartInstances id=$id');
    if (state.activeIncidentId == 'website-down') {
      completedActions.add('incident_instance_started');
      _recheckIncident();
    }
    return AwsResult(ok: true, message: 'Starting $id → running');
  }

  AwsResult terminateInstance(String id) {
    final i = state.instances.where((e) => e.id == id).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'InvalidInstanceID.NotFound: $id');
    i.state = 'terminated';
    state.trail('ec2:TerminateInstances id=$id');
    return AwsResult(ok: true, message: 'Terminating $id → terminated');
  }

  AwsResult testSsh(String instanceId) {
    final i = state.instances.where((e) => e.id == instanceId).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'Instance not found');
    completedActions.add('test_ssh');
    if (i.state != 'running') {
      return AwsResult(ok: false, message: 'ssh: connect to host ${i.publicIp ?? i.privateIp} port 22: No route to host (instance ${i.state})');
    }
    final sgs = state.securityGroups.where((g) => i.securityGroupIds.contains(g.id));
    final allowsSsh = sgs.any((g) => g.ingress.any((r) => r.fromPort <= 22 && r.toPort >= 22));
    if (!allowsSsh) {
      return AwsResult(
        ok: false,
        message: 'ssh: connect to host ${i.publicIp ?? i.privateIp} port 22: Connection timed out\n'
            '(Security group does not allow TCP/22)',
      );
    }
    if (i.publicIp == null) {
      return AwsResult(
        ok: false,
        message: 'ssh: no public IP — instance in private subnet; use bastion or SSM',
      );
    }
    completedActions.add('ssh_ok');
    return AwsResult(
      ok: true,
      message: 'Authenticated to ${i.publicIp} as ec2-user (key ${i.keyName}).\n'
          'Last login: ${DateTime.now()} from 203.0.113.10',
    );
  }

  AwsResult probeHttp(String instanceId) {
    final i = state.instances.where((e) => e.id == instanceId).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'Instance not found');
    completedActions.add('probe_http');
    if (i.state != 'running') {
      return AwsResult(ok: false, message: 'curl: (7) Failed to connect — instance ${i.state}');
    }
    final sgs = state.securityGroups.where((g) => i.securityGroupIds.contains(g.id));
    final allowsHttp = sgs.any((g) => g.ingress.any((r) => r.fromPort <= 80 && r.toPort >= 80));
    if (!allowsHttp) {
      return AwsResult(
        ok: false,
        message: 'curl: (28) Connection timed out after 10000ms\n'
            '(Security group does not allow TCP/80 from 0.0.0.0/0)',
      );
    }
    if (!i.nginxRunning) {
      return AwsResult(
        ok: false,
        message: 'curl: (7) Failed to connect to ${i.publicIp ?? i.privateIp} port 80: Connection refused\n'
            '(Nothing listening on :80 — start nginx)',
      );
    }
    completedActions.add('http_ok');
    if (state.activeIncidentId == 'website-down') {
      completedActions.add('incident_http_restored');
      _recheckIncident();
    }
    return AwsResult(
      ok: true,
      message: 'HTTP/1.1 200 OK\nServer: nginx/1.18.0\n\n<html><body><h1>Welcome to nginx!</h1></body></html>',
    );
  }

  AwsResult setNginxRunning(String instanceId, bool running) {
    final i = state.instances.where((e) => e.id == instanceId).firstOrNull;
    if (i == null) return AwsResult(ok: false, message: 'Instance not found');
    i.nginxRunning = running;
    state.emitLog(
      logGroup: '/var/log/nginx/error.log',
      message: running ? 'nginx started' : 'nginx stopped',
      stream: instanceId,
    );
    if (running) completedActions.add('nginx_fixed');
    _recheckIncident();
    return AwsResult(ok: true, message: 'nginx ${running ? 'active (running)' : 'inactive'}');
  }

  // ── EBS ──────────────────────────────────────────────────────────────────
  AwsResult createVolume({required int sizeGiB, String? az}) {
    final vol = EbsVolume(
      id: state.id('vol'),
      sizeGiB: sizeGiB,
      az: az ?? '${state.region}a',
    );
    state.volumes.add(vol);
    state.trail('ec2:CreateVolume size=$sizeGiB');
    completedActions.add('ebs_created');
    return AwsResult(ok: true, message: 'VolumeId: ${vol.id}\nSize: $sizeGiB GiB\nState: available');
  }

  AwsResult attachVolume({
    required String volumeId,
    required String instanceId,
    String device = '/dev/sdf',
  }) {
    final vol = state.volumes.where((v) => v.id == volumeId).firstOrNull;
    final inst = state.instances.where((i) => i.id == instanceId).firstOrNull;
    if (vol == null) return AwsResult(ok: false, message: 'InvalidVolume.NotFound');
    if (inst == null) return AwsResult(ok: false, message: 'InvalidInstanceID.NotFound');
    vol.instanceId = instanceId;
    vol.state = 'in-use';
    vol.device = device;
    state.trail('ec2:AttachVolume vol=$volumeId instance=$instanceId');
    completedActions.add('ebs_attached');
    return AwsResult(ok: true, message: 'Attached $volumeId to $instanceId as $device');
  }

  // ── S3 ───────────────────────────────────────────────────────────────────
  AwsResult createBucket(String name) {
    if (state.buckets.any((b) => b.name == name)) {
      return AwsResult(ok: false, message: 'BucketAlreadyExists: $name');
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$').hasMatch(name)) {
      return AwsResult(ok: false, message: 'InvalidBucketName: $name');
    }
    state.buckets.add(S3Bucket(name: name, region: state.region));
    state.trail('s3:CreateBucket name=$name');
    completedActions.add('s3_created');
    return AwsResult(
      ok: true,
      message: 'Location: http://$name.s3.${state.region}.amazonaws.com/',
    );
  }

  AwsResult putObject(String bucket, String key, String body) {
    final b = state.buckets.where((e) => e.name == bucket).firstOrNull;
    if (b == null) return AwsResult(ok: false, message: 'NoSuchBucket: $bucket');
    b.objects.add(key);
    state.trail('s3:PutObject bucket=$bucket key=$key');
    completedActions.add('s3_object');
    return AwsResult(ok: true, message: 'ETag: "${body.hashCode.toRadixString(16)}"\nKey: $key');
  }

  // ── RDS / ELB / ASG / CW / Lambda ────────────────────────────────────────
  AwsResult createDbInstance({
    required String id,
    String engine = 'mysql',
    String instanceClass = 'db.t3.micro',
    bool multiAz = false,
  }) {
    state.databases.add(RdsInstance(
      id: id,
      engine: engine,
      instanceClass: instanceClass,
      multiAz: multiAz,
      status: 'available',
    ));
    state.trail('rds:CreateDBInstance id=$id');
    completedActions.add('rds_created');
    return AwsResult(
      ok: true,
      message: 'DBInstanceIdentifier: $id\nEngine: $engine\nDBInstanceStatus: available\n'
          'Endpoint: $id.c9akciq32.${state.region}.rds.amazonaws.com:3306\nMultiAZ: $multiAz',
    );
  }

  AwsResult createLoadBalancer({
    required String name,
    required List<String> subnetIds,
    String scheme = 'internet-facing',
  }) {
    final lb = LoadBalancer(
      arn:
          'arn:aws:elasticloadbalancing:${state.region}:${state.accountId}:loadbalancer/app/$name/50dc6c495c0c9188',
      name: name,
      scheme: scheme,
      dnsName: '$name-1234567890.${state.region}.elb.amazonaws.com',
      subnetIds: subnetIds,
    );
    state.loadBalancers.add(lb);
    state.trail('elbv2:CreateLoadBalancer name=$name');
    completedActions.add('alb_created');
    return AwsResult(ok: true, message: 'LoadBalancerArn: ${lb.arn}\nDNSName: ${lb.dnsName}');
  }

  AwsResult createAutoScalingGroup({
    required String name,
    required int min,
    required int max,
    required int desired,
    required List<String> subnetIds,
  }) {
    state.asgs.add(AutoScalingGroup(
      name: name,
      min: min,
      max: max,
      desired: desired,
      subnetIds: subnetIds,
    ));
    state.trail('autoscaling:CreateAutoScalingGroup name=$name');
    completedActions.add('asg_created');
    return AwsResult(ok: true, message: 'AutoScalingGroup $name created (min=$min max=$max desired=$desired)');
  }

  AwsResult putMetricAlarm({
    required String name,
    required String metric,
    required double threshold,
  }) {
    state.alarms.add(CloudWatchAlarm(name: name, metric: metric, threshold: threshold));
    state.trail('cloudwatch:PutMetricAlarm name=$name');
    completedActions.add('alarm_created');
    return AwsResult(ok: true, message: 'Alarm $name created for $metric > $threshold');
  }

  AwsResult getLogEvents({String? logGroup}) {
    completedActions.add('inspect_logs');
    final events = logGroup == null
        ? state.logEvents
        : state.logEvents.where((e) => e.logGroup.contains(logGroup)).toList();
    if (events.isEmpty) {
      return const AwsResult(ok: true, message: 'No log events found.');
    }
    final buf = StringBuffer();
    for (final e in events.take(40)) {
      buf.writeln('${e.timestamp.toIso8601String()} [${e.logGroup}/${e.stream}] ${e.message}');
    }
    return AwsResult(ok: true, message: buf.toString().trimRight());
  }

  AwsResult createFunction({
    required String name,
    String runtime = 'python3.12',
    String handler = 'index.handler',
  }) {
    state.lambdas.add(LambdaFunction(name: name, runtime: runtime, handler: handler));
    state.trail('lambda:CreateFunction name=$name');
    completedActions.add('lambda_created');
    return AwsResult(
      ok: true,
      message: 'FunctionName: $name\nRuntime: $runtime\nHandler: $handler\n'
          'FunctionArn: arn:aws:lambda:${state.region}:${state.accountId}:function:$name',
    );
  }

  AwsResult describeVpcs() {
    if (state.vpcs.isEmpty) return const AwsResult(ok: true, message: 'No VPCs.');
    final buf = StringBuffer();
    for (final v in state.vpcs) {
      buf.writeln('${v.id}  ${v.cidr}  ${v.name}  ${v.state}');
    }
    return AwsResult(ok: true, message: buf.toString().trimRight());
  }

  AwsResult describeRouteTables() {
    completedActions.add('inspect_routes');
    if (state.routeTables.isEmpty) return const AwsResult(ok: true, message: 'No route tables.');
    final buf = StringBuffer();
    for (final r in state.routeTables) {
      buf.writeln('${r.id} (${r.name}) vpc=${r.vpcId}');
      for (final route in r.routes) {
        buf.writeln('  ${route.destination} → ${route.target}');
      }
      final assocs = state.rtbAssociations.where((a) => a.routeTableId == r.id);
      for (final a in assocs) {
        buf.writeln('  assoc subnet=${a.subnetId}');
      }
    }
    return AwsResult(ok: true, message: buf.toString().trimRight());
  }

  AwsResult describeSecurityGroups() {
    completedActions.add('inspect_sg');
    if (state.securityGroups.isEmpty) return const AwsResult(ok: true, message: 'No security groups.');
    final buf = StringBuffer();
    for (final g in state.securityGroups) {
      buf.writeln('${g.id}  ${g.name}  vpc=${g.vpcId}');
      for (final r in g.ingress) {
        buf.writeln('  IN  ${r.protocol} ${r.fromPort}-${r.toPort} from ${r.cidr}');
      }
      if (g.ingress.isEmpty) buf.writeln('  IN  (none)');
    }
    return AwsResult(ok: true, message: buf.toString().trimRight());
  }

  /// Topology summary for visual renderer.
  List<Map<String, String>> topologyNodes() {
    final nodes = <Map<String, String>>[];
    for (final v in state.vpcs) {
      nodes.add({'id': v.id, 'type': 'vpc', 'label': v.name.isEmpty ? v.id : v.name});
    }
    for (final s in state.subnets) {
      nodes.add({
        'id': s.id,
        'type': s.isPublic ? 'public_subnet' : 'private_subnet',
        'label': '${s.name.isEmpty ? s.id : s.name}\n${s.cidr}',
        'parent': s.vpcId,
      });
    }
    for (final g in state.igws.where((g) => g.vpcId != null)) {
      nodes.add({'id': g.id, 'type': 'igw', 'label': 'IGW', 'parent': g.vpcId!});
    }
    for (final n in state.natGateways) {
      nodes.add({'id': n.id, 'type': 'nat', 'label': 'NAT', 'parent': n.subnetId});
    }
    for (final i in state.instances.where((i) => i.state != 'terminated')) {
      nodes.add({
        'id': i.id,
        'type': 'ec2',
        'label': '${i.name}\n${i.state}',
        'parent': i.subnetId,
      });
    }
    for (final b in state.buckets) {
      nodes.add({'id': b.name, 'type': 's3', 'label': 's3://${b.name}'});
    }
    return nodes;
  }

  // ── Incident: website down ───────────────────────────────────────────────
  /// Seeds a broken production environment the engineer must fix.
  AwsResult loadWebsiteDownIncident() {
    resetDefaults();
    final vpc = state.vpcs.first;
    final pub = state.subnets.firstWhere((s) => s.isPublic);
    // SG that only allows SSH — HTTP blocked (root cause #1)
    final webSg = SecurityGroup(
      id: state.id('sg'),
      vpcId: vpc.id,
      name: 'web-sg',
      description: 'web tier',
      ingress: [
        SgRule(protocol: 'tcp', fromPort: 22, toPort: 22, cidr: '0.0.0.0/0'),
        // port 80 intentionally missing
      ],
      egress: [SgRule(protocol: '-1', fromPort: 0, toPort: 0, cidr: '0.0.0.0/0')],
    );
    state.securityGroups.add(webSg);
    final inst = Ec2Instance(
      id: state.id('i'),
      instanceType: 't3.small',
      ami: 'ami-0abcdef1234567890',
      state: 'running',
      subnetId: pub.id,
      vpcId: vpc.id,
      securityGroupIds: [webSg.id],
      privateIp: '10.0.1.25',
      publicIp: '54.200.12.88',
      keyName: 'cloudamned-key',
      name: 'prod-web-1',
      statusCheck: 'ok',
      nginxRunning: false, // root cause #2 — nginx not running
    );
    state.instances.add(inst);
    state.alarms.add(CloudWatchAlarm(
      name: 'prod-web-5xx',
      metric: 'HTTPCode_Target_5XX_Count',
      threshold: 5,
      state: 'ALARM',
    ));
    state.emitLog(
      logGroup: '/aws/ec2/prod-web-1',
      stream: inst.id,
      message: 'WARN status check ok but no process listening on :80',
    );
    state.emitLog(
      logGroup: '/var/log/nginx/error.log',
      stream: inst.id,
      message: 'nginx: [emerg] open() "/etc/nginx/nginx.conf" failed — service inactive',
    );
    state.emitLog(
      logGroup: '/aws/applicationelb/app-alb',
      stream: 'target-group',
      message: 'Target 10.0.1.25:80 is unhealthy (connection refused)',
    );
    state.activeIncidentId = 'website-down';
    state.incidentMeta['instanceId'] = inst.id;
    state.incidentMeta['sgId'] = webSg.id;
    state.incidentMeta['rootCauses'] = ['sg_missing_80', 'nginx_down'];
    state.incidentMeta['resolved'] = false;
    state.trail('INCIDENT loaded: website-down');
    completedActions.add('incident_loaded');
    return AwsResult(
      ok: true,
      message: 'INCIDENT LOADED: Website Down (SEV-2)\n\n'
          'Customer: "Our production website returns timeouts. Please investigate."\n\n'
          'Affected: prod-web-1 (${inst.publicIp})\n'
          'Alarm: prod-web-5xx = ALARM\n\n'
          'Investigate CloudWatch logs, EC2 status, security groups, routes, SSH, and nginx.\n'
          'Restore HTTP 200 on port 80 to resolve.',
      data: {'instanceId': inst.id, 'sgId': webSg.id},
    );
  }

  void _recheckIncident() {
    if (state.activeIncidentId != 'website-down') return;
    final id = state.incidentMeta['instanceId'] as String?;
    if (id == null) return;
    final i = state.instances.where((e) => e.id == id).firstOrNull;
    if (i == null) return;
    final sgs = state.securityGroups.where((g) => i.securityGroupIds.contains(g.id));
    final allowsHttp = sgs.any((g) => g.ingress.any((r) => r.fromPort <= 80 && r.toPort >= 80));
    if (allowsHttp && i.nginxRunning && i.state == 'running') {
      state.incidentMeta['resolved'] = true;
      for (final a in state.alarms.where((a) => a.name == 'prod-web-5xx')) {
        a.state = 'OK';
      }
      state.emitLog(
        logGroup: '/aws/applicationelb/app-alb',
        stream: 'target-group',
        message: 'Target 10.0.1.25:80 is healthy',
      );
      completedActions.add('incident_resolved');
      state.trail('INCIDENT RESOLVED: website-down');
    }
  }

  bool get incidentResolved => state.incidentMeta['resolved'] == true;

  AwsResult summary() {
    return AwsResult(
      ok: true,
      message: 'AWS Account ${state.accountId} ($region)\n'
          'VPCs: ${state.vpcs.length}  Subnets: ${state.subnets.length}  '
          'IGW: ${state.igws.length}  NAT: ${state.natGateways.length}\n'
          'Route tables: ${state.routeTables.length}  SGs: ${state.securityGroups.length}\n'
          'EC2: ${state.instances.where((i) => i.state != 'terminated').length}  '
          'EBS: ${state.volumes.length}  S3: ${state.buckets.length}\n'
          'RDS: ${state.databases.length}  ALB: ${state.loadBalancers.length}\n'
          'Incident: ${state.activeIncidentId ?? 'none'}'
          '${incidentResolved ? ' (RESOLVED)' : ''}',
    );
  }

  /// Checklist for "build production VPC manually" lab.
  Map<String, bool> vpcBuildChecklist() {
    return {
      'VPC created': completedActions.contains('vpc_created') || state.vpcs.isNotEmpty,
      'Public subnet': completedActions.contains('public_subnet') ||
          state.subnets.any((s) => s.isPublic),
      'Private subnet': completedActions.contains('private_subnet') ||
          state.subnets.any((s) => !s.isPublic),
      'Internet Gateway attached': completedActions.contains('igw_attached') ||
          state.igws.any((g) => g.vpcId != null),
      'NAT Gateway': completedActions.contains('nat_created') || state.natGateways.isNotEmpty,
      'Route to IGW (0.0.0.0/0)': completedActions.contains('route_igw') ||
          state.routeTables.any((r) => r.routes.any((x) => x.target.startsWith('igw-'))),
      'Route to NAT (private)': completedActions.contains('route_nat') ||
          state.routeTables.any((r) => r.routes.any((x) => x.target.startsWith('nat-'))),
      'Route table associations': completedActions.contains('rtb_associated') ||
          state.rtbAssociations.isNotEmpty,
      'Security group with SSH/HTTP':
          completedActions.contains('sg_ssh') || completedActions.contains('sg_http'),
      'EC2 instance running': state.instances.any((i) => i.state == 'running'),
      'EBS volume': state.volumes.isNotEmpty,
      'S3 bucket': state.buckets.isNotEmpty,
    };
  }

  bool _validCidr(String cidr) {
    final m = RegExp(r'^(\d{1,3}\.){3}\d{1,3}/(\d{1,2})$').firstMatch(cidr);
    if (m == null) return false;
    final prefix = int.parse(m.group(2)!);
    if (prefix > 32) return false;
    return cidr.split('/').first.split('.').map(int.parse).every((o) => o >= 0 && o <= 255);
  }

  String get region => state.region;
}
