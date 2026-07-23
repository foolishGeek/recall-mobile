// Recall · GetPage table. One entry per route; tab routes share ShellView so the
// route drives the initial tab. Navigate with Get.toNamed(Routes.x).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/ai_chat/binding/ai_chat_binding.dart';
import '../../modules/ai_chat/view/ai_chat_view.dart';
import '../../modules/bucket/binding/bucket_binding.dart';
import '../../modules/bucket/view/bucket_view.dart';
import '../../modules/bucket_config/binding/bucket_config_binding.dart';
import '../../modules/bucket_config/view/bucket_config_view.dart';
import '../../modules/empty/binding/empty_binding.dart';
import '../../modules/empty/empty_variant.dart';
import '../../modules/empty/view/empty_view.dart';
import '../../modules/node/binding/node_binding.dart';
import '../../modules/node/view/node_view.dart';
import '../../modules/node_add/binding/node_add_binding.dart';
import '../../modules/node_add/view/node_add_view.dart';
import '../../modules/onboarding/binding/onboarding_binding.dart';
import '../../modules/onboarding/view/onboarding_view.dart';
import '../../modules/paywall/binding/paywall_binding.dart';
import '../../modules/paywall/view/paywall_view.dart';
import '../../modules/quiz_config/binding/quiz_config_binding.dart';
import '../../modules/quiz_config/view/quiz_config_view.dart';
import '../../modules/quiz_play/binding/quiz_play_binding.dart';
import '../../modules/quiz_play/view/quiz_play_view.dart';
import '../../modules/quiz_results/binding/quiz_results_binding.dart';
import '../../modules/quiz_results/view/quiz_results_view.dart';
import '../../modules/review/binding/review_binding.dart';
import '../../modules/review/view/review_view.dart';
import '../../modules/settings/binding/settings_binding.dart';
import '../../modules/settings/view/settings_view.dart';
import '../../modules/shell/binding/shell_binding.dart';
import '../../modules/shell/view/shell_view.dart';
import '../../modules/signin/binding/signin_binding.dart';
import '../../modules/signin/view/signin_view.dart';
import '../../modules/splash/binding/splash_binding.dart';
import '../../modules/splash/view/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static GetPage _shellPage(String name) => GetPage(
        name: name,
        page: () => const ShellView(),
        binding: ShellBinding(),
      );

  static final pages = <GetPage>[
    // Auth flow
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.signin,
      page: () => const SigninView(),
      binding: SigninBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),

    // Tab shell (route drives the initial tab)
    _shellPage(Routes.today),
    _shellPage(Routes.buckets),
    _shellPage(Routes.quiz),
    _shellPage(Routes.insights),
    _shellPage(Routes.you),

    // Stacks
    GetPage(
      name: Routes.review,
      page: () => const ReviewView(),
      binding: ReviewBinding(),
      // Present as a modal that slides up over the shell and reverses on exit,
      // so entering/leaving review feels like a card, not a hard cut.
      fullscreenDialog: true,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    ),

    // Buckets / nodes
    GetPage(
      name: Routes.bucket,
      page: () => const BucketView(),
      binding: BucketBinding(),
    ),
    GetPage(
      name: Routes.bucketConfig,
      page: () => const BucketConfigView(),
      binding: BucketConfigBinding(),
    ),
    GetPage(
      name: Routes.node,
      page: () => const NodeView(),
      binding: NodeBinding(),
    ),
    GetPage(
      name: Routes.nodeAdd,
      page: () => const NodeAddView(),
      binding: NodeAddBinding(),
    ),

    // Quiz flow
    GetPage(
      name: Routes.quizConfig,
      page: () => const QuizConfigView(),
      binding: QuizConfigBinding(),
    ),
    GetPage(
      name: Routes.quizPlay,
      page: () => const QuizPlayView(),
      binding: QuizPlayBinding(),
    ),
    GetPage(
      name: Routes.quizResults,
      page: () => const QuizResultsView(),
      binding: QuizResultsBinding(),
    ),

    // Modals
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.paywall,
      page: () => const PaywallView(),
      binding: PaywallBinding(),
      // Sheet slide-up (S23 §9): present from below, 420ms easeOutCubic.
      fullscreenDialog: true,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    ),
    GetPage(
      name: Routes.aiChat,
      page: () => const AiChatView(),
      binding: AiChatBinding(),
    ),

    // Empty states (deep-link fallbacks)
    GetPage(
      name: Routes.emptyBuckets,
      page: () => const EmptyView(variant: EmptyVariant.buckets),
      binding: EmptyBinding(),
    ),
    GetPage(
      name: Routes.emptyToday,
      page: () => const EmptyView(variant: EmptyVariant.today),
      binding: EmptyBinding(),
    ),
    GetPage(
      name: Routes.emptyInsights,
      page: () => const EmptyView(variant: EmptyVariant.insights),
      binding: EmptyBinding(),
    ),
  ];
}
