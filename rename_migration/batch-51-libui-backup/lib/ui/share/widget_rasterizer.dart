import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ui_kit/ui_kit.dart';

/// Renders [child] off screen into a PNG of [size] logical pixels × [pixelRatio]
/// with the ambient theme and direction of [context] — so an exported frame is
/// pixel-for-pixel the widget the user previewed (share card, docs/ui P10).
Future<Uint8List> rasterizeWidget(
  BuildContext context,
  Widget child, {
  required Size size,
  required double pixelRatio,
}) async {
  final theme = Theme.of(context);
  final direction = Directionality.of(context);
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: View.of(context),
    child: RenderPositionedBox(child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  try {
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
        child: Theme(
          data: theme,
          child: Directionality(
            textDirection: direction,
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium ?? const TextStyle(),
              child: MotionPolicyOverride(reduceMotion: true, child: child),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);
    buildOwner
      ..buildScope(root)
      ..finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    buildOwner.finalizeTree();
    renderView.child = null;
    pipeline.rootNode = null;
  }
}
