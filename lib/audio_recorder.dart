import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _SimpleAudioRecorderState();
}

/// Complete [_AudioRecorderState]
class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    super.initState();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => setState(() => _amplitude = amp));
  }

  Future<void> _start() async {
    debugPrint("_start");

    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        debugPrint('${AudioEncoder.aacLc.name} supported: $isSupported');

        // final devs = await _audioRecorder.listInputDevices();
        // final isRecording = await _audioRecorder.isRecording();

        await _audioRecorder.start(path: "/tmp/file.m4a");
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    if (path != null) {
      widget.onStop(path);
    }
  }

  // Future<void> _pause() async {
  //   _timer?.cancel();
  //   await _audioRecorder.pause();
  // }

  // Future<void> _resume() async {
  //   _startTimer();
  //   await _audioRecorder.resume();
  // }

  @override
  Widget build(BuildContext context) {
    return _buildRecordStopControl();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
        child: InkWell(
      child: SizedBox(width: 56, height: 56, child: icon),
      onTap: () {
        debugPrint("Record button tap: $_recordState");
        (_recordState != RecordState.stop) ? _stop() : _start();
      },
    ));
  }

  // Widget _buildPauseResumeControl() {
  //   if (_recordState == RecordState.stop) {
  //     return const SizedBox.shrink();
  //   }

  //   late Icon icon;
  //   late Color color;

  //   if (_recordState == RecordState.record) {
  //     icon = const Icon(Icons.pause, color: Colors.red, size: 30);
  //     color = Colors.red.withOpacity(0.1);
  //   } else {
  //     final theme = Theme.of(context);
  //     icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
  //     color = theme.primaryColor.withOpacity(0.1);
  //   }

  //   return ClipOval(
  //     child: Material(
  //       color: color,
  //       child: InkWell(
  //         child: SizedBox(width: 56, height: 56, child: icon),
  //         onTap: () {
  //           (_recordState == RecordState.pause) ? _resume() : _pause();
  //         },
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildText() {
  //   if (_recordState != RecordState.stop) {
  //     return _buildTimer();
  //   }

  //   return const Text("Waiting to record");
  // }

  // Widget _buildTimer() {
  //   final String minutes = _formatNumber(_recordDuration ~/ 60);
  //   final String seconds = _formatNumber(_recordDuration % 60);

  //   return Text(
  //     '$minutes : $seconds',
  //     style: const TextStyle(color: Colors.red),
  //   );
  // }

  // String _formatNumber(int number) {
  //   String numberStr = number.toString();
  //   if (number < 10) {
  //     numberStr = '0$numberStr';
  //   }

  //   return numberStr;
  // }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}

/// Alternative simple version [_SimpleAudioRecorderState]
/// for demo purpose for event #4
class _SimpleAudioRecorderState extends State<AudioRecorder> {
  final _audioRecorder = Record();

  bool isRecording = false;

  Future<void> _start() async {
    debugPrint("_start");
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          isRecording = true;
        });
        await _audioRecorder.start(path: "/tmp/file.m4a");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }

    isRecording = await _audioRecorder.isRecording();
  }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();

    isRecording = false;

    if (path != null) {
      widget.onStop(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
        child: InkWell(
      child: SizedBox(width: 56, height: 56, child: icon),
      onTap: () {
        debugPrint("Record button tap: $isRecording");
        isRecording ? _stop() : _start();
      },
    ));
  }

  Icon get icon {
    if (isRecording) {
      return const Icon(Icons.stop, color: Colors.red, size: 30);
    }
    return const Icon(Icons.mic, color: Colors.blue, size: 30);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
