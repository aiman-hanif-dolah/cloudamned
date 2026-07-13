class DockerResult {
  const DockerResult({required this.ok, required this.output});
  final bool ok;
  final String output;
}

class DockerImage {
  DockerImage({required this.id, required this.repository, required this.tag, required this.size});
  final String id;
  final String repository;
  final String tag;
  final String size;
}

class DockerContainer {
  DockerContainer({
    required this.id,
    required this.image,
    required this.command,
    required this.status,
    required this.names,
    this.ports = '',
  });
  final String id;
  final String image;
  String command;
  String status;
  final String names;
  String ports;
}

class DockerEngine {
  final List<DockerImage> images = [
    DockerImage(id: 'sha256:aaa111', repository: 'ubuntu', tag: '22.04', size: '77.8MB'),
    DockerImage(id: 'sha256:bbb222', repository: 'nginx', tag: 'alpine', size: '40.7MB'),
  ];
  final List<DockerContainer> containers = [];
  final Set<String> networks = {'bridge', 'host', 'none'};
  final Set<String> volumes = {};
  final Set<String> completedActions = {};
  bool installed = true;
  int _c = 1;

  DockerResult exec(String line) {
    final t = line.trim();
    if (t.isEmpty) return const DockerResult(ok: true, output: '');
    final parts = t.split(RegExp(r'\s+'));
    if (parts.first != 'docker' && parts.first != 'docker-compose' && parts.first != 'compose') {
      return DockerResult(ok: false, output: 'docker: command expected, got ${parts.first}');
    }
    if (parts.first == 'docker-compose' || (parts.length > 1 && parts[0] == 'docker' && parts[1] == 'compose')) {
      return _compose(parts);
    }
    final args = parts.skip(1).toList();
    if (args.isEmpty) return const DockerResult(ok: true, output: 'Usage: docker [images|ps|run|build|...]');

    switch (args.first) {
      case 'version':
        return const DockerResult(ok: true, output: 'Docker version 24.0.7, build afdd53b (simulated)\n');
      case 'info':
        return DockerResult(
          ok: true,
          output: 'Client: Docker Engine - Community (simulated)\n'
              ' Containers: ${containers.length}\n'
              ' Images: ${images.length}\n'
              ' Server Version: 24.0.7\n',
        );
      case 'images':
      case 'image':
        return _images();
      case 'ps':
        return _ps(args.contains('-a'));
      case 'run':
        return _run(args.skip(1).toList());
      case 'build':
        completedActions.add('image_built');
        final tagIdx = args.indexOf('-t');
        final name = tagIdx >= 0 && tagIdx + 1 < args.length ? args[tagIdx + 1] : 'app:latest';
        final repo = name.split(':').first;
        final tag = name.contains(':') ? name.split(':').last : 'latest';
        images.add(DockerImage(id: 'sha256:build${_c++}', repository: repo, tag: tag, size: '125MB'));
        return DockerResult(
          ok: true,
          output: 'Step 1/5 : FROM nginx:alpine\n'
              'Step 2/5 : COPY . /usr/share/nginx/html\n'
              'Successfully built sha256:build${_c - 1}\n'
              'Successfully tagged $name\n',
        );
      case 'stop':
        return _setStatus(args.skip(1).toList(), 'Exited (0)');
      case 'start':
        return _setStatus(args.skip(1).toList(), 'Up 2 seconds');
      case 'rm':
        for (final id in args.skip(1)) {
          containers.removeWhere((c) => c.id.startsWith(id) || c.names == id);
        }
        return const DockerResult(ok: true, output: '');
      case 'rmi':
        for (final id in args.skip(1)) {
          images.removeWhere((i) => i.id.contains(id) || i.repository == id);
        }
        return const DockerResult(ok: true, output: 'Untagged / Deleted (simulated)\n');
      case 'logs':
        return const DockerResult(
          ok: true,
          output: '10.0.1.5 - - [13/Jul/2026:10:00:01] "GET / HTTP/1.1" 200 612\n'
              'nginx started successfully\n',
        );
      case 'exec':
        return const DockerResult(ok: true, output: 'root@container:/# (simulated exec session)\n');
      case 'network':
        if (args.length > 1 && args[1] == 'ls') {
          return DockerResult(
            ok: true,
            output: 'NETWORK ID     NAME      DRIVER\n'
                '${networks.map((n) => '${n.hashCode.toRadixString(16).padLeft(12, '0').substring(0, 12)}   $n      bridge').join('\n')}\n',
          );
        }
        if (args.length > 2 && args[1] == 'create') {
          networks.add(args[2]);
          completedActions.add('network_created');
          return DockerResult(ok: true, output: args[2]);
        }
        return const DockerResult(ok: true, output: 'docker network [ls|create]');
      case 'volume':
        if (args.length > 1 && args[1] == 'ls') {
          return DockerResult(
            ok: true,
            output: 'DRIVER    VOLUME NAME\n${volumes.map((v) => 'local     $v').join('\n')}\n',
          );
        }
        if (args.length > 2 && args[1] == 'create') {
          volumes.add(args[2]);
          completedActions.add('volume_created');
          return DockerResult(ok: true, output: args[2]);
        }
        return const DockerResult(ok: true, output: 'docker volume [ls|create]');
      case 'pull':
        final ref = args.length > 1 ? args[1] : 'nginx:latest';
        final repo = ref.split(':').first;
        final tag = ref.contains(':') ? ref.split(':').last : 'latest';
        images.add(DockerImage(id: 'sha256:pull${_c++}', repository: repo, tag: tag, size: '90MB'));
        return DockerResult(ok: true, output: '$ref: Pull complete (simulated)\n');
      case 'push':
        completedActions.add('image_pushed');
        return DockerResult(ok: true, output: 'The push refers to repository [${args.length > 1 ? args[1] : 'app'}]\nlatest: digest: sha256:abc size: 1234\n');
      case 'inspect':
        return const DockerResult(ok: true, output: '[\n  {\n    "Id": "simulated",\n    "State": {"Status": "running"}\n  }\n]\n');
      default:
        return DockerResult(ok: false, output: 'docker: unknown command: ${args.first}\n');
    }
  }

