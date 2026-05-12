import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/water_reminder_service.dart';
import 'package:waterdays/water_state.dart';
import 'package:waterdays/water_state_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final reminderService = LocalWaterReminderService();
  await reminderService.initialize();

  runApp(
    WaterDaysApp(
      stateStore: SharedPrefsWaterStateStore(),
      reminderService: reminderService,
    ),
  );
}

class _AppColors {
  const _AppColors._();

  static const primary = Color(0xFF5D9FD6);
  static const secondary = Color(0xFF8DBFE7);
  static const background = Color(0xFFF8FBFD);
  static const panel = Colors.white;
  static const panelSoft = Color(0xFFF2F8FC);
  static const progressTrack = Color(0xFFD7E7F2);
  static const textPrimary = Color(0xFF21384B);
  static const textSecondary = Color(0xFF7A8E9F);
  static const textTertiary = Color(0xFF8A9BA9);
  static const border = Color(0xFFD6E2EC);
  static const buttonOutline = Color(0xFFD6E2EC);
  static const icon = Color(0xFF476075);
  static const iconSoft = Color(0xFF34516A);
  static const disabled = Color(0xFFE9EEF2);
  static const disabledText = Color(0xFF90A1AE);
  static const header = Color(0xFF324258);
  static const emptyDrop = Color(0xFFE2E6EA);
  static const emptyDropBorder = Color(0xFFD0D7DD);
  static const filledDrop = Color(0xFF77CFFF);
  static const filledDropBorder = Color(0xFF5BB8F6);
  static const ambientDrop = Color(0xFFB7D9F0);
  static const dotBlue = Color(0xFF5D9FD6);
  static const dotRed = Color(0xFFE8867C);
}

class WaterDaysApp extends StatelessWidget {
  const WaterDaysApp({
    super.key,
    required this.stateStore,
    required this.reminderService,
    this.locale,
  });

  final WaterStateStore stateStore;
  final WaterReminderService reminderService;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: const ColorScheme.light(
        primary: _AppColors.primary,
        secondary: _AppColors.secondary,
        surface: _AppColors.background,
      ),
      scaffoldBackgroundColor: _AppColors.background,
      platform: TargetPlatform.iOS,
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
      localeResolutionCallback: _resolveLocale,
      theme: baseTheme.copyWith(
        textTheme: _appTextTheme(baseTheme.textTheme).apply(
          bodyColor: _AppColors.textPrimary,
          displayColor: _AppColors.textPrimary,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: baseTheme.textTheme.bodyLarge?.copyWith(
            color: _AppColors.textTertiary,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _AppColors.primary, width: 1.3),
          ),
        ),
      ),
      home: WaterFlowPage(
        stateStore: stateStore,
        reminderService: reminderService,
      ),
    );
  }

  Locale _resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return supportedLocales.first;
    }

    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return const Locale('en');
  }

  TextTheme _appTextTheme(TextTheme baseTextTheme) {
    return baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.3),
      bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.3),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

enum FlowStep { goal, tracker }

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
    if (parsed == null || parsed > AppConfig.maxGoalCups) {
      return oldValue;
    }

    return newValue;
  }
}

class WaterFlowPage extends StatefulWidget {
  const WaterFlowPage({
    super.key,
    required this.stateStore,
    required this.reminderService,
  });

  final WaterStateStore stateStore;
  final WaterReminderService reminderService;

  @override
  State<WaterFlowPage> createState() => _WaterFlowPageState();
}

