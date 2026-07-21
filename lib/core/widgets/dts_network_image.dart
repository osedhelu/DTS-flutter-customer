import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DtsNetworkImage extends StatelessWidget {
  const DtsNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    Widget child;
    if (imageUrl == null || imageUrl.isEmpty) {
      child = _placeholder(context);
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _placeholder(context),
        errorWidget: (_, __, ___) => _placeholder(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }
}
