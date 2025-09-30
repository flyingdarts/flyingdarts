import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

part 'speech_event.dart';
part 'speech_state.dart';

/// Simple, fast BLoC for speech recognition, inspired by the original implementation.
@injectable
class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  SpeechBloc()
    : super(
        const SpeechState(
          isListening: false,
          lastEntry: "",
          enabled: true,
          error: "",
        ),
      ) {
    _initSpeechToText();
    on<SpeechButtonLongPressed>(_onSpeechButtonLongPressed);
    on<SpeechButtonLongPressEnded>(_onSpeechButtonLongPressEnded);
    on<SpeechButtonLongPressCancelled>(_onSpeechButtonLongPressCancelled);
    on<_SpeechResultFoundEvent>(_onSpeechResultFound);
  }

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechAvailable = false;

  Future<void> _initSpeechToText() async {
    try {
      final available = await _speechToText.initialize();
      _speechAvailable = available;
      if (!available) {
        emit(
          state.copyWith(
            enabled: false,
            error: "Speech recognition not available",
          ),
        );
      } else {
        emit(state.copyWith(enabled: true, error: ""));
      }
    } catch (e) {
      emit(
        state.copyWith(
          enabled: false,
          error: "Speech recognition initialization failed",
        ),
      );
      debugPrint('[SpeechBloc] Error initializing SpeechToText: $e');
    }
  }

  Future<void> _onSpeechButtonLongPressed(
    SpeechButtonLongPressed event,
    Emitter<SpeechState> emit,
  ) async {
    if (_speechAvailable) {
      _speechToText.listen(
        onResult: (stt.SpeechRecognitionResult result) {
          if (result.finalResult) {
            add(_SpeechResultFoundEvent(result.recognizedWords));
          }
        },
      );
      emit(state.copyWith(isListening: true, enabled: true, error: ""));
    } else {
      emit(
        state.copyWith(
          isListening: false,
          enabled: false,
          error: "Speech recognition not available",
        ),
      );
    }
  }

  Future<void> _onSpeechButtonLongPressEnded(
    SpeechButtonLongPressEnded event,
    Emitter<SpeechState> emit,
  ) async {
    await _speechToText.stop();
    emit(state.copyWith(isListening: false));
  }

  Future<void> _onSpeechButtonLongPressCancelled(
    SpeechButtonLongPressCancelled event,
    Emitter<SpeechState> emit,
  ) async {
    await _speechToText.cancel();
    emit(state.copyWith(isListening: false));
  }

  Future<void> _onSpeechResultFound(
    _SpeechResultFoundEvent event,
    Emitter<SpeechState> emit,
  ) async {
    final result = event.result;
    if (_isValidEntry(result)) {
      emit(state.copyWith(lastEntry: result, error: 'Great success!'));
    } else {
      emit(state.copyWith(lastEntry: '', error: 'Please try again!'));
    }
  }

  bool _isValidEntry(String entry) {
    try {
      double value = double.parse(entry);
      return value >= 0 && value <= 180;
    } catch (e) {
      return false;
    }
  }
}

// Internal event for result handling
class _SpeechResultFoundEvent extends SpeechEvent {
  const _SpeechResultFoundEvent(this.result);
  final String result;
  @override
  List<Object> get props => [result];
}
