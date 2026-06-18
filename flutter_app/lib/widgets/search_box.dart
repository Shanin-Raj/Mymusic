import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Figma-style search box: #282828 rounded rect, magnifier left,
/// text field, Cancel text button right (always visible when controller has text).
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.onChanged,
    this.controller,
    this.onCancel,
  });

  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg  = isDark ? MyColors.cardColor : const Color(0xFFE8E8E8);
    final iconColor  = isDark ? Colors.white70 : MyColors.mutedGrey;
    final textColor  = isDark ? Colors.white   : MyColors.darkText;
    final hintColor  = isDark ? MyColors.mutedGrey : const Color(0xFF9E9E9E);

    return Container(
      color: isDark ? MyColors.surfaceDark : MyColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: boxBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: AppTextStyles.searchHint(color: textColor),
                      cursorColor: MyColors.greenColor,
                      decoration: InputDecoration(
                        hintText: 'What do you want to listen to?',
                        hintStyle: AppTextStyles.searchHint(color: hintColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Clear icon when typing
                  if (controller != null && (controller!.text.isNotEmpty))
                    GestureDetector(
                      onTap: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.close, color: iconColor, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Cancel button — always visible (matches Figma)
          if (onCancel != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onCancel,
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyBold(
                  color: isDark ? Colors.white : MyColors.darkText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
