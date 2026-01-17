import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

// Pomodoro State
enum PomodoroState { idle, working, shortBreak, longBreak, paused }

// Pomodoro Preset
enum PomodoroPreset { standard, deepWork, study, quickTask }

// Pomodoro Settings
class PomodoroSettings {
  final int workDuration; // in minutes
  final int shortBreakDuration;
  final int longBreakDuration;
  final int sessionsUntilLongBreak;
  final bool soundEnabled;
  final bool vibrationEnabled;
  
  const PomodoroSettings({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsUntilLongBreak = 4,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });
  
  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsUntilLongBreak,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return PomodoroSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsUntilLongBreak: sessionsUntilLongBreak ?? this.sessionsUntilLongBreak,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
  
  static PomodoroSettings fromPreset(PomodoroPreset preset) {
    switch (preset) {
      case PomodoroPreset.standard:
        return const PomodoroSettings(workDuration: 25, shortBreakDuration: 5, longBreakDuration: 15);
      case PomodoroPreset.deepWork:
        return const PomodoroSettings(workDuration: 50, shortBreakDuration: 10, longBreakDuration: 30);
      case PomodoroPreset.study:
        return const PomodoroSettings(workDuration: 30, shortBreakDuration: 5, longBreakDuration: 20);
      case PomodoroPreset.quickTask:
        return const PomodoroSettings(workDuration: 15, shortBreakDuration: 3, longBreakDuration: 10);
    }
  }
}

// Pomodoro Session Data
class PomodoroSession {
  final PomodoroState state;
  final int remainingSeconds;
  final int totalSeconds;
  final int completedSessions;
  final bool isRunning;
  final int totalFocusMinutesToday;
  
  const PomodoroSession({
    required this.state,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.completedSessions,
    required this.isRunning,
    this.totalFocusMinutesToday = 0,
  });
  
  double get progress => 1 - (remainingSeconds / totalSeconds);
  
  String get timeDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  PomodoroSession copyWith({
    PomodoroState? state,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedSessions,
    bool? isRunning,
    int? totalFocusMinutesToday,
  }) {
    return PomodoroSession(
      state: state ?? this.state,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      isRunning: isRunning ?? this.isRunning,
      totalFocusMinutesToday: totalFocusMinutesToday ?? this.totalFocusMinutesToday,
    );
  }
}

// Providers
final pomodoroSettingsProvider = StateProvider<PomodoroSettings>((ref) => const PomodoroSettings());

final pomodoroSessionProvider = StateNotifierProvider<PomodoroSessionNotifier, PomodoroSession>((ref) {
  return PomodoroSessionNotifier(ref);
});

class PomodoroSessionNotifier extends StateNotifier<PomodoroSession> {
  final Ref ref;
  Timer? _timer;
  
  PomodoroSessionNotifier(this.ref) : super(const PomodoroSession(
    state: PomodoroState.idle,
    remainingSeconds: 25 * 60,
    totalSeconds: 25 * 60,
    completedSessions: 0,
    isRunning: false,
  ));
  
  void startWork() {
    final settings = ref.read(pomodoroSettingsProvider);
    state = state.copyWith(
      state: PomodoroState.working,
      remainingSeconds: settings.workDuration * 60,
      totalSeconds: settings.workDuration * 60,
      isRunning: true,
    );
    _startTimer();
  }
  
  void startBreak() {
    final settings = ref.read(pomodoroSettingsProvider);
    final isLongBreak = (state.completedSessions + 1) % settings.sessionsUntilLongBreak == 0;
    final duration = isLongBreak ? settings.longBreakDuration : settings.shortBreakDuration;
    
    // Add completed work duration to total focus time
    final focusMinutes = settings.workDuration;
    
    state = state.copyWith(
      state: isLongBreak ? PomodoroState.longBreak : PomodoroState.shortBreak,
      remainingSeconds: duration * 60,
      totalSeconds: duration * 60,
      completedSessions: state.completedSessions + 1,
      totalFocusMinutesToday: state.totalFocusMinutesToday + focusMinutes,
      isRunning: true,
    );
    _startTimer();
    _playCompletionSound();
  }
  
  void pause() {
    _timer?.cancel();
    state = state.copyWith(
      state: PomodoroState.paused,
      isRunning: false,
    );
  }
  
  void resume() {
    state = state.copyWith(
      state: state.state == PomodoroState.paused ? PomodoroState.working : state.state,
      isRunning: true,
    );
    _startTimer();
  }
  
