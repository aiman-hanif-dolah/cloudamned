class K8sResult {
  const K8sResult({required this.ok, required this.output});
  final bool ok;
  final String output;
}

class K8sObject {
  K8sObject({
    required this.kind,
    required this.name,
    required this.namespace,
    this.replicas = 1,
    this.ready = 1,
    this.image = '',
    this.type = '',
  });
  final String kind;
  final String name;
  String namespace;
  int replicas;
  int ready;
  String image;
  String type;
}

class K8sEngine {
  final List<K8sObject> objects = [
    K8sObject(kind: 'Namespace', name: 'default', namespace: ''),
    K8sObject(kind: 'Namespace', name: 'kube-system', namespace: ''),
  ];
  final Set<String> completedActions = {};
  String currentNs = 'default';

  K8sResult exec(String line) {
    final t = line.trim();
    if (t.isEmpty) return const K8sResult(ok: true, output: '');
    final parts = t.split(RegExp(r'\s+'));
    if (parts.first != 'kubectl') {
      return K8sResult(ok: false, output: 'command not found: ${parts.first}');
    }
    final args = parts.skip(1).toList();
    if (args.isEmpty) return const K8sResult(ok: true, output: 'kubectl controls the Kubernetes cluster manager (simulated)\n');

    switch (args.first) {
      case 'version':
        return const K8sResult(ok: true, output: 'Client Version: v1.29.2\nServer Version: v1.29.2 (simulated)\n');
      case 'get':
        return _get(args.skip(1).toList());
      case 'describe':
        return _describe(args.skip(1).toList());
      case 'create':
        return _create(args.skip(1).toList());
      case 'apply':
        completedActions.add('k8s_apply');
        return const K8sResult(ok: true, output: 'deployment.apps/web configured\nservice/web configured\n');
      case 'delete':
        return _delete(args.skip(1).toList());
      case 'scale':
        return _scale(args.skip(1).toList());
      case 'rollout':
        return _rollout(args.skip(1).toList());
      case 'logs':
        return const K8sResult(ok: true, output: '2026-07-13T10:00:00Z app started\n2026-07-13T10:00:01Z listening :8080\n');
      case 'exec':
        return const K8sResult(ok: true, output: 'root@pod:/# (simulated)\n');
      case 'config':
        return K8sResult(ok: true, output: 'Current context: cloudamned-lab\nNamespace: $currentNs\n');
      case 'cluster-info':
        return const K8sResult(
          ok: true,
          output: 'Kubernetes control plane is running at https://127.0.0.1:6443 (simulated)\nCoreDNS is running\n',
        );
      default:
        return K8sResult(ok: false, output: 'error: unknown command "kubectl ${args.first}"\n');
    }
  }

  K8sResult _get(List<String> args) {
    if (args.isEmpty) return const K8sResult(ok: false, output: 'error: resource type required\n');
    final kind = _normalize(args.first);
    var ns = currentNs;
    final nsIdx = args.indexOf('-n');
    if (nsIdx >= 0 && nsIdx + 1 < args.length) ns = args[nsIdx + 1];
    if (kind == 'namespaces' || kind == 'namespace') {
      final buf = StringBuffer('NAME          STATUS   AGE\n');
      for (final o in objects.where((e) => e.kind == 'Namespace')) {
        buf.writeln('${o.name.padRight(13)} Active   10d');
      }
      return K8sResult(ok: true, output: buf.toString());
    }
    final items = objects.where((o) {
      if (o.kind == 'Namespace') return false;
      final matchKind = o.kind.toLowerCase().startsWith(kind.replaceAll('s', '')) ||
          '${o.kind.toLowerCase()}s' == kind ||
          o.kind.toLowerCase() == kind;
      return matchKind && (o.namespace == ns || kind.contains('node'));
    }).toList();

    // looser match
    final filtered = items.isNotEmpty
        ? items
        : objects.where((o) => o.kind.toLowerCase().contains(kind.replaceAll('s', '')) && o.namespace == ns).toList();

    if (kind.startsWith('po')) {
      final pods = objects.where((o) => o.kind == 'Pod' && o.namespace == ns);
      final buf = StringBuffer('NAME                     READY   STATUS    RESTARTS   AGE\n');
      for (final p in pods) {
        buf.writeln('${p.name.padRight(24)} ${p.ready}/${p.replicas}     Running   0          5m');
      }
      if (pods.isEmpty) buf.writeln('(no pods)');
      return K8sResult(ok: true, output: buf.toString());
    }
    if (kind.startsWith('deploy')) {
      final deps = objects.where((o) => o.kind == 'Deployment' && o.namespace == ns);
      final buf = StringBuffer('NAME   READY   UP-TO-DATE   AVAILABLE   AGE\n');
      for (final d in deps) {
        buf.writeln('${d.name.padRight(6)} ${d.ready}/${d.replicas}     ${d.replicas}            ${d.ready}           5m');
      }
      return K8sResult(ok: true, output: buf.toString());
    }
    if (kind.startsWith('svc') || kind == 'services') {
      final svcs = objects.where((o) => o.kind == 'Service' && o.namespace == ns);
      final buf = StringBuffer('NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE\n');
      for (final s in svcs) {
        buf.writeln('${s.name.padRight(6)} ${(s.type.isEmpty ? 'ClusterIP' : s.type).padRight(11)} 10.96.0.1       <none>        80/TCP    5m');
      }
      return K8sResult(ok: true, output: buf.toString());
    }
    final buf = StringBuffer('NAME\n');
    for (final o in filtered) {
      buf.writeln(o.name);
    }
    return K8sResult(ok: true, output: buf.toString());
  }

