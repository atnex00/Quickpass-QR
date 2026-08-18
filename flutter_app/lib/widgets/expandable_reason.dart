import 'package:flutter/material.dart';

import '../config/theme.dart';

class ExpandableReason extends StatefulWidget {
  const ExpandableReason({
    super.key,
    required this.text,
    this.collapsedLines = 2,
    this.style,
  });

  final String text;
  final int collapsedLines;
  final TextStyle? style;

  @override
  State<ExpandableReason> createState() => _ExpandableReasonState();
}

class _ExpandableReasonState extends State<ExpandableReason> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ?? TextStyle(color: context.neutralGray, fontSize: 13);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        if (!painter.didExceedMaxLines) {
          return Text(widget.text, style: style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : widget.collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: style,
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
