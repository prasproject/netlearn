import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

/// NetLearn — Audio Provider
/// Manages sound effects, background music, and audio narration.
/// Uses audioplayers for playback + HapticFeedback for tactile response.

enum SoundEffect {
  buttonTap,
  correct,
  incorrect,
  quizStart,
  quizComplete,
  win,         // score >= 70
  lose,        // score < 50
  excellent,   // score >= 90
  xpGained,
  badgeUnlock,
  packetSend,
  packetArrive,
  slideNext,
  levelUp,
  streak,
  countdown,
  timerWarning,
  navigation,
}

class AudioState {
  final bool sfxEnabled;
  final bool musicEnabled;
  final bool narrationPlaying;
  final double sfxVolume;
  final double musicVolume;

  const AudioState({
    this.sfxEnabled = true,
    this.musicEnabled = false,
    this.narrationPlaying = false,
    this.sfxVolume = 0.7,
    this.musicVolume = 0.3,
  });

  AudioState copyWith({
    bool? sfxEnabled,
    bool? musicEnabled,
    bool? narrationPlaying,
    double? sfxVolume,
    double? musicVolume,
  }) {
    return AudioState(
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      narrationPlaying: narrationPlaying ?? this.narrationPlaying,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState()) {
    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();
    _narrationPlayer = AudioPlayer();
  }

  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _musicPlayer;
  late final AudioPlayer _narrationPlayer;
  static const String _backgroundMusicAsset = 'audio/retro.mp3';

  /// Play a sound effect with haptic feedback
  Future<void> playSfx(SoundEffect effect) async {
    if (!state.sfxEnabled) return;

    // Haptic feedback for all sound effects
    switch (effect) {
      case SoundEffect.correct:
      case SoundEffect.win:
      case SoundEffect.excellent:
      case SoundEffect.badgeUnlock:
      case SoundEffect.levelUp:
        HapticFeedback.mediumImpact();
        break;
      case SoundEffect.incorrect:
      case SoundEffect.lose:
      case SoundEffect.timerWarning:
        HapticFeedback.heavyImpact();
        break;
      case SoundEffect.buttonTap:
      case SoundEffect.navigation:
      case SoundEffect.slideNext:
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }

    // Try to play audio file (will gracefully fail if asset not found)
    try {
      final assetPath = _getAssetPath(effect);
      if (assetPath != null) {
        await _sfxPlayer.setVolume(state.sfxVolume);
        await _sfxPlayer.play(AssetSource(assetPath));
      }
    } catch (_) {
      // Gracefully handle missing audio assets
      // Haptic feedback still provides tactile response
    }
  }

  /// Play background music (loops)
  Future<void> playMusic() async {
    if (!state.musicEnabled) return;
    try {
      await _musicPlayer.setVolume(state.musicVolume);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      if (_musicPlayer.state == PlayerState.playing) return;
      await _musicPlayer.play(AssetSource(_backgroundMusicAsset));
    } catch (_) {
      // No music file available
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  /// Play audio narration for a material slide
  Future<void> playNarration(String? audioPath) async {
    if (audioPath == null) return;
    state = state.copyWith(narrationPlaying: true);
    try {
      await _narrationPlayer.setVolume(1.0);
      await _narrationPlayer.play(AssetSource(audioPath));
      _narrationPlayer.onPlayerComplete.listen((_) {
        if (mounted) state = state.copyWith(narrationPlaying: false);
      });
    } catch (_) {
      state = state.copyWith(narrationPlaying: false);
    }
  }

  /// Stop narration
  Future<void> stopNarration() async {
    await _narrationPlayer.stop();
    state = state.copyWith(narrationPlaying: false);
  }

  /// Toggle sound effects
  void toggleSfx() {
    state = state.copyWith(sfxEnabled: !state.sfxEnabled);
  }

  /// Toggle background music
  void toggleMusic() {
    final newVal = !state.musicEnabled;
    state = state.copyWith(musicEnabled: newVal);
    if (newVal) {
      playMusic();
    } else {
      stopMusic();
    }
  }

  /// Set SFX volume (0.0 to 1.0)
  void setSfxVolume(double vol) {
    state = state.copyWith(sfxVolume: vol.clamp(0.0, 1.0));
  }

  /// Mute all audio
  void muteAll() {
    state = state.copyWith(sfxEnabled: false, musicEnabled: false);
    stopMusic();
    stopNarration();
  }

  /// Unmute all audio
  void unmuteAll() {
    state = state.copyWith(sfxEnabled: true);
  }

  /// Map sound effect to asset path
  String? _getAssetPath(SoundEffect effect) {
    return switch (effect) {
      SoundEffect.correct => 'audio/correct.mp3',
      SoundEffect.incorrect => 'audio/incorrect.mp3',
      SoundEffect.win => 'audio/win.mp3',
      SoundEffect.excellent => 'audio/win.mp3',
      SoundEffect.lose => 'audio/lose.mp3',
      _ => 'audio/beep.mp3', // Fallback for all other sounds to avoid missing asset crashes
    };
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
    _narrationPlayer.dispose();
    super.dispose();
  }
}

final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});
