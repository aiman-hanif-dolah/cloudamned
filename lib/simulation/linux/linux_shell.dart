import 'filesystem.dart';

class CommandResult {
  const CommandResult({
    required this.stdout,
    this.stderr = '',
    this.exitCode = 0,
    this.stateChanges = const {},
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  final Map<String, dynamic> stateChanges;

  bool get ok => exitCode == 0;
}

/// Realistic Linux command interpreter — fully local, no network.
class LinuxShell {
  LinuxShell({VirtualFilesystem? fs}) : fs = fs ?? VirtualFilesystem();

  final VirtualFilesystem fs;
  final List<String> history = [];
  final Set<String> completedActions = {};
  final Set<String> _enabledServices = {'ssh', 'cron'};
  bool _aptUpdated = false;

  String get prompt {
    final home = fs.env['HOME']!;
    var display = fs.cwd;
    if (display == home) {
      display = '~';
    } else if (display.startsWith('$home/')) {
      display = '~${display.substring(home.length)}';
    }
    final sym = fs.user == 'root' ? '#' : '\$';
    return '${fs.user}@${fs.hostname}:$display$sym ';
  }

  CommandResult exec(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const CommandResult(stdout: '');
    history.add(trimmed);

    // pipes (simple single pipe)
    if (trimmed.contains('|') && !trimmed.startsWith('echo')) {
      final parts = trimmed.split('|').map((e) => e.trim()).toList();
      var input = '';
      CommandResult last = const CommandResult(stdout: '');
      for (final part in parts) {
        last = _execOne(part, stdin: input);
        if (!last.ok) return last;
        input = last.stdout;
      }
      return last;
    }

    // redirects
    if (trimmed.contains('>') && !trimmed.startsWith('echo \'')) {
      return _handleRedirect(trimmed);
    }

    return _execOne(trimmed);
  }

  CommandResult _handleRedirect(String line) {
    final append = line.contains('>>');
    final sep = append ? '>>' : '>';
    final idx = line.indexOf(sep);
    final cmd = line.substring(0, idx).trim();
    final target = line.substring(idx + sep.length).trim();
    final result = _execOne(cmd);
    if (!result.ok) return result;
    final parent = fs.resolve(target, parent: true);
    final name = fs.basename(target);
    if (parent == null || name == null || !parent.isDir) {
      return CommandResult(
        stdout: '',
        stderr: 'bash: $target: No such file or directory\n',
        exitCode: 1,
      );
    }
    parent.children ??= {};
    final existing = parent.children![name];
    final content = append && existing != null && !existing.isDir
        ? existing.content + result.stdout
        : result.stdout;
    parent.file(name, content);
    return const CommandResult(stdout: '');
  }

  CommandResult _execOne(String line, {String stdin = ''}) {
    final tokens = _tokenize(line);
    if (tokens.isEmpty) return const CommandResult(stdout: '');
    final cmd = tokens.first;
    final args = tokens.skip(1).toList();

    switch (cmd) {
      case 'help':
        return _help(args);
      case 'pwd':
        completedActions.add('pwd');
        return CommandResult(stdout: '${fs.cwd}\n');
      case 'cd':
        return _cd(args);
      case 'ls':
        return _ls(args);
      case 'll':
        return _ls(['-la', ...args]);
      case 'mkdir':
        return _mkdir(args);
      case 'touch':
        return _touch(args);
      case 'cat':
        return _cat(args, stdin: stdin);
      case 'echo':
        return CommandResult(stdout: '${args.join(' ')}\n');
      case 'rm':
        return _rm(args);
      case 'cp':
        return _cp(args);
      case 'mv':
        return _mv(args);
      case 'chmod':
        return _chmod(args);
      case 'chown':
        return _chown(args);
      case 'whoami':
        return CommandResult(stdout: '${fs.user}\n');
      case 'hostname':
        return CommandResult(stdout: '${fs.hostname}\n');
      case 'uname':
        return _uname(args);
      case 'id':
        return const CommandResult(stdout: 'uid=1000(cloudeng) gid=1000(cloudeng) groups=1000(cloudeng),27(sudo)\n');
      case 'env':
      case 'printenv':
        return CommandResult(
          stdout: fs.env.entries.map((e) => '${e.key}=${e.value}').join('\n') + '\n',
        );
      case 'export':
        if (args.isEmpty) return _execOne('env');
        for (final a in args) {
          final parts = a.split('=');
          if (parts.length >= 2) fs.env[parts[0]] = parts.sublist(1).join('=');
        }
        return const CommandResult(stdout: '');
      case 'history':
        return CommandResult(
          stdout: [
            for (var i = 0; i < history.length; i++)
              '  ${i + 1}  ${history[i]}',
          ].join('\n') +
              '\n',
        );
      case 'clear':
        return const CommandResult(stdout: '', stateChanges: {'clear': true});
      case 'date':
        return CommandResult(stdout: '${DateTime.now().toUtc()} UTC\n');
      case 'df':
        completedActions.add('df_h');
        return const CommandResult(
          stdout:
              'Filesystem     1K-blocks    Used Available Use% Mounted on\n'
              '/dev/vda1       20971520 5242880  15728640  25% /\n'
              'tmpfs            1024000       0  1024000   0% /dev/shm\n',
        );
      case 'du':
        return const CommandResult(stdout: '48\t.\n');
      case 'free':
        return const CommandResult(
          stdout:
              '               total        used        free      shared  buff/cache   available\n'
              'Mem:         2048000      768000      512000       12000      768000     1152000\n'
              'Swap:              0           0           0\n',
        );
      case 'ps':
        completedActions.add('ps_aux');
        return _ps(args);
      case 'top':
      case 'htop':
        return _ps(['aux']);
      case 'kill':
        return _kill(args);
      case 'systemctl':
        return _systemctl(args);
      case 'service':
        // service nginx restart
        if (args.length >= 2) {
          return _systemctl([args[1], args[0]]);
        }
        return const CommandResult(stdout: '', stderr: 'Usage: service <unit> <action>\n', exitCode: 1);
      case 'journalctl':
        return _journalctl(args);
      case 'ip':
        return _ip(args);
      case 'ifconfig':
        return _ip(['addr']);
      case 'ss':
      case 'netstat':
        return const CommandResult(
          stdout:
              'Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port\n'
              'tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*\n'
              'tcp   LISTEN 0      128          0.0.0.0:80         0.0.0.0:*\n',
        );
      case 'ping':
        return _ping(args);
      case 'curl':
        return _curl(args);
      case 'traceroute':
      case 'tracepath':
        return CommandResult(
          stdout:
              'traceroute to ${args.isEmpty ? '8.8.8.8' : args.last} (8.8.8.8), 30 hops max\n'
              ' 1  10.0.0.1  1.2 ms\n'
              ' 2  100.64.0.1  4.5 ms\n'
              ' 3  8.8.8.8  12.1 ms\n',
        );
      case 'ssh':
        return CommandResult(
          stdout:
              'Pseudo-terminal will not be allocated because stdin is not a terminal.\n'
              'Welcome to Ubuntu 22.04 LTS (simulated)\n'
              'Last login: ${DateTime.now()}\n',
        );
      case 'scp':
        return const CommandResult(stdout: '100%  4096    1.2MB/s   00:00\n');
      case 'tar':
        return _tar(args);
      case 'grep':
        return _grep(args, stdin: stdin);
      case 'find':
        return _find(args);
      case 'head':
        return _headTail(args, stdin: stdin, head: true);
      case 'tail':
        return _headTail(args, stdin: stdin, head: false);
      case 'wc':
        return _wc(args, stdin: stdin);
      case 'sudo':
        if (args.isEmpty) {
          return const CommandResult(stdout: '', stderr: 'usage: sudo <command>\n', exitCode: 1);
        }
        final prev = fs.user;
        fs.user = 'root';
        final r = _execOne(args.join(' '));
        fs.user = prev;
        return r;
      case 'apt':
      case 'apt-get':
        return _apt(args);
      case 'yum':
      case 'dnf':
        return _yum(args);
      case 'useradd':
      case 'adduser':
        return _useradd(args);
      case 'passwd':
        return CommandResult(
          stdout: 'passwd: password updated successfully for ${args.isEmpty ? fs.user : args.first}\n',
        );
      case 'ufw':
        return _ufw(args);
      case 'which':
        if (args.isEmpty) return const CommandResult(stdout: '', exitCode: 1);
        return CommandResult(stdout: '/usr/bin/${args.first}\n');
      case 'man':
        return CommandResult(
          stdout: 'Manual entry for ${args.isEmpty ? 'topic' : args.first} (simulated)\n'
              'Use `help` for built-in cloudamned command list.\n',
        );
      case 'tree':
        return _tree(args);
      case 'nano':
      case 'vim':
      case 'vi':
        return CommandResult(
          stdout: '(editor simulated) Opened ${args.isEmpty ? 'buffer' : args.first}. Changes applied via shell redirects in this lab environment.\n',
        );
      case 'ssh-keygen':
        completedActions.add('ssh_keygen');
        final sshDir = fs.resolve('~/.ssh');
        if (sshDir != null && sshDir.isDir) {
          sshDir.file('id_ed25519', '-----BEGIN OPENSSH PRIVATE KEY-----\n...\n', mode: 0x180);
          sshDir.file('id_ed25519.pub', 'ssh-ed25519 AAAA... cloudeng@cloudamned\n');
        }
        return const CommandResult(
          stdout: 'Generating public/private ed25519 key pair.\n'
              'Your identification has been saved in /home/cloudeng/.ssh/id_ed25519\n'
              'Your public key has been saved in /home/cloudeng/.ssh/id_ed25519.pub\n',
        );
      case 'exit':
      case 'logout':
        return const CommandResult(stdout: 'logout\n', stateChanges: {'exit': true});
      default:
        return CommandResult(
          stdout: '',
          stderr: 'bash: $cmd: command not found\n',
          exitCode: 127,
        );
    }
  }

  List<String> _tokenize(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == "'" && !inDouble) {
        inSingle = !inSingle;
        continue;
      }
      if (c == '"' && !inSingle) {
        inDouble = !inDouble;
        continue;
      }
      if (c == ' ' && !inSingle && !inDouble) {
        if (buf.isNotEmpty) {
          result.add(buf.toString());
          buf.clear();
        }
        continue;
      }
      buf.write(c);
    }
    if (buf.isNotEmpty) result.add(buf.toString());
    return result;
  }

