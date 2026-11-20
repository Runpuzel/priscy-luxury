import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

class ColourSwatchSelector extends StatelessWidget {
  const ColourSwatchSelector({
    super.key,
    required this.colours,
    required this.selectedColour,
    required this.variants,
    this.selectedSize,
    required this.onSelected,
  });

  final List<String> colours;
  final String? selectedColour;
  final List<ProductVariant> variants;
  final String? selectedSize;
  final ValueChanged<String> onSelected;

  bool _colourHasAnyStock(String colour) {
    return variants.any(
      (v) => v.colour.toLowerCase() == colour.toLowerCase() && v.isInStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colours.map((colour) {
        final isSelected =
            selectedColour?.toLowerCase() == colour.toLowerCase();
        final inStock = _colourHasAnyStock(colour);

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: inStock ? () => onSelected(colour) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.sand
                  : (inStock ? AppColors.surface : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.espresso
                    : (inStock ? AppColors.border : AppColors.border.withAlpha(120)),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.swatchForName(colour),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  colour,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: inStock ? AppColors.ink : AppColors.mutedText,
                    decoration: inStock ? null : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SizeChipSelector extends StatelessWidget {
  const SizeChipSelector({
    super.key,
    required this.sizes,
    required this.selectedSize,
    required this.variants,
    required this.selectedColour,
    required this.onSelected,
  });

  final List<String> sizes;
  final String? selectedSize;
  final List<ProductVariant> variants;
  final String? selectedColour;
  final ValueChanged<String> onSelected;

  bool _sizeAvailableForColour(String size) {
    return variants.any((v) {
      if (v.size != size || !v.isInStock) return false;
      if (selectedColour == null || selectedColour!.isEmpty) return true;
      return v.colour.toLowerCase() == selectedColour!.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((size) {
        final isSelected = selectedSize == size;
        final enabled = _sizeAvailableForColour(size);

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => onSelected(size) : null,
          child: Container(
            width: 56,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.espresso
                  : (enabled ? AppColors.surface : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.espresso : AppColors.border,
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Text(
              size,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (enabled ? AppColors.ink : AppColors.mutedText.withAlpha(130)),
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
