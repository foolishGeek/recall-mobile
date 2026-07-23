// Recall · route names. Const strings only — the single source of route ids.
// Navigate with Get.toNamed(Routes.review). Pages are wired in app_pages.dart.

abstract class Routes {
  Routes._();

  // Auth flow
  static const splash = '/splash';
  static const signin = '/signin';
  static const onboarding = '/onboarding';

  // Tab shell
  static const today = '/today';
  static const buckets = '/buckets';
  static const quiz = '/quiz';
  static const insights = '/insights';
  static const you = '/you';

  // Stacks
  static const review = '/review';

  // Buckets / nodes
  static const bucket = '/bucket';
  static const bucketConfig = '/bucket/config';
  static const node = '/node';
  static const nodeAdd = '/node/add';

  // Quiz flow
  static const quizConfig = '/quiz/config';
  static const quizPlay = '/quiz/play';
  static const quizResults = '/quiz/results';

  // Modals
  static const settings = '/settings';
  static const paywall = '/paywall';
  static const aiChat = '/ai/chat';

  // Empty states
  static const emptyBuckets = '/empty/buckets';
  static const emptyToday = '/empty/today';
  static const emptyInsights = '/empty/insights';
}
