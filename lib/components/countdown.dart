import 'dart:async';

import 'package:flutter/material.dart';

class CountdownText extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onComplete;

  const CountdownText({super.key, this.initialSeconds = 120, this.onComplete});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "$_seconds",
      style: const TextStyle(fontSize: 64, color: Colors.blue),
      textAlign: TextAlign.center,
    );
  }
}
