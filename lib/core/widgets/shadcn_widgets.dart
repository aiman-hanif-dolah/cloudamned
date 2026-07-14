import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/shadcn_colors.dart';

/// shadcn-style Button
class ShadButton extends StatelessWidget {
  const ShadButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ShadButtonVariant.primary,
    this.size = ShadButtonSize.md,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ShadButtonVariant variant;
  final ShadButtonSize size;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      ShadButtonVariant.primary => (
          ShadcnColors.primary,
          ShadcnColors.primaryForeground,
          Colors.transparent
        ),
      ShadButtonVariant.secondary => (
          ShadcnColors.secondary,
          ShadcnColors.secondaryForeground,
          Colors.transparent
        ),
      ShadButtonVariant.outline => (
          Colors.transparent,
          ShadcnColors.foreground,
          ShadcnColors.border
        ),
      ShadButtonVariant.ghost => (
          Colors.transparent,
          ShadcnColors.foreground,
          Colors.transparent
        ),
      ShadButtonVariant.destructive => (
          ShadcnColors.destructive,
          ShadcnColors.destructiveForeground,
          Colors.transparent
        ),
      ShadButtonVariant.success => (
          ShadcnColors.success,
          Colors.white,
          Colors.transparent
        ),
    };

    final padding = switch (size) {
      ShadButtonSize.sm => const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ShadButtonSize.md => const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ShadButtonSize.lg => const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontSize: size == ShadButtonSize.sm ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ShadButtonVariant { primary, secondary, outline, ghost, destructive, success }
enum ShadButtonSize { sm, md, lg }

/// shadcn-style Card
class ShadCard extends StatelessWidget {
  const ShadCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.header,
    this.footer,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: header!,
          ),
          const SizedBox(height: 8),
        ],
        Padding(padding: padding, child: child),
        if (footer != null) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: footer!,
          ),
        ],
      ],
    );

    return Material(
      color: ShadcnColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ShadcnColors.border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// shadcn-style Badge
class ShadBadge extends StatelessWidget {
  const ShadBadge({
    super.key,
    required this.label,
    this.color,
    this.variant = ShadBadgeVariant.secondary,
  });

  final String label;
  final Color? color;
  final ShadBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      ShadBadgeVariant.default_ => (ShadcnColors.primary, ShadcnColors.primaryForeground),
      ShadBadgeVariant.secondary => (ShadcnColors.secondary, ShadcnColors.secondaryForeground),
      ShadBadgeVariant.outline => (Colors.transparent, ShadcnColors.foreground),
      ShadBadgeVariant.success => (ShadcnColors.success.withValues(alpha: 0.15), ShadcnColors.success),
      ShadBadgeVariant.warning => (ShadcnColors.warning.withValues(alpha: 0.15), ShadcnColors.warning),
      ShadBadgeVariant.destructive => (
          ShadcnColors.destructive.withValues(alpha: 0.15),
          ShadcnColors.destructive
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.15) ?? bg,
        borderRadius: BorderRadius.circular(999),
        border: variant == ShadBadgeVariant.outline
            ? Border.all(color: ShadcnColors.border)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum ShadBadgeVariant { default_, secondary, outline, success, warning, destructive }

/// shadcn-style Input
class ShadInput extends StatelessWidget {
  const ShadInput({
    super.key,
    this.controller,
    this.hint,
    this.prefix,
    this.onSubmitted,
    this.onChanged,
    this.obscure = false,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hint;
  final Widget? prefix;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: ShadcnColors.foreground),
      cursorColor: ShadcnColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        isDense: true,
      ),
    );
  }
}

/// Progress bar
class ShadProgress extends StatelessWidget {
  const ShadProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: ShadcnColors.secondary,
        color: color ?? ShadcnColors.primary,
      ),
    );
  }
}

/// Section header
class ShadSectionHeader extends StatelessWidget {
  const ShadSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: narrow ? 16 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: ShadcnColors.mutedForeground,
            ),
          ),
        ],
      ],
    );

    if (trailing == null) return titleBlock;

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: trailing!),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}

/// Stat tile
class ShadStatTile extends StatelessWidget {
  const ShadStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? ShadcnColors.mutedForeground),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ShadcnColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: color ?? ShadcnColors.foreground,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(
              trend!,
              style: const TextStyle(fontSize: 11, color: ShadcnColors.success),
            ),
          ],
        ],
      ),
    );
  }
}

/// Panel chrome for IDE-style panes
class ShadPanel extends StatelessWidget {
  const ShadPanel({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.showHeader = true,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShadcnColors.panel,
        border: Border.all(color: ShadcnColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader && title != null)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: ShadcnColors.panelHeader,
                border: Border(bottom: BorderSide(color: ShadcnColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ShadcnColors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Tab strip
class ShadTabs extends StatelessWidget {
  const ShadTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ShadcnColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            InkWell(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == index ? ShadcnColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                    color: i == index
                        ? ShadcnColors.foreground
                        : ShadcnColors.mutedForeground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state
class ShadEmpty extends StatelessWidget {
  const ShadEmpty({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 40, color: ShadcnColors.mutedForeground),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: ShadcnColors.mutedForeground),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
