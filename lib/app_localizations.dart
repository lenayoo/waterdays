import 'package:flutter/material.dart';

class AppStrings {
  static const channelName = 'waterdays/widget';
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ko'), Locale('en'), Locale('ja')];

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations not found in context.');
    return localization!;
  }

  static const delegate = _AppLocalizationsDelegate();

  String get _languageCode {
    final code = locale.languageCode.toLowerCase();
    if (code == 'ja' || code == 'ko') {
      return code;
    }
    return 'en';
  }

  bool get isKorean => _languageCode == 'ko';
  bool get isJapanese => _languageCode == 'ja';

  String get appTitle => switch (_languageCode) {
    'ko' => '워터 데이즈',
    'ja' => 'ウォーターデイズ',
    _ => 'Water Days',
  };

  String get completionDialogTitle => switch (_languageCode) {
    'ko' => '목표 완료!',
    'ja' => '目標達成！',
    _ => 'Goal complete!',
  };

  String get completionDialogContent => switch (_languageCode) {
    'ko' => '오늘은 목표를 완료했어요!\n수분 루틴을 잘 지켰네요.',
    'ja' => '今日は目標を達成しました！\n水分ルーティンをしっかり守れましたね。',
    _ =>
      'You reached your goal today!\nYour hydration routine stayed on track.',
  };

  String get completionDialogAction => switch (_languageCode) {
    'ko' => '좋아요',
    'ja' => 'いいね',
    _ => 'Nice',
  };

  String get goalTitle => switch (_languageCode) {
    'ko' => '오늘은 몇 잔을 목표로 할까요?',
    'ja' => '今日は何杯を目標にしますか？',
    _ => 'How many cups is your goal today?',
  };

  String get goalHint => '1~16';

  String get goalSuffix => switch (_languageCode) {
    'ko' => '잔',
    'ja' => '杯',
    _ => 'cups',
  };

  String get goalHelper => switch (_languageCode) {
    'ko' => '최대 16잔까지 설정할 수 있어요.',
    'ja' => '最大16杯まで設定できます。',
    _ => 'You can set up to 16 cups.',
  };

  String get startTrackingButton => switch (_languageCode) {
    'ko' => '물마시기',
    'ja' => '飲みはじめる',
    _ => 'Start drinking',
  };

  String get filledCupSemantic => switch (_languageCode) {
    'ko' => '채워진 물방울',
    'ja' => '満たされたしずく',
    _ => 'Filled water drop',
  };

  String get emptyCupSemantic => switch (_languageCode) {
    'ko' => '비어있는 물방울',
    'ja' => '空のしずく',
    _ => 'Empty water drop',
  };

  String trackerGoal(int goalCups) => switch (_languageCode) {
    'ko' => '오늘 목표 $goalCups잔',
    'ja' => '今日の目標 $goalCups杯',
    _ => 'Today\'s goal: $goalCups cups',
  };
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
