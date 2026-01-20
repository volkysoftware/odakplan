import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/notifications/notification_service.dart';

class FocusTimerState {
  final bool isRunning;
  final bool isBreak;

  final int workMinutes;
  final int breakMinutes;

  final int sessionTotalSeconds;
  final int remainingSeconds;

  const FocusTimerState({
    required this.isRunning,
    required this.isBreak,
    required this.workMinutes,
    required this.breakMinutes,
    required this.sessionTotalSeconds,
    required this.remainingSeconds,
  });

  int get workedSeconds =>
      (sessionTotalSeconds - remainingSeconds).clamp(0, sessionTotalSeconds);

  FocusTimerState copyWith({
    bool? isRunning,
    bool? isBreak,
    int? workMinutes,
    int? breakMinutes,
    int? sessionTotalSeconds,
    int? remainingSeconds,
  }) {
    return FocusTimerState(
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      sessionTotalSeconds: sessionTotalSeconds ?? this.sessionTotalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerController, FocusTimerState>((ref) {
  final c = FocusTimerController(ref);
  ref.onDispose(c.dispose);
  return c;
});

class FocusTimerController extends StateNotifier<FocusTimerState> {
  FocusTimerController(this.ref)
      : super(const FocusTimerState(
          isRunning: false,
          isBreak: false,
          workMinutes: 25,
          breakMinutes: 5,
          sessionTotalSeconds: 25 * 60,
          remainingSeconds: 25 * 60,
        ));

  final Ref ref;

  Timer? _ticker;
  DateTime? _endAt;

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }

  void setWorkMinutes(int minutes) {
    if (minutes <= 0) return;
    state = state.copyWith(workMinutes: minutes);

    // Çalışma modundaysa ve çalışmıyorsa süreyi ekrana yansıt
    if (!state.isBreak && !state.isRunning) {
      applyMode(isBreak: false);
    }
  }

  Future<void> applyMode({required bool isBreak}) async {
    final minutes = isBreak ? state.breakMinutes : state.workMinutes;

    _ticker?.cancel();
    _ticker = null;
    _endAt = null;

    state = state.copyWith(
      isBreak: isBreak,
      isRunning: false,
      sessionTotalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
    );

    // ✅ mode değişince: ongoing + finish schedule temizlensin
    await NotificationService.instance.cancelFocusOngoing();
    await NotificationService.instance.cancelFocusFinishedSchedule();
  }

  String _formatRemainingMinutesOnly(int remainingSeconds) {
    // Kullanıcı "dakika cinsinden" istedi.
    final mins = (remainingSeconds / 60).ceil().clamp(0, 24 * 60);
    return '$mins dk';
  }

  Future<void> _updateOngoingNotification() async {
    if (!state.isRunning) return;

    final title = state.isBreak ? 'Mola devam ediyor' : 'Odak devam ediyor';
    final body = 'Kalan: ${_formatRemainingMinutesOnly(state.remainingSeconds)}';

    await NotificationService.instance.showFocusOngoing(
      title: title,
      body: body,
    );
  }

  Future<void> start() async {
    if (state.isRunning) return;

    final now = DateTime.now();
    _endAt = now.add(Duration(seconds: state.remainingSeconds));
    final endAt = _endAt!;

    state = state.copyWith(isRunning: true);

    // ✅ Ongoing bildirimi başlat
    await _updateOngoingNotification();

    // ✅ Seans bitiş bildirimini planla (uygulama kapalı olsa da gelsin)
    // Not: mola için de planlıyoruz; istersen mola bitişi için farklı metin verebiliriz.
    await NotificationService.instance.scheduleFocusFinishedAt(
      endAt: endAt,
      title: state.isBreak ? 'Mola bitti' : 'Seans bitti',
      body: state.isBreak
          ? 'Mola tamamlandı. Devam edebilirsin ✅'
          : 'Tebrikler! Seansın tamamlandı ✅',
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final end = _endAt;
      if (end == null) return;

      final left = end.difference(DateTime.now()).inSeconds;

      if (left <= 0) {
        _ticker?.cancel();
        _ticker = null;
        _endAt = null;

        state = state.copyWith(isRunning: false, remainingSeconds: 0);

        // ✅ ongoing kapat (finish bildirimi zaten schedule edildi)
        await NotificationService.instance.cancelFocusOngoing();
        return;
      }

      state = state.copyWith(remainingSeconds: left);

      // ✅ ongoing bildirimi güncelle
      // onlyAlertOnce=true olduğu için her tick rahatsız etmez
      await _updateOngoingNotification();
    });
  }

  Future<void> pause() async {
    _ticker?.cancel();
    _ticker = null;
    _endAt = null;

    state = state.copyWith(isRunning: false);

    // ✅ durunca: ongoing kapat + bitiş schedule iptal
    await NotificationService.instance.cancelFocusOngoing();
    await NotificationService.instance.cancelFocusFinishedSchedule();
  }

  Future<void> reset() async {
    _ticker?.cancel();
    _ticker = null;
    _endAt = null;

    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.sessionTotalSeconds,
    );

    // ✅ sıfırla: ongoing kapat + bitiş schedule iptal
    await NotificationService.instance.cancelFocusOngoing();
    await NotificationService.instance.cancelFocusFinishedSchedule();
  }

  /// “Tamamladım” için: kaç dakika çalışıldıysa döndürür (ceil ile yarım dakika da sayılır)
  Future<int> completeEarlyMinutes({bool ceil = true}) async {
    if (state.isBreak) {
      await pause();
      return 0;
    }

    final worked = state.workedSeconds;
    await pause();

    if (worked <= 0) return 0;

    final minutes = ceil ? (worked / 60).ceil() : (worked / 60).floor();
    return minutes <= 0 ? 0 : minutes;
  }
}
