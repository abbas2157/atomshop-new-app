import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';

class CustomFAQWidget extends StatelessWidget {
  final List<FAQItem> faqs;

  const CustomFAQWidget({super.key, required this.faqs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return FAQTile(
          question: faqs[index].question,
          answer: faqs[index].answer,
          // Only the first item (index 0) will be expanded
          initiallyExpanded: index == 0,
        );
      },
    );
  }
}

class FAQTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool initiallyExpanded;

  const FAQTile({
    super.key,
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Different colors for Expanded vs Collapsed
        color: _isExpanded ? Color(0xFFF3F6FB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          // Custom Circular Plus/Minus Icons
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ColorPalette.secondary),
            ),
            child: Icon(
              _isExpanded ? Icons.remove : Icons.add,
              size: 18,
              color: ColorPalette.secondary,
            ),
          ),
          title: Text(widget.question, style: AppTextStyles.bodyMedium),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              widget.answer,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