  CommandResult _help(List<String> args) {
    if (args.isNotEmpty) {
      return CommandResult(
        stdout: '${args.first}: simulated command. Try running it with --help where applicable.\n',
      );
    }
    return const CommandResult(
      stdout: '''cloudamned Linux Shell — simulated commands

Navigation:  pwd ls cd tree mkdir touch rm cp mv cat echo
Permissions: chmod chown
Users:       whoami id useradd passwd sudo
Process:     ps top htop kill
Services:    systemctl journalctl
Network:     ip ifconfig ss ping curl traceroute ssh scp
Packages:    apt apt-get yum
Archive:     tar
Search:      grep find head tail wc
Firewall:    ufw
Other:       df du free env export history date uname clear help

Everything runs offline. No real system changes.
''',
    );
  }

  CommandResult _cd(List<String> args) {
    final target = args.isEmpty ? fs.env['HOME']! : args.first;
    final node = fs.resolve(target);
    if (node == null || !node.isDir) {
      return CommandResult(
        stdout: '',
        stderr: 'bash: cd: $target: No such file or directory\n',
        exitCode: 1,
      );
    }
    fs.cwd = fs.expandPath(target);
    fs.env['PWD'] = fs.cwd;
    return const CommandResult(stdout: '');
  }

  CommandResult _ls(List<String> args) {
    var long = false;
    var all = false;
    final paths = <String>[];
    for (final a in args) {
      if (a.startsWith('-')) {
        if (a.contains('l')) long = true;
        if (a.contains('a')) all = true;
      } else {
        paths.add(a);
      }
    }
    if (paths.isEmpty) paths.add('.');
    final out = StringBuffer();
    for (final p in paths) {
      final node = fs.resolve(p);
      if (node == null) {
        return CommandResult(
          stdout: '',
          stderr: 'ls: cannot access \'$p\': No such file or directory\n',
          exitCode: 2,
        );
      }
      if (fs.cwd == fs.env['HOME'] || p == '~' || p == fs.env['HOME']) {
        completedActions.add('ls_home');
      }
      if (!node.isDir) {
        out.writeln(long ? _longLine(node) : node.name);
        continue;
      }
      final names = node.children?.keys.toList() ?? [];
      names.sort();
      if (all) {
        if (long) {
          out.writeln(_longLine(node, name: '.'));
        }
      }
      for (final name in names) {
        if (!all && name.startsWith('.')) continue;
        final child = node.children![name]!;
        out.writeln(long ? _longLine(child) : name);
      }
    }
    return CommandResult(stdout: out.toString());
  }

