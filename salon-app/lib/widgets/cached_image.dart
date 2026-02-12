import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Max decoded size for memory - limits RAM usage (typical phone ~1080p)
const int _kDefaultMemCacheWidth = 400;
const int _kDefaultMemCacheHeight = 400;

/// Cached network image with placeholder and error handling.
/// Uses memCacheWidth/Height to reduce decoded image memory ~4x.
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final String? placeholderAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.placeholderAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final mw = memCacheWidth ?? (width?.toInt() ?? _kDefaultMemCacheWidth);
    final mh = memCacheHeight ?? (height?.toInt() ?? _kDefaultMemCacheHeight);

    Widget imageWidget = imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: mw > 0 ? mw : null,
            memCacheHeight: mh > 0 ? mh : null,
            maxWidthDiskCache: mw > 0 ? (mw * 2) : null,
            maxHeightDiskCache: mh > 0 ? (mh * 2) : null,
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
    final size = (radius * 2).toInt();
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
                memCacheWidth: size,
                memCacheHeight: size,
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
