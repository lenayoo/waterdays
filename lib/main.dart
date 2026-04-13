import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waterdays/app_localizations.dart';

void main() {
  runApp(const WaterDaysApp());
}

const MethodChannel _widgetChannel = MethodChannel(AppStrings.channelName);

class WaterDaysApp extends StatelessWidget {
  const WaterDaysApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D9FD6),
        secondary: Color(0xFF8DBFE7),
        surface: Color(0xFFF8FBFD),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FBFD),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return supportedLocales.first;
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        final textTheme = _localizedTextTheme(
          base.textTheme,
          AppLocalizations.of(context),
        ).apply(
          bodyColor: const Color(0xFF21384B),
          displayColor: const Color(0xFF21384B),
        );

        return Theme(
          data: base.copyWith(
            textTheme: textTheme,
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF8A9BA9),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD6E2EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD6E2EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF5D9FD6),
                  width: 1.3,
                ),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WaterFlowPage(),
    );
  }

  TextTheme _localizedTextTheme(
    TextTheme baseTextTheme,
    AppLocalizations localizations,
  ) {
    if (localizations.isKorean) {
      return GoogleFonts.gaeguTextTheme(baseTextTheme);
    }
    if (localizations.isJapanese) {
      return GoogleFonts.yomogiTextTheme(baseTextTheme);
    }
    return GoogleFonts.patrickHandTextTheme(baseTextTheme);
  }
}

enum FlowStep { goal, summary, calendar, tracker }

class _GoalLimitFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final parsed = int.tryParse(newValue.text);
    if (parsed == null || parsed > 16) {
      return oldValue;
    }

    return newValue;
  }
}

class WaterFlowPage extends StatefulWidget {
  const WaterFlowPage({super.key});

  @override
  State<WaterFlowPage> createState() => _WaterFlowPageState();
}

class _WaterFlowPageState extends State<WaterFlowPage> {
  final TextEditingController _goalController = TextEditingController(
    text: '8',
  );

