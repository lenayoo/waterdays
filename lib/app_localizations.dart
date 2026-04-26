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

  String text({
    required String en,
    String? ko,
    String? ja,
  }) {
    return switch (languageCode) {
      'ko' => ko ?? en,
      'ja' => ja ?? en,
      _ => en,
    };
  }

  String get appTitle => AppConfig.appName;

  String get completionDialogTitle => text(
    en: 'Goal complete',
    ko: '목표 달성',
    ja: '目標達成',
  );

  String get completionDialogContent => text(
    en: 'You finished today\'s goal.\nNice and steady.',
    ko: '오늘 목표를 채웠어요.\n수분 섭취를 잘 챙겼네요.',
    ja: '今日の目標を達成しました。\n水分補給をしっかり続けられました。',
  );

  String get completionDialogAction => text(
    en: 'Nice',
    ko: '좋아요',
    ja: 'いいね',
  );

  String get goalTitle => text(
    en: 'How many cups is your goal today?',
    ko: '오늘 목표는 몇 잔인가요?',
    ja: '今日の目標は何杯ですか？',
  );

  String get goalHint => '1-${AppConfig.maxGoalCups}';

  String get goalSuffix => text(
    en: 'cups',
    ko: '잔',
    ja: '杯',
  );

  String get goalHelper => text(
    en: 'Set up to ${AppConfig.maxGoalCups} cups.',
    ko: '최대 ${AppConfig.maxGoalCups}잔까지 설정할 수 있어요.',
    ja: '最大${AppConfig.maxGoalCups}杯まで設定できます。',
  );

  String get startTrackingButton => text(
    en: 'Start drinking',
    ko: '기록 시작',
    ja: '記録を始める',
  );

  String get filledCupSemantic => text(
    en: 'Filled water drop',
    ko: '채워진 물방울',
    ja: '満たされた水滴',
  );

  String get emptyCupSemantic => text(
    en: 'Empty water drop',
    ko: '비어 있는 물방울',
    ja: '空の水滴',
  );

  String trackerGoal(int goalCups) => text(
    en: 'Today\'s goal: $goalCups cups',
    ko: '오늘 목표 $goalCups잔',
    ja: '今日の目標 $goalCups杯',
  );
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
