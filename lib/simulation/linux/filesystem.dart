/// Simulated Linux filesystem with permissions and content.
class FsNode {
  FsNode({
    required this.name,
    required this.isDir,
    this.content = '',
    this.mode = 0x1ED, // 0755
    this.owner = 'root',
    this.group = 'root',
    this.children,
    DateTime? mtime,
  }) : mtime = mtime ?? DateTime.now();

  String name;
  bool isDir;
  String content;
  int mode;
  String owner;
  String group;
  DateTime mtime;
  Map<String, FsNode>? children;

  FsNode dir(String n) {
    children ??= {};
    return children!.putIfAbsent(
      n,
      () => FsNode(name: n, isDir: true, children: {}),
    );
  }

  void file(String n, String c, {int mode = 0x1A4}) {
    children ??= {};
    children![n] = FsNode(name: n, isDir: false, content: c, mode: mode);
  }

  String modeString() {
    final perms = mode & 0x1FF;
    final buf = StringBuffer(isDir ? 'd' : '-');
    for (final shift in [6, 3, 0]) {
      final p = (perms >> shift) & 7;
      buf.write((p & 4) != 0 ? 'r' : '-');
      buf.write((p & 2) != 0 ? 'w' : '-');
      buf.write((p & 1) != 0 ? 'x' : '-');
    }
    return buf.toString();
  }
}

class VirtualFilesystem {
  VirtualFilesystem() {
    root = FsNode(name: '/', isDir: true, children: {});
    _seed();
  }

  late FsNode root;
  String cwd = '/home/cloudeng';
  String user = 'cloudeng';
  String hostname = 'cloudamned';
  final Map<String, String> env = {
    'HOME': '/home/cloudeng',
    'USER': 'cloudeng',
    'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    'SHELL': '/bin/bash',
    'PWD': '/home/cloudeng',
  };

  // Services & package state
  final Map<String, String> services = {
    // nginx is NOT pre-installed — user must: apt update && apt install nginx
    'ssh': 'active',
    'cron': 'active',
    'docker': 'inactive',
  };
  final Set<String> packages = {'bash', 'coreutils', 'openssh-client', 'curl'};
  final List<Map<String, dynamic>> processes = [
    {'pid': 1, 'user': 'root', 'cpu': 0.0, 'mem': 0.1, 'cmd': '/sbin/init'},
    {'pid': 422, 'user': 'root', 'cpu': 0.1, 'mem': 0.3, 'cmd': 'sshd'},
    {'pid': 881, 'user': 'cloudeng', 'cpu': 0.2, 'mem': 0.5, 'cmd': 'bash'},
  ];
  int _nextPid = 2000;

  void _seed() {
    final etc = root.dir('etc');
    etc.file('hostname', 'cloudamned\n');
    etc.file('hosts', '127.0.0.1 localhost\n10.0.1.10 cloudamned\n');
    etc.file('passwd',
        'root:x:0:0:root:/root:/bin/bash\ncloudeng:x:1000:1000:Cloud Engineer:/home/cloudeng:/bin/bash\n');
    etc.file('group', 'root:x:0:\ncloudeng:x:1000:\nsudo:x:27:cloudeng\n');
    etc.file('os-release',
        'NAME="Ubuntu"\nVERSION="22.04.4 LTS"\nID=ubuntu\nVERSION_ID="22.04"\n');
    etc.dir('nginx').file('nginx.conf', 'user www-data;\nworker_processes auto;\n');
    etc.dir('ssh').file('sshd_config', 'Port 22\nPermitRootLogin no\nPasswordAuthentication no\n');

    final varLog = root.dir('var').dir('log');
    varLog.file('syslog',
        'Jul 13 10:00:01 cloudamned systemd[1]: Started Session.\nJul 13 10:01:12 cloudamned nginx: error: bind() failed\n');
    varLog.file('auth.log',
        'Jul 13 09:55:00 cloudamned sshd[422]: Accepted publickey for cloudeng\n');
    root.dir('var').dir('www').dir('html').file('index.html',
        '<html><body><h1>Welcome to cloudamned</h1></body></html>\n');

    final home = root.dir('home').dir('cloudeng');
    home.mode = 0x1C0; // 0700
    home.owner = 'cloudeng';
    home.group = 'cloudeng';
    home.file('.bashrc', 'export PS1="\\u@\\h:\\w\\\$ "\nalias ll="ls -la"\n', mode: 0x1A4);
    home.file('README.md',
        '# Cloud Engineer Workspace\n\nPractice Linux commands here. Everything is simulated locally.\n');
    home.dir('projects').file('notes.txt', 'TODO: harden nginx\n');
    home.dir('.ssh').file('authorized_keys', 'ssh-ed25519 AAAA... cloudeng@cloudamned\n',
        mode: 0x180);

    root.dir('root')
      ..owner = 'root'
      ..mode = 0x1C0;
    root.dir('tmp').mode = 0x1FF;
    root.dir('opt');
    root.dir('usr').dir('bin');
    root.dir('bin');
    root.dir('sbin');
    final proc = root.dir('proc');
    proc.file('cpuinfo', 'processor\t: 0\nmodel name\t: Virtual CPU\n');
    proc.file('meminfo', 'MemTotal:        2048000 kB\nMemFree:          512000 kB\n');
  }

  String expandPath(String path) {
    if (path.startsWith('~')) {
      path = path.replaceFirst('~', env['HOME']!);
    }
    if (!path.startsWith('/')) {
      path = cwd.endsWith('/') ? '$cwd$path' : '$cwd/$path';
    }
    final parts = <String>[];
    for (final p in path.split('/')) {
      if (p.isEmpty || p == '.') continue;
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(p);
      }
    }
    return '/${parts.join('/')}';
  }

  List<String> _parts(String abs) =>
      abs == '/' ? <String>[] : abs.split('/').where((p) => p.isNotEmpty).toList();

  FsNode? resolve(String path, {bool parent = false}) {
    final abs = expandPath(path);
    final parts = _parts(abs);
    if (parent) {
      if (parts.isEmpty) return root;
      parts.removeLast();
    }
    var node = root;
    for (final p in parts) {
      if (!node.isDir || node.children == null || !node.children!.containsKey(p)) {
        return null;
      }
      node = node.children![p]!;
    }
    return node;
  }

  String? basename(String path) {
    final abs = expandPath(path);
    if (abs == '/') return '/';
    return abs.split('/').last;
  }

  bool exists(String path) => resolve(path) != null;

  int allocPid() => _nextPid++;
}
