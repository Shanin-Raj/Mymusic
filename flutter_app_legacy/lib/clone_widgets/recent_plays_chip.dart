import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';

/// Spotify-style recent-plays chip:
/// Square thumbnail on the left, bold song name on the right,
/// dark card background, subtle green accent when currently playing.
class RecentPlaysChip extends StatelessWidget {
  const RecentPlaysChip({
    super.key,
    required this.image,
    required this.title,
    this.onTap,
    this.isCurrent = false,
  });

  final String title;
  final String image;
  final VoidCallback? onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.cardColor : Colors.white;
    final textColor = isCurrent ? MyColors.greenColor : (isDark ? MyColors.whiteColor : MyColors.darkText);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: isCurrent ? MyColors.greenColor.withValues(alpha: 0.12) : bg,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent
              ? Border.all(color: MyColors.greenColor.withValues(alpha: 0.4), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Square thumbnail, flush left
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: CachedNetworkImage(
                imageUrl: image,
                height: 56,
                width: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: MyColors.cardColor,
                  child: const Icon(Icons.music_note, color: MyColors.mutedGrey, size: 20),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: MyColors.cardColor,
                  child: const Icon(Icons.music_note, color: MyColors.mutedGrey, size: 20),
                ),
              ),
            ),
            // Song title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle(color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
