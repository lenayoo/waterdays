import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waterdays/app_localizations.dart';

void main() {
  runApp(const WaterDaysApp());
}

const MethodChannel _widgetChannel = MethodChannel(AppConfig.channelName);

class _AppColors {
  const _AppColors._();

  static const primary = Color(0xFF5D9FD6);
  static const secondary = Color(0xFF8DBFE7);
  static const background = Color(0xFFF8FBFD);
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
}

class WaterDaysApp extends StatelessWidget {
  const WaterDaysApp({super.key, this.locale});

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
      builder: (context, child) {
        final localizations = AppLocalizations.of(context);
        final textTheme = _localizedTextTheme(
          baseTheme.textTheme,
          localizations,
        ).apply(
          bodyColor: _AppColors.textPrimary,
          displayColor: _AppColors.textPrimary,
        );

        return Theme(
          data: baseTheme.copyWith(
            textTheme: textTheme,
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: textTheme.bodyLarge?.copyWith(
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
                borderSide: const BorderSide(
                  color: _AppColors.primary,
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

  Locale _resolveLocale(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
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

  TextTheme _localizedTextTheme(
    TextTheme baseTextTheme,
    AppLocalizations localizations,
  ) {
    final localized = switch (localizations.languageCode) {
      'ko' => GoogleFonts.ibmPlexSansKrTextTheme(baseTextTheme),
      'ja' => GoogleFonts.mPlus1pTextTheme(baseTextTheme),
      _ => GoogleFonts.plusJakartaSansTextTheme(baseTextTheme),
    };

    return localized.copyWith(
      headlineMedium: localized.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: localized.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: localized.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyLarge: localized.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: localized.bodyMedium?.copyWith(height: 1.3),
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
  const WaterFlowPage({super.key});

  @override
  State<WaterFlowPage> createState() => _WaterFlowPageState();
}

class _WaterFlowPageState extends State<WaterFlowPage> {
  final TextEditingController _goalController = TextEditingController(
    text: '${AppConfig.defaultGoalCups}',
  );

  FlowStep _step = FlowStep.goal;
  int _goalCups = AppConfig.defaultGoalCups;
  List<bool> _cupStates = List<bool>.filled(AppConfig.defaultGoalCups, false);
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidget());
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  int get _drankCups => _cupStates.where((filled) => filled).length;

  bool get _isGoalComplete => _drankCups >= _goalCups;

  void _startTracking() {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed <= 0 || parsed > AppConfig.maxGoalCups) {
      return;
    }

    setState(() {
      _goalCups = parsed;
      _cupStates = List<bool>.filled(_goalCups, false);
      _completionShown = false;
      _step = FlowStep.tracker;
    });
    _syncWidget();
  }

  void _incrementCup() {
    final nextIndex = _cupStates.indexWhere((filled) => !filled);
    if (nextIndex == -1) {
      return;
    }

    _updateCupState(nextIndex, true);
  }

  void _decrementCup() {
    final lastFilledIndex = _cupStates.lastIndexWhere((filled) => filled);
    if (lastFilledIndex == -1) {
      return;
    }

    _updateCupState(lastFilledIndex, false);
  }

  void _toggleCup(int index) {
    if (!_isValidCupIndex(index)) {
      return;
    }

    _updateCupState(index, !_cupStates[index]);
  }

  bool _isValidCupIndex(int index) {
    return index >= 0 && index < _cupStates.length;
  }

  void _updateCupState(int index, bool isFilled) {
    if (!_isValidCupIndex(index) || _cupStates[index] == isFilled) {
      return;
    }

    setState(() {
      _cupStates[index] = isFilled;
      if (!_isGoalComplete) {
        _completionShown = false;
      }
    });
    _handleCupChange();
  }

  void _handleCupChange() {
    final completed = _isGoalComplete;
    _syncWidget();

    if (!completed || _completionShown) {
      return;
    }

    _completionShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCompletionDialog());
  }

  void _showCompletionDialog() {
    if (!mounted) {
      return;
    }

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
                    onStart: _startTracking,
                  ),
                  FlowStep.tracker => _TrackerStep(
                    goalCups: _goalCups,
                    drankCups: _drankCups,
                    cupStates: _cupStates,
                    onBack: () => setState(() => _step = FlowStep.goal),
                    onCupTap: _toggleCup,
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
            fillColor: _AppColors.ambientDrop.withValues(alpha: opacity),
            highlightColor: Colors.white.withValues(alpha: opacity * 0.7),
            borderColor: _AppColors.ambientDrop.withValues(alpha: opacity * 1.2),
          ),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.controller, required this.onStart});

  final TextEditingController controller;
  final VoidCallback onStart;

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
              ).textTheme.bodySmall?.copyWith(color: _AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _PrimaryActionButton(
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

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.goalCups,
    required this.drankCups,
    required this.cupStates,
    required this.onBack,
    required this.onCupTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int goalCups;
  final int drankCups;
  final List<bool> cupStates;
  final VoidCallback onBack;
  final ValueChanged<int> onCupTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            color: _AppColors.iconSoft,
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: _AppColors.header,
            ),
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
          border: Border.all(
            color: borderColor,
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color: iconColor,
        ),
      ),
    );
  }
}

class WaterCup extends StatelessWidget {
  const WaterCup({
    super.key,
    required this.isFilled,
    this.onTap,
  });

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
              fillColor: isFilled ? _AppColors.filledDrop : _AppColors.emptyDrop,
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
