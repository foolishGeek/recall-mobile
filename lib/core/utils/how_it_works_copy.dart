// Recall · shared How-it-works copy for coach tips + Settings sheets.
// Plain language only — no engine jargon (stability / retrievability).

import '../widgets/how_it_works_sheet.dart';

abstract final class HowItWorksCopy {
  static const todayTitle = 'How due works';
  static const todayTip =
      'Due means ready to review — Recall brings notes back just before you\'d forget.';
  static const todaySections = <HowItWorksSection>[
    HowItWorksSection(
      heading: 'What\'s due',
      body:
          'Only notes in spaced revision appear here. The number is how many are ready right now.',
    ),
    HowItWorksSection(
      heading: 'When to start',
      body:
          'Open a short session when you have a quiet minute. Honest ratings keep the timing right.',
    ),
    HowItWorksSection(
      heading: 'Reference notes',
      body:
          'Turn revision off on a note (or bucket) to keep plain reference material — it never shows as due.',
    ),
  ];

  static const reviewTitle = 'How grading works';
  static const reviewTip =
      'Rate honestly. Forgot brings it back sooner; Got it spaces it out.';
  static const reviewSections = <HowItWorksSection>[
    HowItWorksSection(
      heading: 'Forgot / Got it',
      body:
          'Forgot means you need it again soon. Got it means you\'re solid — the next look comes later.',
    ),
    HowItWorksSection(
      heading: 'Hard & Easy',
      body:
          'Open More for Hard and Easy when you want a finer gap. They tune the same schedule, gently.',
    ),
    HowItWorksSection(
      heading: 'Why honesty matters',
      body:
          'Guessing "Got it" stretches the gap too far. Honest taps make Memory strength actually help.',
    ),
  ];

  static const noteSrTitle = 'Spaced revision';
  static const noteSrTip =
      'Spaced revision resurfaces this note over time so it sticks. Off keeps a plain reference note.';
  static const noteSrSections = <HowItWorksSection>[
    HowItWorksSection(
      heading: 'On',
      body:
          'Recall schedules the note and may nudge you with a Recall Drop when it\'s due.',
    ),
    HowItWorksSection(
      heading: 'Off',
      body:
          'Saved only — never due, never in Today or a Drop. Perfect for reference material.',
    ),
    HowItWorksSection(
      heading: 'Buckets',
      body:
          'A bucket can set the default for new notes. You can always override a single note here.',
    ),
  ];

  static const bucketsTitle = 'Buckets & revision';
  static const bucketsTip =
      'Buckets group a topic. Turn revision off on a bucket or note for plain reference material.';
  static const bucketsSections = <HowItWorksSection>[
    HowItWorksSection(
      heading: 'What a bucket is',
      body:
          'A calm container for one subject — notes inside can join spaced revision or stay as reference.',
    ),
    HowItWorksSection(
      heading: 'Skip revision',
      body:
          'On a bucket\'s screen you can turn spaced revision off for everything inside, or flip a single note.',
    ),
    HowItWorksSection(
      heading: 'Memory strength',
      body:
          'How firmly notes stick is set in Settings. Stronger means more reviews, sturdier recall.',
    ),
  ];

  static const settingsTitle = 'Review preferences';
  static const settingsTip =
      'Memory strength and Reminder style shape how often notes return — and how insistently Drop nudges.';
  static const settingsSections = <HowItWorksSection>[
    HowItWorksSection(
      heading: 'Memory strength',
      body:
          'How sure you want to be when it matters. Relaxed spaces reviews out; Thorough brings them sooner.',
    ),
    HowItWorksSection(
      heading: 'Reminder style',
      body:
          'Gentle / Standard / Persistent — how often Recall Drop knocks when due notes wait unseen.',
    ),
    HowItWorksSection(
      heading: 'Quiet hours',
      body: 'Drops stay silent in your quiet window so evenings stay calm.',
    ),
  ];

  static const memoryStrengthTitle = 'Memory strength';
  static const memoryStrengthSections = <HowItWorksSection>[
    HowItWorksSection(
      body:
          'How sure do you want to be when it matters? Behind the scenes this sets desired retention for the scheduler.',
    ),
    HowItWorksSection(
      heading: 'Relaxed · Balanced · Thorough',
      body:
          'Relaxed spaces reviews out. Balanced is the default. Thorough reviews more often for sturdier recall.',
    ),
  ];

  static const reminderStyleTitle = 'Reminder style';
  static const reminderStyleSections = <HowItWorksSection>[
    HowItWorksSection(
      body:
          'Controls how insistently a Recall Drop nudges you when notes are due and still unseen.',
    ),
    HowItWorksSection(
      heading: 'Gentle · Standard · Persistent',
      body:
          'Gentle waits for a larger set. Standard is balanced. Persistent re-nudges about every two hours until you look.',
    ),
    HowItWorksSection(
      heading: 'One setting for the whole app',
      body:
          'Reminder style is account-wide — it applies to every bucket. Change it once in Settings.',
    ),
  ];

  static const coolingPeriodTitle = 'Cooling period';
  static const coolingPeriodSections = <HowItWorksSection>[
    HowItWorksSection(
      body:
          'After you finish this bucket\'s cards, Recall rests the whole topic for a set time before bringing it back — so you\'re not drilling the same set every day.',
    ),
    HowItWorksSection(
      heading: 'A quick example',
      body:
          'Rest 14 days = once you\'ve worked through the bucket, the topic returns roughly every couple of weeks instead of tomorrow.',
    ),
    HowItWorksSection(
      heading: 'It\'s per bucket',
      body:
          'Fast-moving topics can rest less; slow-burn ones can rest more. Each bucket keeps its own pace.',
    ),
  ];

  static const bucketConfigTitle = 'What is Bucket config?';
  static const bucketConfigSections = <HowItWorksSection>[
    HowItWorksSection(
      body:
          'Three small dials that shape how this bucket comes back to you. You can read the effect of each in plain words — no need to guess.',
    ),
    HowItWorksSection(
      heading: 'Cooling period',
      body:
          'How long the topic rests after a session before it returns. Per bucket.',
    ),
    HowItWorksSection(
      heading: 'Memory strength',
      body:
          'How sure you want to be when it matters. Stronger means reviews come back sooner. Per bucket.',
    ),
    HowItWorksSection(
      heading: 'Reminder style',
      body:
          'How insistently Drops nudge you. This one is account-wide — set once in Settings.',
    ),
  ];
}
