import 'package:flutter/material.dart';

import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';

class WindowsServerPage extends StatefulWidget {
  const WindowsServerPage({super.key});

  @override
  State<WindowsServerPage> createState() => _WindowsServerPageState();
}

class _WindowsServerPageState extends State<WindowsServerPage> {
  final _roles = <String, bool>{
    'Web Server (IIS)': false,
    'DNS Server': false,
    'DHCP Server': false,
    'Active Directory Domain Services': false,
    'Remote Desktop Services': false,
    'File and Storage Services': false,
  };
  final _log = <String>['Server Manager — cloudamned-WIN01 (simulated)'];
  final _ps = TextEditingController();
  final _psOut = <String>[];

  void _install(String role) {
    setState(() {
      _roles[role] = true;
      _log.add('Install-WindowsFeature: $role → Success');
      _log.add('Restart may be required (simulated: not needed)');
    });
  }

  void _runPs(String cmd) {
    final c = cmd.trim().toLowerCase();
    String out;
    if (c.startsWith('get-windowsfeature') || c.contains('feature')) {
      out = _roles.entries.map((e) => '${e.key.padRight(40)} ${e.value ? 'Installed' : 'Available'}').join('\n');
    } else if (c.startsWith('get-service')) {
      out = 'Status   Name               DisplayName\nRunning  W3SVC              World Wide Web Publishing\nRunning  DNS                DNS Server\nStopped  DHCPServer         DHCP Server';
    } else if (c.startsWith('get-localuser') || c.contains('user')) {
      out = 'Name          Enabled\nAdministrator True\ncloudeng      True';
    } else if (c.startsWith('new-localuser')) {
      out = 'User created (simulated)';
    } else if (c.contains('firewall')) {
      out = 'Name                  Enabled\nDomain Profile        True\nPrivate Profile       True\nPublic Profile        True';
    } else if (c == 'help' || c.isEmpty) {
      out = 'Simulated PowerShell: Get-WindowsFeature, Get-Service, Get-LocalUser, New-LocalUser, Get-NetFirewallProfile';
    } else {
      out = 'Command completed (simulated): $cmd';
    }
    setState(() {
      _psOut.add('PS C:\\> $cmd');
      _psOut.add(out);
    });
    _ps.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShadSectionHeader(
            title: 'Windows Server Manager',
            subtitle: 'Roles, features, users, firewall, PowerShell — offline simulation',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ShadPanel(
                    title: 'Roles & Features',
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final e in _roles.entries)
                          ListTile(
                            dense: true,
                            leading: Icon(
                              e.value ? Icons.check_box : Icons.check_box_outline_blank,
                              color: e.value ? ShadcnColors.success : ShadcnColors.mutedForeground,
                              size: 18,
                            ),
                            title: Text(e.key, style: const TextStyle(fontSize: 13)),
                            trailing: e.value
                                ? const ShadBadge(label: 'Installed', variant: ShadBadgeVariant.success)
                                : ShadButton(
                                    size: ShadButtonSize.sm,
                                    onPressed: () => _install(e.key),
                                    child: const Text('Install'),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadPanel(
                    title: 'PowerShell',
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: const Color(0xFF012456),
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            child: ListView(
                              children: [
                                for (final l in _psOut)
                                  Text(l,
                                      style: const TextStyle(
                                          fontFamily: 'Consolas',
                                          fontSize: 12,
                                          color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        TextField(
                          controller: _ps,
                          style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                          decoration: const InputDecoration(
                            prefixText: 'PS> ',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onSubmitted: _runPs,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 260,
                  child: ShadPanel(
                    title: 'Event log',
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        for (final l in _log.reversed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(l, style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                          ),
                      ],
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
}
