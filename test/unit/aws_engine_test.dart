import 'package:cloudamned/simulation/aws/aws_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AwsEngine aws;

  setUp(() {
    aws = AwsEngine(seedDefaults: false);
  });

  test('blank account has no VPCs', () {
    expect(aws.state.vpcs, isEmpty);
    expect(aws.state.keyPairs, isNotEmpty);
  });

  test('manual VPC build path', () {
    final vpc = aws.createVpc('10.0.0.0/16', name: 'prod');
    expect(vpc.ok, isTrue);
    final vpcId = vpc.data!['vpcId'] as String;

    final pub = aws.createSubnet(
      vpcId: vpcId,
      cidr: '10.0.1.0/24',
      az: 'us-east-1a',
      mapPublicIpOnLaunch: true,
      name: 'public-a',
    );
    expect(pub.ok, isTrue);

    final priv = aws.createSubnet(
      vpcId: vpcId,
      cidr: '10.0.2.0/24',
      az: 'us-east-1a',
      name: 'private-a',
    );
    expect(priv.ok, isTrue);

    final igw = aws.createInternetGateway();
    expect(igw.ok, isTrue);
    final attach = aws.attachInternetGateway(igwId: igw.data!['igwId'] as String, vpcId: vpcId);
    expect(attach.ok, isTrue);

    final eip = aws.allocateAddress();
    final nat = aws.createNatGateway(
      subnetId: pub.data!['subnetId'] as String,
      allocationId: eip.data!['allocationId'] as String,
    );
    expect(nat.ok, isTrue);

    final rtb = aws.createRouteTable(vpcId: vpcId, name: 'public-rt');
    aws.createRoute(
      routeTableId: rtb.data!['rtbId'] as String,
      destinationCidr: '0.0.0.0/0',
      gatewayId: igw.data!['igwId'] as String,
    );
    aws.associateRouteTable(
      routeTableId: rtb.data!['rtbId'] as String,
      subnetId: pub.data!['subnetId'] as String,
    );

    final sg = aws.createSecurityGroup(name: 'web', description: 'web', vpcId: vpcId);
    aws.authorizeSecurityGroupIngress(
      groupId: sg.data!['sgId'] as String,
      protocol: 'tcp',
      fromPort: 80,
      toPort: 80,
      cidr: '0.0.0.0/0',
    );

    final inst = aws.runInstances(
      subnetId: pub.data!['subnetId'] as String,
      securityGroupIds: [sg.data!['sgId'] as String],
    );
    expect(inst.ok, isTrue);
    expect(aws.state.instances.last.state, 'running');

    final checklist = aws.vpcBuildChecklist();
    expect(checklist['VPC created'], isTrue);
    expect(checklist['Internet Gateway attached'], isTrue);
    expect(checklist['NAT Gateway'], isTrue);
  });

  test('createBucket validates name', () {
    final bad = aws.createBucket('BAD_NAME');
    expect(bad.ok, isFalse);
    final good = aws.createBucket('cloudamned-valid-bucket');
    expect(good.ok, isTrue);
  });

  test('website-down incident resolves after SG + nginx fix', () {
    aws.loadWebsiteDownIncident();
    expect(aws.state.activeIncidentId, 'website-down');
    expect(aws.incidentResolved, isFalse);

    final sgId = aws.state.incidentMeta['sgId'] as String;
    final instId = aws.state.incidentMeta['instanceId'] as String;

    aws.authorizeSecurityGroupIngress(
      groupId: sgId,
      protocol: 'tcp',
      fromPort: 80,
      toPort: 80,
      cidr: '0.0.0.0/0',
    );
    aws.setNginxRunning(instId, true);
    expect(aws.incidentResolved, isTrue);

    final http = aws.probeHttp(instId);
    expect(http.ok, isTrue);
  });
}
