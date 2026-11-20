import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Clean, dependency-free Markdown renderer for editable policy & static pages.
class MarkdownBodyView extends StatelessWidget {
  const MarkdownBodyView({super.key, required this.markdown});
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split(RegExp(r'\r?\n'));
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              line.substring(3),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(4),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.espresso,
                  ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 10),
                  child: Icon(Icons.circle, size: 6, color: AppColors.gold),
                ),
                Expanded(child: _RichBoldText(text: line.substring(2))),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final dotIdx = line.indexOf('.');
        final numPrefix = line.substring(0, dotIdx + 1);
        final rest = line.substring(dotIdx + 1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    numPrefix,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
                Expanded(child: _RichBoldText(text: rest)),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _RichBoldText(text: line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _RichBoldText extends StatelessWidget {
  const _RichBoldText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: spans,
      ),
    );
  }
}
