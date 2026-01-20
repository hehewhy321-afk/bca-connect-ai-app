import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/constants/easter_eggs.dart';
import '../../widgets/easter_egg_widget.dart';

final selectedDateProvider = StateProvider<NepaliDateTime>((ref) => NepaliDateTime.now());
final selectedViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);

enum CalendarView { month, year }

// Helper function to get correct Nepali day name from AD date
String getNepaliDayName(DateTime adDate) {
  const nepaliDays = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहिबार', 'शुक्रबार', 'शनिबार'];
  // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
  // We need: 0=Sunday, 1=Monday, ..., 6=Saturday
  final dayIndex = adDate.weekday == 7 ? 0 : adDate.weekday;
  return nepaliDays[dayIndex];
}

// Helper function to get English month name
String _getEnglishMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

class NepaliCalendarScreen extends ConsumerStatefulWidget {
  const NepaliCalendarScreen({super.key});

  @override
  ConsumerState<NepaliCalendarScreen> createState() => _NepaliCalendarScreenState();
}

class _NepaliCalendarScreenState extends ConsumerState<NepaliCalendarScreen> {
  late PageController _pageController;
  final int _currentPageIndex = 1200; // Start from middle to allow backward navigation

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedView = ref.watch(selectedViewProvider);
    final today = NepaliDateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ModernTheme.primaryOrange,
                      ModernTheme.primaryOrange.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            EasterEggWidget(
                              soundFile: EasterEggs.calendar.soundFile,
                              emoji: EasterEggs.calendar.emoji,
                              message: EasterEggs.calendar.message,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Iconsax.calendar_1,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'नेपाली पात्रो',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Nepali Calendar',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Current Date Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    NepaliDateFormat('MMMM dd, yyyy', Language.nepali).format(today),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    getNepaliDayName(today.toDateTime()),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${today.toDateTime().day} ${_getEnglishMonthName(today.toDateTime().month)} ${today.toDateTime().year}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  today.day.toString(),
                                  style: const TextStyle(
                                    color: ModernTheme.primaryOrange,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Calendar Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month/Year Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildViewButton(
                            context,
                            'Month',
                            CalendarView.month,
                            selectedView == CalendarView.month,
                          ),
                        ),
                        Expanded(
                          child: _buildViewButton(
                            context,
                            'Year',
                            CalendarView.year,
                            selectedView == CalendarView.year,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 20),

                  // Calendar Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (selectedView == CalendarView.month) {
                            // Handle month navigation with year transition
                            final newYear = selectedDate.month == 1 
                                ? selectedDate.year - 1 
                                : selectedDate.year;
                            final newMonth = selectedDate.month == 1 
                                ? 12 
                                : selectedDate.month - 1;
                            final newDate = NepaliDateTime(newYear, newMonth);
                            ref.read(selectedDateProvider.notifier).state = newDate;
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            final newDate = NepaliDateTime(selectedDate.year - 1);
                            ref.read(selectedDateProvider.notifier).state = newDate;
                          }
                        },
                        icon: const Icon(Iconsax.arrow_left_2),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Text(
                        selectedView == CalendarView.month
                            ? NepaliDateFormat('MMMM yyyy', Language.nepali).format(selectedDate)
                            : NepaliDateFormat('yyyy', Language.nepali).format(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (selectedView == CalendarView.month) {
                            // Handle month navigation with year transition
                            final newYear = selectedDate.month == 12 
                                ? selectedDate.year + 1 
                                : selectedDate.year;
                            final newMonth = selectedDate.month == 12 
                                ? 1 
                                : selectedDate.month + 1;
                            final newDate = NepaliDateTime(newYear, newMonth);
                            ref.read(selectedDateProvider.notifier).state = newDate;
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            final newDate = NepaliDateTime(selectedDate.year + 1);
                            ref.read(selectedDateProvider.notifier).state = newDate;
                          }
                        },
                        icon: const Icon(Iconsax.arrow_right_3),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // Calendar Grid
                  if (selectedView == CalendarView.month)
                    _buildMonthView(context, selectedDate, today)
                  else
                    _buildYearView(context, selectedDate, today),

                  const SizedBox(height: 24),

                  // Today Button
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state = NepaliDateTime.now();
                    },
                    icon: const Icon(Iconsax.calendar_tick),
                    label: const Text('आज (Today)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ModernTheme.primaryOrange,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),

                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nepali calendar is based on Bikram Sambat (BS) system',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(BuildContext context, String label, CalendarView view, bool isSelected) {
    return InkWell(
      onTap: () => ref.read(selectedViewProvider.notifier).state = view,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ModernTheme.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, NepaliDateTime selectedDate, NepaliDateTime today) {
    final firstDayOfMonth = NepaliDateTime(selectedDate.year, selectedDate.month, 1);
    // Get days in month by checking the last day of the month
    final nextMonth = selectedDate.month == 12 
        ? NepaliDateTime(selectedDate.year + 1, 1, 1)
        : NepaliDateTime(selectedDate.year, selectedDate.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    final daysInMonth = lastDayOfMonth.day;
    
    // Convert to AD date to get correct weekday
    final firstDayAD = firstDayOfMonth.toDateTime();
    // weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // We need: 0=Sunday, 1=Monday, ..., 6=Saturday
    final startWeekday = firstDayAD.weekday == 7 ? 0 : firstDayAD.weekday;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['आइत', 'सोम', 'मंगल', 'बुध', 'बिहि', 'शुक्र', 'शनि']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Calendar Days
          ...List.generate((daysInMonth + startWeekday) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final isToday = today.year == selectedDate.year &&
                      today.month == selectedDate.month &&
                      today.day == dayNumber;

                  // Check if this specific date is Saturday by converting to AD
                  final currentDate = NepaliDateTime(selectedDate.year, selectedDate.month, dayNumber);
                  final currentDateAD = currentDate.toDateTime();
                  final isSaturday = currentDateAD.weekday == 6; // 6 = Saturday in Dart DateTime

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state = NepaliDateTime(
                          selectedDate.year,
                          selectedDate.month,
                          dayNumber,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? ModernTheme.primaryOrange
                              : isSaturday
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? ModernTheme.primaryOrange
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            NepaliUnicode.convert('$dayNumber'),
                            style: TextStyle(
                              color: isToday
                                  ? Colors.white
                                  : isSaturday
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms, begin: const Offset(0.95, 0.95));
  }

  Widget _buildYearView(BuildContext context, NepaliDateTime selectedDate, NepaliDateTime today) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isCurrentMonth = today.year == selectedDate.year && today.month == month;

        return InkWell(
          onTap: () {
            ref.read(selectedDateProvider.notifier).state = NepaliDateTime(
              selectedDate.year,
              month,
            );
            ref.read(selectedViewProvider.notifier).state = CalendarView.month;
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentMonth
                  ? ModernTheme.primaryOrange.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentMonth
                    ? ModernTheme.primaryOrange
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                NepaliDateFormat('MMMM', Language.nepali).format(
                  NepaliDateTime(selectedDate.year, month),
                ),
                style: TextStyle(
                  color: isCurrentMonth
                      ? ModernTheme.primaryOrange
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().scale();
      },
    );
  }
}
