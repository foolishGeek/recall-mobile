// Feature access policy surface. Add a new pro/free feature here, then one
// case in TierGate.access / capFor — nowhere else.

enum Feature {
  reviewStack,
  bucketCreate,
  aiChat,
  aiOverview,
  insightsFull,
  youLedger,
  sessionSize,
  quiz,
}

extension FeaturePolicyKey on Feature {
  /// `ai_feature_policy.feature` for server-governed features; null when the
  /// rules live in [AppLimits] instead.
  String? get policyKey {
    switch (this) {
      case Feature.aiChat:
        return 'rag_chat';
      case Feature.aiOverview:
        return 'evaluate';
      case Feature.quiz:
        return 'quiz_generate';
      case Feature.reviewStack:
      case Feature.bucketCreate:
      case Feature.insightsFull:
      case Feature.youLedger:
      case Feature.sessionSize:
        return null;
    }
  }
}

enum AccessDenial { paywall, quota, wip }

class Access {
  const Access.allowed()
      : allowed = true,
        denial = null,
        message = null;

  const Access.denied(this.denial, {this.message}) : allowed = false;

  final bool allowed;
  final AccessDenial? denial;
  final String? message;
}
