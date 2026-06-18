import 'package:flutter/material.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';

/// Figma-style library filter chips: horizontal scrollable pills
/// with border outline, rounded corners, Montserrat text.
class LibraryOptionsList extends StatelessWidget {
  const LibraryOptionsList({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const List<String> chipTitles = [
      'Playlists',
      'Artists',
      'Albums',
      'Liked Songs',
    ];

    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chipTitles.length,
        itemBuilder: (context, index) {
          final title = chipTitles[index];
          final isSelected = title == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  onFilterSelected(null); // toggle off
                } else {
                  onFilterSelected(title);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? MyColors.greenColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? MyColors.greenColor
                        : (isDark ? const Color(0xFF535353) : const Color(0xFFCCCCCC)),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title,
                      style: AppTextStyles.navLabel(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white : MyColors.darkText),
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
