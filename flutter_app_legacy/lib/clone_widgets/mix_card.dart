import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';

/// Figma-style album/mix card: 154×154 square artwork, bold title, grey subtitle.
class MixCard extends StatelessWidget {
  const MixCard({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isCurrent = false,
  });

  final String title;
  final String? subtitle;
  final String image;
  final VoidCallback? onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isCurrent ? MyColors.greenColor : (isDark ? Colors.white : MyColors.darkText);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 154,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    height: 154,
                    width: 154,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 154,
                      width: 154,
                      color: MyColors.cardColor,
                      child: const Icon(Icons.album, color: MyColors.mutedGrey, size: 40),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 154,
                      width: 154,
                      color: MyColors.cardColor,
                      child: const Icon(Icons.album, color: MyColors.mutedGrey, size: 40),
                    ),
                  ),
                  // Playing indicator overlay
                  if (isCurrent)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: MyColors.greenColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pause, color: Colors.black, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              title,
              style: AppTextStyles.cardTitle(color: titleColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: AppTextStyles.cardSubtitle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