  FlowStep _step = FlowStep.goal;
  int _goalCups = 8;
  List<bool> _cupStates = List<bool>.filled(8, false);
  late DateTime _calendarMonth;
  late final Map<DateTime, bool> _history;
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _calendarMonth = DateTime(today.year, today.month);
    _history = _seedHistory(today);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidget());
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  DateTime get _today => _dateOnly(DateTime.now());

  int get _drankCups => _cupStates.where((filled) => filled).length;

  bool get _isGoalComplete => _drankCups >= _goalCups;

  void _goToSummaryStep() {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed <= 0 || parsed > 16) {
      return;
    }

    setState(() {
      _goalCups = parsed;
      _cupStates = List<bool>.filled(_goalCups, false);
      _completionShown = false;
      _history[_today] = false;
      _step = FlowStep.summary;
    });
    _syncWidget();
  }

  void _startTracking() {
    setState(() {
      _step = FlowStep.tracker;
    });
  }

  void _goToCalendar() {
    setState(() {
      _step = FlowStep.calendar;
    });
  }

  void _incrementCup() {
    if (_isGoalComplete) {
      return;
    }

    final nextIndex = _cupStates.indexWhere((filled) => !filled);
    if (nextIndex == -1) {
      return;
    }

    setState(() {
      _cupStates[nextIndex] = true;
    });
    _afterCupChange();
  }

  void _decrementCup() {
    if (_isGoalComplete) {
      return;
    }

    final lastFilledIndex = _cupStates.lastIndexWhere((filled) => filled);
    if (lastFilledIndex == -1) {
      return;
    }

    setState(() {
      _cupStates[lastFilledIndex] = false;
      _history[_today] = false;
    });
    _syncWidget();
  }

  void _toggleCup(int index) {
    if (_isGoalComplete || index < 0 || index >= _cupStates.length) {
      return;
    }

    setState(() {
      _cupStates[index] = !_cupStates[index];
    });
    _afterCupChange();
  }

  void _afterCupChange() {
    final completed = _isGoalComplete;
    setState(() {
      _history[_today] = completed;
    });
    _syncWidget();

    if (completed && !_completionShown) {
      _completionShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context).completionDialogTitle),
                content: Text(
                  AppLocalizations.of(context).completionDialogContent,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.of(context).completionDialogAction,
                    ),
                  ),
                ],
              ),
        );
      });
    }
  }

  Future<void> _syncWidget() async {
    try {
      await _widgetChannel.invokeMethod<void>('updateWaterProgress', {
        'drankCups': _drankCups,
        'goalCups': _goalCups,
      });
    } on PlatformException {
      // iOS widget sync is optional while running on other platforms.
    }
  }

  void _showPreviousMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
    });
  }

  void _showNextMonth() {
    final currentMonth = DateTime(_today.year, _today.month);
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
    if (next.isAfter(currentMonth)) {
      return;
    }

    setState(() {
      _calendarMonth = next;
    });
  }

  Map<DateTime, bool> _seedHistory(DateTime today) {
    final history = <DateTime, bool>{};

    final currentMonthStart = DateTime(today.year, today.month, 1);
    for (var day = 1; day < today.day; day++) {
      final date = DateTime(today.year, today.month, day);
      history[date] = day.isEven || day % 5 == 0;
    }

    final previousMonthStart = DateTime(today.year, today.month - 1, 1);
    final previousMonthDays = DateUtils.getDaysInMonth(
      previousMonthStart.year,
      previousMonthStart.month,
    );
    for (var day = 1; day <= previousMonthDays; day++) {
      final date = DateTime(
        previousMonthStart.year,
        previousMonthStart.month,
        day,
      );
      history[date] = day % 3 != 0;
    }

    history[currentMonthStart] = true;
    history[_dateOnly(today)] = false;
    return history;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 36,
              right: 28,
              child: _AmbientDrop(size: 48, opacity: 0.18),
            ),
            const Positioned(
              bottom: 72,
              left: 24,
              child: _AmbientDrop(size: 84, opacity: 0.12),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: switch (_step) {
                  FlowStep.goal => _GoalStep(
                    controller: _goalController,
                    onNext: _goToSummaryStep,
                  ),
                  FlowStep.summary => _SummaryStep(
                    goalCups: _goalCups,
                    onBack: () => setState(() => _step = FlowStep.goal),
                    onCalendar: _goToCalendar,
                    onStart: _startTracking,
                  ),
                  FlowStep.calendar => _CalendarStep(
                    month: _calendarMonth,
                    history: _history,
                    today: _today,
                    onBack: () => setState(() => _step = FlowStep.summary),
                    onPreviousMonth: _showPreviousMonth,
                    onNextMonth: _showNextMonth,
                    onStart: _startTracking,
                  ),
                  FlowStep.tracker => _TrackerStep(
                    goalCups: _goalCups,
                    cupStates: _cupStates,
                    onBack: () => setState(() => _step = FlowStep.summary),
                    onCupTap: _toggleCup,
                    isGoalComplete: _isGoalComplete,
                    onIncrement: _incrementCup,
                    onDecrement: _decrementCup,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientDrop extends StatelessWidget {
  const _AmbientDrop({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size * 1.25,
        child: CustomPaint(
          painter: _WaterDropPainter(
            fillColor: const Color(0xFFB7D9F0).withValues(alpha: opacity),
            highlightColor: Colors.white.withValues(alpha: opacity * 0.7),
            borderColor: const Color(
              0xFFB7D9F0,
            ).withValues(alpha: opacity * 1.2),
          ),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.goalTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
                _GoalLimitFormatter(),
              ],
              decoration: InputDecoration(
                hintText: l10n.goalHint,
                suffixText: l10n.goalSuffix,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goalHelper,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8E9F)),
            ),
            const SizedBox(height: 18),
            _PrimaryActionButton(label: l10n.nextButton, onTap: onNext),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.goalCups,
    required this.onBack,
    required this.onCalendar,
    required this.onStart,
  });

  final int goalCups;
  final VoidCallback onBack;
  final VoidCallback onCalendar;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(showBack: true, onBack: onBack),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryGoal(goalCups),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            _PrimaryActionButton(
              label: l10n.viewMonthlyRecordButton,
              onTap: onCalendar,
            ),
            const SizedBox(height: 10),
            _SecondaryActionButton(
              label: l10n.startTrackingButton,
              onTap: onStart,
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _CalendarStep extends StatelessWidget {
  const _CalendarStep({
    required this.month,
    required this.history,
    required this.today,
    required this.onBack,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onStart,
  });

  final DateTime month;
  final Map<DateTime, bool> history;
  final DateTime today;
  final VoidCallback onBack;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmpty = firstDay.weekday % 7;
    final labels = l10n.weekdayLabels;
    final stats = _monthStats(month, history, today);
    final message = _monthMessage(l10n, month, stats, today);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(showBack: true, onBack: onBack),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.monthRecordTitle(month),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onPreviousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    onPressed:
                        DateTime(month.year, month.month) ==
                                DateTime(today.year, today.month)
                            ? null
                            : onNextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    labels.map((label) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF6D8295)),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.76,
                ),
                itemCount: leadingEmpty + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) {
                    return const SizedBox.shrink();
                  }

                  final day = index - leadingEmpty + 1;
                  final date = DateTime(month.year, month.month, day);
                  final status = _statusForDate(date, history, today);
                  return _CalendarDay(
                    day: day,
                    isToday: DateUtils.isSameDay(date, today),
                    status: status,
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                l10n.calendarLegend,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6C8496),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              _PrimaryActionButton(
                label: l10n.goToTodayTrackingButton,
                onTap: onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static _DayStatus _statusForDate(
    DateTime date,
    Map<DateTime, bool> history,
    DateTime today,
  ) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final state = history[normalizedDate];

    if (state == true) {
      return _DayStatus.complete;
    }
    if (state == false && !normalizedDate.isAfter(normalizedToday)) {
      return _DayStatus.incomplete;
    }
    return _DayStatus.none;
  }

  static ({int completed, int incomplete}) _monthStats(
    DateTime month,
    Map<DateTime, bool> history,
    DateTime today,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    var completed = 0;
    var incomplete = 0;

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      switch (_statusForDate(date, history, today)) {
        case _DayStatus.complete:
          completed += 1;
        case _DayStatus.incomplete:
          incomplete += 1;
        case _DayStatus.none:
          break;
      }
    }
    return (completed: completed, incomplete: incomplete);
  }

  static String _monthMessage(
    AppLocalizations l10n,
    DateTime month,
    ({int completed, int incomplete}) stats,
    DateTime today,
  ) {
    final currentMonth = DateTime(today.year, today.month);
    final viewedMonth = DateTime(month.year, month.month);

    if (viewedMonth == currentMonth) {
      return l10n.currentMonthHabitMessage(month);
    }

    if (stats.completed > stats.incomplete) {
      return l10n.goodPastMonthMessage;
    }

    return l10n.badPastMonthMessage;
  }
}

