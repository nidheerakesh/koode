import 'package:flutter/material.dart';

import '../../ui/theme.dart';

/// Number pad fallback, for when the camera or voice can't read the price.
Future<int?> askAmount(BuildContext context, String title) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AmountPad(title),
  );
}

class _AmountPad extends StatefulWidget {
  final String title;
  const _AmountPad(this.title);
  @override
  State<_AmountPad> createState() => _AmountPadState();
}

class _AmountPadState extends State<_AmountPad> {
  String v = '';

  Widget _key(String k) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          height: 72,
          child: FilledButton.tonal(
            onPressed: () => setState(() {
              if (k == '⌫') {
                if (v.isNotEmpty) v = v.substring(0, v.length - 1);
              } else if (v.length < 5) {
                v += k;
              }
            }),
            child: Text(k, style: const TextStyle(fontSize: 30)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title, style: const TextStyle(fontSize: 22)),
          Text('₹${v.isEmpty ? '0' : v}',
              style: const TextStyle(
                  fontSize: 56, fontWeight: FontWeight.w800, color: K.ink)),
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['⌫', '0', '✓'],
          ])
            Row(
                children: row
                    .map((k) => Expanded(
                        child: k == '✓'
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: SizedBox(
                                  height: 72,
                                  child: FilledButton(
                                    onPressed: v.isEmpty || int.parse(v) == 0
                                        ? null
                                        : () => Navigator.pop(
                                            context, int.parse(v)),
                                    child: const Icon(Icons.check, size: 36),
                                  ),
                                ),
                              )
                            : _key(k)))
                    .toList()),
        ]),
      ),
    );
  }
}
