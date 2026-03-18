import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget couverture qui gère les URLs http ET les données base64
class CoverImage extends StatelessWidget {
  final String? coverUrl;
  final double width;
  final double height;
  final double placeholderFontSize;
  final BoxFit fit;

  const CoverImage({
    super.key,
    required this.coverUrl,
    required this.width,
    required this.height,
    this.placeholderFontSize = 22,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return _placeholder();
    }

    // Base64 data URI
    if (coverUrl!.startsWith('data:')) {
      try {
        final parts = coverUrl!.split(',');
        final bytes = base64Decode(parts.length > 1 ? parts[1] : parts[0]);
        return Image.memory(
          Uint8List.fromList(bytes),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }

    // URL http(s)
    return CachedNetworkImage(
      imageUrl: coverUrl!,
      width: width,
      height: height,
      fit: fit,
      errorWidget: (_, __, ___) => _placeholder(),
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFF161820),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF55596E)),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF161820),
      child: Center(
        child: Text('📕', style: TextStyle(fontSize: placeholderFontSize)),
      ),
    );
  }
}
