import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class OrderSoundService {
  static const String _assetPath = 'order_incoming_loop.mp3';
  static const String _pickupConfirmationAssetPath = 'pickup-confirmation.wav';

  static Future<void> initialize() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  AudioPlayer? _playerInstance;
  AudioPlayer get _player =>
      _playerInstance ??= AudioPlayer()
        ..audioCache = AudioCache(prefix: 'lib/assets/');
  AudioPlayer? _pickupPlayerInstance;
  AudioPlayer get _pickupPlayer =>
      _pickupPlayerInstance ??= AudioPlayer()
        ..audioCache = AudioCache(prefix: 'lib/assets/');
  Future<void>? _playbackFuture;
  bool _isLooping = false;
  StreamSubscription<PlayerState>? _stateSubscription;

  Future<void> playIncomingOrderSound() {
    final activePlayback = _playbackFuture;
    if (activePlayback != null) {
      return activePlayback;
    }

    final playback = _playSequence().whenComplete(() {
      _playbackFuture = null;
    });

    _playbackFuture = playback;
    return playback;
  }

  Future<void> startLoopingIncomingOrderSound() async {
    if (_isLooping) return;

    _isLooping = true;
    _playbackFuture = null;

    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(_assetPath));

    _stateSubscription?.cancel();
    _stateSubscription = _player.onPlayerStateChanged.listen((playerState) {
      if (!_isLooping) return;
      if (playerState == PlayerState.stopped ||
          playerState == PlayerState.completed) {
        _player.play(AssetSource(_assetPath));
      }
    });
  }

  Future<void> stopIncomingOrderSound() async {
    _isLooping = false;
    _playbackFuture = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playPickupConfirmationSound() async {
    await _pickupPlayer.stop();
    await _pickupPlayer.setReleaseMode(ReleaseMode.stop);
    await _pickupPlayer.play(AssetSource(_pickupConfirmationAssetPath));
  }

  Future<void> dispose() async {
    _isLooping = false;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _playerInstance?.dispose();
    _playerInstance = null;
    await _pickupPlayerInstance?.dispose();
    _pickupPlayerInstance = null;
  }

  Future<void> _playSequence() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _playOnce();
  }

  Future<void> _playOnce() async {
    await _player.stop();
    final completed = _player.onPlayerComplete.first;
    await _player.play(AssetSource(_assetPath));
    try {
      await completed.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      return;
    }
  }
}
