/// Professional progression inside fictional consulting firm (cloudamned).
enum CareerRank {
  graduateEngineer,
  cloudEngineer,
  cloudTechnicalEngineer,
  seniorCloudEngineer,
  solutionsArchitect,
  principalCloudArchitect,
  cloudConsultant,
  technicalLead,
  cloudPracticeManager,
}

extension CareerRankX on CareerRank {
  String get title => switch (this) {
        CareerRank.graduateEngineer => 'Graduate Cloud Technical Engineer',
        CareerRank.cloudEngineer => 'Cloud Engineer',
        CareerRank.cloudTechnicalEngineer => 'Cloud Technical Engineer',
        CareerRank.seniorCloudEngineer => 'Senior Cloud Engineer',
        CareerRank.solutionsArchitect => 'Solutions Architect',
        CareerRank.principalCloudArchitect => 'Principal Cloud Architect',
        CareerRank.cloudConsultant => 'Cloud Consultant',
        CareerRank.technicalLead => 'Technical Lead',
        CareerRank.cloudPracticeManager => 'Cloud Practice Manager',
      };

  int get order => index;

  int get xpToPromote => switch (this) {
        CareerRank.graduateEngineer => 500,
        CareerRank.cloudEngineer => 1200,
        CareerRank.cloudTechnicalEngineer => 2500,
        CareerRank.seniorCloudEngineer => 4000,
        CareerRank.solutionsArchitect => 6000,
        CareerRank.principalCloudArchitect => 8500,
        CareerRank.cloudConsultant => 11000,
        CareerRank.technicalLead => 14000,
        CareerRank.cloudPracticeManager => 999999,
      };

  String get unlocks => switch (this) {
        CareerRank.graduateEngineer => 'SME projects, single-region, guided mentor',
        CareerRank.cloudEngineer => 'Mid-size migrations, multi-AZ, ticket ownership',
        CareerRank.cloudTechnicalEngineer => 'Enterprise landing zones, SEV-2 lead',
        CareerRank.seniorCloudEngineer => 'Multi-account, hybrid, cost ownership',
        CareerRank.solutionsArchitect => 'Board-level design, multi-cloud tradeoffs',
        CareerRank.principalCloudArchitect => 'Platform standards, Well-Architected reviews',
        CareerRank.cloudConsultant => 'Pre-sales, complex discovery, difficult stakeholders',
        CareerRank.technicalLead => 'Mentoring juniors, practice delivery quality',
        CareerRank.cloudPracticeManager => 'Portfolio of accounts, hiring bar, P&L awareness',
      };

  CareerRank? get next {
    final i = index + 1;
    if (i >= CareerRank.values.length) return null;
    return CareerRank.values[i];
  }
}

class CareerProgression {
  CareerProgression({
    this.rank = CareerRank.graduateEngineer,
    this.careerXp = 0,
    this.projectsCompleted = 0,
    this.companyName = 'Nusantara Cloud Consulting',
  });

  CareerRank rank;
  int careerXp;
  int projectsCompleted;
  String companyName;

  double get rankProgress {
    final need = rank.xpToPromote;
    if (need >= 999999) return 1;
    return (careerXp / need).clamp(0.0, 1.0);
  }

  bool addXp(int amount) {
    careerXp += amount;
    var promoted = false;
    while (rank.next != null && careerXp >= rank.xpToPromote) {
      careerXp -= rank.xpToPromote;
      rank = rank.next!;
      promoted = true;
    }
    return promoted;
  }

  Map<String, dynamic> toJson() => {
        'rank': rank.name,
        'careerXp': careerXp,
        'projectsCompleted': projectsCompleted,
        'companyName': companyName,
      };

  factory CareerProgression.fromJson(Map<String, dynamic> j) {
    final rankName = j['rank'] as String? ?? CareerRank.graduateEngineer.name;
    return CareerProgression(
      rank: CareerRank.values.firstWhere(
        (r) => r.name == rankName,
        orElse: () => CareerRank.graduateEngineer,
      ),
      careerXp: j['careerXp'] as int? ?? 0,
      projectsCompleted: j['projectsCompleted'] as int? ?? 0,
      companyName: j['companyName'] as String? ?? 'Nusantara Cloud Consulting',
    );
  }
}
