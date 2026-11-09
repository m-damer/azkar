import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_info.dart';
import '../services/update_service.dart';

enum UpdatePhase { idle, checking, upToDate, available, downloading, error }

class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.info,
    this.progress = 0,
    this.installFailed = false,
  });

  final UpdatePhase phase;
  final UpdateInfo? info;
  final double progress;
  final bool installFailed;

  UpdateState copyWith({
    UpdatePhase? phase,
    UpdateInfo? info,
    double? progress,
    bool? installFailed,
  }) =>
      UpdateState(
        phase: phase ?? this.phase,
        info: info ?? this.info,
        progress: progress ?? this.progress,
        installFailed: installFailed ?? this.installFailed,
      );
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  UpdateService get _service => ref.read(updateServiceProvider);

  /// Checks GitHub for a newer build. [silent] keeps quiet when it fails.
  Future<void> check({bool silent = false}) async {
    if (state.phase == UpdatePhase.checking ||
        state.phase == UpdatePhase.downloading) {
      return;
    }
    state = const UpdateState(phase: UpdatePhase.checking);
    try {
      final info = await _service.latest();
      if (info != null && info.build > buildNumber) {
        state = UpdateState(phase: UpdatePhase.available, info: info);
      } else {
        state = const UpdateState(phase: UpdatePhase.upToDate);
      }
    } catch (_) {
      state = silent
          ? const UpdateState()
          : const UpdateState(phase: UpdatePhase.error);
    }
  }

  Future<void> downloadAndInstall() async {
    final info = state.info;
    if (info == null || state.phase == UpdatePhase.downloading) return;
    state = UpdateState(phase: UpdatePhase.downloading, info: info);
    try {
      final path = await _service.download(
        info,
        (p) => state = state.copyWith(progress: p),
      );
      final ok = await _service.install(path);
      state = UpdateState(
          phase: UpdatePhase.available, info: info, installFailed: !ok);
    } catch (_) {
      state = UpdateState(phase: UpdatePhase.error, info: info);
    }
  }
}

final updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);
