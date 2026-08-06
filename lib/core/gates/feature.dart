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
