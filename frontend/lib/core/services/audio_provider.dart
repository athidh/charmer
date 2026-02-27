import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Custom StreamAudioSource that serves in-memory bytes to just_audio.
/// Avoids writing to disk — low latency for farmer voice responses.
class _Base64AudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _Base64AudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

/// AudioProvider — decodes Base64 audio and plays via just_audio.
/// Handles URI-prefixed strings (e.g., "data:audio/mpeg;base64,...")
/// and raw Base64 strings from ElevenLabs backend.
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _lastError;
  String? get lastError => _lastError;

  AudioProvider() {
    // Listen for playback state changes
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }

      // Auto-reset when done
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });
  }

  /// Play a Base64-encoded audio string.
  /// Strips data URI prefixes if present (e.g., "data:audio/mpeg;base64,").
  /// Returns true on success, false on failure.
  Future<bool> playBase64Audio(String base64String) async {
    _lastError = null;

    try {
      // Strip data URI prefix if present
      final cleaned = _stripBase64Prefix(base64String);

      if (cleaned.isEmpty) {
        _lastError = 'Empty audio data';
        debugPrint('🔇 AudioProvider: empty base64 string');
        notifyListeners();
        return false;
      }

      // Decode Base64 → raw bytes
      final Uint8List audioBytes;
      try {
        audioBytes = Uint8List.fromList(base64Decode(cleaned));
      } catch (e) {
        _lastError = 'Base64 decode failed: $e';
        debugPrint('❌ AudioProvider: base64 decode error — $e');
        debugPrint(
          '   First 50 chars: ${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}',
        );
        notifyListeners();
        return false;
      }

      if (audioBytes.isEmpty) {
        _lastError = 'Decoded audio is 0 bytes';
        debugPrint('🔇 AudioProvider: decoded audio is empty');
        notifyListeners();
        return false;
      }

      debugPrint(
        '🔊 AudioProvider: playing ${audioBytes.length} bytes (${(audioBytes.length / 1024).toStringAsFixed(1)} KB)',
      );

      // Stop any previous playback and reset
      await _player.stop();

      // Set the audio source (in-memory, no disk write)
      await _player.setAudioSource(_Base64AudioSource(audioBytes));

      // Play
      await _player.play();

      return true;
    } catch (e, stack) {
      _lastError = 'Playback failed: $e';
      debugPrint('❌ AudioProvider: playback error — $e');
      debugPrint('   Stack: $stack');
      notifyListeners();
      return false;
    }
  }

  /// Stop current playback.
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    notifyListeners();
  }

  /// Strip Base64 data URI prefix.
  /// Handles: "data:audio/mpeg;base64,XXXX" → "XXXX"
  String _stripBase64Prefix(String input) {
    final trimmed = input.trim();

    // Regex to strip any data URI prefix
    final prefixPattern = RegExp(r'^data:[^;]+;base64,', caseSensitive: false);
    final cleaned = trimmed.replaceFirst(prefixPattern, '');

    if (cleaned.length != trimmed.length) {
      debugPrint(
        '🔧 AudioProvider: stripped data URI prefix (${trimmed.length - cleaned.length} chars)',
      );
    }

    return cleaned;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
