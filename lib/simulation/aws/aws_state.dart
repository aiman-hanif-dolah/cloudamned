import 'package:uuid/uuid.dart';

/// Local AWS account simulation state for cloudamned.
class AwsState {
  AwsState({
    this.accountId = '123456789012',
    this.region = 'us-east-1',
  });

  final String accountId;
  String region;
  final _uuid = const Uuid();

  final List<IamUser> users = [];
  final List<IamRole> roles = [];
  final List<IamPolicy> policies = [];
  final List<Vpc> vpcs = [];
  final List<Subnet> subnets = [];
  final List<InternetGateway> igws = [];
  final List<NatGateway> natGateways = [];
  final List<RouteTable> routeTables = [];
  final List<RouteTableAssociation> rtbAssociations = [];
  final List<SecurityGroup> securityGroups = [];
  final List<Ec2Instance> instances = [];
  final List<EbsVolume> volumes = [];
  final List<S3Bucket> buckets = [];
  final List<RdsInstance> databases = [];
  final List<LoadBalancer> loadBalancers = [];
  final List<AutoScalingGroup> asgs = [];
  final List<CloudWatchAlarm> alarms = [];
  final List<CloudWatchLogEvent> logEvents = [];
  final List<LambdaFunction> lambdas = [];
  final List<KeyPair> keyPairs = [];
  final List<ElasticIp> elasticIps = [];
  final List<String> cloudTrailEvents = [];

  /// Optional active incident id (e.g. website-down).
  String? activeIncidentId;
  final Map<String, dynamic> incidentMeta = {};

  String id([String prefix = 'i']) =>
      '$prefix-${_uuid.v4().replaceAll('-', '').substring(0, 8)}';

  void clearAll() {
    users.clear();
    roles.clear();
    policies.clear();
    vpcs.clear();
    subnets.clear();
    igws.clear();
    natGateways.clear();
    routeTables.clear();
    rtbAssociations.clear();
    securityGroups.clear();
    instances.clear();
    volumes.clear();
    buckets.clear();
    databases.clear();
    loadBalancers.clear();
    asgs.clear();
    alarms.clear();
    logEvents.clear();
    lambdas.clear();
    keyPairs.clear();
    elasticIps.clear();
    cloudTrailEvents.clear();
    activeIncidentId = null;
    incidentMeta.clear();
  }

  /// Empty account — user builds everything manually (AWS Console clone mode).
  void seedBlankAccount() {
    clearAll();
    keyPairs.add(KeyPair(
      name: 'cloudamned-key',
      fingerprint: 'https://example.com/p/dynamo:https://example.com/p/dynamo',
    ));
    trail('Blank account ready in $region — create VPC and resources manually');
  }

  /// Quick-start defaults for labs that need a pre-built network.
  void seedDefaults() {
    if (vpcs.isNotEmpty) return;
    final vpcId = id('vpc');
    vpcs.add(Vpc(id: vpcId, cidr: '10.0.0.0/16', name: 'default-vpc'));
    final pub = id('subnet');
    final priv = id('subnet');
    subnets.addAll([
      Subnet(id: pub, vpcId: vpcId, cidr: '10.0.1.0/24', az: '${region}a', isPublic: true, name: 'public-a'),
      Subnet(id: priv, vpcId: vpcId, cidr: '10.0.2.0/24', az: '${region}a', isPublic: false, name: 'private-a'),
    ]);
    final igwId = id('igw');
    igws.add(InternetGateway(id: igwId, vpcId: vpcId, state: 'attached'));
    final rtbPublic = id('rtb');
    final rtbPrivate = id('rtb');
    routeTables.addAll([
      RouteTable(
        id: rtbPublic,
        vpcId: vpcId,
        name: 'public-rt',
        routes: [
          Route(destination: '10.0.0.0/16', target: 'local'),
          Route(destination: '0.0.0.0/0', target: igwId),
        ],
      ),
      RouteTable(
        id: rtbPrivate,
        vpcId: vpcId,
        name: 'private-rt',
        routes: [
          Route(destination: '10.0.0.0/16', target: 'local'),
        ],
      ),
    ]);
    rtbAssociations.addAll([
      RouteTableAssociation(id: id('rtbassoc'), routeTableId: rtbPublic, subnetId: pub),
      RouteTableAssociation(id: id('rtbassoc'), routeTableId: rtbPrivate, subnetId: priv),
    ]);
    securityGroups.add(SecurityGroup(
      id: id('sg'),
      vpcId: vpcId,
      name: 'default',
      description: 'default VPC security group',
      ingress: [],
      egress: [
        SgRule(protocol: '-1', fromPort: 0, toPort: 0, cidr: '0.0.0.0/0'),
      ],
    ));
    keyPairs.add(KeyPair(
      name: 'cloudamned-key',
      fingerprint: 'https://example.com/p/dynamo:https://example.com/p/dynamo',
    ));
    trail('Account seeded with default VPC in $region');
  }

  void trail(String msg) {
    cloudTrailEvents.insert(0, '${DateTime.now().toIso8601String()} $msg');
    if (cloudTrailEvents.length > 200) cloudTrailEvents.removeLast();
  }