enum _DayStatus { none, complete, incomplete }

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isToday,
    required this.status,
  });

  final int day;
  final bool isToday;
  final _DayStatus status;

  @override
  Widget build(BuildContext context) {
    Color? dotColor;
    if (status == _DayStatus.complete) {
      dotColor = const Color(0xFF3C98F4);
    } else if (status == _DayStatus.incomplete) {
      dotColor = const Color(0xFFFF6C78);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday ? const Color(0xFF90BEDF) : const Color(0xFFD9E4EC),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor ?? Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.goalCups,
    required this.cupStates,
    required this.onBack,
    required this.onCupTap,
    required this.isGoalComplete,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int goalCups;
  final List<bool> cupStates;
  final VoidCallback onBack;
  final ValueChanged<int> onCupTap;
  final bool isGoalComplete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(showBack: true, onBack: onBack),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n.trackerGoal(goalCups),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 16,
                          children: List.generate(goalCups, (index) {
                            return WaterCup(
                              isFilled: cupStates[index],
                              isDisabled: isGoalComplete,
                              onTap: () => onCupTap(index),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RoundControlButton(
                              icon: Icons.remove,
                              onTap: onDecrement,
                              isDisabled: isGoalComplete,
                            ),
                            const SizedBox(width: 16),
                            _RoundControlButton(
                              icon: Icons.add,
                              onTap: onIncrement,
                              filled: true,
                              isDisabled: isGoalComplete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.showBack = false, this.onBack});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF34516A),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF324258),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5D9FD6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF34516A),
          side: const BorderSide(color: Color(0xFFD6E2EC)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.isDisabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isDisabled
                  ? const Color(0xFFE9EEF2)
                  : filled
                  ? const Color(0xFF5D9FD6)
                  : Colors.white,
          border: Border.all(
            color:
                filled || isDisabled
                    ? Colors.transparent
                    : const Color(0xFFD6E2EC),
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color:
              isDisabled
                  ? const Color(0xFF90A1AE)
                  : filled
                  ? Colors.white
                  : const Color(0xFF476075),
        ),
      ),
    );
  }
}

class WaterCup extends StatelessWidget {
  const WaterCup({
    super.key,
    required this.isFilled,
    this.isDisabled = false,
    this.onTap,
  });

  final bool isFilled;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: isFilled ? l10n.filledCupSemantic : l10n.emptyCupSemantic,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 58,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
          child: CustomPaint(
            painter: _WaterDropPainter(
              fillColor:
                  isFilled
                      ? isDisabled
                          ? const Color(0xFF94D5F8)
                          : const Color(0xFF77CFFF)
                      : const Color(0xFFE2E6EA),
              highlightColor:
                  isFilled
                      ? Colors.white.withValues(alpha: 0.52)
                      : Colors.white.withValues(alpha: 0.40),
              borderColor:
                  isFilled ? const Color(0xFF5BB8F6) : const Color(0xFFD0D7DD),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  const _WaterDropPainter({
    required this.fillColor,
    required this.highlightColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color highlightColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final drop =
        Path()
          ..moveTo(size.width * 0.50, size.height * 0.03)
          ..cubicTo(
            size.width * 0.25,
            size.height * 0.28,
            size.width * 0.08,
            size.height * 0.48,
            size.width * 0.08,
            size.height * 0.68,
          )
          ..cubicTo(
            size.width * 0.08,
            size.height * 0.90,
            size.width * 0.26,
            size.height * 0.98,
            size.width * 0.50,
            size.height * 0.98,
          )
          ..cubicTo(
            size.width * 0.74,
            size.height * 0.98,
            size.width * 0.92,
            size.height * 0.90,
            size.width * 0.92,
            size.height * 0.68,
          )
          ..cubicTo(
            size.width * 0.92,
            size.height * 0.48,
            size.width * 0.75,
            size.height * 0.28,
            size.width * 0.50,
            size.height * 0.03,
          )
          ..close();

    canvas.drawPath(
      drop,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      drop,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final highlight =
        Path()
          ..moveTo(size.width * 0.34, size.height * 0.34)
          ..cubicTo(
            size.width * 0.24,
            size.height * 0.48,
            size.width * 0.25,
            size.height * 0.63,
            size.width * 0.35,
            size.height * 0.74,
          );

    canvas.drawPath(
      highlight,
      Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.borderColor != borderColor;
  }
}
