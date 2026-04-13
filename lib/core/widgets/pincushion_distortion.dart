import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// A widget that applies a pincushion distortion effect using a FragmentShader.
/// This is used for high-end transitions in the Wandr app.
class PincushionDistortion extends StatelessWidget {
  const PincushionDistortion({
    super.key,
    required this.child,
    this.distortionAmount = 0.5,
    this.enabled = true,
  });

  final Widget child;
  
  /// The strength of the distortion. 
  /// Positive values create pincushion, negative create barrel.
  /// Typically animated from 1.0 to 0.0 for a reveal effect.
  final double distortionAmount;
  
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return ShaderBuilder(
      (BuildContext context, ui.FragmentShader shader, child) {
        return AnimatedSampler(
          (ui.Image image, size, canvas) {
            shader
              ..setFloat(0, size.width)
              ..setFloat(1, size.height)
              ..setFloat(2, distortionAmount)
              ..setImageSampler(0, image);

            canvas.drawRect(
              Offset.zero & size,
              Paint()..shader = shader,
            );
          },
          enabled: enabled,
          child: child!,
        );
      },
      assetKey: 'assets/shaders/pincushion.glsl',
      child: child,
    );
  }
}
