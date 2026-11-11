import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'brand.dart';
import 'device_family.dart';
import 'test_id.dart';

/// Width class for adaptive layouts (phase 5): regular = iPad and wide
/// landscape, where pages switch to two columns. Every two-column branch
/// goes through here, so it is regular only while the app ships for iPad
/// ([ipadEnabled], ADR-0037); the iPhone (portrait only) is always compact.
enum WindowClass {
  compact,
  regular;

  static WindowClass of(BuildContext context) =>
      ipadEnabled &&
          MediaQuery.sizeOf(context).width >= SongletSize.twoPaneBreakpoint
      ? regular
      : compact;
}

/// Horizontal page gutter for the current width class.
double pageGutter(BuildContext context) =>
    WindowClass.of(context) == WindowClass.regular
    ? SongletSpace.gutterRegular
    : SongletSpace.gutter;

/// A scrolling page body: safe area, gutter, readable max width, optional
/// sticky [footer] (primary action) that stays above the home indicator.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.maxWidth = SongletSize.contentMaxWidth,
    this.controller,
  });

  final Widget? header;
  final List<Widget> children;
  final Widget? footer;
  final double maxWidth;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final gutter = pageGutter(context);
    // Children take the full readable width (centred on wide screens).
    Widget constrain(Widget child) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
    // At accessibility Dynamic Type sizes a pinned footer can outgrow the
    // screen, so it scrolls in after the content instead.
    final pinFooter =
        footer != null && !SongletType.isAccessibilitySize(context);
    return AuroraBackground(
      child: SafeArea(
        bottom: !pinFooter,
        child: Column(
          children: [
            if (header != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  SongletSpace.x2,
                  gutter,
                  SongletSpace.x2,
                ),
                child: constrain(header!),
              ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  SongletSpace.x2,
                  gutter,
                  SongletSpace.x8,
                ),
                children: [
                  for (final child in children) constrain(child),
                  if (footer != null && !pinFooter) ...[
                    const SizedBox(height: SongletSpace.x4),
                    constrain(footer!),
                  ],
                ],
              ),
            ),
            if (pinFooter)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: SongletSpace.x4),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    gutter,
                    SongletSpace.x2,
                    gutter,
                    0,
                  ),
                  child: constrain(footer!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Header of a pushed page (docs/ui P07, P09, P11, P13): back button, the
/// centred brand, and trailing actions.
class PushedHeader extends StatelessWidget {
  const PushedHeader({
    super.key,
    this.actions = const [],
    this.onBack,
    this.showBrand = true,
  });

  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final canPop = onBack != null || context.canPop();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: SongletSize.minTap + SongletSpace.x4,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          // Keeps the brand centred whatever the widths of the two sides.
          child: NavigationToolbar(
            leading: canPop
                ? TestId(
                    'nav.back',
                    child: IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: l10n.commonBack,
                      onPressed: onBack ?? () => context.pop(),
                    ),
                  )
                : null,
            middle: showBrand
                ? BrandHeader(
                    title: SongletBrand.name,
                    tagline: l10n.appTagline,
                    centered: true,
                    markSize: SongletSize.minTap,
                  )
                : null,
            trailing: actions.isEmpty
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
            middleSpacing: SongletSpace.x2,
          ),
        ),
      ),
    );
  }
}

/// Page-level large title with optional subtitle (P04, P10, P15).
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: SongletSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aurora kicker: a small gradient rule that announces the title.
          Container(
            width: SongletSpace.x10,
            height: SongletSpace.x1,
            margin: const EdgeInsetsDirectional.only(bottom: SongletSpace.x3),
            decoration: BoxDecoration(
              gradient: c.actionGradient,
              borderRadius: SongletRadius.pillAll,
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              title,
              style: SongletType.largeTitle.copyWith(color: c.ink),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: SongletSpace.x1),
            Text(
              subtitle!,
              style: SongletType.body.copyWith(color: c.inkSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
