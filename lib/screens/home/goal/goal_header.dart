import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:cyanase/theme/theme.dart';

class GoalHeader extends StatefulWidget {
  final double saved;
  final double goal;

  GoalHeader({
    required this.saved,
    required this.goal,
  });

  @override
  _GoalHeaderState createState() => _GoalHeaderState();
}

class _GoalHeaderState extends State<GoalHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Animation duration
      vsync: this,
    );

    // Calculate the progress value (as a percentage)
    final double progressValue = (widget.saved / widget.goal) * 100;

    // Define the animation using Tween
    _animation =
        Tween<double>(begin: 0, end: progressValue).animate(_controller)
          ..addListener(() {
            setState(() {}); // Update the UI on each animation tick
          });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Gauge with Updated RadialAxis
          Container(
            height: 180, // Fixed height to constrain the gauge size
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  showLabels: false,
                  showTicks: false,
                  startAngle: 180,
                  endAngle: 0,
                  radiusFactor: 0.8, // Adjusted to reduce space around the bar
                  canScaleToFit: true,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.1,
                    color: const Color.fromARGB(30, 0, 72, 181),
                    thicknessUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.startCurve,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: _animation.value, // Use the animated value
                      width: 0.2, // Increased thickness of the bar
                      sizeUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                      color: primaryTwo,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '${_animation.value.toStringAsFixed(1)}%', // Use the animated value
                        style: TextStyle(
                          fontSize: 30, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color:
                              primaryColor, // Ensure the text color is visible
                        ),
                      ),
                      angle:
                          270, // Adjusted angle to place text in the middle of the curve
                      positionFactor: 0.2, // Adjusted to center the text
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Savings Progress Text
          Center(
            child: Text(
              'Saved out of UGX${widget.goal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15, // Reduced font size
                color: Colors.grey[600],
                fontWeight: FontWeight.bold, // Using grey for the text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