class _WaterFlowPageState extends State<WaterFlowPage>
    with WidgetsBindingObserver {
  final TextEditingController _goalController = TextEditingController(
    text: '${AppConfig.defaultGoalCups}',
  );

  WaterTrackerState _trackerState = WaterTrackerState.initial();
  FlowStep _step = FlowStep.goal;
  bool _completionShown = false;
  bool _isEditingGoal = false;
  bool _isLoading = true;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreState(requestPermissions: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goalController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restoreState();
    }
  }

  Future<void> _restoreState({bool requestPermissions = false}) async {
    if (_isRestoring) {
      return;
    }

    _isRestoring = true;
    final now = DateTime.now();
    var nextState = (await widget.stateStore.load()).normalizeForDate(now);
    final launchAction = await widget.stateStore.consumeLaunchAction();

    if (launchAction == LaunchActions.quickAdd &&
        nextState.hasStartedTracking &&
        !nextState.isGoalComplete) {
      nextState = nextState.incrementCup();
    }

    await widget.stateStore.save(nextState);

    if (!mounted) {
      _isRestoring = false;
      return;
    }

    setState(() {
      _trackerState = nextState;
      _step = nextState.hasStartedTracking ? FlowStep.tracker : FlowStep.goal;
      _goalController.text = '${nextState.goalCups}';
      _completionShown = nextState.isGoalComplete;
      _isEditingGoal = false;
      _isLoading = false;
    });

    await widget.reminderService.syncReminder(
      state: nextState,
      l10n: AppLocalizations.of(context),
    );

    if (requestPermissions) {
      unawaited(widget.reminderService.requestPermissions());
    }

    _isRestoring = false;
  }

  Future<void> _updateState(
    WaterTrackerState nextState, {
    FlowStep? nextStep,
    bool requestPermissions = false,
    bool showCompletionDialog = true,
    bool closeGoalEditor = false,
  }) async {
    final wasComplete = _trackerState.isGoalComplete;

    if (!mounted) {
      return;
    }

    setState(() {
      _trackerState = nextState;
      _step = nextStep ?? _step;
      _goalController.text = '${nextState.goalCups}';
      if (!nextState.isGoalComplete) {
        _completionShown = false;
      } else if (!showCompletionDialog) {
        _completionShown = true;
      }
      if (closeGoalEditor) {
        _isEditingGoal = false;
      }
    });

    await widget.stateStore.save(nextState);
    if (!mounted) {
      return;
    }

    await widget.reminderService.syncReminder(
      state: nextState,
      l10n: AppLocalizations.of(context),
    );

    if (requestPermissions) {
      unawaited(widget.reminderService.requestPermissions());
    }

    if (showCompletionDialog &&
        !wasComplete &&
        nextState.isGoalComplete &&
        !_completionShown) {
      _completionShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCompletionDialog();
        }
      });
    }
  }

  void _saveGoal() {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed <= 0 || parsed > AppConfig.maxGoalCups) {
      return;
    }

    final now = DateTime.now();
    final normalizedState = _trackerState.normalizeForDate(now);
    final isEditingGoal = _isEditingGoal && normalizedState.hasStartedTracking;
    final nextState =
        isEditingGoal
            ? normalizedState.updateGoal(parsed, now: now)
            : normalizedState.startTracking(parsed, now: now);

    _updateState(
      nextState,
      nextStep: FlowStep.tracker,
      requestPermissions: !isEditingGoal,
      showCompletionDialog: !isEditingGoal,
      closeGoalEditor: true,
    );
  }

  void _incrementCup() {
    if (_trackerState.isGoalComplete) {
      return;
    }
    _updateState(_trackerState.incrementCup());
  }

  void _decrementCup() {
    if (_trackerState.drankCups <= 0) {
      return;
    }
    _updateState(_trackerState.decrementCup());
  }

  void _toggleCup(int index) {
    if (_trackerState.isGoalComplete) {
      return;
    }
    _updateState(_trackerState.toggleCup(index));
  }

  void _openGoalEditor() {
    setState(() {
      _isEditingGoal = true;
      _step = FlowStep.goal;
      _goalController.text = '${_trackerState.goalCups}';
    });
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.completionDialogTitle),
            content: Text(l10n.completionDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.completionDialogAction),
              ),
            ],
          ),
    );
  }

  void _openMonthlyHistory() {
    final platform = Theme.of(context).platform;
    final heightFactor = platform == TargetPlatform.android ? 0.88 : 0.78;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: _MonthlyHistorySheet(trackerState: _trackerState),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _AppColors.primary),
        ),
      );
    }

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
              duration: const Duration(milliseconds: 260),
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: switch (_step) {
                  FlowStep.goal => _GoalStep(
                    controller: _goalController,
                    title:
                        _isEditingGoal
                            ? AppLocalizations.of(context).editGoalTitle
                            : AppLocalizations.of(context).goalTitle,
                    actionLabel:
                        _isEditingGoal
                            ? AppLocalizations.of(context).saveGoalButton
                            : AppLocalizations.of(context).startTrackingButton,
                    onStart: _saveGoal,
                    onMonthlyRecordTap: _openMonthlyHistory,
                  ),
                  FlowStep.tracker => _TrackerStep(
                    goalCups: _trackerState.goalCups,
                    drankCups: _trackerState.drankCups,
                    cupStates: _trackerState.cupStates,
                    onEditGoalTap: _openGoalEditor,
                    onCupTap: _toggleCup,
                    onIncrement: _incrementCup,
                    onDecrement: _decrementCup,
                    statusText: AppLocalizations.of(context).trackerStatus(
                      _trackerState.drankCups,
                      _trackerState.goalCups,
                    ),
                    progress: _trackerState.progress,
                    remainingText:
                        _trackerState.isGoalComplete
                            ? AppLocalizations.of(
                              context,
                            ).completionDialogContent
                            : AppLocalizations.of(
                              context,
                            ).trackerRemaining(_trackerState.remainingCups),
                    onMonthlyRecordTap: _openMonthlyHistory,
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
            fillColor: _AppColors.ambientDrop.withValues(alpha: opacity),
            highlightColor: Colors.white.withValues(alpha: opacity * 0.7),
            borderColor: _AppColors.ambientDrop.withValues(
              alpha: opacity * 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.controller,
    required this.title,
    required this.actionLabel,
    required this.onStart,
    required this.onMonthlyRecordTap,
  });

  final TextEditingController controller;
  final String title;
  final String actionLabel;
  final VoidCallback onStart;
  final VoidCallback onMonthlyRecordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onMonthlyRecordTap: onMonthlyRecordTap),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
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
              ).textTheme.bodySmall?.copyWith(color: _AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _PrimaryActionButton(label: actionLabel, onTap: onStart),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.goalCups,
    required this.drankCups,
    required this.cupStates,
    required this.onEditGoalTap,
    required this.onCupTap,
    required this.onIncrement,
    required this.onDecrement,
    required this.statusText,
    required this.progress,
    required this.remainingText,
    required this.onMonthlyRecordTap,
  });

  final int goalCups;
  final int drankCups;
  final List<bool> cupStates;
  final VoidCallback onEditGoalTap;
  final ValueChanged<int> onCupTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String statusText;
  final double progress;
  final String remainingText;
  final VoidCallback onMonthlyRecordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGoalComplete = drankCups >= goalCups;
    final canIncrement = drankCups < goalCups;
    final canDecrement = drankCups > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    showEdit: true,
                    onEditGoalTap: onEditGoalTap,
                    onMonthlyRecordTap: onMonthlyRecordTap,
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _AppColors.panelSoft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _AppColors.border),
                          ),
                          child: Text(
                            statusText,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: _AppColors.iconSoft),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '$drankCups / $goalCups',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          remainingText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: _AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: progress.clamp(0, 1),
                              backgroundColor: _AppColors.progressTrack,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.trackerGoal(goalCups),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 16,
                          children: List.generate(goalCups, (index) {
                            return WaterCup(
                              isFilled: cupStates[index],
                              onTap:
                                  isGoalComplete ? null : () => onCupTap(index),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child:
                              isGoalComplete
                                  ? const Text(
                                    '🎉',
                                    key: ValueKey('trackerCelebrationEmoji'),
                                    style: TextStyle(fontSize: 38),
                                  )
                                  : Row(
                                    key: const ValueKey('trackerControls'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _RoundControlButton(
                                        icon: Icons.remove,
                                        onTap: onDecrement,
                                        isDisabled: !canDecrement,
                                      ),
                                      const SizedBox(width: 16),
                                      _RoundControlButton(
                                        icon: Icons.add,
                                        onTap: onIncrement,
                                        filled: true,
                                        isDisabled: !canIncrement,
                                      ),
                                    ],
                                  ),
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
  const _Header({
    this.showEdit = false,
    this.onEditGoalTap,
    required this.onMonthlyRecordTap,
  });

  final bool showEdit;
  final VoidCallback? onEditGoalTap;
  final VoidCallback onMonthlyRecordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        const SizedBox(width: 98),
        Expanded(
          child: Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: _AppColors.header),
          ),
        ),
        SizedBox(
          width: 98,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showEdit && onEditGoalTap != null) ...[
                _HeaderIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: l10n.editGoalButtonLabel,
                  onTap: onEditGoalTap!,
                ),
                const SizedBox(width: 10),
              ],
              _HeaderIconButton(
                icon: Icons.calendar_month_rounded,
                tooltip: l10n.monthlyRecordButtonLabel,
                onTap: onMonthlyRecordTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(icon, size: 22, color: _AppColors.iconSoft),
        ),
      ),
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
          backgroundColor: _AppColors.primary,
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
    final backgroundColor =
        isDisabled
            ? _AppColors.disabled
            : filled
            ? _AppColors.primary
            : Colors.white;
    final borderColor =
        filled || isDisabled ? Colors.transparent : _AppColors.buttonOutline;
    final iconColor =
        isDisabled
            ? _AppColors.disabledText
            : filled
            ? Colors.white
            : _AppColors.icon;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Icon(icon, size: 30, color: iconColor),
      ),
    );
  }
}

