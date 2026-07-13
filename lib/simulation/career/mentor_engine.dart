/// Local Principal Cloud Architect mentor — guides, never dumps answers.
class MentorEngine {
  final List<String> history = [];

  static const _socratic = [
    'What problem does the customer actually feel day-to-day?',
    'If the budget were cut 30%, what would you drop first — and why not security?',
    'Which component, if it fails, takes the whole business offline?',
    'Are you solving a technology preference or a business constraint?',
    'What is the blast radius of this change on Sunday night?',
    'How will a junior on-call know this is broken at 2am?',
    'What is your abort criteria for cutover?',
    'Did you verify backups restore, or only that backups exist?',
    'Is multi-AZ buying availability or just a checkbox?',
    'Where does identity live after migration — and who owns break-glass?',
  ];

  static const _tradeoffs = [
    'Managed DB costs more than EC2 SQL but reduces 2am pages — which risk does the customer pay for?',
    'Single NAT saves money; dual NAT raises resilience. What is their RTO?',
    'Lift-and-shift is faster; replatform is cleaner. What is the timeline pressure?',
    'Public ALB is fine; public RDS is not. What trust boundary did you draw?',
  ];

  String coach({String? context, int step = 0}) {
    final pool = [..._socratic, ..._tradeoffs];
    final q = pool[(step + (context?.hashCode ?? 0)).abs() % pool.length];
    final msg =
        'Mentor (Principal Architect): $q\n\nThink out loud. I will not give the answer — defend your reasoning.';
    history.add(msg);
    return msg;
  }

  String challenge(String assumption) {
    final msg =
        'Mentor: You assumed "$assumption". What evidence from discovery supports that? '
        'What happens if the assumption is wrong in production?';
    history.add(msg);
    return msg;
  }

  String reviewDecision(String decision, {required List<String> missingDiscovery}) {
    if (missingDiscovery.isNotEmpty) {
      final msg =
          'Mentor: You chose "$decision" but discovery never covered: '
          '${missingDiscovery.take(3).join('; ')}. '
          'Revisit the customer before you terraform.';
      history.add(msg);
      return msg;
    }
    final msg =
        'Mentor: "$decision" may be valid. Explain cost, availability, security, and day-2 ops in one paragraph each.';
    history.add(msg);
    return msg;
  }
}
