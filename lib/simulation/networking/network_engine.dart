class NetNode {
  NetNode({
    required this.id,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    this.cidr,
    this.rules = const [],
  });

  final String id;
  final String type; // vpc, subnet, igw, nat, instance, lb, router, firewall
  String label;
  double x; // mutable for canvas drag
  double y;
  String? cidr;
  List<String> rules;
}

class NetLink {
  NetLink({required this.from, required this.to, this.kind = 'link'});
  final String from;
  final String to;
  final String kind;
}

class PacketResult {
  PacketResult({required this.ok, required this.path, required this.reason});
  final bool ok;
  final List<String> path;
  final String reason;
}

/// Topology builder + packet path simulation for networking labs.
class NetworkEngine {
  final List<NetNode> nodes = [];
  final List<NetLink> links = [];
  final Set<String> completedActions = {};

  void seedBrokenSshScenario() {
    nodes.clear();
    links.clear();
    nodes.addAll([
      NetNode(id: 'igw', type: 'igw', label: 'Internet Gateway', x: 200, y: 40),
      NetNode(id: 'vpc', type: 'vpc', label: 'VPC 10.0.0.0/16', x: 200, y: 120, cidr: '10.0.0.0/16'),
      NetNode(id: 'pub', type: 'subnet', label: 'Public 10.0.1.0/24', x: 80, y: 220, cidr: '10.0.1.0/24'),
      NetNode(id: 'priv', type: 'subnet', label: 'Private 10.0.2.0/24', x: 320, y: 220, cidr: '10.0.2.0/24'),
      NetNode(
        id: 'web',
        type: 'instance',
        label: 'web-1 10.0.1.10',
        x: 80,
        y: 320,
        rules: ['deny:22:0.0.0.0/0'], // broken: SSH denied
      ),
      NetNode(id: 'db', type: 'instance', label: 'db-1 10.0.2.20', x: 320, y: 320, rules: ['allow:3306:10.0.1.0/24']),
    ]);
    links.addAll([
      NetLink(from: 'igw', to: 'vpc'),
      NetLink(from: 'vpc', to: 'pub'),
      NetLink(from: 'vpc', to: 'priv'),
      NetLink(from: 'pub', to: 'web'),
      NetLink(from: 'priv', to: 'db'),
    ]);
  }

  void seedDefault() {
    nodes.clear();
    links.clear();
    nodes.addAll([
      NetNode(id: 'inet', type: 'internet', label: 'Internet', x: 220, y: 20),
      NetNode(id: 'igw', type: 'igw', label: 'IGW', x: 220, y: 100),
      NetNode(id: 'vpc', type: 'vpc', label: 'VPC', x: 220, y: 180, cidr: '10.0.0.0/16'),
    ]);
    links.addAll([
      NetLink(from: 'inet', to: 'igw'),
      NetLink(from: 'igw', to: 'vpc'),
    ]);
  }

  NetNode addNode(String type, String label, double x, double y, {String? cidr}) {
    final id = '${type}_${nodes.length + 1}';
    final n = NetNode(id: id, type: type, label: label, x: x, y: y, cidr: cidr);
    nodes.add(n);
    completedActions.add('node_added');
    return n;
  }

  void link(String from, String to) {
    if (nodes.any((n) => n.id == from) && nodes.any((n) => n.id == to)) {
      links.add(NetLink(from: from, to: to));
      completedActions.add('link_added');
    }
  }

  void setInstanceRule(String nodeId, String rule) {
    final n = nodes.where((e) => e.id == nodeId).firstOrNull;
    if (n == null) return;
    n.rules = [...n.rules.where((r) => !r.endsWith(rule.split(':').skip(1).join(':'))), rule];
    if (rule.startsWith('allow:22')) completedActions.add('ssh_allowed');
    if (rule.startsWith('allow:80')) completedActions.add('http_allowed');
    if (rule.startsWith('deny:')) completedActions.add('traffic_blocked');
    completedActions.add('network_ok');
  }

  /// Simulate path from internet client to target instance on a port.
  PacketResult trace({required String targetId, required int port, String sourceCidr = '0.0.0.0/0'}) {
    final target = nodes.where((n) => n.id == targetId).firstOrNull;
    if (target == null) {
      return PacketResult(ok: false, path: [], reason: 'Target not found');
    }
    final path = <String>['Internet', 'IGW'];
    // find subnet parent
    final toTarget = links.where((l) => l.to == targetId).map((l) => l.from).toList();
    if (toTarget.isEmpty) {
      return PacketResult(ok: false, path: path, reason: 'Instance not attached to subnet');
    }
    final subnetId = toTarget.first;
    final subnet = nodes.where((n) => n.id == subnetId).firstOrNull;
    path.add(subnet?.label ?? subnetId);

    // public path requires IGW connectivity for inbound
    final subnetIsPrivate = subnet?.label.toLowerCase().contains('private') ?? false;
    if (subnetIsPrivate) {
      return PacketResult(
        ok: false,
        path: path,
        reason: 'Target is in private subnet — no direct inbound from Internet',
      );
    }

    path.add(target.label);

    final deny = target.rules.any((r) => r.startsWith('deny:$port'));
    final allow = target.rules.any((r) => r.startsWith('allow:$port'));
    if (deny && !allow) {
      return PacketResult(
        ok: false,
        path: path,
        reason: 'Security group/firewall denies port $port from $sourceCidr',
      );
    }
    if (!allow && target.rules.isNotEmpty) {
      return PacketResult(
        ok: false,
        path: path,
        reason: 'No allow rule for port $port',
      );
    }
    completedActions.add('packet_ok');
    return PacketResult(ok: true, path: path, reason: 'Packet delivered on port $port');
  }

  /// Validate CIDR notation quickly.
  static bool validCidr(String cidr) {
    final m = RegExp(r'^(\d{1,3}\.){3}\d{1,3}/(\d{1,2})$').firstMatch(cidr);
    if (m == null) return false;
    final prefix = int.parse(m.group(2)!);
    if (prefix > 32) return false;
    final ip = cidr.split('/').first.split('.').map(int.parse);
    return ip.every((o) => o >= 0 && o <= 255);
  }

  static int hostCount(String cidr) {
    final prefix = int.parse(cidr.split('/').last);
    final bits = 32 - prefix;
    if (bits <= 0) return 1;
    final total = 1 << bits;
    return total > 2 ? total - 2 : total;
  }
}
