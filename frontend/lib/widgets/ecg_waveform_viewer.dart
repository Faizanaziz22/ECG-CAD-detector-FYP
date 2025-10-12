import 'package:flutter/material.dart';
import 'dart:math' as math;

class ECGWaveformViewer extends StatefulWidget {
  final List<double> waveformData;
  final String leadName;
  final double amplitude;
  final double timeScale;
  final bool showGrid;
  final bool interactive;
  final Function(double)? onTimeSelected;
  final Color waveformColor;
  final double height;

  const ECGWaveformViewer({
    Key? key,
    required this.waveformData,
    this.leadName = 'Lead II',
    this.amplitude = 1.0,
    this.timeScale = 1.0,
    this.showGrid = true,
    this.interactive = false,
    this.onTimeSelected,
    this.waveformColor = Colors.green,
    this.height = 200,
  }) : super(key: key);

  @override
  State<ECGWaveformViewer> createState() => _ECGWaveformViewerState();
}

class _ECGWaveformViewerState extends State<ECGWaveformViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double? _selectedTime;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _resetPlayback() {
    setState(() {
      _isPlaying = false;
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lead name and controls
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.leadName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const Spacer(),
                if (widget.interactive) ...[
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayback,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _resetPlayback,
                    tooltip: 'Reset',
                  ),
                ],
              ],
            ),
          ),
          
          // ECG Waveform Display
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: GestureDetector(
              onTapDown: widget.interactive
                  ? (details) {
                      final RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      final localPosition =
                          renderBox.globalToLocal(details.globalPosition);
                      final timeRatio = localPosition.dx / renderBox.size.width;
                      final selectedTime = timeRatio * widget.waveformData.length;
                      
                      setState(() {
                        _selectedTime = selectedTime;
                      });
                      
                      if (widget.onTimeSelected != null) {
                        widget.onTimeSelected!(selectedTime);
                      }
                    }
                  : null,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ECGWaveformPainter(
                      waveformData: widget.waveformData,
                      amplitude: widget.amplitude,
                      timeScale: widget.timeScale,
                      showGrid: widget.showGrid,
                      waveformColor: widget.waveformColor,
                      selectedTime: _selectedTime,
                      animationProgress: _animation.value,
                      isPlaying: _isPlaying,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          
          // Footer with measurements and info
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildMeasurement('HR', '72 bpm', Colors.red),
                const SizedBox(width: 16),
                _buildMeasurement('PR', '160 ms', Colors.blue),
                const SizedBox(width: 16),
                _buildMeasurement('QRS', '90 ms', Colors.orange),
                const SizedBox(width: 16),
                _buildMeasurement('QT', '400 ms', Colors.purple),
                const Spacer(),
                if (_selectedTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Time: ${_selectedTime!.toStringAsFixed(1)}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurement(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class ECGWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double amplitude;
  final double timeScale;
  final bool showGrid;
  final Color waveformColor;
  final double? selectedTime;
  final double animationProgress;
  final bool isPlaying;

  ECGWaveformPainter({
    required this.waveformData,
    required this.amplitude,
    required this.timeScale,
    required this.showGrid,
    required this.waveformColor,
    this.selectedTime,
    required this.animationProgress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveformColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    final selectedPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    final playbackPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 3.0;

    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size, gridPaint);
    }

    // Draw ECG waveform
    if (waveformData.isNotEmpty) {
      _drawWaveform(canvas, size, paint);
    }

    // Draw selected time indicator
    if (selectedTime != null) {
      _drawSelectedTime(canvas, size, selectedPaint);
    }

    // Draw playback indicator
    if (isPlaying) {
      _drawPlaybackIndicator(canvas, size, playbackPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    // Vertical grid lines (time)
    final timeStep = size.width / 10;
    for (int i = 0; i <= 10; i++) {
      final x = i * timeStep;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal grid lines (amplitude)
    final amplitudeStep = size.height / 8;
    for (int i = 0; i <= 8; i++) {
      final y = i * amplitudeStep;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Center line (baseline)
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 1.0,
    );
  }

  void _drawWaveform(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final centerY = size.height / 2;
    final scaleX = size.width / waveformData.length;
    final scaleY = (size.height / 4) * amplitude; // Use 1/4 of height for amplitude range

    bool firstPoint = true;
    for (int i = 0; i < waveformData.length; i++) {
      final x = i * scaleX;
      final y = centerY - (waveformData[i] * scaleY);

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawSelectedTime(Canvas canvas, Size size, Paint paint) {
    if (selectedTime == null) return;

    final x = (selectedTime! / waveformData.length) * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );

    // Draw time value
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${selectedTime!.toStringAsFixed(1)}s',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final textX = x - textPainter.width / 2;
    const textY = 5.0;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  void _drawPlaybackIndicator(Canvas canvas, Size size, Paint paint) {
    final x = animationProgress * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(ECGWaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.timeScale != timeScale ||
        oldDelegate.selectedTime != selectedTime ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isPlaying != isPlaying;
  }
}

// Helper class to generate sample ECG data for demo purposes
class ECGDataGenerator {
  static List<double> generateSampleECG({
    int duration = 10, // seconds
    int sampleRate = 500, // Hz
    double heartRate = 75, // bpm
    bool addNoise = true,
    ECGPattern pattern = ECGPattern.normal,
  }) {
    final totalSamples = duration * sampleRate;
    final samples = <double>[];
    final period = 60.0 / heartRate; // seconds per beat

    for (int i = 0; i < totalSamples; i++) {
      final time = i / sampleRate;
      final beatPhase = (time % period) / period;
      
      double amplitude = _generateBeatAmplitude(beatPhase, pattern);
      
      // Add noise if requested
      if (addNoise) {
        amplitude += (math.Random().nextDouble() - 0.5) * 0.05;
      }
      
      samples.add(amplitude);
    }

    return samples;
  }

  static double _generateBeatAmplitude(double phase, ECGPattern pattern) {
    switch (pattern) {
      case ECGPattern.normal:
        return _generateNormalBeat(phase);
      case ECGPattern.atrial_fibrillation:
        return _generateAFibBeat(phase);
      case ECGPattern.bradycardia:
        return _generateBradycardiaBeat(phase);
      case ECGPattern.tachycardia:
        return _generateTachycardiaBeat(phase);
      default:
        return _generateNormalBeat(phase);
    }
  }

  static double _generateNormalBeat(double phase) {
    double amplitude = 0;
    
    if (phase < 0.1) {
      // P wave
      amplitude = 0.2 * math.sin(phase * math.pi / 0.1);
    } else if (phase < 0.2) {
      // PR segment
      amplitude = 0;
    } else if (phase < 0.25) {
      // Q wave
      amplitude = -0.1;
    } else if (phase < 0.3) {
      // R wave
      amplitude = 1.0 * math.sin((phase - 0.25) * math.pi / 0.05);
    } else if (phase < 0.35) {
      // S wave
      amplitude = -0.3 * math.sin((phase - 0.3) * math.pi / 0.05);
    } else if (phase < 0.5) {
      // ST segment
      amplitude = 0;
    } else if (phase < 0.7) {
      // T wave
      amplitude = 0.3 * math.sin((phase - 0.5) * math.pi / 0.2);
    }
    
    return amplitude;
  }

  static double _generateAFibBeat(double phase) {
    // Irregular rhythm with varying R-R intervals
    final irregularity = math.Random().nextDouble() * 0.3 - 0.15;
    final adjustedPhase = (phase + irregularity).clamp(0.0, 1.0);
    return _generateNormalBeat(adjustedPhase) * (0.8 + math.Random().nextDouble() * 0.4);
  }

  static double _generateBradycardiaBeat(double phase) {
    // Slower heart rate, normal morphology
    return _generateNormalBeat(phase) * 0.9;
  }

  static double _generateTachycardiaBeat(double phase) {
    // Faster heart rate, slightly altered morphology
    return _generateNormalBeat(phase) * 1.1;
  }
}

enum ECGPattern {
  normal,
  atrial_fibrillation,
  bradycardia,
  tachycardia,
}