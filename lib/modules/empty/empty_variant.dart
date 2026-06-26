enum EmptyVariant { buckets, today, insights }

extension EmptyVariantRoute on EmptyVariant {
  static EmptyVariant? fromRoute(String route) {
    if (route.contains('/empty/buckets')) return EmptyVariant.buckets;
    if (route.contains('/empty/today')) return EmptyVariant.today;
    if (route.contains('/empty/insights')) return EmptyVariant.insights;
    return null;
  }
}
