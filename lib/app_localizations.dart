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

  String get nextButton => switch (_languageCode) {
    'ko' => '다음',
    'ja' => '次へ',
    _ => 'Next',
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

  String get viewMonthlyRecordButton => switch (_languageCode) {
    'ko' => '한 달 기록 보기',
    'ja' => '1か月の記録を見る',
    _ => 'View monthly record',
  };

  String get startTrackingButton => switch (_languageCode) {
    'ko' => '물마시기',
    'ja' => '飲みはじめる',
    _ => 'Start drinking',
  };

  String get goToTodayTrackingButton => switch (_languageCode) {
    'ko' => '오늘 물마시기 화면으로 가기',
    'ja' => '今日の記録画面へ',
    _ => 'Go to today\'s tracker',
  };

  String get calendarLegend => switch (_languageCode) {
    'ko' => '파란 점: 완료 · 빨간 점: 미완료',
    'ja' => '青い点: 完了 · 赤い点: 未完了',
    _ => 'Blue dot: done · Red dot: missed',
  };

  String get goodPastMonthMessage => switch (_languageCode) {
    'ko' => '이번 달은 물을 많이 마셨어요. 아주 잘했어요.',
    'ja' => '今月はたくさん飲めました。とてもよくできました。',
    _ => 'You drank plenty of water this month. Nicely done.',
  };

  String get badPastMonthMessage => switch (_languageCode) {
    'ko' => '이번 달은 물을 덜 마셨어요. 다음 달에 다시 해봐요.',
    'ja' => '今月は少なめでした。来月また頑張りましょう。',
    _ => 'You drank a bit less this month. Try again next month.',
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

  String summaryGoal(int goalCups) => switch (_languageCode) {
    'ko' => '오늘 목표는\n${goalCups}잔입니다.',
    'ja' => '今日の目標は\n${goalCups}杯です。',
    _ => 'Today\'s goal is\n$goalCups cups.',
  };

  String monthRecordTitle(DateTime month) => switch (_languageCode) {
    'ko' => '${month.month}월 기록',
    'ja' => '${month.month}月の記録',
    _ => '${_monthName(month.month)} record',
  };

  String currentMonthHabitMessage(DateTime month) => switch (_languageCode) {
    'ko' => '${month.month}월에는 물을 많이 마시는 습관을 들여요!',
    'ja' => '${month.month}月はしっかり水を飲む習慣をつけましょう！',
    _ => 'Build a better hydration habit in ${_monthName(month.month)}!',
  };

  String trackerGoal(int goalCups) => switch (_languageCode) {
    'ko' => '오늘 목표 ${goalCups}잔',
    'ja' => '今日の目標 ${goalCups}杯',
    _ => 'Today\'s goal: $goalCups cups',
  };

  List<String> get weekdayLabels => switch (_languageCode) {
    'ko' => const ['일', '월', '화', '수', '목', '금', '토'],
    'ja' => const ['日', '月', '火', '水', '木', '金', '土'],
    _ => const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  };

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
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