  void reset() {
    _timer?.cancel();
    final settings = ref.read(pomodoroSettingsProvider);
    state = state.copyWith(
      state: PomodoroState.idle,
      remainingSeconds: settings.workDuration * 60,
      totalSeconds: settings.workDuration * 60,
      isRunning: false,
    );
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }
  
  void _onTimerComplete() {
    final settings = ref.read(pomodoroSettingsProvider);
    
    if (settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    
    if (state.state == PomodoroState.working) {
      // Work session completed, start break
      startBreak();
    } else {
      // Break completed, reset to idle
      reset();
    }
  }
  
  void _playCompletionSound() {
    final settings = ref.read(pomodoroSettingsProvider);
    if (settings.soundEnabled) {
      // Play system sound
      SystemSound.play(SystemSoundType.alert);
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pomodoroSessionProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          // Purple Gradient Header with Settings
          _buildGradientHeader(context, ref),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Quick Presets (if idle)
                  if (session.state == PomodoroState.idle)
                    _buildQuickPresets(context, ref),
                  
                  if (session.state == PomodoroState.idle)
                    const SizedBox(height: 24),
                  
                  // Timer Circle
                  _buildTimerCircle(context, session, ref),
                  
                  const SizedBox(height: 32),
                  
                  // Control Buttons
                  _buildControlButtons(context, session, ref),
                  
                  const SizedBox(height: 32),
                  
                  // Stats Cards
                  _buildStatsCards(context, session),
                  
                  const SizedBox(height: 24),
                  
                  // AI Insights
                  _buildAIInsights(context, session),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDA7809), // Orange
            Color(0xFFFF9500), // Lighter orange
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.timer_1,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pomodoro Timer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Focus & productivity tracker',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings Button
              IconButton(
                onPressed: () => _showSettingsModal(context, ref),
                icon: const Icon(Iconsax.setting_2, color: Colors.white),
                iconSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPresets(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPresetCard(
                context,
                ref,
                preset: PomodoroPreset.standard,
                icon: Iconsax.timer,
                label: 'Standard',
                subtitle: '25 min',
                color: const Color(0xFFDA7809),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPresetCard(
                context,
                ref,
                preset: PomodoroPreset.deepWork,
                icon: Iconsax.lamp_charge,
                label: 'Deep Work',
                subtitle: '50 min',
                color: const Color(0xFFDA7809),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPresetCard(
                context,
                ref,
                preset: PomodoroPreset.study,
                icon: Iconsax.book,
                label: 'Study',
                subtitle: '30 min',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPresetCard(
                context,
                ref,
                preset: PomodoroPreset.quickTask,
                icon: Iconsax.flash_1,
                label: 'Quick',
                subtitle: '15 min',
                color: const Color(0xFFEC4899),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    WidgetRef ref, {
    required PomodoroPreset preset,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        ref.read(pomodoroSettingsProvider.notifier).state = PomodoroSettings.fromPreset(preset);
        ref.read(pomodoroSessionProvider.notifier).reset();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCircle(BuildContext context, PomodoroSession session, WidgetRef ref) {
    final color = _getStateColor(session.state);
    
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Ring
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: ProgressRingPainter(
                progress: session.progress,
                color: color,
              ),
            ),
          ),
          
          // Time Display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                session.timeDisplay,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStateLabel(session.state),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, PomodoroSession session, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        if (session.state != PomodoroState.idle)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              onPressed: () => ref.read(pomodoroSessionProvider.notifier).reset(),
              icon: const Icon(Iconsax.refresh, color: Colors.white),
              iconSize: 24,
              padding: const EdgeInsets.all(16),
            ),
          ),
        
        // Play/Pause Button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getStateColor(session.state),
                _getStateColor(session.state).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getStateColor(session.state).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              if (session.state == PomodoroState.idle) {
                ref.read(pomodoroSessionProvider.notifier).startWork();
              } else if (session.isRunning) {
                ref.read(pomodoroSessionProvider.notifier).pause();
              } else {
                ref.read(pomodoroSessionProvider.notifier).resume();
              }
            },
            icon: Icon(
              session.isRunning ? Iconsax.pause : Iconsax.play,
              color: Colors.white,
            ),
            iconSize: 32,
            padding: const EdgeInsets.all(24),
          ),
        ),
        
        // Skip Button
        if (session.state != PomodoroState.idle)
          Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              onPressed: () {
                if (session.state == PomodoroState.working) {
                  ref.read(pomodoroSessionProvider.notifier).startBreak();
                } else {
                  ref.read(pomodoroSessionProvider.notifier).reset();
                }
              },
              icon: const Icon(Iconsax.forward, color: Colors.white),
              iconSize: 24,
              padding: const EdgeInsets.all(16),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context, PomodoroSession session) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Iconsax.tick_circle,
            label: 'Sessions',
            value: '${session.completedSessions}',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Iconsax.clock,
            label: 'Today',
            value: '${session.totalFocusMinutesToday}m',
            color: const Color(0xFFDA7809),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Iconsax.flash_1,
            label: 'Streak',
            value: '${session.completedSessions ~/ 4}',
            color: const Color(0xFFDA7809),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(BuildContext context, PomodoroSession session) {
    final insights = _getAIInsights(session);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDA7809),
            Color(0xFFFF9500),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.lamp_charge,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getStateColor(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return const Color(0xFFDA7809);
      case PomodoroState.shortBreak:
        return const Color(0xFF10B981);
      case PomodoroState.longBreak:
        return const Color(0xFFDA7809);
      case PomodoroState.paused:
        return const Color(0xFFEF4444);
      case PomodoroState.idle:
        return const Color(0xFF6B7280);
    }
  }

  String _getStateLabel(PomodoroState state) {
    switch (state) {
      case PomodoroState.working:
        return 'Focus Time';
      case PomodoroState.shortBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break';
      case PomodoroState.paused:
        return 'Paused';
      case PomodoroState.idle:
        return 'Ready to Start';
    }
  }

  List<String> _getAIInsights(PomodoroSession session) {
    if (session.completedSessions == 0) {
      return [
        'Start your first Pomodoro session to build focus',
        'Studies show 25-minute intervals maximize productivity',
        'Take breaks to maintain peak mental performance',
      ];
    } else if (session.completedSessions < 4) {
      return [
        'Great start! You\'re building a productive habit',
        'Try to complete 4 sessions for optimal results',
        'Stay hydrated during your breaks',
      ];
    } else if (session.completedSessions < 8) {
      return [
        'Excellent progress! You\'re in the flow state',
        'Consider a longer break after this cycle',
        'You\'ve focused for ${session.totalFocusMinutesToday} minutes today',
      ];
    } else {
      return [
        'Outstanding! You\'re a productivity champion',
        'Remember to rest - quality over quantity',
        'You\'ve completed ${session.completedSessions} sessions today!',
      ];
    }
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(pomodoroSettingsProvider);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDA7809).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.setting_2,
                          color: Color(0xFFDA7809),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Timer Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Iconsax.close_circle, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: Color(0xFF2A2A2A)),
                