  String _longLine(FsNode n, {String? name}) {
    final m = n.mtime;
    final date =
        '${_mon(m.month)} ${m.day.toString().padLeft(2)} ${m.hour.toString().padLeft(2, '0')}:${m.minute.toString().padLeft(2, '0')}';
    final size = n.isDir ? 4096 : n.content.length;
    return '${n.modeString()} 1 ${n.owner.padRight(8)} ${n.group.padRight(8)} ${size.toString().padLeft(6)} $date ${name ?? n.name}';
  }

  String _mon(int m) =>
      const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

  CommandResult _mkdir(List<String> args) {
    if (args.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'mkdir: missing operand\n', exitCode: 1);
    }
    final pFlag = args.contains('-p');
    final paths = args.where((a) => !a.startsWith('-')).toList();
    for (final p in paths) {
      if (fs.exists(p) && !pFlag) {
        return CommandResult(
          stdout: '',
          stderr: 'mkdir: cannot create directory \'$p\': File exists\n',
          exitCode: 1,
        );
      }
      final abs = fs.expandPath(p);
      final parts = abs.split('/').where((e) => e.isNotEmpty).toList();
      var node = fs.root;
      for (final part in parts) {
        node.children ??= {};
        if (!node.children!.containsKey(part)) {
          if (!pFlag && part != parts.last) {
            return CommandResult(
              stdout: '',
              stderr: 'mkdir: cannot create directory \'$p\': No such file or directory\n',
              exitCode: 1,
            );
          }
          node.children![part] = FsNode(name: part, isDir: true, children: {}, owner: fs.user, group: fs.user);
        }
        node = node.children![part]!;
        if (!node.isDir) {
          return CommandResult(
            stdout: '',
            stderr: 'mkdir: cannot create directory \'$p\': Not a directory\n',
            exitCode: 1,
          );
        }
      }
    }
    completedActions.add('mkdir_demo');
    return const CommandResult(stdout: '');
  }

  CommandResult _touch(List<String> args) {
    if (args.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'touch: missing file operand\n', exitCode: 1);
    }
    for (final p in args) {
      final parent = fs.resolve(p, parent: true);
      final name = fs.basename(p);
      if (parent == null || name == null || !parent.isDir) {
        return CommandResult(
          stdout: '',
          stderr: 'touch: cannot touch \'$p\': No such file or directory\n',
          exitCode: 1,
        );
      }
      parent.children ??= {};
      if (!parent.children!.containsKey(name)) {
        parent.file(name, '', mode: 0x1A4);
      } else {
        parent.children![name]!.mtime = DateTime.now();
      }
    }
    completedActions.add('touch_file');
    return const CommandResult(stdout: '');
  }

  CommandResult _cat(List<String> args, {String stdin = ''}) {
    if (args.isEmpty) {
      return CommandResult(stdout: stdin.endsWith('\n') || stdin.isEmpty ? stdin : '$stdin\n');
    }
    final out = StringBuffer();
    for (final p in args) {
      final node = fs.resolve(p);
      if (node == null || node.isDir) {
        return CommandResult(
          stdout: '',
          stderr: 'cat: $p: ${node == null ? 'No such file or directory' : 'Is a directory'}\n',
          exitCode: 1,
        );
      }
      out.write(node.content.endsWith('\n') || node.content.isEmpty ? node.content : '${node.content}\n');
    }
    completedActions.add('cat_file');
    return CommandResult(stdout: out.toString());
  }

  CommandResult _rm(List<String> args) {
    final recursive = args.contains('-r') || args.contains('-rf') || args.contains('-fr');
    final paths = args.where((a) => !a.startsWith('-')).toList();
    if (paths.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'rm: missing operand\n', exitCode: 1);
    }
    for (final p in paths) {
      final abs = fs.expandPath(p);
      if (abs == '/' ) {
        return const CommandResult(stdout: '', stderr: 'rm: it is dangerous to operate recursively on \'/\'\n', exitCode: 1);
      }
      final parent = fs.resolve(p, parent: true);
      final name = fs.basename(p);
      final node = fs.resolve(p);
      if (parent == null || name == null || node == null) {
        return CommandResult(stdout: '', stderr: 'rm: cannot remove \'$p\': No such file or directory\n', exitCode: 1);
      }
      if (node.isDir && !recursive) {
        return CommandResult(stdout: '', stderr: 'rm: cannot remove \'$p\': Is a directory\n', exitCode: 1);
      }
      parent.children?.remove(name);
    }
    return const CommandResult(stdout: '');
  }

  CommandResult _cp(List<String> args) {
    final paths = args.where((a) => !a.startsWith('-')).toList();
    if (paths.length < 2) {
      return const CommandResult(stdout: '', stderr: 'cp: missing file operand\n', exitCode: 1);
    }
    final src = fs.resolve(paths[0]);
    if (src == null || src.isDir) {
      return CommandResult(stdout: '', stderr: 'cp: cannot stat \'${paths[0]}\': No such file or directory\n', exitCode: 1);
    }
    final dest = paths[1];
    final parent = fs.resolve(dest, parent: true);
    var name = fs.basename(dest)!;
    final destNode = fs.resolve(dest);
    if (destNode != null && destNode.isDir) {
      name = src.name;
      destNode.children ??= {};
      destNode.children![name] =
          FsNode(name: name, isDir: false, content: src.content, mode: src.mode, owner: fs.user, group: fs.user);
      return const CommandResult(stdout: '');
    }
    if (parent == null || !parent.isDir) {
      return CommandResult(stdout: '', stderr: 'cp: cannot create regular file \'$dest\': No such file or directory\n', exitCode: 1);
    }
    parent.children ??= {};
    parent.children![name] =
        FsNode(name: name, isDir: false, content: src.content, mode: src.mode, owner: fs.user, group: fs.user);
    return const CommandResult(stdout: '');
  }

  CommandResult _mv(List<String> args) {
    if (args.length < 2) {
      return const CommandResult(stdout: '', stderr: 'mv: missing file operand\n', exitCode: 1);
    }
    final srcPath = args[0];
    final destPath = args[1];
    final src = fs.resolve(srcPath);
    final srcParent = fs.resolve(srcPath, parent: true);
    final srcName = fs.basename(srcPath);
    if (src == null || srcParent == null || srcName == null) {
      return CommandResult(stdout: '', stderr: 'mv: cannot stat \'$srcPath\': No such file or directory\n', exitCode: 1);
    }
    final destNode = fs.resolve(destPath);
    if (destNode != null && destNode.isDir) {
      destNode.children ??= {};
      destNode.children![srcName] = src;
      srcParent.children?.remove(srcName);
      return const CommandResult(stdout: '');
    }
    final destParent = fs.resolve(destPath, parent: true);
    final destName = fs.basename(destPath);
    if (destParent == null || destName == null) {
      return CommandResult(stdout: '', stderr: 'mv: cannot move to \'$destPath\': No such file or directory\n', exitCode: 1);
    }
    destParent.children ??= {};
    destParent.children![destName] = src..name = destName;
    srcParent.children?.remove(srcName);
    return const CommandResult(stdout: '');
  }

  CommandResult _chmod(List<String> args) {
    if (args.length < 2) {
      return const CommandResult(stdout: '', stderr: 'chmod: missing operand\n', exitCode: 1);
    }
    final modeStr = args[0];
    final path = args[1];
    final node = fs.resolve(path);
    if (node == null) {
      return CommandResult(stdout: '', stderr: 'chmod: cannot access \'$path\': No such file or directory\n', exitCode: 1);
    }
    final mode = int.tryParse(modeStr, radix: 8);
    if (mode == null) {
      return CommandResult(stdout: '', stderr: 'chmod: invalid mode: ‘$modeStr’\n', exitCode: 1);
    }
    node.mode = mode;
    if (modeStr == '755' || modeStr == '0755') completedActions.add('chmod_755');
    return const CommandResult(stdout: '');
  }

  CommandResult _chown(List<String> args) {
    if (args.length < 2) {
      return const CommandResult(stdout: '', stderr: 'chown: missing operand\n', exitCode: 1);
    }
    final ownerGroup = args[0].split(':');
    final node = fs.resolve(args[1]);
    if (node == null) {
      return CommandResult(stdout: '', stderr: 'chown: cannot access \'${args[1]}\': No such file or directory\n', exitCode: 1);
    }
    node.owner = ownerGroup[0];
    if (ownerGroup.length > 1 && ownerGroup[1].isNotEmpty) node.group = ownerGroup[1];
    return const CommandResult(stdout: '');
  }

  CommandResult _uname(List<String> args) {
    if (args.contains('-a')) {
      return const CommandResult(
        stdout: 'Linux cloudamned 5.15.0-105-generic #115-Ubuntu SMP x86_64 GNU/Linux\n',
      );
    }
    return const CommandResult(stdout: 'Linux\n');
  }

  CommandResult _ps(List<String> args) {
    final out = StringBuffer('USER       PID %CPU %MEM COMMAND\n');
    for (final p in fs.processes) {
      out.writeln(
        '${(p['user'] as String).padRight(10)} ${p['pid'].toString().padLeft(4)} '
        '${(p['cpu'] as double).toStringAsFixed(1).padLeft(4)} '
        '${(p['mem'] as double).toStringAsFixed(1).padLeft(4)} ${p['cmd']}',
      );
    }
    return CommandResult(stdout: out.toString());
  }

  CommandResult _kill(List<String> args) {
    if (args.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'kill: usage: kill PID\n', exitCode: 1);
    }
    final pid = int.tryParse(args.last);
    if (pid == null) {
      return CommandResult(stdout: '', stderr: 'kill: (${args.last}): invalid signal specification\n', exitCode: 1);
    }
    final before = fs.processes.length;
    fs.processes.removeWhere((p) => p['pid'] == pid);
    if (fs.processes.length == before) {
      return CommandResult(stdout: '', stderr: 'kill: ($pid): No such process\n', exitCode: 1);
    }
    return const CommandResult(stdout: '');
  }

  CommandResult _systemctl(List<String> args) {
    if (args.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'systemctl: missing arguments\n', exitCode: 1);
    }
    final action = args[0];
    final unit = args.length > 1 ? args[1].replaceAll('.service', '') : '';
    switch (action) {
      case 'status':
        final state = fs.services[unit] ?? 'not-found';
        if (state == 'not-found') {
          return CommandResult(
            stdout: '',
            stderr: 'Unit $unit.service could not be found.\n'
                'Hint: package may not be installed. Try: sudo apt install $unit\n',
            exitCode: 4,
          );
        }
        final enabled = _enabledServices.contains(unit) ? 'enabled' : 'disabled';
        return CommandResult(
          stdout: '● $unit.service - ${unit.toUpperCase()} service\n'
              '     Loaded: loaded (/lib/systemd/system/$unit.service; $enabled; vendor preset: enabled)\n'
              '     Active: $state (${state == 'active' ? 'running' : 'dead'}) since ${DateTime.now()}\n'
              '   Main PID: ${state == 'active' ? '1200' : 'n/a'} ($unit)\n',
        );
      case 'start':
        if (!fs.services.containsKey(unit)) {
          return CommandResult(
            stdout: '',
            stderr: 'Failed to start $unit.service: Unit $unit.service not found.\n',
            exitCode: 5,
          );
        }
        if (unit == 'nginx' && !fs.packages.contains('nginx')) {
          return CommandResult(
            stdout: '',
            stderr: 'Failed to start nginx.service: Unit not found.\n'
                'Install with: sudo apt install nginx\n',
            exitCode: 5,
          );
        }
        fs.services[unit] = 'active';
        if (unit == 'nginx') completedActions.add('nginx_running');
        return const CommandResult(stdout: '');
      case 'stop':
        if (!fs.services.containsKey(unit)) {
          return CommandResult(stdout: '', stderr: 'Failed to stop $unit.service: Unit not found.\n', exitCode: 5);
        }
        fs.services[unit] = 'inactive';
        return const CommandResult(stdout: '');
      case 'restart':
        if (!fs.services.containsKey(unit) && unit == 'nginx' && !fs.packages.contains('nginx')) {
          return CommandResult(
            stdout: '',
            stderr: 'Failed to restart nginx.service: Unit not found.\n',
            exitCode: 5,
          );
        }
        if (!fs.services.containsKey(unit) && fs.packages.contains(unit)) {
          fs.services[unit] = 'inactive';
        }
        if (!fs.services.containsKey(unit)) {
          return CommandResult(stdout: '', stderr: 'Failed to restart $unit.service: Unit not found.\n', exitCode: 5);
        }
        fs.services[unit] = 'active';
        if (unit == 'nginx') {
          completedActions.add('nginx_running');
          completedActions.add('nginx_restarted');
        }
        return const CommandResult(stdout: '');
      case 'enable':
        if (!fs.services.containsKey(unit) && !fs.packages.contains(unit)) {
          return CommandResult(
            stdout: '',
            stderr: 'Failed to enable unit: Unit file $unit.service does not exist.\n',
            exitCode: 1,
          );
        }
        fs.services.putIfAbsent(unit, () => 'inactive');
        _enabledServices.add(unit);
        if (unit == 'nginx') completedActions.add('nginx_enabled');
        return CommandResult(
          stdout: 'Created symlink /etc/systemd/system/multi-user.target.wants/$unit.service → /lib/systemd/system/$unit.service.\n',
        );
      case 'disable':
        _enabledServices.remove(unit);
        return CommandResult(
          stdout: 'Removed /etc/systemd/system/multi-user.target.wants/$unit.service.\n',
        );
      case 'is-active':
        final st = fs.services[unit] ?? 'unknown';
        return CommandResult(stdout: '$st\n', exitCode: st == 'active' ? 0 : 3);
      case 'is-enabled':
        final en = _enabledServices.contains(unit);
        return CommandResult(stdout: '${en ? 'enabled' : 'disabled'}\n', exitCode: en ? 0 : 1);
      case 'list-units':
        return CommandResult(
          stdout: fs.services.entries
                  .map((e) => '${e.key}.service'.padRight(24) + ' loaded ${e.value}')
                  .join('\n') +
              '\n',
        );
      default:
        return CommandResult(stdout: '', stderr: 'Unknown operation $action\n', exitCode: 1);
    }
  }

  CommandResult _journalctl(List<String> args) {
    final unit = args.contains('-u') ? args[args.indexOf('-u') + 1] : 'syslog';
    completedActions.add('journal_nginx');
    return CommandResult(
      stdout: '-- Journal begins at ${DateTime.now().subtract(const Duration(days: 1))} --\n'
          'Jul 13 10:00:01 cloudamned systemd[1]: Started $unit.\n'
          'Jul 13 10:01:12 cloudamned $unit[1200]: configuration loaded\n'
          'Jul 13 10:02:00 cloudamned $unit[1200]: listening on 0.0.0.0:80\n',
    );
  }

  CommandResult _ip(List<String> args) {
    completedActions.add('ip_addr');
    if (args.isEmpty || args.first == 'addr' || args.first == 'a') {
      return const CommandResult(
        stdout: '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536\n'
            '    inet 127.0.0.1/8 scope host lo\n'
            '2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001\n'
            '    inet 10.0.1.10/24 brd 10.0.1.255 scope global eth0\n'
            '    inet6 fe80::a00:27ff:fe4e:66a1/64 scope link\n',
      );
    }
    if (args.first == 'route' || args.first == 'r') {
      return const CommandResult(
        stdout: 'default via 10.0.1.1 dev eth0\n'
            '10.0.1.0/24 dev eth0 proto kernel scope link src 10.0.1.10\n',
      );
    }
    return const CommandResult(stdout: 'Usage: ip [ addr | route ]\n');
  }

  CommandResult _ping(List<String> args) {
    final host = args.isEmpty ? '127.0.0.1' : args.last;
    return CommandResult(
      stdout: 'PING $host ($host) 56(84) bytes of data.\n'
          '64 bytes from $host: icmp_seq=1 ttl=64 time=0.4 ms\n'
          '64 bytes from $host: icmp_seq=2 ttl=64 time=0.3 ms\n'
          '64 bytes from $host: icmp_seq=3 ttl=64 time=0.3 ms\n'
          '--- $host ping statistics ---\n'
          '3 packets transmitted, 3 received, 0% packet loss\n',
    );
  }

  CommandResult _curl(List<String> args) {
    final url = args.isEmpty ? 'http://localhost' : args.last;
    if (url.contains('localhost') || url.contains('127.0.0.1') || url.contains('10.0.1.10')) {
      if (fs.services['nginx'] == 'active') {
        completedActions.add('curl_nginx_ok');
        final node = fs.resolve('/var/www/html/index.html');
        final body = node != null && !node.isDir
            ? node.content
            : '<html><body><h1>Welcome to nginx!</h1></body></html>\n';
        return CommandResult(stdout: body);
      }
      return const CommandResult(
        stdout: '',
        stderr: 'curl: (7) Failed to connect to localhost port 80: Connection refused\n',
        exitCode: 7,
      );
    }
    return CommandResult(
      stdout: '',
      stderr:
          'curl: (6) Could not resolve host: ${url.replaceAll(RegExp(r'https?://'), '')} (offline simulation)\n',
      exitCode: 6,
    );
  }

  CommandResult _tar(List<String> args) {
    completedActions.add('tar_create');
    if (args.contains('-czf') || args.contains('-czvf') || (args.contains('-c') && args.contains('-f'))) {
      return const CommandResult(stdout: '');
    }
    if (args.contains('-xzf') || args.contains('-x')) {
      return const CommandResult(stdout: '');
    }
    return const CommandResult(stdout: '', stderr: 'tar: You must specify one of the -c or -x options\n', exitCode: 2);
  }

  CommandResult _grep(List<String> args, {String stdin = ''}) {
    if (args.isEmpty) {
      return const CommandResult(stdout: '', stderr: 'Usage: grep PATTERN [FILE]\n', exitCode: 2);
    }
    final pattern = args.first;
    final files = args.skip(1).where((a) => !a.startsWith('-')).toList();
    final out = StringBuffer();
    if (files.isEmpty) {
      for (final line in stdin.split('\n')) {
        if (line.contains(pattern)) out.writeln(line);
      }
    } else {
      for (final f in files) {
        final node = fs.resolve(f);
        if (node == null || node.isDir) continue;
        for (final line in node.content.split('\n')) {
          if (line.contains(pattern)) {
            out.writeln(files.length > 1 ? '$f:$line' : line);
            if (pattern.toLowerCase().contains('error') || line.toLowerCase().contains('error')) {
              completedActions.add('grep_error');
            }
          }
        }
      }
    }
    return CommandResult(stdout: out.toString());
  }

  CommandResult _find(List<String> args) {
    final start = args.isEmpty ? '.' : args.first;
    final nameIdx = args.indexOf('-name');
    final namePat = nameIdx >= 0 && nameIdx + 1 < args.length ? args[nameIdx + 1].replaceAll('*', '') : null;
    final out = <String>[];
    void walk(FsNode node, String path) {
      if (namePat == null || node.name.contains(namePat)) {
        out.add(path.isEmpty ? '/' : path);
      }
      if (node.isDir && node.children != null) {
        for (final e in node.children!.entries) {
          final childPath = path == '/' ? '/${e.key}' : '$path/${e.key}';
          walk(e.value, path.isEmpty ? '/${e.key}' : childPath);
        }
      }
    }

    final node = fs.resolve(start);
    if (node == null) {
      return CommandResult(stdout: '', stderr: 'find: ‘$start’: No such file or directory\n', exitCode: 1);
    }
    walk(node, fs.expandPath(start));
    return CommandResult(stdout: '${out.join('\n')}\n');
  }

  CommandResult _headTail(List<String> args, {required bool head, String stdin = ''}) {
    var n = 10;
    final paths = <String>[];
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '-n' && i + 1 < args.length) {
        n = int.tryParse(args[++i]) ?? 10;
      } else if (args[i].startsWith('-') && int.tryParse(args[i].substring(1)) != null) {
        n = int.parse(args[i].substring(1));
      } else if (!args[i].startsWith('-')) {
        paths.add(args[i]);
      }
    }
    String text = stdin;
    if (paths.isNotEmpty) {
      final node = fs.resolve(paths.first);
      if (node == null || node.isDir) {
        return CommandResult(stdout: '', stderr: 'No such file\n', exitCode: 1);
      }
      text = node.content;
    }
    final lines = text.split('\n');
    final slice = head
        ? lines.take(n)
        : lines.skip(lines.length > n ? lines.length - n : 0);
    return CommandResult(stdout: '${slice.join('\n')}\n');
  }

  CommandResult _wc(List<String> args, {String stdin = ''}) {
    String text = stdin;
    if (args.isNotEmpty) {
      final node = fs.resolve(args.last);
      if (node != null && !node.isDir) text = node.content;
    }
    final lines = text.isEmpty ? 0 : text.split('\n').length - (text.endsWith('\n') ? 1 : 0);
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final bytes = text.length;
    return CommandResult(stdout: '$lines $words $bytes\n');
  }

  CommandResult _apt(List<String> args) {
    if (args.isEmpty) return const CommandResult(stdout: 'apt 2.4.11 (amd64) — cloudamned offline simulator\n');
    if (args.first == 'update') {
      _aptUpdated = true;
      completedActions.add('apt_update');
      return const CommandResult(
        stdout: 'Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease\n'
            'Get:2 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]\n'
            'Get:3 http://security.ubuntu.com/ubuntu jammy-security InRelease [110 kB]\n'
            'Fetched 229 kB in 0s (simulated)\n'
            'Reading package lists... Done\n'
            'Building dependency tree... Done\n'
            'All packages are up to date.\n',
      );
    }
    if (args.first == 'install') {
      final pkgs = args.skip(1).where((a) => !a.startsWith('-') && a != '-y' && a != '--yes').toList();
      if (pkgs.isEmpty) {
        return const CommandResult(stdout: '', stderr: 'E: No packages specified\n', exitCode: 100);
      }
      if (!_aptUpdated) {
        // Still allow install (like real apt often does) but warn
        completedActions.add('apt_install_without_update');
      }
      for (final p in pkgs) {
        fs.packages.add(p);
        if (p == 'nginx') {
          fs.services['nginx'] = 'inactive';
          final conf = fs.root.dir('etc').dir('nginx');
          conf.file(
            'nginx.conf',
            'user www-data;\nworker_processes auto;\nevents { worker_connections 768; }\n'
            'http {\n  server {\n    listen 80 default_server;\n    root /var/www/html;\n'
            '    index index.html;\n  }\n}\n',
          );
          fs.root.dir('var').dir('www').dir('html').file(
                'index.html',
                '<!DOCTYPE html><html><body><h1>Welcome to nginx!</h1></body></html>\n',
              );
          completedActions.add('nginx_installed');
        }
      }
      completedActions.add('apt_install');
      return CommandResult(
        stdout: 'Reading package lists... Done\n'
            'Building dependency tree... Done\n'
            'Reading state information... Done\n'
            'The following NEW packages will be installed:\n  ${pkgs.join(' ')}\n'
            '0 upgraded, ${pkgs.length} newly installed, 0 to remove.\n'
            'Need to get 1,234 kB of archives.\n'
            'After this operation, 5,120 kB of additional disk space will be used.\n'
            'Get:1 http://archive.ubuntu.com/ubuntu jammy/main ${pkgs.first} [1234 kB]\n'
            'Fetched 1,234 kB in 0s (simulated)\n'
            'Selecting previously unselected package ${pkgs.first}.\n'
            '(Reading database ... 120000 files and directories currently installed.)\n'
            'Preparing to unpack .../${pkgs.first}.deb ...\n'
            'Unpacking ${pkgs.first} ...\n'
            'Setting up ${pkgs.join(' ')} ...\n'
            'Processing triggers for man-db (2.10.2-1) ...\n',
      );
    }
    if (args.first == 'remove' || args.first == 'purge') {
      final pkgs = args.skip(1).where((a) => !a.startsWith('-'));
      for (final p in pkgs) {
        fs.packages.remove(p);
        fs.services.remove(p);
      }
      return const CommandResult(stdout: 'Removing packages... Done\n');
    }
    if (args.first == 'list' || (args.length >= 2 && args[0] == '--installed')) {
      return CommandResult(stdout: fs.packages.map((p) => '$p/now jammy [installed]').join('\n') + '\n');
    }
    return CommandResult(stdout: 'E: Invalid operation ${args.first}\n', exitCode: 100);
  }

  CommandResult _yum(List<String> args) {
    if (args.isNotEmpty && args.first == 'install') {
      final pkgs = args.skip(1).where((a) => !a.startsWith('-'));
      fs.packages.addAll(pkgs);
      return const CommandResult(stdout: 'Installed (simulated)\nComplete!\n');
    }
    return const CommandResult(stdout: 'yum simulated on cloudamned\n');
  }

  CommandResult _useradd(List<String> args) {
    final name = args.where((a) => !a.startsWith('-')).lastOrNull;
    if (name == null) {
      return const CommandResult(stdout: '', stderr: 'useradd: missing user name\n', exitCode: 1);
    }
    final home = fs.root.dir('home').dir(name);
    home.owner = name;
    home.group = name;
    completedActions.add('user_created');
    if (name == 'deploy') completedActions.add('user_deploy');
    return const CommandResult(stdout: '');
  }

  CommandResult _ufw(List<String> args) {
    if (args.isEmpty || args.first == 'status') {
      return CommandResult(
        stdout: 'Status: ${completedActions.contains('ufw_active') ? 'active' : 'inactive'}\n'
            'To                         Action      From\n'
            '--                         ------      ----\n'
            '22/tcp                     ALLOW       Anywhere\n'
            '80/tcp                     ALLOW       Anywhere\n',
      );
    }
    if (args.first == 'enable') {
      completedActions.add('ufw_active');
      return const CommandResult(stdout: 'Firewall is active and enabled on system startup\n');
    }
    if (args.first == 'allow') {
      if (args.any((a) => a.contains('22') || a.toLowerCase() == 'ssh')) {
        completedActions.add('ufw_allow_22');
      }
      return CommandResult(stdout: 'Rule added (${args.skip(1).join(' ')})\n');
    }
    if (args.first == 'deny') {
      return CommandResult(stdout: 'Rule added (${args.skip(1).join(' ')})\n');
    }
    return const CommandResult(stdout: 'ERROR: Invalid syntax\n', exitCode: 1);
  }

  CommandResult _tree(List<String> args) {
    final start = args.isEmpty ? '.' : args.first;
    final node = fs.resolve(start);
    if (node == null) {
      return CommandResult(stdout: '', stderr: 'tree: $start: No such file or directory\n', exitCode: 1);
    }
    final out = StringBuffer('${fs.expandPath(start)}\n');
    void walk(FsNode n, String prefix) {
      final entries = n.children?.entries.toList() ?? [];
      for (var i = 0; i < entries.length; i++) {
        final last = i == entries.length - 1;
        final e = entries[i];
        out.writeln('$prefix${last ? '└──' : '├──'} ${e.key}');
        if (e.value.isDir) {
          walk(e.value, '$prefix${last ? '    ' : '│   '}');
        }
      }
    }

    walk(node, '');
    return CommandResult(stdout: out.toString());
  }
}
