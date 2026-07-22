// Recall · one-time coach tip keys for LocalStore.coachSeen / markCoachSeen.
// Keep keys stable — renaming re-shows tips to existing users.

abstract final class CoachKeys {
  static const todayDue = 'today_due';
  static const reviewGrades = 'review_grades';
  static const noteSrToggle = 'note_sr_toggle';
  static const bucketsRevision = 'buckets_revision';
  static const settingsReview = 'settings_review';
}