  K8sResult _describe(List<String> args) {
    if (args.length < 2) return const K8sResult(ok: false, output: 'error: specify resource\n');
    final name = args[1];
    final o = objects.where((e) => e.name == name).firstOrNull;
    if (o == null) return K8sResult(ok: false, output: 'Error from server (NotFound): $name not found\n');
    return K8sResult(
      ok: true,
      output: 'Name:         ${o.name}\n'
          'Namespace:    ${o.namespace}\n'
          'Kind:         ${o.kind}\n'
          'Replicas:     ${o.ready}/${o.replicas}\n'
          'Image:        ${o.image}\n'
          'Events:\n  Normal  Scheduled  pod assigned to node cloudamned-worker-1\n',
    );
  }

  K8sResult _create(List<String> args) {
    if (args.isEmpty) return const K8sResult(ok: false, output: 'error: missing type\n');
    if (args.first == 'deployment') {
      // kubectl create deployment web --image=nginx
      final name = args.length > 1 ? args[1] : 'web';
      var image = 'nginx';
      final imgIdx = args.indexOf('--image');
      if (imgIdx >= 0 && imgIdx + 1 < args.length) image = args[imgIdx + 1];
      // also --image=nginx form
      for (final a in args) {
        if (a.startsWith('--image=')) image = a.split('=').last;
      }
      objects.add(K8sObject(kind: 'Deployment', name: name, namespace: currentNs, replicas: 1, ready: 1, image: image));
      objects.add(K8sObject(kind: 'ReplicaSet', name: '$name-abc123', namespace: currentNs, replicas: 1, ready: 1, image: image));
      objects.add(K8sObject(kind: 'Pod', name: '$name-abc123-xyz', namespace: currentNs, replicas: 1, ready: 1, image: image));
      completedActions.add('deployment_created');
      completedActions.add('k8s_step');
      return K8sResult(ok: true, output: 'deployment.apps/$name created\n');
    }
    if (args.first == 'namespace' || args.first == 'ns') {
      final name = args[1];
      objects.add(K8sObject(kind: 'Namespace', name: name, namespace: ''));
      completedActions.add('namespace_created');
      return K8sResult(ok: true, output: 'namespace/$name created\n');
    }
    if (args.first == 'service' || args.first == 'svc') {
      // expose style simplified
      final name = args.length > 1 ? args[1] : 'web';
      objects.add(K8sObject(kind: 'Service', name: name, namespace: currentNs, type: 'ClusterIP'));
      completedActions.add('service_created');
      return K8sResult(ok: true, output: 'service/$name created\n');
    }
    return K8sResult(ok: false, output: 'error: unsupported create ${args.first}\n');
  }

  K8sResult _delete(List<String> args) {
    if (args.length < 2) return const K8sResult(ok: false, output: 'error: resource required\n');
    final name = args[1];
    objects.removeWhere((o) => o.name == name || o.name.startsWith('$name-'));
    return K8sResult(ok: true, output: '${args[0]}/$name deleted\n');
  }

  K8sResult _scale(List<String> args) {
    // kubectl scale deployment web --replicas=3
    final name = args.length > 1 ? args[1] : '';
    var replicas = 1;
    for (final a in args) {
      if (a.startsWith('--replicas=')) replicas = int.tryParse(a.split('=').last) ?? 1;
    }
    final dep = objects.where((o) => o.kind == 'Deployment' && o.name == name).firstOrNull;
    if (dep == null) return K8sResult(ok: false, output: 'Error: deployment $name not found\n');
    dep.replicas = replicas;
    dep.ready = replicas;
    // adjust pods
    objects.removeWhere((o) => o.kind == 'Pod' && o.name.startsWith('$name-'));
    for (var i = 0; i < replicas; i++) {
      objects.add(K8sObject(
        kind: 'Pod',
        name: '$name-abc123-p$i',
        namespace: currentNs,
        replicas: 1,
        ready: 1,
        image: dep.image,
      ));
    }
    completedActions.add('scaled');
    return K8sResult(ok: true, output: 'deployment.apps/$name scaled\n');
  }

  K8sResult _rollout(List<String> args) {
    if (args.contains('status')) {
      completedActions.add('rollout_ok');
      return const K8sResult(ok: true, output: 'deployment "web" successfully rolled out\n');
    }
    if (args.contains('undo')) {
      return const K8sResult(ok: true, output: 'deployment.apps/web rolled back\n');
    }
    return const K8sResult(ok: true, output: 'kubectl rollout [status|undo] deployment/<name>\n');
  }

  String _normalize(String k) => k.toLowerCase();
}
