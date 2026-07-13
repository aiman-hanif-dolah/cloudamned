class MeetingScenario {
  const MeetingScenario({
    required this.id,
    required this.title,
    required this.setting,
    required this.agenda,
    required this.prompt,
    required this.keywords,
  });

  final String id;
  final String title;
  final String setting;
  final List<String> agenda;
  final String prompt;
  final List<String> keywords;
}

class MeetingScore {
  const MeetingScore({
    required this.communication,
    required this.decisions,
    required this.technical,
    required this.overall,
    required this.feedback,
  });

  final int communication;
  final int decisions;
  final int technical;
  final int overall;
  final String feedback;
}

abstract final class MeetingBank {
  static const scenarios = <MeetingScenario>[
    MeetingScenario(
      id: 'standup',
      title: 'Daily stand-up',
      setting: 'Platform engineering squad',
      agenda: ['Yesterday', 'Today', 'Blockers'],
      prompt: 'Deliver your stand-up update as Cloud Technical Engineer on the ABC migration.',
      keywords: ['yesterday', 'today', 'blocker', 'ticket', 'vpc', 'migration'],
    ),
    MeetingScenario(
      id: 'arch-review',
      title: 'Architecture review',
      setting: 'Design authority board',
      agenda: ['Context', 'Options', 'Risks', 'Decision'],
      prompt: 'Defend multi-AZ private data tier and reject public RDS.',
      keywords: ['multi-az', 'private', 'risk', 'security', 'cost', 'trade-off'],
    ),
    MeetingScenario(
      id: 'sprint',
      title: 'Sprint planning',
      setting: '2-week sprint',
      agenda: ['Backlog', 'Capacity', 'Commitments'],
      prompt: 'Propose sprint goals: landing zone controls + pilot web migration.',
      keywords: ['sprint', 'pilot', 'landing zone', 'story', 'risk', 'dependency'],
    ),
    MeetingScenario(
      id: 'customer',
      title: 'Customer meeting',
      setting: 'Weekly steering',
      agenda: ['Status', 'Risks', 'Decisions needed'],
      prompt: 'Explain timeline slip risk if SQL licenses arrive late—ask for decision.',
      keywords: ['timeline', 'risk', 'decision', 'budget', 'mitigation', 'owner'],
    ),
    MeetingScenario(
      id: 'exec',
      title: 'Executive presentation',
      setting: 'C-level 15 minutes',
      agenda: ['Why', 'What', 'Cost', 'Ask'],
      prompt: 'Pitch HA landing zone value without jargon overload.',
      keywords: ['uptime', 'risk', 'cost', 'security', 'ask', 'outcome'],
    ),
    MeetingScenario(
      id: 'bridge',
      title: 'Incident bridge call',
      setting: 'SEV-2 bridge',
      agenda: ['Impact', 'Timeline', 'Actions', 'Comms'],
      prompt: 'Lead first update on website-down bridge.',
      keywords: ['impact', 'timeline', 'action', 'owner', 'eta', 'customer'],
    ),
  ];

  static MeetingScore grade(MeetingScenario m, String speech) {
    final text = speech.toLowerCase();
    final hits = m.keywords.where((k) => text.contains(k)).length;
    final technical = (25 + hits / m.keywords.length * 75).round().clamp(0, 100);
    final communication = speech.trim().length < 50
        ? 35
        : speech.trim().length > 400
            ? 70
            : 85;
    final decisions = text.contains('decision') ||
            text.contains('next') ||
            text.contains('owner') ||
            text.contains('will')
        ? 80
        : 50;
    final overall = ((technical + communication + decisions) / 3).round();
    return MeetingScore(
      communication: communication,
      decisions: decisions,
      technical: technical,
      overall: overall,
      feedback:
          'Hits $hits/${m.keywords.length} agenda signals. '
          '${overall >= 70 ? 'Clear and actionable.' : 'Add owners, decisions, and less waffle.'}',
    );
  }
}
