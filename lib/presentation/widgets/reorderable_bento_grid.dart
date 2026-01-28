import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/services/quick_actions_service.dart';

class ReorderableBentoGrid extends StatefulWidget {
  final List<QuickAction> actions;
  final Function(List<QuickAction>) onReorder;
  final bool isCustomizationMode;
  final VoidCallback? onToggleCustomization;

  const ReorderableBentoGrid({
    super.key,
    required this.actions,
    required this.onReorder,
    this.isCustomizationMode = false,
    this.onToggleCustomization,
  });

  @override
  State<ReorderableBentoGrid> createState() => _ReorderableBentoGridState();
}

class _ReorderableBentoGridState extends State<ReorderableBentoGrid>
    with TickerProviderStateMixin {
  late List<QuickAction> _actions;
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _actions = List.from(widget.actions);
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    if (widget.isCustomizationMode) {
      _wiggleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReorderableBentoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actions != oldWidget.actions) {
      _actions = List.from(widget.actions);
    }

    if (widget.isCustomizationMode != oldWidget.isCustomizationMode) {
      if (widget.isCustomizationMode) {
        _wiggleController.repeat(reverse: true);
      } else {
        _wiggleController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isCustomizationMode) _buildCustomizationHeader(),
        _buildResponsiveBentoGrid(),
        if (widget.isCustomizationMode) ...[
          const SizedBox(height: 16),
          _buildResetButton(),
        ],
      ],
    );
  }

  Widget _buildCustomizationHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.edit,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Quick Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Drag and drop tiles to rearrange',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onToggleCustomization,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final service = QuickActionsService();
        await service.resetToDefault();
        final defaultActions = await service.getOrderedQuickActions();
        widget.onReorder(defaultActions);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quick actions reset to default order'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      icon: const Icon(Iconsax.refresh, size: 18),
      label: const Text('Reset Order'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResponsiveBentoGrid() {
    if (_actions.isEmpty) return const SizedBox.shrink();

    final List<Widget> widgets = [];
    int i = 0;

    while (i < _actions.length) {
      // 1. Check for Pattern: Large Left (Large card + 2 Horizontal cards)
      if (i + 2 < _actions.length &&
          _actions[i].type == QuickActionType.large &&
          _actions[i + 1].type == QuickActionType.horizontal &&
          _actions[i + 2].type == QuickActionType.horizontal) {
        widgets.add(_buildPatternLargeLeft(i));
        i += 3;
        continue;
      }

      // 2. Check for Pattern: Large Right (2 Horizontal cards + Large card)
      if (i + 2 < _actions.length &&
          _actions[i].type == QuickActionType.horizontal &&
          _actions[i + 1].type == QuickActionType.horizontal &&
          _actions[i + 2].type == QuickActionType.large) {
        widgets.add(_buildPatternLargeRight(i));
        i += 3;
        continue;
      }

      // 3. Wide pattern
      if (_actions[i].type == QuickActionType.wide) {
        widgets.add(_buildCardWrapper(_actions[i], isWide: true));
        i += 1;
        continue;
      }

      // 4. Default: Pair or Single
      if (i + 1 < _actions.length) {
        widgets.add(_buildPair(i));
        i += 2;
      } else {
        widgets.add(_buildCardWrapper(_actions[i], isWide: true));
        i += 1;
      }
    }

    return Column(children: widgets);
  }

  Widget _buildCardWrapper(
    QuickAction action, {
    bool isLarge = false,
    bool isHorizontal = false,
    bool isWide = false,
  }) {
    final index = _actions.indexOf(action);

    Widget cardContent = _BentoGridCard(
      action: action,
      isLarge: isLarge,
      isHorizontal: isHorizontal,
      isWide: isWide,
      onTap: () => context.push(action.route),
    );

    if (widget.isCustomizationMode) {
      cardContent = AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          return Transform.rotate(
            angle: 0.01 * (index % 2 == 0 ? 1 : -1) * _wiggleController.value,
            child: child,
          );
        },
        child: cardContent,
      );

      return DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) {
          final oldIndex = details.data;
          setState(() {
            final item = _actions.removeAt(oldIndex);
            _actions.insert(index, item);
          });
          widget.onReorder(_actions);
          HapticFeedback.mediumImpact();
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: isLarge ? 160 : (isHorizontal ? 76 : (isWide ? 76 : 100)),
            child: LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: isWide
                      ? MediaQuery.of(context).size.width - 32
                      : (MediaQuery.of(context).size.width - 40) / 2,
                  height: isLarge ? 160 : 76,
                  child: Transform.scale(
                    scale: 1.05,
                    child: _BentoGridCard(
                      action: action,
                      isLarge: isLarge,
                      isHorizontal: isHorizontal,
                      isWide: isWide,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
              child: cardContent,
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: isLarge ? 160 : (isHorizontal ? 76 : (isWide ? 76 : 100)),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onToggleCustomization?.call();
        },
        child: cardContent,
      ),
    );
  }

  Widget _buildPatternLargeLeft(int startIndex) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildCardWrapper(_actions[startIndex], isLarge: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _buildCardWrapper(
                    _actions[startIndex + 1],
                    isHorizontal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildCardWrapper(
                    _actions[startIndex + 2],
                    isHorizontal: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternLargeRight(int startIndex) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _buildCardWrapper(
                    _actions[startIndex],
                    isHorizontal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildCardWrapper(
                    _actions[startIndex + 1],
                    isHorizontal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _buildCardWrapper(_actions[startIndex + 2], isLarge: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPair(int startIndex) {
    final leftAction = _actions[startIndex];
    final rightAction = _actions[startIndex + 1];

    return Container(
      height: 76,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildCardWrapper(leftAction, isHorizontal: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildCardWrapper(rightAction, isHorizontal: true)),
        ],
      ),
    );
  }
}

class _BentoGridCard extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;
  final bool isLarge;
  final bool isHorizontal;
  final bool isWide;

  const _BentoGridCard({
    required this.action,
    required this.onTap,
    this.isLarge = false,
    this.isHorizontal = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: action.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLarge) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(action.icon, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            action.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else if (isWide) {
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(action.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(action.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
}
