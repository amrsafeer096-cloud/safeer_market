// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/product_image.dart';

/// Native HTML `<img draggable>` so Chrome can drag the picture into
/// WhatsApp Desktop / the taskbar, and right-click → Copy image.
class DraggableProductImage extends StatefulWidget {
  const DraggableProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.iconSize = 56,
    this.padding = const EdgeInsets.all(8),
  });

  final String? imageUrl;
  final BoxFit fit;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  State<DraggableProductImage> createState() => _DraggableProductImageState();
}

class _DraggableProductImageState extends State<DraggableProductImage> {
  static final _registered = <String>{};

  String? _viewType;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant DraggableProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _register();
    }
  }

  void _register() {
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      _viewType = null;
      return;
    }
    final viewType = 'safeer-product-img-${url.hashCode}';
    if (!_registered.contains(viewType)) {
      _registered.add(viewType);
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..draggable = true
          ..crossOrigin = 'anonymous'
          ..alt = 'product'
          ..style.objectFit = 'contain'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          ..style.margin = '0'
          ..style.padding = '0'
          ..style.backgroundColor = 'white'
          ..style.cursor = 'grab';
        return img;
      });
    }
    _viewType = viewType;
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) {
      return ProductImage(
        imageUrl: null,
        fit: widget.fit,
        iconSize: widget.iconSize,
        padding: widget.padding,
      );
    }
    return Padding(
      padding: widget.padding,
      child: HtmlElementView(
        key: ValueKey(viewType),
        viewType: viewType,
      ),
    );
  }
}