  DockerResult _images() {
    final buf = StringBuffer('REPOSITORY   TAG       IMAGE ID       SIZE\n');
    for (final i in images) {
      buf.writeln('${i.repository.padRight(12)} ${i.tag.padRight(9)} ${i.id.substring(7, 19)}   ${i.size}');
    }
    return DockerResult(ok: true, output: buf.toString());
  }

  DockerResult _ps(bool all) {
    final list = all ? containers : containers.where((c) => c.status.startsWith('Up'));
    final buf = StringBuffer('CONTAINER ID   IMAGE     COMMAND   STATUS   PORTS   NAMES\n');
    for (final c in list) {
      buf.writeln('${c.id}   ${c.image.padRight(8)} ${c.command.padRight(8)} ${c.status.padRight(8)} ${c.ports.padRight(6)} ${c.names}');
    }
    return DockerResult(ok: true, output: buf.toString());
  }

  DockerResult _run(List<String> args) {
    var detach = false;
    var name = 'container_${_c}';
    var ports = '';
    final imageArgs = <String>[];
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '-d') {
        detach = true;
      } else if (args[i] == '--name' && i + 1 < args.length) {
        name = args[++i];
      } else if (args[i] == '-p' && i + 1 < args.length) {
        ports = args[++i];
      } else if (!args[i].startsWith('-')) {
        imageArgs.add(args[i]);
      }
    }
    if (imageArgs.isEmpty) {
      return const DockerResult(ok: false, output: 'docker: image name required\n');
    }
    final image = imageArgs.first;
    final id = (_c++).toRadixString(16).padLeft(12, '0');
    containers.add(DockerContainer(
      id: id,
      image: image,
      command: '"/bin/sh"',
      status: 'Up 1 second',
      names: name,
      ports: ports,
    ));
    completedActions.add('container_running');
    if (detach) return DockerResult(ok: true, output: '$id\n');
    return DockerResult(ok: true, output: '$id\n(container running in foreground simulation)\n');
  }

  DockerResult _setStatus(List<String> ids, String status) {
    for (final id in ids) {
      for (final c in containers) {
        if (c.id.startsWith(id) || c.names == id) c.status = status;
      }
    }
    return DockerResult(ok: true, output: ids.join('\n') + '\n');
  }

  DockerResult _compose(List<String> parts) {
    final action = parts.contains('up')
        ? 'up'
        : parts.contains('down')
            ? 'down'
            : parts.contains('ps')
                ? 'ps'
                : 'help';
    switch (action) {
      case 'up':
        completedActions.add('compose_up');
        exec('docker run -d --name web -p 8080:80 nginx:alpine');
        exec('docker run -d --name db postgres:15');
        return const DockerResult(
          ok: true,
          output: 'Creating network "app_default"\n'
              'Creating volume "app_dbdata"\n'
              'Creating web ... done\n'
              'Creating db  ... done\n',
        );
      case 'down':
        containers.clear();
        return const DockerResult(ok: true, output: 'Stopping containers... done\nRemoving network... done\n');
      case 'ps':
        return _ps(true);
      default:
        return const DockerResult(ok: true, output: 'docker compose [up|down|ps]\n');
    }
  }
}
