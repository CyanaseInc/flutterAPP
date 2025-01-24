import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 25.0, // Predefined size (diameter)
        width: 25.0, // Predefined size (diameter)
        child: CircularProgressIndicator(
          strokeWidth: 2.0, // Predefined border thickness
          valueColor:
              AlwaysStoppedAnimation<Color>(primaryColor), // Predefined color
        ),
      ),
    );
  }
}

class WhiteLoader extends StatelessWidget {
  const WhiteLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 30.0, // Predefined size (diameter)
        width: 30.0, // Predefined size (diameter)
        child: CircularProgressIndicator(
          strokeWidth: 2.0, // Predefined border thickness
          valueColor: AlwaysStoppedAnimation<Color>(white), // Predefined color
        ),
      ),
    );
  }
}
