import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/utils/quick_add_parser.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';

class VoiceQuickAddScreen extends ConsumerStatefulWidget {
  const VoiceQuickAddScreen({super.key});

  @override
  ConsumerState<VoiceQuickAddScreen> createState() =>
      _VoiceQuickAddScreenState();
}

class _VoiceQuickAddScreenState extends ConsumerState<VoiceQuickAddScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _backgroundController;
  late final AnimationController _waveController;
  static const MethodChannel _channel =
      MethodChannel('hisabi/voice_input');

  bool _isListening = false;
  bool _isSaving = false;
  String _rawTranscript = '';
  QuickAddParseResult? _parsed;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _startVoiceInput();
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _isListening = true;
      _rawTranscript = '';
      _parsed = null;
      _error = null;
    });

    try {
      final text = await _channel.invokeMethod<String>('startVoiceInput');
      if (!mounted) return;
      if (text == null || text.isEmpty) {
        setState(() {
          _isListening = false;
          _error = 'No speech recognized. Try again.';
        });
        return;
      }
      setState(() {
        _isListening = false;
        _rawTranscript = text;
        _parsed = parseQuickAdd(text);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _error = e.message ?? 'Speech recognition not available.';
      });
    }
  }

  Future<void> _stopListening() async {
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _showConfirmAndSave() async {
    final parsed = _parsed ?? parseQuickAdd(_rawTranscript);
    if (parsed == null) {
      setState(() {
        _error = 'Did not understand. Say e.g. "20 for groceries".';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Use this entry?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Heard: $_rawTranscript',
                style: const TextStyle(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Parsed: ${parsed.amount} for ${parsed.description}',
                style: const TextStyle(color: AppColors.onSurface),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retry'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _onSave(parsed);
    }
  }

  Future<void> _onSave([QuickAddParseResult? parsedArg]) async {
    final parsed = parsedArg ?? _parsed ?? parseQuickAdd(_rawTranscript);
    if (parsed == null) {
      setState(() {
        _error = 'Try saying something like: "20 for groceries".';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final item = ReceiptItem(
        name: parsed.description,
        quantity: 1.0,
        price: parsed.amount,
        total: parsed.amount,
      );

      final receipt = ReceiptModel(
        id: '',
        name: parsed.description,
        date: DateTime.now(),
        store: 'Quick Add',
        items: [item],
        total: parsed.amount,
      );

      final notifier = ref.read(receiptEntryProvider.notifier);
      final ok = await notifier.saveReceipt(
        'Quick: ${parsed.description}',
        receipt,
      );

      if (!mounted) return;

      if (!ok) {
        setState(() {
          _error = 'Failed to save receipt.';
        });
      } else {
        final formattedAmount =
            NumberFormat.currency(symbol: 'USD').format(parsed.amount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $formattedAmount for ${parsed.description}'),
          ),
        );
        if (context.mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error while saving: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _backgroundController.dispose();
    _waveController.dispose();
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'Quick Add',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          _AnimatedBackground(
            controller: _backgroundController,
            waveController: _waveController,
            isListening: _isListening,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _MicrophoneButton(
                          isListening: _isListening,
                          isSaving: _isSaving,
                          pulseController: _pulseController,
                          onTap: _isSaving
                              ? null
                              : () {
                                  if (!_isListening) {
                                    _startVoiceInput();
                                  }
                                },
                        ),
                        const SizedBox(height: 48),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isListening
                              ? const Text(
                                  'Listening...',
                                  key: ValueKey('listening'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                )
                              : _rawTranscript.isEmpty
                                  ? const Text(
                                      'Tap to start recording',
                                      key: ValueKey('idle'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.onSurfaceMuted,
                                        letterSpacing: 0.2,
                                      ),
                                    )
                                  : const SizedBox.shrink(key: ValueKey('transcript')),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _rawTranscript.isNotEmpty
                                ? AppColors.primary.withOpacity(0.3)
                                : AppColors.border.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: _rawTranscript.isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: _rawTranscript.isEmpty
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.mic_none,
                                    size: 18,
                                    color: AppColors.onSurfaceMuted.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Say something like "20 for groceries"...',
                                    style: TextStyle(
                                      color: AppColors.onSurfaceMuted.withOpacity(0.7),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'TRANSCRIPT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _rawTranscript,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                      fontSize: 16,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/add-receipt');
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isSaving || _rawTranscript.isEmpty
                                  ? null
                                  : _showConfirmAndSave,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final AnimationController waveController;
  final bool isListening;

  const _AnimatedBackground({
    required this.controller,
    required this.waveController,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, waveController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            animationValue: controller.value,
            waveValue: waveController.value,
            isListening: isListening,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final double waveValue;
  final bool isListening;

  _BackgroundPainter({
    required this.animationValue,
    required this.waveValue,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gradient circles that move
    for (int i = 0; i < 3; i++) {
      final offset = animationValue * 2 * math.pi + (i * 2 * math.pi / 3);
      final x = size.width * 0.5 +
          math.cos(offset) * size.width * 0.3;
      final y = size.height * 0.3 +
          math.sin(offset) * size.height * 0.2;

      final radius = 80 + math.sin(animationValue * 2 * math.pi + i) * 30;
      final opacity = 0.03 + math.sin(animationValue * 2 * math.pi + i) * 0.02;

      paint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Wave effect at bottom
    if (isListening) {
      final path = Path();
      path.moveTo(0, size.height * 0.7);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.7 +
            math.sin((x / size.width * 4 * math.pi) + (waveValue * 2 * math.pi)) *
                20;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = AppColors.primary.withOpacity(0.05);
      canvas.drawPath(path, paint);
    }

    // Floating particles
    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final seed = i * 100;
      final x = (random.nextDouble() * size.width +
              math.sin(animationValue * 2 * math.pi + seed) * 50) %
          size.width;
      final y = (random.nextDouble() * size.height * 0.6 +
              math.cos(animationValue * 2 * math.pi + seed) * 30) %
          (size.height * 0.6);

      final particleSize = 2 + math.sin(animationValue * 2 * math.pi + seed) * 1;
      final opacity = 0.1 + math.sin(animationValue * 2 * math.pi + seed) * 0.05;

      paint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.isListening != isListening;
  }
}

class _MicrophoneButton extends StatelessWidget {
  final bool isListening;
  final bool isSaving;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  const _MicrophoneButton({
    required this.isListening,
    required this.isSaving,
    required this.pulseController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final pulseScale = isListening
              ? 1.0 + pulseController.value * 0.15
              : 1.0;
          final glowOpacity = isListening
              ? 0.3 + pulseController.value * 0.2
              : 0.1;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              if (isListening)
                ...List.generate(3, (index) {
                  final delay = index * 0.3;
                  final adjustedValue = (pulseController.value + delay) % 1.0;
                  final scale = 1.0 + adjustedValue * 0.5;
                  final opacity = (1.0 - adjustedValue) * 0.2;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
              // Middle ring
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(glowOpacity),
                        AppColors.primary.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Main button
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isListening
                        ? [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ]
                        : [
                            AppColors.surface,
                            AppColors.surfaceVariant,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isListening
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.white : AppColors.onSurfaceMuted,
                  size: 48,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