  void emitLog({
    required String logGroup,
    required String message,
    String stream = 'i-web',
  }) {
    logEvents.insert(
      0,
      CloudWatchLogEvent(
        logGroup: logGroup,
        stream: stream,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    if (logEvents.length > 500) logEvents.removeLast();
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'region': region,
        'vpcs': vpcs.length,
        'subnets': subnets.length,
        'natGateways': natGateways.length,
        'instances': instances.map((e) => e.toJson()).toList(),
        'buckets': buckets.map((e) => e.name).toList(),
        'securityGroups': securityGroups.length,
        'activeIncidentId': activeIncidentId,
      };
}

class IamUser {
  IamUser({required this.name, this.groups = const [], this.policies = const []});
  final String name;
  List<String> groups;
  List<String> policies;
}

class IamRole {
  IamRole({required this.name, required this.trust, this.policies = const []});
  final String name;
  final String trust;
  List<String> policies;
}

class IamPolicy {
  IamPolicy({required this.name, required this.document});
  final String name;
  final String document;
}

class Vpc {
  Vpc({required this.id, required this.cidr, this.name = '', this.state = 'available'});
  final String id;
  final String cidr;
  String name;
  String state;
}

class Subnet {
  Subnet({
    required this.id,
    required this.vpcId,
    required this.cidr,
    required this.az,
    required this.isPublic,
    this.name = '',
    this.mapPublicIpOnLaunch = false,
  });
  final String id;
  final String vpcId;
  final String cidr;
  final String az;
  bool isPublic;
  String name;
  bool mapPublicIpOnLaunch;
}

class InternetGateway {
  InternetGateway({required this.id, this.vpcId, this.state = 'available'});
  final String id;
  String? vpcId;
  String state;
}

class NatGateway {
  NatGateway({
    required this.id,
    required this.subnetId,
    required this.allocationId,
    this.state = 'available',
  });
  final String id;
  final String subnetId;
  final String allocationId;
  String state;
}

class ElasticIp {
  ElasticIp({required this.allocationId, required this.publicIp, this.associationId});
  final String allocationId;
  final String publicIp;
  String? associationId;
}

class Route {
  Route({required this.destination, required this.target});
  final String destination;
  final String target;
}

class RouteTable {
  RouteTable({
    required this.id,
    required this.vpcId,
    required this.routes,
    this.name = '',
  });
  final String id;
  final String vpcId;
  String name;
  List<Route> routes;
}

class RouteTableAssociation {
  RouteTableAssociation({
    required this.id,
    required this.routeTableId,
    required this.subnetId,
  });
  final String id;
  final String routeTableId;
  final String subnetId;
}

class SgRule {
  SgRule({
    required this.protocol,
    required this.fromPort,
    required this.toPort,
    required this.cidr,
  });
  final String protocol;
  final int fromPort;
  final int toPort;
  final String cidr;
}

class SecurityGroup {
  SecurityGroup({
    required this.id,
    required this.vpcId,
    required this.name,
    required this.description,
    required this.ingress,
    required this.egress,
  });
  final String id;
  final String vpcId;
  final String name;
  final String description;
  List<SgRule> ingress;
  List<SgRule> egress;
}

class Ec2Instance {
  Ec2Instance({
    required this.id,
    required this.instanceType,
    required this.ami,
    required this.state,
    required this.subnetId,
    required this.vpcId,
    required this.securityGroupIds,
    this.privateIp,
    this.publicIp,
    this.keyName,
    this.name = '',
    this.statusCheck = 'ok',
    this.userData = '',
    this.nginxRunning = false,
  });
  final String id;
  final String instanceType;
  final String ami;
  String state;
  final String subnetId;
  final String vpcId;
  List<String> securityGroupIds;
  String? privateIp;
  String? publicIp;
  String? keyName;
  String name;
  String statusCheck;
  String userData;
  bool nginxRunning;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': instanceType,
        'state': state,
        'publicIp': publicIp,
        'privateIp': privateIp,
        'name': name,
        'nginxRunning': nginxRunning,
      };
}

class EbsVolume {
  EbsVolume({
    required this.id,
    required this.sizeGiB,
    required this.az,
    this.instanceId,
    this.state = 'available',
    this.device,
  });
  final String id;
  final int sizeGiB;
  final String az;
  String? instanceId;
  String state;
  String? device;
}

class S3Bucket {
  S3Bucket({required this.name, required this.region, this.versioning = false});
  final String name;
  final String region;
  bool versioning;
  final List<String> objects = [];
}

class RdsInstance {
  RdsInstance({
    required this.id,
    required this.engine,
    required this.instanceClass,
    required this.multiAz,
    this.status = 'available',
  });
  final String id;
  final String engine;
  final String instanceClass;
  final bool multiAz;
  String status;
}

class LoadBalancer {
  LoadBalancer({
    required this.arn,
    required this.name,
    required this.scheme,
    required this.dnsName,
    required this.subnetIds,
  });
  final String arn;
  final String name;
  final String scheme;
  final String dnsName;
  final List<String> subnetIds;
}

class AutoScalingGroup {
  AutoScalingGroup({
    required this.name,
    required this.min,
    required this.max,
    required this.desired,
    required this.subnetIds,
  });
  final String name;
  int min;
  int max;
  int desired;
  final List<String> subnetIds;
}

class CloudWatchAlarm {
  CloudWatchAlarm({
    required this.name,
    required this.metric,
    required this.threshold,
    this.state = 'OK',
  });
  final String name;
  final String metric;
  final double threshold;
  String state;
}

class CloudWatchLogEvent {
  CloudWatchLogEvent({
    required this.logGroup,
    required this.stream,
    required this.message,
    required this.timestamp,
  });
  final String logGroup;
  final String stream;
  final String message;
  final DateTime timestamp;
}

class LambdaFunction {
  LambdaFunction({required this.name, required this.runtime, required this.handler});
  final String name;
  final String runtime;
  final String handler;
}

class KeyPair {
  KeyPair({required this.name, required this.fingerprint});
  final String name;
  final String fingerprint;
}
