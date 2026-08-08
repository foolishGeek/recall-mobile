// Recall · Load-cache TTLs for Insights / Settings / retention (perf pass).

/// In-memory Insights dashboard: skip network + skeleton on revisit.
const Duration kInsightsMemoryTtl = Duration(seconds: 60);

/// In-memory Settings entitlement (Profile + Subscription) after splash/refresh.
const Duration kEntitlementMemoryTtl = Duration(seconds: 60);

/// Server retention curve freshness (must match `retention_resolve_rpc` TTL).
const Duration kRetentionServerTtl = Duration(minutes: 15);
