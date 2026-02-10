import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cached network image with placeholder and error handling
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildPlaceholder(),
          )
        : _buildPlaceholder();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: placeholderAsset != null
          ? Image.asset(
              placeholderAsset!,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_outlined,
                size: (height ?? 100) * 0.5,
                color: Colors.grey[400],
              ),
            )
          : Icon(
              Icons.image_outlined,
              size: (height ?? 100) * 0.5,
              color: Colors.grey[400],
            ),
    );
  }
}

/// Circular cached image (for categories, avatars, etc.)
class CachedCircleImage extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;
  final double radius;

  const CachedCircleImage({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return placeholderAsset != null
        ? Image.asset(
            placeholderAsset!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.image_outlined,
              size: radius,
              color: Colors.grey[400],
            ),
          )
        : Icon(
            Icons.image_outlined,
            size: radius,
            color: Colors.grey[400],
          );
  }
}