class _MonthlyHistorySheet extends StatefulWidget {
  const _MonthlyHistorySheet({required this.trackerState});

  final WaterTrackerState trackerState;

  @override
  State<_MonthlyHistorySheet> createState() => _MonthlyHistorySheetState();
}

class _MonthlyHistorySheetState extends State<_MonthlyHistorySheet> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizations = MaterialLocalizations.of(context);
    final monthRecords = _monthRecords();
    final completedDays =
        monthRecords.values.where((record) => record.metGoal).length;
    final missedDays = monthRecords.length - completedDays;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, isAndroid ? 8 : 12, 20, 24),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _AppColors.iconSoft,
                ),
                Expanded(
                  child: Text(
                    localizations.formatMonthYear(_visibleMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _AppColors.iconSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      l10n.monthlyRecordSummary(
                        completedDays: completedDays,
                        missedDays: missedDays,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CalendarGrid(
                      month: _visibleMonth,
                      trackerState: widget.trackerState,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                          color: _AppColors.dotBlue,
                          label: l10n.calendarLegendComplete,
                        ),
                        const SizedBox(width: 18),
                        _LegendDot(
                          color: _AppColors.dotRed,
                          label: l10n.calendarLegendMissed,
                        ),
                      ],
                    ),
                    if (monthRecords.isEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        l10n.calendarEmptyTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.calendarEmptyBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, WaterHistoryRecord> _monthRecords() {
    final result = <String, WaterHistoryRecord>{};
    final now = DateTime.now();

    for (final entry in widget.trackerState.history.entries) {
      final date = dateFromKey(entry.key);
      if (date == null) {
        continue;
      }
      if (date.year == _visibleMonth.year &&
          date.month == _visibleMonth.month) {
        result[entry.key] = entry.value;
      }
    }

    if (widget.trackerState.hasStartedTracking) {
      final todayKey = widget.trackerState.currentDateKey;
      final today = dateFromKey(todayKey) ?? now;
      if (today.year == _visibleMonth.year &&
          today.month == _visibleMonth.month) {
        result[todayKey] = WaterHistoryRecord(
          goalCups: widget.trackerState.goalCups,
          drankCups: widget.trackerState.drankCups,
        );
      }
    }

    return result;
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.month, required this.trackerState});

  final DateTime month;
  final WaterTrackerState trackerState;

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final dayLabels = _weekdayLabels(materialLocalizations);
    final cells = _buildCells(materialLocalizations.firstDayOfWeekIndex);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children:
                dayLabels.map((label) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final cell = cells[index];
              if (cell == null) {
                return const SizedBox.shrink();
              }

              final record = trackerState.recordForDate(cell);
              final today = DateTime.now();
              final isToday =
                  cell.year == today.year &&
                  cell.month == today.month &&
                  cell.day == today.day;
              final isFuture = cell.isAfter(
                DateTime(today.year, today.month, today.day),
              );

              Color? dotColor;
              if (!isFuture && record != null) {
                dotColor =
                    record.metGoal ? _AppColors.dotBlue : _AppColors.dotRed;
              }

              return Container(
                decoration: BoxDecoration(
                  color: isToday ? _AppColors.panelSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isToday ? Border.all(color: _AppColors.border) : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${cell.day}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isFuture
                                ? _AppColors.textTertiary
                                : _AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 8,
                      height: 8,
                      child:
                          dotColor == null
                              ? const SizedBox.shrink()
                              : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> _weekdayLabels(MaterialLocalizations localizations) {
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    return List<String>.generate(7, (index) {
      return localizations.narrowWeekdays[(firstDayIndex + index) % 7];
    });
  }

  List<DateTime?> _buildCells(int firstDayOfWeekIndex) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final sundayBasedWeekday = firstDay.weekday % 7;
    final leadingEmpty = (sundayBasedWeekday - firstDayOfWeekIndex + 7) % 7;

    final cells = List<DateTime?>.filled(42, null);
    for (var day = 1; day <= daysInMonth; day++) {
      cells[leadingEmpty + day - 1] = DateTime(month.year, month.month, day);
    }
    return cells;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _AppColors.textSecondary),
        ),
      ],
    );
  }
}

class WaterCup extends StatelessWidget {
  const WaterCup({super.key, required this.isFilled, this.onTap});

  final bool isFilled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: isFilled ? l10n.filledCupSemantic : l10n.emptyCupSemantic,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
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
                  isFilled ? _AppColors.filledDrop : _AppColors.emptyDrop,
              highlightColor:
                  isFilled
                      ? Colors.white.withValues(alpha: 0.52)
                      : Colors.white.withValues(alpha: 0.40),
              borderColor:
                  isFilled
                      ? _AppColors.filledDropBorder
                      : _AppColors.emptyDropBorder,
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
