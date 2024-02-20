import 'dart:async';
import 'package:flutter/material.dart';
import 'package:icalnotifier/animated_border.dart';

class AnimatedBorderState extends State<AnimatedBorder> {
  double hue = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        hue = (hue + 1) % 360;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
          width: 3.5,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Text(
        "ICal Notifier",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 32.0,
        ),
      ),
    );
  }
}
