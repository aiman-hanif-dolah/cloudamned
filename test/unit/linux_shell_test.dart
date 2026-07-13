import 'package:cloudamned/simulation/linux/linux_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LinuxShell shell;

  setUp(() {
    shell = LinuxShell();
  });

  test('pwd returns home directory', () {
    final r = shell.exec('pwd');
    expect(r.ok, isTrue);
    expect(r.stdout.trim(), '/home/cloudeng');
  });

  test('mkdir and ls work', () {
    expect(shell.exec('mkdir demo').ok, isTrue);
    final ls = shell.exec('ls');
    expect(ls.stdout, contains('demo'));
  });

  test('nginx requires install then enable restart', () {
    // Not installed yet
    final before = shell.exec('systemctl start nginx');
    expect(before.ok, isFalse);

    expect(shell.exec('sudo apt update').ok, isTrue);
    expect(shell.completedActions.contains('apt_update'), isTrue);

    expect(shell.exec('sudo apt install nginx').ok, isTrue);
    expect(shell.completedActions.contains('nginx_installed'), isTrue);

    expect(shell.exec('sudo systemctl enable nginx').ok, isTrue);
    expect(shell.completedActions.contains('nginx_enabled'), isTrue);

    expect(shell.exec('sudo systemctl restart nginx').ok, isTrue);
    expect(shell.completedActions.contains('nginx_running'), isTrue);

    final curl = shell.exec('curl http://localhost');
    expect(curl.ok, isTrue);
    expect(curl.stdout.toLowerCase(), contains('nginx'));
  });

  test('chmod records action', () {
    shell.exec('touch script.sh');
    shell.exec('chmod 755 script.sh');
    expect(shell.completedActions.contains('chmod_755'), isTrue);
  });

  test('unknown command fails', () {
    final r = shell.exec('notacommand');
    expect(r.exitCode, 127);
  });
}
