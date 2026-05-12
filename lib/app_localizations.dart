import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'Water Days';
  static const channelName = 'waterdays/widget';
  static const defaultGoalCups = 8;
  static const maxGoalCups = 16;
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ko'), Locale('en'), Locale('ja')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations not found in context.');
    return localization!;
  }

  String get languageCode {
    final code = locale.languageCode.toLowerCase();
    if (code == 'ko' || code == 'ja') {
      return code;
    }
    return 'en';
  }

  String text({required String en, String? ko, String? ja}) {
    return switch (languageCode) {
      'ko' => ko ?? en,
      'ja' => ja ?? en,
      _ => en,
    };
  }

  String get appTitle => AppConfig.appName;

  String get completionDialogTitle =>
      text(en: 'You did it', ko: '해냈어요', ja: 'できました');

  String get completionDialogContent => text(
    en: 'Today\'s goal is complete.',
    ko: '오늘 목표를 채웠어요.',
    ja: '今日の目標を達成しました。',
  );

  String get completionDialogAction => text(en: 'Nice', ko: '좋아요', ja: 'いいね');

  String get goalTitle =>
      text(en: 'How many cups today?', ko: '오늘은 몇 잔 마실까요?', ja: '今日は何杯飲みますか？');

  String get goalHint => '1-${AppConfig.maxGoalCups}';

  String get goalSuffix => text(en: 'cups', ko: '잔', ja: '杯');

  String get goalHelper => text(
    en: 'Choose up to ${AppConfig.maxGoalCups} cups.',
    ko: '최대 ${AppConfig.maxGoalCups}잔까지 고를 수 있어요.',
    ja: '最大${AppConfig.maxGoalCups}杯まで選べます。',
  );

  String get startTrackingButton =>
      text(en: 'Start drinking', ko: '기록 시작', ja: '記録を始める');

  String get filledCupSemantic =>
      text(en: 'Filled water drop', ko: '채워진 물방울', ja: '満たされた水滴');

  String get emptyCupSemantic =>
      text(en: 'Empty water drop', ko: '비어 있는 물방울', ja: '空の水滴');

  String trackerGoal(int goalCups) => text(
    en: 'Today\'s goal: $goalCups cups',
    ko: '오늘 목표 $goalCups잔',
    ja: '今日の目標 $goalCups杯',
  );

  String trackerStatus(int drankCups, int goalCups) {
    if (drankCups <= 0) {
      return trackerStatusDrinkWater;
    }
    if (drankCups >= goalCups) {
      return trackerStatusDone;
    }
    return trackerStatusHydrated;
  }

  String get trackerStatusDrinkWater =>
      text(en: 'Drink water', ko: '물 마셔요', ja: '水を飲もう');

  String get trackerStatusHydrated =>
      text(en: 'Hydrated', ko: '잘 마시고 있어요', ja: '좋은 흐름');

  String get trackerStatusDone =>
      text(en: 'You did it', ko: '해냈어요', ja: 'できました');

  String trackerRemaining(int remainingCups) => text(
    en: '$remainingCups cups left',
    ko: '$remainingCups잔 남았어요',
    ja: 'あと$remainingCups杯',
  );

  String get monthlyRecordButtonLabel =>
      text(en: 'Monthly record', ko: '월 기록', ja: '月の記録');

  String get monthlyRecordTitle =>
      text(en: 'Monthly record', ko: '월 기록', ja: '月の記録');

  String monthlyRecordSummary({
    required int completedDays,
    required int missedDays,
  }) {
    return text(
      en: '$completedDays good days, $missedDays missed days',
      ko: '달성 $completedDays일, 미달성 $missedDays일',
      ja: '達成 $completedDays日、未達成 $missedDays日',
    );
  }

  String get calendarLegendComplete =>
      text(en: 'Goal met', ko: '목표 달성', ja: '目標達成');

  String get calendarLegendMissed => text(en: 'Not met', ko: '미달성', ja: '未達成');

  String get calendarEmptyTitle =>
      text(en: 'No record yet', ko: '아직 기록이 없어요', ja: 'まだ記録がありません');

  String get calendarEmptyBody => text(
    en: 'Your days will appear here.',
    ko: '기록이 쌓이면 여기에 보여요.',
    ja: '記録が増えるとここに表示されます。',
  );

  String get reminderTitle =>
      text(en: 'You are doing well today', ko: '오늘도 잘하고 있어요', ja: '今日もいい調子です');

  String reminderBody({required int currentCups, required int remainingCups}) {
    return text(
      en: 'Today\'s progress: $currentCups cups. Only $remainingCups cups left.',
      ko: '오늘은 $currentCups잔 마셨어요. $remainingCups잔만 더 마시면 돼요.',
      ja: '今日は$currentCups杯飲みました。あと$remainingCups杯です。',
    );
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
