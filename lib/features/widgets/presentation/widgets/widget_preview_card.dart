import 'dart:io';
import 'package:flutter/material.dart';

import '../../domain/models/widget_config_model.dart';

class WidgetPreviewCard extends StatelessWidget {
  final WidgetConfigModel config;
  final VoidCallback? onTap;

  const WidgetPreviewCard({
    super.key,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(config.backgroundColor).withOpacity(
      config.isTransparent ? config.opacity : 1.0,
    );
    final textColor = Color(config.textColor);

    double width = 120;
    double height = 120;

    if (config.widgetSize == 'medium') {
      width = 240;
      height = 100;
    } else if (config.widgetSize == 'large') {
      width = 220;
      height = 200;
    }

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(config.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildLayoutForSize(context, textColor),
        ),
      ),
    );
  }

  Widget _buildLayoutForSize(BuildContext context, Color textColor) {
    if (config.widgetSize == 'medium') {
      return Row(
        children: [
          _buildAvatar(48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.showName)
                  Text(
                    config.contactName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (config.showPhone && config.phoneNumber.isNotEmpty)
                  Text(
                    config.phoneNumber,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(Icons.call_rounded, color: textColor, size: 24),
        ],
      );
    } else if (config.widgetSize == 'large') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAvatar(64),
          const SizedBox(height: 8),
          if (config.showName)
            Text(
              config.contactName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (config.showPhone && config.phoneNumber.isNotEmpty)
            Text(
              config.phoneNumber,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSimBadgeLabel(config.simSelectionMode),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // Small widget (default)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAvatar(44),
        if (config.showName) ...[
          const SizedBox(height: 4),
          Text(
            config.contactName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(double size) {
    Widget imageWidget;
    if (config.photoPath.isNotEmpty && File(config.photoPath).existsSync()) {
      imageWidget = Image.file(
        File(config.photoPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      final initial = config.contactName.isNotEmpty
          ? config.contactName.substring(0, 1).toUpperCase()
          : '?';
      imageWidget = Container(
        width: size,
        height: size,
        color: const Color(0xFF4A6572),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
          ),
        ),
      );
    }

    BorderRadius borderRadius;
    if (config.imageShape == 'circular') {
      borderRadius = BorderRadius.circular(size / 2);
    } else if (config.imageShape == 'rounded') {
      borderRadius = BorderRadius.circular(12);
    } else {
      borderRadius = BorderRadius.zero;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageWidget,
    );
  }

  String _getSimBadgeLabel(int mode) {
    switch (mode) {
      case 1:
        return 'SIM 1';
      case 2:
        return 'SIM 2';
      case 3:
        return 'Ask';
      default:
        return 'Default SIM';
    }
  }
}
