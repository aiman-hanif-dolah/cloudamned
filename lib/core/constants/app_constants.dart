abstract final class AppConstants {
  static const appName = 'cloudamned';
  static const appTagline = 'Cloud Technical Engineer Simulator';
  static const version = '1.0.0';

  static const defaultWindowWidth = 1440.0;
  static const defaultWindowHeight = 900.0;
  /// Allow narrow desktop windows / phone-like previews.
  static const minWindowWidth = 360.0;
  static const minWindowHeight = 560.0;

  static const sidebarWidth = 240.0;
  static const sidebarCollapsedWidth = 56.0;
  static const activityBarWidth = 48.0;

  /// Below this width: drawer navigation instead of permanent sidebar.
  static const mobileBreakpoint = 800.0;
  /// Compact padding / single-column content.
  static const compactBreakpoint = 600.0;

  static const xpPerLab = 100;
  static const xpPerModule = 500;
  static const xpPerExamPass = 750;
  static const xpPerScenario = 200;
  static const xpPerInterview = 300;

  static const hiveBoxProgress = 'progress';
  static const hiveBoxSettings = 'settings';
  static const hiveBoxAchievements = 'achievements';
  static const hiveBoxSimState = 'sim_state';

  static const dbName = 'cloudamned.db';
  static const dbVersion = 1;
}
