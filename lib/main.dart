import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const WaterDaysApp());
}

class WaterDaysApp extends StatelessWidget {
  const WaterDaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'waterdays',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1D7ED6),
          secondary: Color(0xFF7EC8F3),
          surface: Color(0xFFF6F8FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF4FB),
        fontFamily: 'SF Pro Rounded',
        fontFamilyFallback: const [
          'Arial Rounded MT Bold',
          'Trebuchet MS',
          'sans-serif',
        ],
        useMaterial3: true,
      ),
      home: const WaterFlowPage(),
    );
  }
}

enum FlowStep {
  name,
  goal,
  summary,
  tracker,
}

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController(text: '8');

  FlowStep _step = FlowStep.name;
  int _goalCups = 8;
  List<bool> _cupStates = List<bool>.filled(8, false);

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  String get _displayName {
    final trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? 'waterdays' : trimmed;
  }

  String get _todayLabel {
    final now = DateTime.now();
    return '${now.month}월 ${now.day}일';
  }

  int get _drankCups => _cupStates.where((filled) => filled).length;

  bool get _isGoalComplete => _drankCups >= _goalCups;

  void _goToGoalStep() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _step = FlowStep.goal;
    });
  }

  void _goToSummaryStep() {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed <= 0 || parsed > 16) {
      return;
    }

    setState(() {
      _goalCups = parsed;
      _cupStates = List<bool>.filled(_goalCups, false);
      _step = FlowStep.summary;
    });
  }

  void _startTracking() {
    setState(() {
      _step = FlowStep.tracker;
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
  }

  void _toggleCup(int index) {
    if (_isGoalComplete || index < 0 || index >= _cupStates.length) {
      return;
    }

    setState(() {
      _cupStates[index] = !_cupStates[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Padding(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: switch (_step) {
              FlowStep.name => _NameStep(
                  controller: _nameController,
                  onNext: _goToGoalStep,
                ),
              FlowStep.goal => _GoalStep(
                  controller: _goalController,
                  displayName: _displayName,
                  onBack: () => setState(() => _step = FlowStep.name),
                  onNext: _goToSummaryStep,
                ),
              FlowStep.summary => _SummaryStep(
                  displayName: _displayName,
                  todayLabel: _todayLabel,
                  goalCups: _goalCups,
                  onBack: () => setState(() => _step = FlowStep.goal),
                  onStart: _startTracking,
                ),
              FlowStep.tracker => _TrackerStep(
                  displayName: _displayName,
                  todayLabel: _todayLabel,
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
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.onNext,
  });

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const Spacer(),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이름을 입력해주세요',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF163047),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '매일의 물 습관을 귀엽고 가볍게 시작해볼게요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF607487),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '이름 또는 닉네임',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D7ED6),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.controller,
    required this.displayName,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController controller;
  final String displayName;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(showBack: true, onBack: onBack),
        const Spacer(),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘은 몇 잔을 목표로 할까요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF163047),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$displayName 님에게 딱 맞는 오늘의 목표를 정해주세요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF607487),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                  _GoalLimitFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: '1~16',
                  suffixText: '잔',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '최대 16잔까지 설정할 수 있어요.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6F8292),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D7ED6),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.displayName,
    required this.todayLabel,
    required this.goalCups,
    required this.onBack,
    required this.onStart,
  });

  final String displayName;
  final String todayLabel;
  final int goalCups;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(showBack: true, onBack: onBack),
        const Spacer(),
        _SectionCard(
          accentColor: const Color(0xFF103551),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  todayLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF12314A),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$displayName 님의 오늘 목표는\n$todayLabel $goalCups잔이에요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF103551),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('물마시기로 시작하기'),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.displayName,
    required this.todayLabel,
    required this.goalCups,
    required this.cupStates,
    required this.onBack,
    required this.onCupTap,
    required this.isGoalComplete,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String displayName;
  final String todayLabel;
  final int goalCups;
  final List<bool> cupStates;
  final VoidCallback onBack;
  final ValueChanged<int> onCupTap;
  final bool isGoalComplete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final drankCups = cupStates.where((filled) => filled).length;
    final remainingCups = math.max(goalCups - drankCups, 0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(showBack: true, onBack: onBack),
          const SizedBox(height: 18),
          _SectionCard(
            accentColor: const Color(0xFF103551),
            child: Column(
              children: [
                Text(
                  '물마시기',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$todayLabel · $displayName 님',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isGoalComplete
                      ? '오늘은 목표를 완료했어요!'
                      : '현재 $drankCups잔 완료 · $remainingCups잔 남음',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 목표 $goalCups잔',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF163047),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '컵을 직접 누르거나 + 버튼으로 기록해보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF63788C),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
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
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    this.showBack = false,
    this.onBack,
  });

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF163047),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                'waterdays',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF12314A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '오늘의 수분 루틴을 편하게 기록해요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5D7285),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.accentColor,
  });

  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: accentColor == null
            ? null
            : LinearGradient(
                colors: [accentColor!, const Color(0xFF3F9AE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: accentColor == null ? const Color(0xFFDDF1FF) : null,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74A8CA).withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
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
          color: isDisabled
              ? const Color(0xFFD5E1EA)
              : filled
                  ? const Color(0xFF1D7ED6)
                  : Colors.white,
          border: Border.all(
            color: filled || isDisabled
                ? Colors.transparent
                : const Color(0xFF9FB8C9),
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color: isDisabled
              ? const Color(0xFF8EA3B2)
              : filled
                  ? Colors.white
                  : const Color(0xFF557188),
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
    return Semantics(
      button: true,
      label: isFilled ? '채워진 물컵' : '비어있는 물컵',
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 58,
          height: 94,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 7,
                right: 7,
                bottom: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  height: isFilled ? 50 : 0,
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? const Color(0xFF86C6F5)
                        : const Color(0xFF4DA9F6),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                      top: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _CupOutlinePainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = const Color(0xFF92A7B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final cupPath = Path()
      ..moveTo(size.width * 0.20, size.height * 0.18)
      ..lineTo(size.width * 0.80, size.height * 0.18)
      ..lineTo(size.width * 0.70, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.98,
        size.width * 0.30,
        size.height * 0.90,
      )
      ..close();

    canvas.drawPath(cupPath, outlinePaint);
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.12),
      Offset(size.width * 0.86, size.height * 0.12),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