                // Settings Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingSlider(
                          context,
                          ref,
                          label: 'Work Duration',
                          value: settings.workDuration.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          unit: 'min',
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(workDuration: value.toInt());
                            ref.read(pomodoroSessionProvider.notifier).reset();
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSettingSlider(
                          context,
                          ref,
                          label: 'Short Break',
                          value: settings.shortBreakDuration.toDouble(),
                          min: 3,
                          max: 15,
                          divisions: 12,
                          unit: 'min',
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(shortBreakDuration: value.toInt());
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSettingSlider(
                          context,
                          ref,
                          label: 'Long Break',
                          value: settings.longBreakDuration.toDouble(),
                          min: 10,
                          max: 45,
                          divisions: 7,
                          unit: 'min',
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(longBreakDuration: value.toInt());
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSettingSlider(
                          context,
                          ref,
                          label: 'Sessions Until Long Break',
                          value: settings.sessionsUntilLongBreak.toDouble(),
                          min: 2,
                          max: 8,
                          divisions: 6,
                          unit: 'sessions',
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(sessionsUntilLongBreak: value.toInt());
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Toggle Settings
                        _buildSettingToggle(
                          context,
                          ref,
                          label: 'Sound Notifications',
                          subtitle: 'Play sound when timer completes',
                          value: settings.soundEnabled,
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(soundEnabled: value);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildSettingToggle(
                          context,
                          ref,
                          label: 'Vibration',
                          subtitle: 'Vibrate when timer completes',
                          value: settings.vibrationEnabled,
                          onChanged: (value) {
                            ref.read(pomodoroSettingsProvider.notifier).state = 
                              settings.copyWith(vibrationEnabled: value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingSlider(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDA7809).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toInt()} $unit',
                style: const TextStyle(
                  color: Color(0xFFDA7809),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFDA7809),
            inactiveTrackColor: const Color(0xFF2A2A2A),
            thumbColor: const Color(0xFFDA7809),
            overlayColor: const Color(0xFFDA7809).withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingToggle(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFDA7809),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Progress Ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  ProgressRingPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress ring
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
