import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  HighlightedText({
    required this.wholeString,
    required this.highlightedString,
    this.defaultStyle = const TextStyle(color: Colors.black),
    this.highlightStyle = const TextStyle(color: Colors.blue),
    this.isCaseSensitive = false,
  });

  final String wholeString;
  final String highlightedString;
  final TextStyle defaultStyle;
  final TextStyle highlightStyle;
  final bool isCaseSensitive;

  int get _highlightStart {
    if (isCaseSensitive) {
      return wholeString.indexOf(highlightedString);
    }
    return wholeString.toLowerCase().indexOf(highlightedString.toLowerCase());
  }

  int get _highlightEnd => _highlightStart + highlightedString.length;

  @override
  Widget build(BuildContext context) {
    if (_highlightStart == -1) {
      return Text(wholeString, style: defaultStyle);
    }
    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: [
          TextSpan(text: wholeString.substring(0, _highlightStart)),
          TextSpan(
            text: wholeString.substring(_highlightStart, _highlightEnd),
            style: highlightStyle,
          ),
          TextSpan(text: wholeString.substring(_highlightEnd))
        ],
      ),
    );
  }
}
