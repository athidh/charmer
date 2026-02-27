import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A full-screen looping video background for the auth/sign-in screen.
/// Plays `assets/loginpage.mp4` edge-to-edge with a subtle dark overlay
/// so white text on top remains readable.
class AnimatedShowcaseBackground extends StatefulWidget {
  const AnimatedShowcaseBackground({super.key});

  @override
  State<AnimatedShowcaseBackground> createState() =>
      _AnimatedShowcaseBackgroundState();
}

class _AnimatedShowcaseBackgroundState extends State<AnimatedShowcaseBackground> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/loginpage.mp4')
      ..setLooping(true)
      ..setVolume(0) // muted background
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Show a matching dark gradient while video loads
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-bleed video ──
        // Use FittedBox with BoxFit.cover so the video fills the screen
        // regardless of aspect ratio, cropping excess rather than letterboxing.
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),

        // ── Subtle dark scrim for text legibility ──
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.45),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
