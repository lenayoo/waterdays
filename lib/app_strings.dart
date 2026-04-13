class AppStrings {
  static const appTitle = 'Water Days';
  static const channelName = 'waterdays/widget';

  static const completionDialogTitle = '목표 완료!';
  static const completionDialogContent = '오늘은 목표를 완료했어요!\n수분 루틴을 잘 지켰네요.';
  static const completionDialogAction = '좋아요';

  static const nextButton = '다음';

  static const goalTitle = '오늘은 몇 잔을 목표로 할까요?';
  static const goalHint = '1~16';
  static const goalSuffix = '잔';
  static const goalHelper = '최대 16잔까지 설정할 수 있어요.';

  static const viewMonthlyRecordButton = '한 달 기록 보기';
  static const startTrackingButton = '물마시기';
  static const goToTodayTrackingButton = '오늘 물마시기 화면으로 가기';

  static const calendarLegend = '파란 점: 완료 · 빨간 점: 미완료';
  static const currentMonthMessage = '%d월에는 물을 많이 마시는 습관을 들여요!';
  static const goodPastMonthMessage = '요번달은 물을 많이 마셨어요. 참잘했어요.';
  static const badPastMonthMessage = '요번달에는 물을 많이 마시지 못했어요. 다음달에 더 힘내요.';

  static const filledCupSemantic = '채워진 물방울';
  static const emptyCupSemantic = '비어있는 물방울';

  static String summaryGoal(int goalCups) => '오늘 목표는\n${goalCups}잔입니다.';

  static String monthRecordTitle(DateTime month) => '${month.month}월 기록';

  static String currentMonthHabitMessage(DateTime month) =>
      currentMonthMessage.replaceFirst('%d', '${month.month}');

  static String trackerGoal(int goalCups) => '오늘 목표 ${goalCups}잔';
}
