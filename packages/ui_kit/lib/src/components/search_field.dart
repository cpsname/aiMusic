import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Rounded search input (docs/ui P02 "Search country").
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: SongletType.body.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: c.inkSecondary,
          size: SongletSize.iconLg,
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: SongletSpace.x4,
          vertical: SongletSpace.x3,
        ),
      ),
    );
  }
}
