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
    final localized =
        localizations.isKorean
            ? GoogleFonts.gaeguTextTheme(baseTextTheme)
            : localizations.isJapanese
            ? GoogleFonts.yomogiTextTheme(baseTextTheme)
            : GoogleFonts.cormorantGaramondTextTheme(baseTextTheme);

    return _slightlyLargerTextTheme(localized);
  }

  TextTheme _slightlyLargerTextTheme(TextTheme textTheme) {
    TextStyle? grow(TextStyle? style) {
      final fontSize = style?.fontSize;
      if (fontSize == null) {
        return style;
      }
      return style?.copyWith(fontSize: fontSize * 1.05);
    }

    return textTheme.copyWith(
      displayLarge: grow(textTheme.displayLarge),
      displayMedium: grow(textTheme.displayMedium),
      displaySmall: grow(textTheme.displaySmall),
      headlineLarge: grow(textTheme.headlineLarge),
      headlineMedium: grow(textTheme.headlineMedium),
      headlineSmall: grow(textTheme.headlineSmall),
      titleLarge: grow(textTheme.titleLarge),
      titleMedium: grow(textTheme.titleMedium),
      titleSmall: grow(textTheme.titleSmall),
      bodyLarge: grow(textTheme.bodyLarge),
      bodyMedium: grow(textTheme.bodyMedium),
      bodySmall: grow(textTheme.bodySmall),
      labelLarge: grow(textTheme.labelLarge),
      labelMedium: grow(textTheme.labelMedium),
      labelSmall: grow(textTheme.labelSmall),
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
    if (parsed == null || parsed <= 0 || parsed > 16) {
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
                    cupStates: _cupStates,
                    onBack: () => setState(() => _step = FlowStep.goal),
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
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8E9F)),
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
